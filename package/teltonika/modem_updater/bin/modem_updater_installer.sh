#!/bin/ash

checkIfFlasherFileExists() {
        local FLASHER_FILE="$1"
        local FLASHER_PATH="$2"
        if [ -f "$FLASHER_PATH" ]; then
                debug "[INFO] Flasher found: $FLASHER_PATH"
                return 0
        fi
        debug "[INFO] Flasher not found. Downloading the flasher using opkg."

        opkg update
        opkg install "$FLASHER_FILE"
        if [ $? -ne 0 ]; then
                echo "[ERROR] Failed to install flasher '$FLASHER_FILE'. Exiting.."
                return 1
        fi
        return 0
}