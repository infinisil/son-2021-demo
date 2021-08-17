let
  pkgs = import <nixpkgs> {};
in pkgs.mkShell {
  nativeBuildInputs = [
    pkgs.inotifyTools
    pkgs.kitty
    pkgs.jq
  ];
}
