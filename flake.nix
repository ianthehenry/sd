{
  description = "A simple command dispatch tool";

  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }: {
    overlay = final: prev: {
      sd = with final; stdenv.mkDerivation {
        pname = "sd";
        version = "0.1.${nixpkgs.lib.substring 0 8 self.lastModifiedDate}.${self.shortRev or "dirty"}";

        src = self;

        installPhase =
          ''
            install -D sd -m 0555 "$out/bin/sd"
            install -D _sd -m 0444 "$out/share/zsh/site-functions/_sd"
          '';
      };
    };
  } //
  flake-utils.lib.eachDefaultSystem (system: {
    defaultPackage = (import nixpkgs {
      inherit system;
      overlays = [ self.overlay ];
    }).sd;
  });
}
