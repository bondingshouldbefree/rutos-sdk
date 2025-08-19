# Example Package Guide

## Overview

A template package demonstrating how to create and build OpenWrt packages for RUTOS firmware.

## Building the Package

1. **Copy Package Files**

   Copy the example package to the OpenWrt packages directory:

   ```sh
   cp -r "ipk-example" "RUTM_R_GPL_00.07.17.1/package/base/example_package"
   ```

2. **Configure OpenWrt**

   ```sh
   make menuconfig
   ```

   Navigate to **Base system** and select:
   - `[M]` for manual installation (package will need to be installed separately)
   - `[*]` for automatic installation (package will be included in firmware)

3. **Build the Package**

   For manual installation mode (`[M]`):

   ```sh
   make package/example_package/{clean,compile}
   ```

   For automatic installation mode (`[*]`):

   ```sh
   make clean
   make
   ```

   > After building, the package will be available in:  
   > `RUTM_R_GPL_00.07.17.1/bin/packages/ramips/base`

## Manual Installation

1. **Copy Package to Device**

   Copy the built package to the device:

   ```sh
   scp "RUTM_R_GPL_00.07.17.1/bin/packages/ramips/base/example_package_1.0-1_ramips.ipk" \
       root@192.168.1.1:/tmp
   ```

2. **Install Package**

   Install using opkg:

   ```sh
   opkg install /tmp/example_package_1.0-1_ramips.ipk
   ```

## Package Manager Integration

1. **Modify Package Configuration**

   Edit `RUTM_R_GPL_00.07.17.1/ipk_packages.json`:

   ```json
   {
     "example_package": {
       "name": "example_package",
       "base_dep": "busybox"
     }
   }
   ```

2. **Configure OpenWrt**

   ```sh
   make menuconfig
   ```

   Navigate to **Base system** and select `[M]` for `example_package`.

3. **Build Package**

   ```sh
   make package/example_package/{clean,compile}
   ```

4. **Compile Package Manager Packages**

   ```sh
   make pm
   ```

   > After compilation, the package will be available as `example_package.tar.gz` in:  
   > `RUTM_R_GPL_00.07.17.1/bin/packages/<arch_name>/zipped_packages`

## Package Contents

The package installs:

- `/usr/bin/example.sh` - Example shell script

## Usage

After installation, you can run the example script:

```sh
example.sh
```

## Development Guide

This package can be developed in two ways: using static files or building from source.

### Option 1: Static Files

1. **Update Package Configuration**

   Edit `Makefile` to modify:
   - Package version: `PKG_VERSION`
   - Package dependencies: `DEPENDS`
   - Installation paths

2. **Add Package Files**

   Place your files in the `files/` directory:

   ```sh
   files/
   ├── example.sh     # Example shell script
   └── example.conf   # Configuration file
   ```

3. **Set Installation Rules**

   Append installation paths in `Makefile`:

   ```makefile
   define Package/example_package/install
       [...]
       $(INSTALL_DIR) $(1)/etc/config
       $(INSTALL_CONF) ./files/example.conf $(1)//etc/config/example
   endef
   ```

### Source Build Approach

1. **Organize Source Files**

   Create a `src/` directory structure:

   ```sh
   src/
   ├── Makefile           # Source build rules
   ├── include/           # Header files
   │   └── example.h
   └── src/               # Source files
       └── example.c
   ```

2. **Configure Build Process**

   Edit the `Build/Compile` section in the package `Makefile`:

   ```makefile
   define Build/Compile
       $(MAKE) -C $(PKG_BUILD_DIR)/ \
           LIBDIR="$(TARGET_LDFLAGS)" \
           CC="$(TARGET_CC) $(TARGET_CFLAGS) $(TARGET_CPPFLAGS) $(FPIC)" \
           LD="$(TARGET_CROSS)ld -shared" \
           all
   endef
   ```

   > **Note:**  
   > - For simple packages using standard `make`, this whole section can be removed
   > - More examples can be found in other packages' `Build/Compile` sections

3. **Define Installation Rules**

   Set up installation paths in `Makefile`:

   ```makefile
   define Package/example_package/install
       $(INSTALL_DIR) $(1)/usr/bin
       $(INSTALL_BIN) $(PKG_BUILD_DIR)/example $(1)/usr/bin/
   endef
   ```

   > **Installation Macros:**
   > - `$(INSTALL_DIR)` - Create directories
   > - `$(INSTALL_BIN)` - Install executables (mode 0755)
   > - `$(INSTALL_DATA)` - Install configuration files (mode 0644)
   > - `$(INSTALL_CONF)` - Install protected config files (mode 0600)

After making changes, rebuild the package following the [Building the Package](#building-the-package) steps.
