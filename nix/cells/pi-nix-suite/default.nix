{ pkgs, lib, ... }:

pkgs.buildNpmPackage rec {
  pname = "pi-nix-suite";
  version = "0.1.0";
  
  src = ./extension;
  
  npmDepsHash = lib.fakeHash; # Will update after first build attempt
  
  nativeBuildInputs = with pkgs; [
    nodejs
    typescript
  ];
  
  buildPhase = ''
    npm run build
  '';
  
  installPhase = ''
    mkdir -p $out/share/pi/extensions/pi-nix-suite
    cp -r dist/* $out/share/pi/extensions/pi-nix-suite/
    cp -r templates $out/share/pi/extensions/pi-nix-suite/ || true
    
    # Install default skills
    mkdir -p $out/share/pi/skills
    cp -r ${./skills}/* $out/share/pi/skills/ 2>/dev/null || true
  '';
  
  meta = with lib; {
    description = "Nix integration suite for pi coding agent";
    license = licenses.mit;
  };
}
