{
  autoUpdatePackages.jj-hooks = { };

  packages.jj-hooks =
    {
      lib,
      rustPlatform,
      fetchFromGitHub,
      stdenv,
      installShellFiles,
      nix-update-script,
      jujutsu,
      git,
      writableTmpDirAsHomeHook,
      pre-commit,
      prek,
      lefthook,
    }:
    rustPlatform.buildRustPackage (finalAttrs: {
      pname = "jj-hooks";
      version = "0.3.8";
      __structuredAttrs = true;

      src = fetchFromGitHub {
        owner = "mattwilkinsonn";
        repo = "zireael";
        tag = "v${finalAttrs.version}";
        hash = "sha256-Pts+/HAE2J4AlLJ0pOKZEcqhg0Je6y+HNHxZ0AY1ZWo=";
      };

      cargoHash = "sha256-3p6XSYtL2reu3KS3cUkcY/L6HhMIG+biuSuo3KJZd5Q=";
      buildAndTestSubdir = "tools/jj-hooks";

      nativeBuildInputs = [
        installShellFiles
      ];

      cargoBuildFlags = [
        # only jj-hooks, not jj-hp
        "--bin=jj-hooks"
      ];

      nativeCheckInputs = [
        jujutsu
        git
        writableTmpDirAsHomeHook
        pre-commit
        prek
        lefthook
      ];

      checkFlags = [
        # hk attempts to read ssl certs for building http client
        "--skip=hk_hook_autofix_creates_fixup_ref"
        "--skip=hk_passing_hooks_pushes"
        "--skip=first_push_root_parented_commit_hk"
        # needs python interpreter with pre_commit module
        "--skip=resolver_layer2_real_pre_commit_via_install_shim"
      ];
      dontUsePytestCheck = true;

      postInstall = lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
        installShellCompletion --cmd jj-hooks \
          --bash <($out/bin/jj-hooks completions bash) \
          --fish <($out/bin/jj-hooks completions fish) \
          --zsh <($out/bin/jj-hooks completions zsh)
      '';

      passthru.updateScript = nix-update-script { };

      meta = {
        description = "Run pre-commit, prek, lefthook, or hk hooks against jj bookmark pushes";
        homepage = "https://github.com/mattwilkinsonn/zireael";
        changelog = "https://github.com/mattwilkinsonn/zireael/blob/${finalAttrs.src.rev}/CHANGELOG.md";
        license = with lib.licenses; [
          asl20
          mit
        ];
        maintainers = [ lib.maintainers.gigamonster256 ];
        mainProgram = "jj-hooks";
      };
    });
}
