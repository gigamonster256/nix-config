{
  nixpkgs.allowedUnfreePackages = [ "makemkv" ];

  # notes: command to dump: makemkvcon f -d /dev/sr0 dump auto -o ./
  # command to flash: makemkvcon f -d /dev/sr0 rawflash -i <file>
  flake.modules.nixos.default =
    {
      lib,
      config,
      ...
    }:
    let
      cfg = config.programs.makemkv;
    in
    lib.mkIf cfg.enable {
      # aparently 1.17.7 works best to flash
      # programs.makemkv.package =
      #   (pkgs.makemkv.overrideAttrs (_prevAttrs: rec {
      #     version = "1.17.7";
      #     passthru.srcs.bin = pkgs.fetchurl {
      #       url = [
      #         "https://www.makemkv.com/download/old/makemkv-bin-${version}.tar.gz"
      #       ];
      #       hash = "sha256-jFvIMbyVKx+HPMhFDGTjktsLJHm2JtGA8P/JZWaJUdA=";
      #     };
      #     passthru.srcs.oss = pkgs.fetchurl {
      #       urls = "https://www.makemkv.com/download/old/makemkv-oss-${version}.tar.gz";
      #       hash = "sha256-di5VLUb57HWnxi3LfZfA/Z5qFRINDvb1oIDO4pHToO8=";
      #     };
      #   }))
      #   # which needs ffmpeg 7
      #   .override
      #     {
      #       ffmpeg_8 = pkgs.ffmpeg_7;
      #     };

      boot.kernelModules = [ "sg" ];

      # TODO: put into file/package?
      services.udev.extraRules = ''
        SUBSYSTEM=="block", KERNEL=="sr[0-9]*", GROUP="cdrom", MODE="0660", TAG+="uaccess"
        SUBSYSTEM=="scsi_generic", KERNEL=="sg[0-9]*", ATTRS{type}=="5", GROUP="cdrom", MODE="0660", TAG+="uaccess"
      '';
    };

  persistence.wrappers.nixos = [ "makemkv" ];

  persistence.programs.nixos-home = {
    makemkv = {
      directories = [ ".MakeMKV" ];
    };
  };
}
