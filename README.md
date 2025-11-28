# TOPCAT Integrated Launcher

A robust wrapper script that solves display configuration issues when launching TOPCAT (Tool for OPerations on Catalogues And Tables) on modern Linux systems, particularly those using Wayland display servers.

**Quick Links:** [Installation](#installation) | [Usage](#usage) | [Troubleshooting](topcat_wayland_troubleshooting.md) | [Contributing](#contributing)

---

## The Problem

TOPCAT is an essential tool for astronomical catalog analysis, but launching it on modern Linux systems—especially those using Wayland—often fails with cryptic display errors:

```
No X11 DISPLAY variable was set
java.awt.HeadlessException
Can't connect to X11 window server
```

These errors occur because TOPCAT requires X11, but modern Ubuntu systems use Wayland by default. Manual workarounds are tedious and error-prone.

## The Solution

This integrated launcher automatically:
- Detects your display server (Wayland or X11)
- Configures XWayland authentication
- Validates Java and TOPCAT installations
- Provides intelligent error messages with solutions
- Handles edge cases that cause common launch failures

**Developed and tested on Ubuntu 24.04 LTS.** Community testing on other distributions is welcome and encouraged.

---

## Features

- **Zero-configuration launch** - Works immediately on Ubuntu 24.04 LTS
- **Intelligent error handling** - Catches failures and suggests specific solutions
- **Display auto-detection** - Seamlessly handles Wayland and X11 sessions
- **Environment validation** - Checks Java, TOPCAT, and XWayland before launching
- **Detailed diagnostics** - Shows exactly what's configured when launching
- **Drop-in replacement** - Use it exactly like the standard `topcat` command

---

## Repository Contents

```
topcat-smart-launcher/
├── topcat_integrated_launcher.sh          # Main launcher script
├── topcat_wayland_troubleshooting.md      # Comprehensive troubleshooting guide
├── README.md                              # This file
└── LICENSE                                # MIT License
```

**`topcat_integrated_launcher.sh`** - The complete launcher with error handling and display configuration  
**`topcat_wayland_troubleshooting.md`** - Detailed solutions for specific error scenarios and platform variations

---

## Prerequisites

Before installing the launcher, ensure you have these components:

**Required:**
- ✅ Ubuntu 24.04 LTS (or compatible Debian-based distribution)
- ✅ Java Runtime Environment (JRE) 21 or higher
- ✅ TOPCAT installed at `/opt/topcat/topcat-full.jar`
- ✅ XWayland (for Wayland desktop sessions)

**Installation commands:**
```bash
# Install Java
sudo apt update
sudo apt install openjdk-21-jdk openjdk-21-jre

# Install XWayland
sudo apt install xwayland

# Download and install TOPCAT
cd /tmp
wget https://www.star.bris.ac.uk/~mbt/topcat/topcat-full.jar
sudo mkdir -p /opt/topcat
sudo mv topcat-full.jar /opt/topcat/
```

---

## Installation

### Quick Install (Recommended)

Download and install the launcher script directly:

```bash
# Download the launcher
wget https://github.com/RedChaosWolf92/TOPCAT_RESOURCES/blob/main/topcat_integrated_launcher.sh

# Install to system path
sudo mv topcat_integrated_launcher.sh /usr/local/bin/topcat
sudo chmod +x /usr/local/bin/topcat

# Verify installation
which topcat
# Should output: /usr/local/bin/topcat
```

### Alternative: Manual Installation

If you prefer to inspect the script first:

```bash
# Download to your home directory
cd ~
wget https://github.com/RedChaosWolf92/TOPCAT_RESOURCES/blob/main/topcat_integrated_launcher.sh

# Review the script
cat topcat_integrated_launcher.sh

# Install when satisfied
sudo mv topcat_integrated_launcher.sh /usr/local/bin/topcat
sudo chmod +x /usr/local/bin/topcat
```

### Verification

Test that the launcher is working:

```bash
# Launch TOPCAT
topcat

# You should see diagnostic output like:
# 🚀 Launching TOPCAT...
#    Display: :0
#    XAuthority: /run/user/1000/.mutter-Xwaylandauth.ABC123
#
# ✅ TOPCAT launched successfully
```

---

## Usage

### Basic Usage

The launcher works as a drop-in replacement for the standard TOPCAT command:

```bash
# Launch TOPCAT with default settings
topcat

# Open a specific catalog file
topcat /path/to/catalog.fits

# Pass Java options
topcat -Xmx2048m

# Multiple files
topcat catalog1.fits catalog2.csv
```

### Usage Examples

**Analyze a FITS catalog:**
```bash
topcat ~/data/gaia_dr3_sample.fits
```

**Launch with increased memory:**
```bash
topcat -Xmx4096m
```

**Open multiple catalogs for cross-matching:**
```bash
topcat 2mass.fits sdss.csv wise.vot
```

### What Happens When You Launch

The launcher performs these steps automatically:

1. **Display Configuration**
   - Detects Wayland vs X11 session
   - Sets `DISPLAY` environment variable
   - Locates and configures `XAUTHORITY` file
   - Verifies XWayland availability

2. **Environment Validation**
   - Checks Java installation
   - Verifies TOPCAT JAR file exists
   - Confirms all prerequisites are met

3. **Launch with Monitoring**
   - Starts TOPCAT with proper display settings
   - Captures any error messages
   - Provides troubleshooting guidance on failure

4. **Success Confirmation**
   - Reports successful launch
   - Shows configured display settings

---

## How It Works

The launcher script handles the complex display configuration that often causes TOPCAT launch failures on modern Linux systems.

### Key Technical Solutions

**1. XWayland Authentication**
```bash
# The launcher automatically locates the Wayland X authority file
export XAUTHORITY=$(ls /run/user/$(id -u)/.mutter-Xwaylandauth* 2>/dev/null | head -1)
```

**2. Display Server Detection**
```bash
# Sets appropriate display variables for Wayland sessions
export DISPLAY=${DISPLAY:-:0}
export WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-wayland-0}
```

**3. Java Headless Mode Override**
```bash
# Ensures Java knows to use GUI mode
java -Djava.awt.headless=false -jar /opt/topcat/topcat-full.jar
```

**4. Error Analysis**
The script captures Java exceptions and provides context-specific solutions based on the error type.

For complete technical details, see the [launcher script](topcat_integrated_launcher.sh) itself.

---

## Platform Support

### Tested Platforms

| Distribution | Version | Status | Notes |
|--------------|---------|--------|-------|
| **Ubuntu** | **24.04 LTS** | **✅ Fully Tested** | Primary development and testing platform |
| Ubuntu | 22.04 LTS | 🟡 Expected to Work | XAuthority paths may differ slightly |
| Ubuntu | 20.04 LTS | 🟡 Expected to Work | May require Java 11 instead of Java 21 |
| Debian | 12 (Bookworm) | 🔶 Untested | Should work with minimal adjustments |
| Fedora | 40+ | 🔶 Untested | XAuthority path likely differs |
| Arch Linux | Rolling | 🔶 Untested | Package names differ; script should work |
| Pop!_OS | 22.04 | 🔶 Untested | Ubuntu-based; likely compatible |

**Status Legend:**
- ✅ **Fully Tested** - Confirmed working on this platform
- 🟡 **Expected to Work** - Not tested but should work with minimal/no changes
- 🔶 **Untested** - Compatible but requires community testing
- ❌ **Known Issues** - Incompatible or requires significant modification

### Help Us Test!

We need community help testing this launcher on different Linux distributions. If you successfully use this launcher on a platform not marked as "Fully Tested," please:

1. Open an issue titled "Platform Test: [Your Distribution]"
2. Include your OS version, Java version, and test results
3. Note any modifications you needed to make
4. Share any errors encountered and solutions

See [Contributing](#contributing) for details.

---

## Troubleshooting

### Quick Fixes

**If TOPCAT fails to launch**, the script will provide specific error messages and solutions. Common issues:

**"Java is not installed"**
```bash
sudo apt install openjdk-21-jdk openjdk-21-jre
```

**"TOPCAT JAR file not found"**
```bash
cd /tmp
wget https://www.star.bris.ac.uk/~mbt/topcat/topcat-full.jar
sudo mkdir -p /opt/topcat
sudo mv topcat-full.jar /opt/topcat/
```

**"XWayland not found"**
```bash
sudo apt install xwayland
# Then logout and login again
```

### Comprehensive Troubleshooting

For detailed troubleshooting covering specific error messages, platform-specific issues, and advanced diagnostics, see:

**📖 [Complete Troubleshooting Guide](topcat_wayland_troubleshooting.md)**

This guide includes:
- Detailed solutions for each error type
- Platform-specific configuration differences
- Manual testing procedures
- Debug mode instructions
- Community-reported solutions

---

## Contributing

Contributions are welcome! We particularly need:

### Priority Needs
- **Platform testing** on distributions other than Ubuntu 24.04 LTS
- **Error scenario documentation** for edge cases
- **Installation script** improvements
- **Documentation** enhancements and clarifications

### How to Contribute

**1. Testing on Other Platforms**

Test the launcher and report results:
```bash
# Document your environment
cat /etc/os-release > platform-test.txt
java -version >> platform-test.txt
echo "---" >> platform-test.txt

# Test the launcher
topcat >> platform-test.txt 2>&1

# Open an issue with platform-test.txt contents
```

**2. Reporting Issues**

When reporting problems, include:
- Operating system and version
- Java version (`java -version`)
- Display server (Wayland or X11)
- Complete error message
- What you tried to fix it

**3. Submitting Improvements**

Standard GitHub workflow:
```bash
# Fork the repository on GitHub
# Clone your fork
git clone https://github.com/YOUR_USERNAME/topcat-smart-launcher.git
cd topcat-smart-launcher

# Create a feature branch
git checkout -b improvement/description

# Make your changes
# Test thoroughly on your platform

# Commit and push
git add .
git commit -m "Description of improvement"
git push origin improvement/description

# Open a Pull Request on GitHub
```

### Platform-Specific Adaptations

If you're adapting the launcher for a different distribution, key areas to check:

**XAuthority Path:**
```bash
# Ubuntu/Debian (Wayland):
/run/user/$(id -u)/.mutter-Xwaylandauth*

# Fedora/RHEL might use:
$HOME/.Xauthority

# Check your system:
echo $XAUTHORITY
```

**Package Names:**
```bash
# Debian/Ubuntu:
sudo apt install openjdk-21-jdk xwayland

# Fedora:
sudo dnf install java-21-openjdk xorg-x11-server-Xwayland

# Arch:
sudo pacman -S jdk21-openjdk xorg-xwayland
```

Document any platform-specific changes in your pull request.

---

## Additional Resources

### TOPCAT Documentation
- [TOPCAT Official Website](https://www.star.bris.ac.uk/~mbt/topcat/)
- [TOPCAT User Manual (SUN/253)](https://www.star.bris.ac.uk/~mbt/topcat/sun253/)
- [TOPCAT Quick Start Guide](https://www.star.bris.ac.uk/~mbt/topcat/sun253/sun253.html)

### Display Server Information
- [XWayland Documentation](https://wayland.freedesktop.org/xserver.html)
- [Ubuntu Wayland Guide](https://ubuntu.com/blog/what-is-wayland)
- [X11 vs Wayland Comparison](https://wayland.freedesktop.org/)

### Java on Linux
- [OpenJDK Installation](https://openjdk.org/install/)
- [Java on Ubuntu Tutorial](https://ubuntu.com/tutorials/install-jre)

---

## License

This project is released under the MIT License. See [LICENSE](LICENSE) for full details.

You are free to use, modify, and distribute this software with attribution.

---

## Acknowledgments

- **Built for the astronomy community** - Developed to make astronomical data analysis more accessible
- **Tested by astronomy students and researchers** at Open University and beyond
- **Inspired by real-world deployment challenges** in astronomy education settings
- **Community contributions welcome** - This project improves with your feedback and testing

Special thanks to:
- The TOPCAT development team for creating an invaluable astronomy tool
- Ubuntu developers for Wayland implementation and XWayland compatibility
- The astronomy education community for identifying pain points and testing solutions

---

## Support & Contact

- **Issues:** [GitHub Issues](https://github.com/YOUR_USERNAME/topcat-smart-launcher/issues)
- **Discussions:** [GitHub Discussions](https://github.com/YOUR_USERNAME/topcat-smart-launcher/discussions)
- **Email:** goxley@asu.edu

### Getting Help

1. **Check the [Troubleshooting Guide](topcat_wayland_troubleshooting.md)** first
2. **Search [existing issues](https://github.com/YOUR_USERNAME/topcat-smart-launcher/issues)** for similar problems
3. **Open a new issue** with detailed information about your setup and error
4. **Join the discussion** to share experiences and solutions with the community

---

**Version:** 1.0.0  
**Last Updated:** November 2024  
**Platform:** Ubuntu 24.04 LTS (Noble Numbat)  
**Maintainer:** Greg Oxley

**⭐ If this launcher solved your TOPCAT display issues, please star the repository!**

---

*This launcher is part of a broader effort to make astronomy tools more accessible to students, researchers, and educators. Contributions and feedback help improve the experience for everyone in the astronomy community.*
