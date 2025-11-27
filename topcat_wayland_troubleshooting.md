# TOPCAT Installation & Troubleshooting Guide
*For Ubuntu 22.04+ with Wayland Display System*

## Overview

This guide addresses common issues when installing and running TOPCAT (Tool for OPerations on Catalogues And Tables) on modern Ubuntu systems that use Wayland instead of the traditional X11 display system.

**System Requirements:**
- Ubuntu 22.04 or later
- Wayland display system (Ubuntu default)
- Java 11 or higher

---

## Quick Installation

### Step 1: Install Java

```bash
# Install full OpenJDK with GUI support (NOT headless)
sudo apt update
sudo apt install openjdk-21-jdk openjdk-21-jre

# Verify installation
java -version
# Should show: openjdk version "21.x.x" or similar
```

**⚠️ Critical:** Do NOT install `openjdk-xx-jre-headless` - this version lacks GUI libraries needed for TOPCAT.

### Step 2: Download and Install TOPCAT

```bash
# Download TOPCAT
cd ~/Downloads
wget https://www.star.bris.ac.uk/~mbt/topcat/topcat-full.jar

# Create installation directory
sudo mkdir -p /opt/topcat
sudo mv topcat-full.jar /opt/topcat/

# Create launcher script
sudo tee /usr/local/bin/topcat << 'EOF'
#!/bin/bash
java -Djava.awt.headless=false -jar /opt/topcat/topcat-full.jar "$@"
EOF

# Make executable
sudo chmod +x /usr/local/bin/topcat
```

### Step 3: Install XWayland

```bash
# XWayland bridges Wayland to X11 applications
sudo apt install xwayland
```

### Step 4: Configure Display Environment

```bash
# Add to your shell configuration (~/.bashrc or ~/.zshrc)
cat >> ~/.zshrc << 'EOF'

# X11 Display configuration for GUI applications (Wayland/XWayland)
export DISPLAY=:0
export WAYLAND_DISPLAY=wayland-0
export XAUTHORITY=$(ls /run/user/1000/.mutter-Xwaylandauth* 2>/dev/null | head -1)
EOF

# Reload configuration
source ~/.zshrc
```

### Step 5: Test TOPCAT

```bash
topcat
```

A window should appear with the TOPCAT interface.

---

## Common Errors & Solutions

### Error 1: "No X11 DISPLAY variable was set"

**Full Error Message:**
```
Exception in thread "main" java.awt.HeadlessException: 
No X11 DISPLAY variable was set,
or no headful library support was found
```

**Cause:** DISPLAY environment variable is not set or incorrect.

**Diagnosis:**
```bash
# Check current DISPLAY setting
echo $DISPLAY

# Check what XWayland is running on
ps aux | grep -i xwayland | grep -v grep
# Look for ":0" or ":1" in the output

# Check available X11 sockets
ls -la /tmp/.X11-unix/
```

**Solution:**
```bash
# Set DISPLAY to match XWayland (usually :0)
export DISPLAY=:0

# Make permanent by adding to ~/.zshrc
echo 'export DISPLAY=:0' >> ~/.zshrc
source ~/.zshrc

# Test
topcat
```

---

### Error 2: "Can't load library: libawt_xawt.so"

**Full Error Message:**
```
Exception in thread "main" java.lang.UnsatisfiedLinkError: 
Can't load library: /usr/lib/jvm/java-21-openjdk-amd64/lib/libawt_xawt.so
```

**Cause:** You have the headless version of Java installed, which lacks GUI libraries.

**Diagnosis:**
```bash
# Check if GUI library exists
ls -la /usr/lib/jvm/java-21-openjdk-amd64/lib/libawt_xawt.so

# Check installed Java packages
dpkg -l | grep openjdk
```

**Solution:**
```bash
# Remove headless version
sudo apt remove openjdk-21-jre-headless

# Install full version with GUI support
sudo apt install openjdk-21-jdk openjdk-21-jre

# Verify the library now exists
ls -la /usr/lib/jvm/java-21-openjdk-amd64/lib/libawt_xawt.so
# Should show a file ~588KB in size

# Test TOPCAT
topcat
```

---

### Error 3: "Authorization required, but no authorization protocol specified"

**Full Error Message:**
```
Authorization required, but no authorization protocol specified
Exception in thread "main" java.awt.AWTError: 
Can't connect to X11 window server using ':0' as the value of the DISPLAY variable.
```

**Cause:** XAUTHORITY environment variable is not set or points to wrong/missing file.

**Diagnosis:**
```bash
# Check XAUTHORITY setting
echo $XAUTHORITY

# Check if file exists
ls -la $XAUTHORITY

# Find current auth files
ls -la /run/user/1000/.mutter-Xwaylandauth*
```

**Solution Option 1 - Dynamic XAUTHORITY (Recommended):**
```bash
# Edit ~/.zshrc
nano ~/.zshrc

# Add this line (finds current auth file automatically):
export XAUTHORITY=$(ls /run/user/1000/.mutter-Xwaylandauth* 2>/dev/null | head -1)

# Save: Ctrl+O, Enter, Ctrl+X

# Reload and test
source ~/.zshrc
topcat
```

**Solution Option 2 - Use xhost:**
```bash
# Allow local X connections
xhost +local:

# Only need DISPLAY, not XAUTHORITY
# Edit ~/.zshrc and ensure only these lines exist:
export DISPLAY=:0
export WAYLAND_DISPLAY=wayland-0

# Test
topcat
```

**Solution Option 3 - Copy to Home Directory:**
```bash
# Copy auth file to stable location
cp /run/user/1000/.mutter-Xwaylandauth* ~/.Xauthority

# Edit ~/.zshrc
nano ~/.zshrc

# Set XAUTHORITY to home directory:
export XAUTHORITY=~/.Xauthority

# Reload and test
source ~/.zshrc
topcat
```

---

### Error 4: Duplicate or Conflicting DISPLAY Variables

**Symptom:** TOPCAT works sometimes but not others, or worked before but stopped.

**Diagnosis:**
```bash
# Check for duplicate entries in shell config
grep -n "DISPLAY\|XAUTHORITY" ~/.zshrc
```

If you see multiple lines setting DISPLAY or XAUTHORITY, you have conflicts.

**Solution:**
```bash
# Backup first
cp ~/.zshrc ~/.zshrc.backup

# Remove all display-related duplicates
sed -i '/export DISPLAY=/d' ~/.zshrc
sed -i '/export XAUTHORITY=/d' ~/.zshrc
sed -i '/export WAYLAND_DISPLAY=/d' ~/.zshrc

# Add clean configuration ONCE
cat >> ~/.zshrc << 'EOF'

# X11 Display configuration for GUI applications (Wayland/XWayland)
export DISPLAY=:0
export WAYLAND_DISPLAY=wayland-0
export XAUTHORITY=$(ls /run/user/1000/.mutter-Xwaylandauth* 2>/dev/null | head -1)
EOF

# Reload
source ~/.zshrc

# Verify clean configuration
grep -n "DISPLAY\|XAUTHORITY" ~/.zshrc
# Should show only 3 lines at the end

# Test
topcat
```

---

## Complete Diagnostic Checklist

If TOPCAT isn't working, run through this checklist:

```bash
echo "=== TOPCAT Diagnostic Checklist ==="
echo ""

# 1. Java installation
echo "1. Java Version:"
java -version
echo ""

# 2. GUI library exists
echo "2. Java GUI Library:"
ls -la /usr/lib/jvm/java-*/lib/libawt_xawt.so 2>/dev/null || echo "❌ GUI library missing"
echo ""

# 3. XWayland running
echo "3. XWayland Status:"
ps aux | grep -i xwayland | grep -v grep || echo "❌ XWayland not running"
echo ""

# 4. X11 sockets
echo "4. X11 Sockets:"
ls -la /tmp/.X11-unix/
echo ""

# 5. Environment variables
echo "5. Environment Variables:"
echo "   DISPLAY = $DISPLAY"
echo "   WAYLAND_DISPLAY = $WAYLAND_DISPLAY"
echo "   XAUTHORITY = $XAUTHORITY"
echo ""

# 6. XAUTHORITY file exists
echo "6. XAUTHORITY File:"
if [ -f "$XAUTHORITY" ]; then
    ls -la $XAUTHORITY
else
    echo "❌ XAUTHORITY file not found or not set"
fi
echo ""

# 7. TOPCAT script
echo "7. TOPCAT Launcher Script:"
cat /usr/local/bin/topcat 2>/dev/null || echo "❌ TOPCAT script not found"
echo ""

# 8. Test simple X11 app
echo "8. Testing X11 with xeyes (window should appear):"
which xeyes > /dev/null && echo "   Run: xeyes" || echo "   Install: sudo apt install x11-apps"
```

---

## Verification Tests

### Test 1: Simple X11 Application

```bash
# Install test application
sudo apt install x11-apps

# Test X11 display
xeyes
# Should open a window with eyes that follow cursor
# Press Ctrl+C to close
```

If `xeyes` doesn't work, your X11 configuration has issues that need to be fixed before TOPCAT will work.

### Test 2: Java GUI Capability

```bash
# Test Java with explicit environment
DISPLAY=:0 XAUTHORITY=$XAUTHORITY java -Djava.awt.headless=false -jar /opt/topcat/topcat-full.jar
```

### Test 3: Display Information

```bash
# Check display details
xdpyinfo -display :0 | head -10
```

Should show X server information without errors.

---

## Final Working Configuration

After following this guide, your `~/.zshrc` should contain:

```bash
# X11 Display configuration for GUI applications (Wayland/XWayland)
export DISPLAY=:0
export WAYLAND_DISPLAY=wayland-0
export XAUTHORITY=$(ls /run/user/1000/.mutter-Xwaylandauth* 2>/dev/null | head -1)
```

And `/usr/local/bin/topcat` should contain:

```bash
#!/bin/bash
java -Djava.awt.headless=false -jar /opt/topcat/topcat-full.jar "$@"
```

---

## Using TOPCAT with Python Astronomy Environment

TOPCAT works alongside your Python astronomy tools:

```bash
# 1. Activate astronomy environment
foundation  # or source your environment

# 2. Process data in Python
python
>>> from astropy.table import Table
>>> data = Table.read('observations.csv')
>>> data.write('data_for_topcat.fits', overwrite=True)
>>> exit()

# 3. Open in TOPCAT
topcat data_for_topcat.fits &

# 4. Continue Python work while TOPCAT is open
```

**Best formats for TOPCAT:**
- FITS (`.fits`) - Recommended
- VOTable (`.vot`, `.xml`)
- CSV (`.csv`)
- ASCII tables (`.txt`, `.dat`)

---

## Troubleshooting Tips

### If You Made Changes but They Don't Work

```bash
# Close all terminals and open a new one
# OR reload configuration:
source ~/.zshrc

# OR logout and login again
```

### If TOPCAT Worked Before But Stopped

```bash
# The XAUTHORITY file may have changed
# Remove the old path and use dynamic detection:
nano ~/.zshrc

# Change XAUTHORITY line to:
export XAUTHORITY=$(ls /run/user/1000/.mutter-Xwaylandauth* 2>/dev/null | head -1)
```

### If Connected via SSH

```bash
# Disconnect and reconnect with X forwarding
ssh -X username@hostname

# Or with compression for better performance:
ssh -XC username@hostname
```

### Alternative: Use X11 Session Instead of Wayland

If all else fails, you can switch to X11 temporarily:

1. Logout from your desktop
2. At login screen, click your username
3. Click the gear icon ⚙️ at bottom right
4. Select "Ubuntu on Xorg" instead of "Ubuntu"
5. Login
6. TOPCAT should work without special configuration

---

## Quick Reference Commands

```bash
# Check configuration
grep "DISPLAY\|XAUTHORITY" ~/.zshrc
echo $DISPLAY
echo $XAUTHORITY

# Test X11
xeyes

# Launch TOPCAT
topcat

# Launch with file
topcat data.fits

# Launch multiple files
topcat file1.fits file2.csv file3.vot
```

---

## Summary of Root Causes

The TOPCAT display issues on Ubuntu 22.04+ stem from:

1. **Wayland vs X11:** Ubuntu switched from X11 to Wayland, but TOPCAT requires X11
2. **Headless Java:** Installing wrong Java package without GUI libraries
3. **Missing Environment Variables:** DISPLAY and XAUTHORITY not configured
4. **Dynamic Auth Files:** Wayland creates auth files with changing names
5. **Duplicate Configurations:** Multiple conflicting settings in shell config

Following this guide addresses all these issues systematically.

---

**Last Updated:** October 2025
**Tested On:** Ubuntu 24.04 LTS with Wayland, OpenJDK 21