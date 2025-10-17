#!/usr/bin/env python3
"""NixOS Configuration Validator"""

import re
import sys
from pathlib import Path

class NixValidator:
    def __init__(self, repo_root: Path):
        self.repo_root = repo_root
        self.errors = []
        self.warnings = []
    
    def validate_all(self) -> bool:
        print("=== Advanced NixOS Configuration Validation ===\n")
        self.validate_syntax()
        self.validate_consistency()
        self.validate_security()
        self.print_results()
        return len(self.errors) == 0
    
    def validate_syntax(self):
        print("Checking syntax patterns...")
        for file_path in ['configuration.nix', 'disko.nix', 'hardware-configuration.nix', 'modules/impermanence.nix']:
            full_path = self.repo_root / file_path
            if not full_path.exists():
                self.errors.append(f"Missing file: {file_path}")
                continue
            content = full_path.read_text()
            if content.count('{') != content.count('}'):
                self.errors.append(f"{file_path}: Mismatched braces")
            if content.count('[') != content.count(']'):
                self.errors.append(f"{file_path}: Mismatched brackets")
        print("  ✓ Syntax pattern checks complete\n")
    
    def validate_consistency(self):
        print("Checking configuration consistency...")
        config = (self.repo_root / 'configuration.nix').read_text()
        disko = (self.repo_root / 'disko.nix').read_text()
        config_subvols = set(re.findall(r'subvol=(\w+)', config))
        disko_subvols = set(re.findall(r'"(root|home|nix|persist|log|tmp)"', disko))
        for subvol in config_subvols:
            if subvol not in disko_subvols:
                self.errors.append(f"Subvolume '{subvol}' in config but not in disko")
        print("  ✓ Consistency checks complete\n")
    
    def validate_security(self):
        print("Checking security configuration...")
        config = (self.repo_root / 'configuration.nix').read_text()
        if 'PermitRootLogin = "no"' not in config:
            self.warnings.append("Root login should be disabled")
        disko = (self.repo_root / 'disko.nix').read_text()
        if 'type = "luks"' not in disko:
            self.errors.append("Disk encryption (LUKS) not configured")
        print("  ✓ Security checks complete\n")
    
    def print_results(self):
        print("=" * 50)
        print("Validation Results")
        print("=" * 50)
        if self.errors:
            print(f"\n✗ Errors ({len(self.errors)}):")
            for error in self.errors:
                print(f"  - {error}")
        if self.warnings:
            print(f"\n⚠ Warnings ({len(self.warnings)}):")
            for warning in self.warnings:
                print(f"  - {warning}")
        if not self.errors and not self.warnings:
            print("\n✓ All validation checks passed!")

def main():
    repo_root = Path(__file__).parent.parent
    validator = NixValidator(repo_root)
    success = validator.validate_all()
    sys.exit(0 if success else 1)

if __name__ == '__main__':
    main()