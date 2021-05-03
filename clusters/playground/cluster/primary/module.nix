{ config, ... }:
{
  cluster."primary" = {
    spin = "nixos";
    swpins.channels = [ "nixos-stable" "vpsadminos-master" ];

    host = {
        target = "185.8.164.45";
         };
  };
}
