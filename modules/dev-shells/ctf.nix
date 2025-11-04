let
  shell =
    {
      pkgs ? import <nixpkgs> { config.allowUnfree = true; },
    }:
    pkgs.mkShellNoCC {
      packages = builtins.attrValues {
        inherit (pkgs)
          burpsuite # unfree
          ghidra
          john
          metasploit
          nmap
          sqlmap
          ;
      };
    };
in
{
  nixpkgs.allowedUnfreePackages = [ "burpsuite" ];
  perSystem =
    { pkgs, ... }:
    {
      devShells.ctf = shell { inherit pkgs; };
    };
}
