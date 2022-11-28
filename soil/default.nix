{l}: let
  winnow = import ./winnow.nix {inherit l;};
  harvest = import ./harvest.nix {inherit winnow;};
  pick = import ./pick.nix {inherit harvest;};
in {inherit winnow harvest pick;}
