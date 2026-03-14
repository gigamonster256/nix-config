{
  flake.modules.nixos.vr = {
    programs.alvr.enable = true;
    programs.alvr.openFirewall = true;
  };
}
