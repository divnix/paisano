<!--
SPDX-FileCopyrightText: 2022 The Standard Authors

SPDX-License-Identifier: Unlicense
-->
# Usage

```nix
# flake.nix
{
  inputs.paisano.url = "github:divnix/paisano";
  inputs.paisano.inputs.nixpkgs.follows = "nixpkgs";

  outputs = { paisano, self }@inputs: 
    paisano.growOn {
      /* 
        the grow function needs `inputs` to desystemize
        them and make them available to your cell blocks
      */
      inherit inputs;
      /* 
        sepcify from where to grow the cells
        `./nix` is a typical choice that signals
        to everyone where the nix code lies
      */
      cellsFrom = ./nix;
      /*
        These blocks may or may not be found in a particular cell.
        But blocks that aren't defined here, cannot exist in any cell.
      */
      cellBlocks = [
        {
          /*
            Because the name is `mycellblock`, paisano's importer
            will be hooking into any file `<cell>/mycellblock.nix`
            or `<cell>/mycellblock/default.nix`.
            Block tragets are exposed under:
            #<system>.<cell>.<block>.<target>
          */
          name = "mycellblock";
          type = "mytype";

          /*
            Optional
            
            Actions are exposed in paisano's "registry" under
            #__std.actions.<system>.<cell>.<block>.<target>.<action>
          */
          actions = {
            system,
            flake,
            fragment,
            fragmentRelPath,
          }: [
            {
              name = "build";
              description = "build this target";
              command = ''
                nix build ${flake}#${fragment}
              '';
            }
          ];
          /*
            Optional
            
            The CI registry flattens the targets and
            the actions to run for each target into a list
            so that downstream tooling can discover what to
            do in the CI. The invokable action is determined
            by the attribute name: ci.<action> = true

            #__std.ci.<system> = [ {...} ... ];
          */
          ci.build = true;
        }
      ];
    }
    {
      /* Soil */
      devShells = paisano.harvest self [ "<cellname>" "<blockname>"];
      packages = paisano.winnow (n: v: n == "<targetname>" && v != null ) self [ "<cellname>" "<blockname>"];
      templates = paisano.pick self [ "<cellname>" "<blockname>"];
    };
}
```
