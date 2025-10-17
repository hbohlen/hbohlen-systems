# NixOS Configuration Test Suite

Comprehensive validation for NixOS configuration files.

## Running Tests

### Run all tests:
```bash
cd tests
./run-all-tests.sh
```

### Run individual tests:
```bash
./test-syntax.sh
./test-structure.sh
./test-configuration.sh
./test-disko.sh
./test-hardware.sh
./test-impermanence.sh
```

### Run advanced validation:
```bash
python3 nix-validator.py
```

## Test Coverage

1. **Syntax** - Validates Nix file syntax
2. **Structure** - Validates file organization and imports
3. **Configuration** - Validates system settings
4. **Disko** - Validates disk partitioning
5. **Hardware** - Validates hardware-specific configuration
6. **Impermanence** - Validates persistent storage setup
7. **Advanced** - Deep validation with Python

## CI Integration

```yaml
name: Validate NixOS Config
on: [push, pull_request]
jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Run tests
        run: cd tests && ./run-all-tests.sh
```