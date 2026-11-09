"""Blink the power-button LED while fprintd waits for a finger."""

import math
import os
import signal
import subprocess
import sys
import threading
import time

DEFAULT_LED = "chromeos:white:power"
DEFAULT_ON_S = "0.25"
DEFAULT_OFF_S = "0.25"
DEFAULT_MAX_S = "60"
DEFAULT_MONITOR = "dbus-monitor"

LED_ROOT = "/sys/class/leds"
TRIGGER_NONE = "none"
TRIGGER_AUTO = "chromeos-auto"
BRIGHTNESS_ON = "100"
BRIGHTNESS_OFF = "0"

START_MEMBERS = {"VerifyStart", "EnrollStart"}
STOP_MEMBERS = {"VerifyStop", "EnrollStop", "Release"}
STATUS_MEMBERS = {"VerifyStatus", "EnrollStatus"}
DEVICE_INTERFACE = "interface=net.reactivated.Fprint.Device"


def env_float(name, default):
    """Read a positive float from the environment, falling back on error."""
    raw = os.environ.get(name, default)
    try:
        value = float(raw)
    except ValueError:
        value = 0.0
    if not math.isfinite(value) or value <= 0:
        print(
            "framework-fingerprint-led-blink: invalid %s=%r, using %s"
            % (name, raw, default),
            file=sys.stderr,
        )
        return float(default)
    return value


class Led:
    """Controls one LED under /sys/class/leds."""

    def __init__(self, name):
        self.directory = os.path.join(LED_ROOT, name)

    def _write(self, filename, value):
        path = os.path.join(self.directory, filename)
        try:
            with open(path, "w", encoding="ascii") as handle:
                handle.write(value)
            return True
        except OSError as error:
            print(
                "framework-fingerprint-led-blink: cannot write %r to %s: %s"
                % (value, path, error),
                file=sys.stderr,
            )
            return False

    def restore(self):
        """Give the LED back to the embedded controller."""
        self._write("trigger", TRIGGER_AUTO)

    def claim_for_blinking(self):
        """Detach the LED from the controller trigger."""
        self._write("trigger", TRIGGER_NONE)

    def set_brightness(self, value):
        self._write("brightness", value)


class Blinker:
    """Owns a worker thread that blinks until told to stop or it times out.

    All commands go through a condition variable, so a stop that arrives
    while the worker is finishing a blink can never be lost, and the LED
    is always restored to the controller trigger before the worker
    reports itself idle.
    """

    def __init__(self, led, on_s, off_s, max_s):
        self.led = led
        self.on_s = on_s
        self.off_s = off_s
        self.max_s = max_s
        self._condition = threading.Condition()
        self._command = None
        self._shutdown = False
        self._busy = False
        self._idle = True
        self._thread = threading.Thread(
            target=self._run, name="blinker", daemon=True
        )
        self._thread.start()

    def _run(self):
        while True:
            with self._condition:
                while self._command is None and not self._shutdown:
                    self._condition.wait()
                if self._shutdown:
                    self._restore_locked()
                    return
                command = self._command
                self._command = None
                if command == "stop":
                    self._restore_locked()
                    continue
                self._busy = True
                self._idle = False
            self._blink()
            with self._condition:
                self._busy = False
                self._restore_locked()

    def _restore_locked(self):
        self.led.set_brightness(BRIGHTNESS_OFF)
        self.led.restore()
        self._idle = True
        self._busy = False
        self._condition.notify_all()

    def _sleep_until(self, seconds, deadline):
        """Wait, returning False if a stop or shutdown interrupts us."""
        end = time.monotonic() + seconds
        with self._condition:
            while True:
                if self._shutdown or self._command == "stop":
                    self._command = None
                    return False
                if self._command == "start":
                    self._command = None
                remaining = min(end - time.monotonic(), deadline -
                                time.monotonic())
                if remaining <= 0:
                    return True
                self._condition.wait(remaining)

    def _blink(self):
        deadline = time.monotonic() + self.max_s
        self.led.claim_for_blinking()
        try:
            while time.monotonic() < deadline:
                self.led.set_brightness(BRIGHTNESS_ON)
                if not self._sleep_until(self.on_s, deadline):
                    break
                self.led.set_brightness(BRIGHTNESS_OFF)
                if not self._sleep_until(self.off_s, deadline):
                    break
        finally:
            self.led.set_brightness(BRIGHTNESS_OFF)
            self.led.restore()

    def start(self):
        """Request blinking; harmless if a blink is already in progress."""
        with self._condition:
            self._command = "start"
            self._idle = False
            self._condition.notify_all()

    def stop(self):
        """Request a stop and block until the LED has been restored."""
        with self._condition:
            self._command = "stop"
            self._condition.notify_all()
            while not self._idle:
                self._condition.wait()

    def shutdown(self):
        """Stop blinking and stop the worker thread."""
        with self._condition:
            self._shutdown = True
            self._command = None
            self._condition.notify_all()
        self._thread.join(timeout=5)


def extract_member(line):
    """Return the D-Bus member name from a header line, if present."""
    if "member=" not in line:
        return None
    member = line.split("member=", 1)[1]
    return member.split()[0].split(",")[0].rstrip(";")


def first_boolean(lines):
    """Return the first boolean argument found in a status message."""
    for line in lines:
        if "boolean true" in line:
            return True
        if "boolean false" in line:
            return False
    return None


class MonitorParser:
    """Turns dbus-monitor output lines into start/stop decisions."""

    def __init__(self, blinker):
        self.blinker = blinker
        self._lines = []
        self._kind = None
        self._is_device = False
        self._member = None
        self._status_stopped = False

    def feed(self, line):
        stripped = line.strip()
        kind = self._message_kind(stripped)
        if kind is not None:
            self._finish()
            self._lines = [line]
            self._kind = kind
            self._is_device = False
            self._member = None
            self._status_stopped = False
            self._inspect(line)
            return
        if not self._lines:
            return
        if not stripped:
            self._finish()
            self._lines = []
            self._kind = None
            self._is_device = False
            self._member = None
            self._status_stopped = False
            return
        self._lines.append(line)
        self._inspect(line)
        self._maybe_stop_on_status(line)

    def _inspect(self, line):
        if DEVICE_INTERFACE in line:
            self._is_device = True
        member = extract_member(line)
        if member is not None:
            self._member = member

    def _maybe_stop_on_status(self, line):
        """React as soon as a status signal reports a finger present.

        dbus-monitor may keep the message open until the next message
        arrives, so waiting for the message to be complete could leave
        the LED blinking after verification has already succeeded.
        """
        if self._status_stopped:
            return
        if self._kind != "signal" or not self._is_device:
            return
        if self._member not in STATUS_MEMBERS:
            return
        if "boolean true" not in line:
            return
        self._status_stopped = True
        self.blinker.stop()

    @staticmethod
    def _message_kind(stripped):
        if stripped.startswith("method call "):
            return "call"
        if stripped.startswith("signal "):
            return "signal"
        if stripped.startswith("method return ") or stripped.startswith(
            "error "
        ):
            return "other"
        return None

    def _finish(self):
        if not self._is_device or self._member is None:
            return
        if self._kind == "call":
            if self._member in START_MEMBERS:
                self.blinker.start()
            elif self._member in STOP_MEMBERS:
                self.blinker.stop()
        elif self._kind == "signal" and self._member in STATUS_MEMBERS:
            if not self._status_stopped and first_boolean(self._lines):
                self.blinker.stop()

    def finish(self):
        self._finish()


def read_monitor(stream, parser, stop_event):
    """Read dbus-monitor output until EOF or shutdown."""
    try:
        for raw_line in stream:
            if stop_event.is_set():
                break
            line = raw_line.decode("utf-8", "replace")
            parser.feed(line.rstrip("\n"))
        parser.finish()
    except (OSError, ValueError):
        pass


def monitor_command(executable):
    """Build the dbus-monitor argument vector."""
    return [
        executable,
        "--system",
        "interface='net.reactivated.Fprint.Device'",
    ]


def terminate(process):
    """Terminate the monitor subprocess and reap it."""
    if process is None:
        return
    try:
        process.terminate()
    except OSError:
        pass
    try:
        process.wait(timeout=5)
    except subprocess.TimeoutExpired:
        process.kill()
        process.wait()


def main():
    led_name = os.environ.get("FINGERPRINT_LED_BLINK_LED", DEFAULT_LED)
    on_s = env_float("FINGERPRINT_LED_BLINK_ON_S", DEFAULT_ON_S)
    off_s = env_float("FINGERPRINT_LED_BLINK_OFF_S", DEFAULT_OFF_S)
    max_s = env_float("FINGERPRINT_LED_BLINK_MAX_S", DEFAULT_MAX_S)
    monitor = os.environ.get(
        "FINGERPRINT_LED_BLINK_DBUS_MONITOR", DEFAULT_MONITOR
    )

    led = Led(led_name)
    led.restore()
    blinker = Blinker(led, on_s, off_s, max_s)
    stop_event = threading.Event()

    def handle_signal(signum, frame):
        stop_event.set()

    signal.signal(signal.SIGTERM, handle_signal)
    signal.signal(signal.SIGINT, handle_signal)

    process = None
    reader = None
    exit_code = 1
    try:
        process = subprocess.Popen(
            monitor_command(monitor),
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
        )
        parser = MonitorParser(blinker)
        reader = threading.Thread(
            target=read_monitor,
            args=(process.stdout, parser, stop_event),
            name="monitor-reader",
            daemon=True,
        )
        reader.start()
        while not stop_event.is_set() and process.poll() is None:
            stop_event.wait(0.2)
        if stop_event.is_set():
            exit_code = 0
        else:
            process.wait()
            exit_code = 1
    except OSError as error:
        print(
            "framework-fingerprint-led-blink: cannot run %r: %s"
            % (monitor, error),
            file=sys.stderr,
        )
        exit_code = 1
    except KeyboardInterrupt:
        exit_code = 0
    finally:
        signal.signal(signal.SIGTERM, signal.SIG_IGN)
        signal.signal(signal.SIGINT, signal.SIG_IGN)
        terminate(process)
        if reader is not None:
            reader.join(timeout=5)
        if process is not None and process.stdout is not None:
            process.stdout.close()
        blinker.shutdown()
        led.restore()

    sys.exit(exit_code)


if __name__ == "__main__":
    main()
