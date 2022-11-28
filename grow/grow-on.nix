{
  l,
  grow,
}:
/*
A variant of `paisano.grow` that let's you pass an arbitraty
(variadic) amount of arguments after "growing" the flake.

These arguments are conied "layers of soil" for convenience
and are recursively merged -- in order from top to bottom --
onto the "grown flake output".

Use this facility to implement compatibility layers with
other tooling that expect a certain flake schema.

See `paisano.harvest` for how to level-up outputs conveniently.

Example use:

```nix
{
  inputs = {
    # ...
    std.url = "github:divnix/std";
  };

  outputs = inputs: let
    tasks = import ./nix/std.nix inputs;
    lib = import ./nix/lib.nix inputs;
  in
    inputs.std.growOn {
      inherit inputs;
      cellsFrom = ./cells;
      cellBlocks = [
        # ...
      ];
    }
    # Soil ...
    # nix-cli compat
    {
      devShell = inputs.std.harvest inputs.self ["tullia" "devshell" "default"];
      defaultPackage = inputs.std.harvest inputs.self ["tullia" "apps" "tullia"];
    }
    # dog food
    (lib.fromStd {
      actions = inputs.std.harvest inputs.self ["tullia" "action"];
      tasks = inputs.std.harvest inputs.self ["tullia" "task"];
    })
    # top level tullia outputs
    (lib // {inherit tasks;});
}
```
*/
args:
grow args
// {
  __functor = l.flip l.recursiveUpdate;
}
