# Firmware Building and Installation

## Building with Docker Environment (recommended)

The helper script is available at: `RUTX_R_GPL_00.07.17.1/scripts/dockerbuild`.

The first invocation of the helper script will take longer, because it needs to build the compilation image. Subsequent runs will use the built image.

1. [Install Docker](https://docs.docker.com/engine/install/)

2. Extract the  archive to an empty folder

   ```sh
   mkdir RUTX_R_GPL_00.07.17.1
   tar -xzf ~/Downloads/RUTX_R_GPL_00.07.17.1.tar.gz -C RUTX_R_GPL_00.07.17.1
   ```

3. Update feeds

   ```sh
   cd RUTX_R_GPL_00.07.17.1
   ./scripts/dockerbuild ./scripts/feeds update -a
   ```

4. Build the image

   ```sh
   ./scripts/dockerbuild make
   ```

5. Prepare packages for offline installation (optional)

   ```sh
   ./scripts/dockerbuild make pm
   ```

   After this you can find packages in "RUTX_R_GPL_00.07.17.1/bin/packages/<arch_name>/zipped_packages".

6. Sign the image with local keys (optional):

   This step is only necessary if the firmware needs to be flashed from the bootloader.

   ```sh
   ./scripts/dockerbuild make sign
   ```

   > Note:
   >
   > - Do not launch the 'dockerbuild' script as root user (e.g. with sudo) - the script will use sudo itself, where appropriate.
   > - Rootless docker is unsupported due to file ownership issues - files created on host will appear to be owned by 'root' user in the container.

## Building with Host OS

### Prerequisites

Make sure you're running a supported Linux distribution.
We recommend using [Ubuntu 22.04 LTS](http://www.ubuntu.com/download/desktop).
You might succeed with other distributions.

---

1. Install NodeJS v20+ and NPM v10.5+

   Please follow NodeJS and NPM installation guides for your distribution.

   > Third-party helpers such as [`n`](https://github.com/tj/n) can be used to manage multiple NodeJS and NPM versions on the system.

2. Install required packages

   ```sh
   sudo apt update
   sudo apt install binutils binutils-gold bison build-essential bzip2    \
     ca-certificates curl cmake default-jdk device-tree-compiler          \
     devscripts ecj file flex fuse g++ gawk gcc gcovr gengetopt gettext   \
     git gnupg groff gperf help2man java-wrappers java-propose-classpath  \
     jq libc6-dev libffi-dev libexpat-dev libncurses5-dev libpcre3-dev    \
     libsqlite3-dev libssl-dev libxml-parser-perl lz4 liblz4-dev          \
     libzstd-dev make ocaml ocaml-findlib ocaml-nox patch pkg-config      \
     psmisc python-is-python3 python3.11 python3.11-dev                   \
     python3-setuptools python3-yaml rsync ruby sharutils subversion swig \
     u-boot-tools unzip uuid-dev vim-common wget zip zlib1g-dev
   ```

3. Extract the  archive to an empty folder

   ```sh
   mkdir RUTX_R_GPL_00.07.17.1
   tar -xzf ~/Downloads/RUTX_R_GPL_00.07.17.1.tar.gz -C RUTX_R_GPL_00.07.17.1
   ```

4. Update feeds

   ```sh
   cd RUTX_R_GPL_00.07.17.1
   ./scripts/feeds update -a
   ```

5. Build the image

   ```sh
   make
   ```

6. Prepare packages for offline installation (optional)

   ```sh
   make pm
   ```

   After this you can find packages in `RUTX_R_GPL_00.07.17.1/bin/packages/<arch_name>/zipped_packages`.

7. Sign the image with local keys (optional)

   This step is only necessary if the firmware needs to be flashed from the bootloader.

   ```sh
   make sign
   ```

## Installation

After successful build you will get the firmware file in `RUTX_R_GPL_00.07.17.1/bin/targets/ipq40xx/generic/tltFws`.

Update the new firmware via the web interface on your device.

## Minimal Image Configuration

You can set up a minimal image build where only core packages are included.  
**Note:** The device will be accessible only through Ethernet LAN and SSH.

1. Remove the `.config` file and run menuconfig

   ```sh
   rm .config
   make menuconfig
   ```

2. Navigate to **Target Images** and select **Build Minimal Image**.

3. Exit menuconfig, save the configuration, and build the image as stated in the previous steps.

> **Note:** If you're using dockerbuild, run menuconfig through it:
>
> ```sh
> ./scripts/dockerbuild make menuconfig
> ```

## Firmware Rebranding

### WebUI Rebranding

All changes should be done in:

```text
RUTX_R_GPL_00.07.17.1/package/feeds/vuci/vuci-ui-core/bin/dist
```

**File Locations:**

- WebUI Colors: `brand/brand.css`
- Company Information: `brand/brand.json`

**Logo and Icon Changes:**

- Main WebUI logo: `tlt_networks_logo.svg`
- Login page logo: `tlt-icons/tlt_networks_logo_white.svg`
- Favicon: `favicon.ico` and `assets/favicon.ico`
- Other icons: `tlt-icons` folder

### SSH Banner

1. Install figlet tool:

   ```sh
   sudo apt install figlet
   ```

2. Generate banner text:

   ```sh
   figlet YOUR_TEXT > "RUTX_R_GPL_00.07.17.1/package/base-files/files/etc/banner.logo"
   ```

### Firmware Version Change

Edit `gpl_version` file to change the prefix and/or version of the compiled firmware.

### Default IP Change

1. Open the device family file:

   ```text
   RUTX_R_GPL_00.07.17.1/target/linux/ipq40xx/image/devices/rutxxx_family.mk
   ```

2. Locate the `DEVICE_INTERFACE_CONF` variable with `lan default_ip` option

3. Set your desired IP, e.g.:

   ```makefile
   DEVICE_INTERFACE_CONF := \
       lan default_ip 192.168.10.1
   ```

4. Regenerate tmpinfo files:

   ```sh
   rm -rf "RUTX_R_GPL_00.07.17.1/tmp"
   ```

### Default Password Change

Edit the password configuration file:

```text
RUTX_R_GPL_00.07.17.1/package/base-files/files/lib/preinit/84_set_password
```

Change `admin01` to your desired password in this line:

```sh
[ -z "$passwd" ] && passwd="$(mkpasswd admin01)"
```
