# Hyprland Desktop Environment Testing

This directory contains comprehensive test scripts to validate the Hyprland desktop environment configuration managed through home-manager.

## Test Scripts Overview

### 1. Main Test Script
- **`test-hyprland-desktop.sh`** - Comprehensive test suite for the entire desktop environment
- Tests all components and provides interactive validation options
- **Requirements tested**: 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 2.1, 2.2, 2.3, 2.4, 2.5, 3.1, 3.2, 3.3, 3.4, 5.1, 5.2, 5.3

### 2. Component-Specific Test Scripts

#### Waybar Testing
- **`test-waybar-functionality.sh`** - Tests waybar status bar functionality
- **Requirements tested**: 2.1, 2.2, 2.3, 2.4, 2.5
- Tests workspace integration, system monitoring, audio controls, and theming

#### Fuzzel Testing  
- **`test-fuzzel-launcher.sh`** - Tests fuzzel application launcher
- **Requirements tested**: 3.1, 3.2, 3.3, 3.4, 3.5
- Tests configuration, search functionality, keyboard navigation, and theming

#### Workspace Management Testing
- **`test-workspace-management.sh`** - Tests workspace and window management
- **Requirements tested**: 1.5, 1.6, 5.1, 5.2, 5.3
- Tests workspace switching, window movement, and management features

### 3. Validation Script
- **`validate-hyprland-environment.sh`** - Comprehensive validation with detailed reporting
- Validates all components and generates a detailed status report
- **Requirements tested**: All requirements (1.2 through 5.3)

## Usage

### Quick Validation
Run the comprehensive validation script to get an overview of system status:

```bash
./validate-hyprland-environment.sh
```

### Full Interactive Testing
Run the main test script with interactive tests:

```bash
./test-hyprland-desktop.sh
```

### Component-Specific Testing
Test individual components:

```bash
# Test waybar functionality
./test-waybar-functionality.sh

# Test fuzzel launcher
./test-fuzzel-launcher.sh

# Test workspace management
./test-workspace-management.sh
```

### Command Line Options

All scripts support these options:
- `-h, --help` - Show help information
- `-q, --quiet` - Run in quiet mode (less verbose output)

Additional options for main test script:
- `-i, --interactive` - Run interactive tests only
- `--no-interactive` - Skip interactive tests

## Test Categories

### 1. Environment Tests
- Hyprland session detection
- IPC connectivity
- Environment variables (NVIDIA compatibility)
- Configuration file presence

### 2. Keybinding Tests (Requirements 1.2-1.7)
- **Super+Return** → Launch kitty terminal (1.2)
- **Super+Q** → Close focused window (1.3)  
- **Super+Space** → Launch fuzzel (1.4)
- **Super+[1-9]** → Switch to workspace (1.5)
- **Super+Shift+[1-9]** → Move window to workspace (1.6)
- **Super+H/J/K/L** → Vim-like focus movement (1.7)

### 3. Waybar Tests (Requirements 2.1-2.5)
- Service status and process running (2.1)
- Workspace indicators update (2.2)
- System resource monitoring (CPU, memory, network) (2.3)
- Clock and date display (2.4)
- Audio volume integration (2.5)

### 4. Fuzzel Tests (Requirements 3.1-3.5)
- Application launcher availability (3.1)
- Search functionality and filtering (3.2)
- Application launching (3.3)
- Keyboard navigation (3.4)
- Theming and appearance (3.5)

### 5. Window Management Tests (Requirements 5.1-5.3)
- **Super+F** → Fullscreen toggle (5.1)
- **Super+Shift+Space** → Floating toggle (5.2)
- Window rules and workspace assignments (5.3)

### 6. System Integration Tests (Requirements 4.1-4.4)
- Home-manager configuration management (4.1, 4.2)
- Systemd service integration (4.3)
- Environment compatibility (4.4)

## Interactive Tests

The test scripts include interactive components that require user input:

### Keybinding Tests
- Press specific key combinations to verify functionality
- Observe visual feedback (windows opening, workspace changes)
- Confirm expected behavior

### Waybar Tests
- Observe workspace indicator updates
- Check system resource display
- Test audio controls
- Verify clock display

### Fuzzel Tests
- Launch fuzzel and test search
- Navigate with keyboard
- Launch applications
- Test cancel functionality

### Workspace Tests
- Switch between workspaces
- Move windows between workspaces
- Test fullscreen and floating modes
- Test vim-like focus movement

## Expected Results

### Successful Test Run
- All core functionality tests pass
- Configuration files are present and valid
- Services are running correctly
- Keybindings are properly configured
- Interactive tests confirm expected behavior

### Common Issues and Solutions

#### Hyprland Not Running
```
✗ Not running in Hyprland session
```
**Solution**: Run tests within a Hyprland desktop session

#### Missing Configuration Files
```
✗ Waybar config file missing
```
**Solution**: Ensure home-manager has been built and activated

#### Service Not Running
```
✗ Waybar service is not active
```
**Solution**: Start the service manually or check systemd configuration
```bash
systemctl --user start waybar.service
```

#### Keybinding Not Found
```
✗ Terminal launch keybinding not found
```
**Solution**: Check Hyprland configuration and rebuild home-manager

#### Application Not Available
```
✗ Fuzzel binary not found
```
**Solution**: Ensure fuzzel is installed and available in PATH

## Test Output Format

### Success Indicators
- ✓ Green checkmarks for passed tests
- Detailed information about found configurations
- Component status summaries

### Failure Indicators  
- ✗ Red X marks for failed tests
- Specific error descriptions
- Suggestions for resolution

### Warnings
- ⚠ Yellow warning symbols for non-critical issues
- Optional features not configured
- Recommendations for improvement

## Automation

### CI/CD Integration
The validation script can be used in automated testing:

```bash
# Exit code 0 = success, 1 = failure
./validate-hyprland-environment.sh --quiet
echo "Exit code: $?"
```

### Scheduled Validation
Run periodic validation to ensure system health:

```bash
# Add to crontab for daily validation
0 9 * * * /path/to/validate-hyprland-environment.sh --quiet >> /var/log/hyprland-validation.log 2>&1
```

## Requirements Mapping

| Requirement | Description | Test Script | Test Function |
|-------------|-------------|-------------|---------------|
| 1.2 | Terminal launch (Super+Return → kitty) | All scripts | `test_keybinding_config` |
| 1.3 | Window close (Super+Q) | All scripts | `test_keybinding_config` |
| 1.4 | App launcher (Super+Space → fuzzel) | All scripts | `test_keybinding_config` |
| 1.5 | Workspace switching (Super+[1-9]) | All scripts | `test_workspace_keybindings` |
| 1.6 | Window movement (Super+Shift+[1-9]) | All scripts | `test_workspace_keybindings` |
| 1.7 | Vim-like focus (Super+H/J/K/L) | All scripts | `test_window_management_keybindings` |
| 2.1 | Waybar autostart | waybar, validation | `test_waybar_service` |
| 2.2 | Workspace indicators | waybar, validation | `test_workspace_integration` |
| 2.3 | System resource display | waybar, validation | `test_system_monitoring` |
| 2.4 | Clock and date | waybar, validation | `test_clock_display` |
| 2.5 | Audio volume | waybar, validation | `test_audio_integration` |
| 3.1 | Fuzzel availability | fuzzel, validation | `test_fuzzel_binary` |
| 3.2 | Application search | fuzzel, validation | `test_search_functionality` |
| 3.3 | Application launch | fuzzel, validation | `interactive_fuzzel_test` |
| 3.4 | Keyboard navigation | fuzzel, validation | `test_keyboard_navigation` |
| 3.5 | Theming integration | fuzzel, validation | `test_fuzzel_theming` |
| 4.1-4.4 | System integration | All scripts | `validate_system_integration` |
| 5.1 | Fullscreen toggle (Super+F) | workspace, validation | `test_window_management_keybindings` |
| 5.2 | Floating toggle (Super+Shift+Space) | workspace, validation | `test_window_management_keybindings` |
| 5.3 | Window rules | workspace, validation | `test_window_rules` |

## Troubleshooting

### Debug Mode
Run scripts with verbose output to debug issues:

```bash
# Enable debug output
set -x
./test-hyprland-desktop.sh
```

### Manual Component Testing
Test individual components manually:

```bash
# Test Hyprland IPC
hyprctl version

# Test waybar config
waybar --help

# Test fuzzel
fuzzel --help

# Check systemd services
systemctl --user status waybar.service
```

### Log Analysis
Check system logs for errors:

```bash
# Hyprland logs
journalctl --user -u hyprland.service

# Waybar logs  
journalctl --user -u waybar.service

# Home-manager logs
home-manager news
```

## Contributing

When adding new tests:

1. Follow the existing script structure
2. Use consistent output formatting (success/fail/warn functions)
3. Include requirement references in comments
4. Add interactive tests where appropriate
5. Update this documentation

### Test Script Template

```bash
#!/usr/bin/env bash
# Component Test Script
# Tests [component] functionality
# Requirements: [list requirements]

set -euo pipefail

# Colors and logging functions
# ... (copy from existing scripts)

# Test functions
test_component_feature() {
    log "Testing component feature..."
    # Test implementation
}

# Interactive tests
interactive_component_test() {
    log "Starting interactive component test..."
    # Interactive test implementation
}

# Main function
main() {
    log "Starting Component Test"
    # Run tests
}

# Execute
main "$@"
```