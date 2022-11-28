{
  l,
  deSystemize,
}: cfg: let
  self = cfg.inputs.self.sourceInfo // {rev = cfg.inputs.self.sourceInfo.rev or "not-a-commit";};
  instantiateNixpkgsWith = system:
    (import cfg.inputs.nixpkgs {
      inherit system;
      config = cfg.nixpkgsConfig;
    })
    // {inherit (cfg.inputs.nixpkgs) sourceInfo;};
in
  system: cells: (
    (deSystemize system cfg.inputs)
    // {
      inherit self;
      cells = deSystemize system cells; # recursion on cells
    }
    // l.optionalAttrs (cfg.inputs ? nixpkgs) {
      nixpkgs = instantiateNixpkgsWith system;
    }
  )
