# SPDX-FileCopyrightText: 2022 The Standard Authors
#
# SPDX-License-Identifier: Unlicense
{
  inputs.nosys.url = "github:divnix/nosys";
  inputs.yants.url = "github:divnix/yants";
  inputs.yants.inputs.nixpkgs.follows = "nixpkgs";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

  outputs = {
    nixpkgs,
    nosys,
    yants,
    self,
  }: let
    l = nixpkgs.lib // builtins;
    deSystemize = nosys.lib.deSys;
    paths = import ./paths.nix;
    types = import ./types {inherit l yants paths;};
  in {
    inherit (import ./soil {inherit l;}) pick harvest winnow;
    inherit (import ./grow {inherit l deSystemize paths types;}) grow growOn;
  };
}
