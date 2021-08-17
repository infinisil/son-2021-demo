{ participantToCheck ? null }:
let
  pkgs = import <nixpkgs> {};
  inherit (pkgs) lib;
  inherit (lib) types;

  users = if participantToCheck != null then {
    ${participantToCheck} = { ... }: {
      imports = [
        (/home/participants + "/${participantToCheck}/module.nix")
      ];
    };
  } else lib.mapAttrs' (file: _:
    lib.nameValuePair (lib.removeSuffix ".nix" file) (
      { ... }: {
        imports = [ (./participants + "/${file}") ];
      }
    )
  ) (builtins.readDir ./participants);

  rootModule = { options, ... }: {

    imports = [ ./modules ];

    config = lib.optionalAttrs (options ? users) {
      users = users;
    };

  };
in lib.evalModules {
  modules = [ rootModule ];
}
