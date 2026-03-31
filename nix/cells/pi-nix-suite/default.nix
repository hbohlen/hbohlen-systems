{ pkgs, lib, ... }:

let
  pi-nix-suite = pkgs.stdenvNoCC.mkDerivation rec {
    pname = "pi-nix-suite";
    version = "0.1.0";
    
    src = ./.;
    
    installPhase = ''
      # Install slash commands
      mkdir -p $out/share/pi/agent/commands
      cp -r $src/commands/* $out/share/pi/agent/commands/
      chmod +x $out/share/pi/agent/commands/*
      
      # Install agent templates
      mkdir -p $out/share/pi/agent/templates
      cp -r $src/templates/* $out/share/pi/agent/templates/
      
      # Install default skills
      mkdir -p $out/share/pi/skills
      cp -r $src/skills/* $out/share/pi/skills/
      
      # Create activation script
      mkdir -p $out/bin
      cat > $out/bin/pi-nix-suite-setup << 'EOF'
#!/usr/bin/env bash
# pi-nix-suite-setup - Activate pi-nix-suite in your pi configuration

PI_DIR="${PI_DIR:-$HOME/.pi}"
SUITE_DIR="${PI_NIX_SUITE_DIR:-@out@/share}"

echo "Setting up pi-nix-suite..."

# Create directories
mkdir -p "$PI_DIR/agent/commands"
mkdir -p "$PI_DIR/agent/templates"
mkdir -p "$PI_DIR/agent/skills"

# Link commands
for cmd in "$SUITE_DIR/pi/agent/commands/"*; do
    if [[ -f "$cmd" ]]; then
        basename=$(basename "$cmd")
        ln -sf "$cmd" "$PI_DIR/agent/commands/$basename"
        echo "  Linked command: $basename"
    fi
done

# Link templates
for tmpl in "$SUITE_DIR/pi/agent/templates/"*; do
    if [[ -f "$tmpl" ]]; then
        basename=$(basename "$tmpl")
        ln -sf "$tmpl" "$PI_DIR/agent/templates/$basename"
        echo "  Linked template: $basename"
    fi
done

# Link skills
for skill in "$SUITE_DIR/pi/skills/"*; do
    if [[ -f "$skill" ]]; then
        basename=$(basename "$skill")
        ln -sf "$skill" "$PI_DIR/agent/skills/$basename"
        echo "  Linked skill: $basename"
    fi
done

echo ""
echo "pi-nix-suite activated!"
echo "Available commands:"
echo "  /subagent <task> [--agent=TYPE]"
echo "  /repl <nix|python|node>"
echo "  /nix <query>"
echo "  /flake-check [path]"
EOF
      substituteInPlace $out/bin/pi-nix-suite-setup --subst-var out
      chmod +x $out/bin/pi-nix-suite-setup
    '';
    
    meta = with lib; {
      description = "Nix integration suite for pi coding agent";
      license = licenses.mit;
    };
  };
in
  pi-nix-suite
