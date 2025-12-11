{ config, ... }:
{
  unify.hosts.nixos.wyse-F4 = {
    modules = with config.unify.modules; [
      wyse
    ];
    nixos = {
      services.openssh.enable = true;

      networking.interfaces.enp1s0 = {
        ipv4.addresses = [
          {
            address = "172.16.15.54";
            prefixLength = 24;
          }
        ];
      };

      users.users.root = {
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB3tGxUsgEJN/dwJ+QovVJd0yNg+YkJercIjGVJD+rvt caleb@chnorton-fw"
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC+r3cAB0MVWfjOEfKfaIiIKQH+oGVroILI6ZZBsazyZvv+5tv+Ruw7nsbePG4JZlz356Zh4/csTrnrutYHOw6t7fWODKOvPBr3qDjNNbenuT7SUqOwZvBk5Du7zQ9VYq3qnHay+lw9BDcf0TruISlFihiL7yeC7jSm3+AAJW+vr6JV6J0wVnZ25/x3Sje1UL2GVyTr8HrGB+HRTHDINfkQG5jZCNyyFy9FEu6BuPHsOfDL0pgSBMxBPI4OkVPUUKHugmFqxsEaj4y87IUbRhGAyZBXIJ9e6zoRIdDZ5agF7ztHIletjYeJ9sDQyeXuGx6LMJI03A4GJyGJFSdxE+Gu0z16kr03UT+1czL+k98PZyo9JVIB0HsFBdhVCzJKDzi128WBrvCJQ6XRpKSYYfWzXYP5bVOFwM2vEpT0IgvZX6AdbdubFluCaWf6Aw2Ui2n786z2EqcPcj8qrF5GjGWcYg28n+LhJZGMu2RyKy17NisopLt+dIeQkAHqKFSfsHe4YJNkJJlkZFr1a/cM57JJu8EnUeR/y2IH8lzME1GS5yIFNAmDgskE0LbBvjtDwzaUmr7uRX8RGkvFb4nV1cG79wb+ROnyEtSfZ8fLreimPGL5JhJKOBAQLAxAbf1tv4I0K8TNtYGcCxD0Ugl8XLI8ScvuqXT1u3Kzk6kRYucj+Q== openpgp:0xAD72366B"
        ];
      };
    };
  };
}
