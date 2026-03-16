{
  packages.fv =
    {
      buildGoModule,
      fetchFromGitHub,
    }:
    buildGoModule (finalAttrs: {
      pname = "fv";
      version = "0.5.8";
      src = fetchFromGitHub {
        owner = "kenshaw";
        repo = "fv";
        tag = "v${finalAttrs.version}";
        hash = "sha256-cHddB2qHAw1/iKCQ0gWfEGWKcdwC6pby8UlaHCcpZJo=";
      };
      vendorHash = "sha256-LSg8bz+ZrOHqvRBcQLcuUy7EKNoztLy5ELcud8YUtIk=";
    });
}
