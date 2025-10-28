# reader beware: scuffed code ahead to allow occasional usage of gpg-agent for ssh keys
let
  writeSourceable =
    name: text:
    { writeTextFile }:
    writeTextFile {
      inherit name;
      executable = true;
      destination = "/bin/${name}";
      inherit text;
      meta.mainProgram = name;
    };

  # switch to ssh-agent for key management
  ssh-ssh =
    writeSourceable "ssh-ssh"
      # https://github.com/NixOS/nixpkgs/blob/78e34d1667d32d8a0ffc3eba4591ff256e80576e/nixos/modules/programs/ssh.nix#L400
      ''export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent"'';

  # switch to gpg-agent for key management
  gpg-ssh =
    gpgpkg:
    writeSourceable "gpg-ssh"
      # https://github.com/NixOS/nixpkgs/blob/6a08e6bb4e46ff7fcbb53d409b253f6bad8a28ce/nixos/modules/programs/gnupg.nix#L231
      ''
        sock=$(${gpgpkg}/bin/gpgconf --list-dirs agent-ssh-socket)
        export SSH_AUTH_SOCK="$sock"
      '';
in
{
  flake.modules.nixos.base =
    { pkgs, config, ... }:
    {
      environment.defaultPackages = [
        (pkgs.callPackage ssh-ssh { })
        (pkgs.callPackage (gpg-ssh config.programs.gnupg.package) { })
      ];

      # dont use gnome gcr ssh agent (keyring)
      services.gnome.gcr-ssh-agent.enable = false;

      # good old fashioned ssh-agent
      programs.ssh.startAgent = true;

      # gpg for ssh is sometimes useful (shoutout yubikey)
      programs.gnupg.agent = {
        enable = true;
        # enableSSHSupport = true; # see below
      };

      # https://github.com/NixOS/nixpkgs/blob/6a08e6bb4e46ff7fcbb53d409b253f6bad8a28ce/nixos/modules/programs/gnupg.nix#L235
      # nixos trying to make me decide between gpg-agent ssh support and ssh-agent :(

      # after all, why cant i have it?
      # https://github.com/NixOS/nixpkgs/blob/6a08e6bb4e46ff7fcbb53d409b253f6bad8a28ce/nixos/modules/programs/gnupg.nix#L141
      # what programs.gnupg.agent.enableSSHSupport would do if I could enable it alongside programs.ssh.startAgent
      systemd.user.sockets.gpg-agent-ssh = {
        unitConfig = {
          Description = "GnuPG cryptographic agent (ssh-agent emulation)";
          Documentation = "man:gpg-agent(1) man:ssh-add(1) man:ssh-agent(1) man:ssh(1)";
        };
        socketConfig = {
          ListenStream = "%t/gnupg/S.gpg-agent.ssh";
          FileDescriptorName = "ssh";
          Service = "gpg-agent.service";
          SocketMode = "0600";
          DirectoryMode = "0700";
        };
        wantedBy = [ "sockets.target" ];
      };

      programs.ssh.extraConfig = ''
        # The SSH agent protocol doesn't have support for changing TTYs; however we
        # can simulate this with the `exec` feature of openssh (see ssh_config(5))
        # that hooks a command to the shell currently running the ssh program.
        Match host * exec "${pkgs.runtimeShell} -c '${config.programs.gnupg.package}/bin/gpg-connect-agent --quiet updatestartuptty /bye >/dev/null 2>&1'"
      '';
    };
}
