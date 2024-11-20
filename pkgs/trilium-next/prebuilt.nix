{pkgs}: let
  metaCommon = with pkgs.lib; {
    description = "Open-source, cross-platform hierarchical note taking application with focus on building large personal knowledge bases.";
    homepage = "https://github.com/TriliumNext/Notes";
    license = licenses.agpl3Plus;
    sourceProvenance = with sourceTypes; [binaryNativeCode];
    platforms = ["x86_64-linux"];
  };
in {
  trilium-next = pkgs.callPackage ./desktop.nix {metaCommon = metaCommon;};
  # trilium-server = callPackage ./server.nix { metaCommon = metaCommon; };
}
