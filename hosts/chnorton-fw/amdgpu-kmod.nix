# https://github.com/Atemu/nixos-config/blob/master/modules/amdgpu/kernel-module.nix
# https://wiki.nixos.org/wiki/Linux_kernel#Patching_a_single_In-tree_kernel_module
{
  lib,
  stdenv,
  kernel, # The kernel to patch
  patches ? [ ],
}:

stdenv.mkDerivation {
  pname = "amdgpu-kernel-module-customised";
  inherit (kernel)
    src
    version
    postPatch
    nativeBuildInputs
    modDirVersion
    ;
  patches = kernel.patches or [ ] ++ patches;

  modulePath = "drivers/gpu/drm/amd/amdgpu";

  buildPhase = ''
    BUILT_KERNEL=${kernel.dev}/lib/modules/$modDirVersion/build

    cp $BUILT_KERNEL/Module.symvers $BUILT_KERNEL/.config ${kernel.dev}/vmlinux ./

    make "-j$NIX_BUILD_CORES" modules_prepare
    make "-j$NIX_BUILD_CORES" M=$modulePath modules
  '';

  installPhase = ''
    make \
      INSTALL_MOD_PATH="$out" \
      XZ="xz -T$NIX_BUILD_CORES" \
      M="$modulePath" \
      INSTALL_MOD_STRIP=1 \
      modules_install
  '';

  meta = {
    description = "AMD GPU kernel module";
    license = lib.licenses.gpl3;
  };
}
