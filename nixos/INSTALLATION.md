# NixOS Installation Guide - Yoga 7 with Impermanence

## Pre-Installation Checklist

- [ ] Configuration validated (you've done this!)
  - nix flake check passed ✅
  - nix build passed ✅

- [ ] Download NixOS 25.05 ISO
  - Get it from: https://nixos.org/download
  - Use the GNOME ISO (easier for initial setup)

- [ ] Create bootable USB
  - Use tool like Balena Etcher or dd
  - Minimum 4GB USB drive

- [ ] Backup any existing data ⚠️
  - This process will WIPE YOUR ENTIRE DRIVE
  - No recovery possible after disko runs


## Installation Steps
## Phase 1: Boot and Network Setup

- [ ] Step 1: Boot from USB
  - Insert USB and restart Yoga 7
  - Press F12 (or appropriate key) to access boot menu
  - Select your USB drive
  - Expected: NixOS live environment loads with GNOME desktop

- [ ] Step 2: Connect to WiFi
  - Click WiFi icon in top-right corner
  - Connect to your network
  - Test: Open terminal and run `ping google.com` to verify connection

## Phase 2: Preparation
- [ ] Step 3: Open terminal and become root
```bash
sudo -i
```
What this does: Gives you root privileges for installation
Expected: Prompt changes to show `#` instead of `$`

- [ ] Step 4: Clone your configuration repository
```bash
git clone https://github.com/hbohlen/hbohlen-systems
```
```bash
cd hbohlen-systems/nixos
```

- What this does: Downloads your config files to the live environment
- Expected: See your three files: `flake.nix`, `disko.nix`, `configuration.nix`
- Verify: Run `ls -la` to confirm files are present

## Phase 3: Disk Setup (The Critical Part!)
- [ ] Step 5: Run disko to partition and format disk ⚠️ POINT OF NO RETURN

```bash
nix --experimental-features "nix-command flakes" run github:nix-community/disko -- --mode disko ./disko.nix
```

- What this does:
  - Partitions your NVMe drive
  - Sets up LUKS encryption
  - Creates BTRFS filesystem with subvolumes (root, nix, persist, swap)
  - Mounts everything to `/mnt`
- IMPORTANT PROMPT: You'll be asked to create an encryption password
  - Choose a strong password you'll remember!
  - You'll need this password EVERY TIME you boot
  - Write it down somewhere safe
- Expected duration: 2-5 minutes
- When complete: Your disk is ready, mounted at `/mnt`
- Verify: Run `ls /mnt` - you should see `boot`, `nix`, `persist`, `swap`

## Phase 4: System Installation
- [ ] Step 6: Install NixOS

```bash
nixos-install --flake .#yoga7
```
- What this does:
  - Builds your entire system configuration
    - Downloads all packages (GNOME, VSCode, etc.)
    - Installs everything to /mnt
    - Installs bootloader to /mnt/boot
  - Expected duration: 15-45 minutes (depends on internet speed)
  - You'll see: Lots of package downloads and build output
  - IMPORTANT PROMPT: At the end, you'll be asked to set a root password
    - Set a password (you can change it later if needed)
  - When complete: Message says "installation finished!"

## Phase 5: Set User Password (Critical!)

- [ ] Step 7: Enter the new system environment

```bash
nixos-enter
```

- What this does: Enters your newly installed system (still mounted at `/mnt`)
- Why necessary: Your user account needs a password to login
- Expected: Prompt changes slightly, you're now "inside" the new system

- [ ]  Step 8: Set your user password

```bash
passwd hbohlen
```

- What this does: Sets the password for your user account
- IMPORTANT: You MUST do this before rebooting or you can't login!
- Expected: Asks you to enter password twice

- [ ]  Step 9: Exit the new system environment

```bash
exit
```

- What this does: Returns you to the live USB environment
- Expected: Back to the regular root prompt

## Phase 6: Pre-Reboot Verification (Optional but Recommended)

- [ ]  Step 10: Verify bootloader was installed

```bash
ls /mnt/boot/EFI
```

- Expected: You should see `systemd` and `BOOT` directories
- Why check: Confirms the bootloader installed correctly

- [ ]  Step 11: Verify persist directory structure

```bash
ls -la /mnt/persist
```

- Expected: Should be mostly empty (maybe some system directories)
- Why check: Confirms persistent storage is ready

## Phase 7: First Boot!

- [ ]  Step 12: Reboot into your new system

```bash
reboot
```

- What happens:
  1. System reboots
  2. Remove USB drive when prompted
  3. You'll see LUKS password prompt (enter your encryption password)
  4. System boots to GDM login screen
  5. Login as `hbohlen` with the password you set
- Expected: GNOME desktop loads successfully!

## Post-Installation

- [ ]  First login successful - You're in GNOME!
- [ ]   WiFi reconnects - Join your network again (will be saved to `/persist`)
- [ ]    Test impermanence - Create a test file in `/tmp`, reboot, verify it's gone
- [ ]     Clone your repo - git clone your config to `~/dev` for future updates

## Troubleshooting

If you can't login:
- Did you run `passwd hbohlen` before rebooting
- Try root password and run `passwd hbohlen` from there

If boot fails:

- Check that encryption password is correct
- Boot back to live USB to investigate

If WiFi passwords are lost after reboot:

- Check that `/etc/NetworkManager/system-connections` is in your persist directories


















