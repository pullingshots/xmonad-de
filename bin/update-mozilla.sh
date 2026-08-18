#!/bin/bash

# --- Configuration ---
# Define the apps to update. 
# Format: "InternalName|DownloadURL|InstallPath"
APPS=(
    "firefox|https://download.mozilla.org/?product=firefox-latest-ssl&os=linux64&lang=en-US|~/firefox"
    "thunderbird|https://download.mozilla.org/?product=thunderbird-latest-ssl&os=linux64&lang=en-US|~/thunderbird"
)

# Temporary directory for downloads
TMP_DIR="/tmp/mozilla_updates"
mkdir -p "$TMP_DIR"

update_app() {
    local name=$1
    local url=$2
    local install_path=$(eval echo $3) # Resolve tilde (~)

    echo "Checking for updates for $name..."

    if [ ! -d "$install_path" ]; then
        echo "Error: Install path $install_path not found. Please install the app first."
        return
    fi

    # 1. Get the current version installed
    # Most Mozilla apps have a version file or we can query the binary
    current_version=$("$install_path/$name" --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1)
    
    # 2. Determine the latest version available
    # We use a curl head request to check the server's version header
    latest_version=$(curl -sI "$url" | grep -i "location" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1)

    if [ -z "$latest_version" ]; then
        echo "Could not determine latest version for $name. Skipping."
        return
    fi

    if [ "$current_version" == "$latest_version" ]; then
        echo "$name is already up to date (v$current_version)."
    else
        echo "New version found! ($current_version -> $latest_version)"
        echo "Downloading and installing..."

        # Download the tar.xz
        curl -L "$url" -o "$TMP_DIR/$name.tar.xz"

        # Extract to the install path
        # --strip-components=1 removes the top-level folder (e.g., 'firefox/') 
        # so it extracts directly into your existing folder.
        tar -xJf "$TMP_DIR/$name.tar.xz" -C "$install_path" --strip-components=1

        echo "Successfully updated $name to v$latest_version."
    fi
}

# Main loop
for app_info in "${APPS[@]}"; do
    IFS='|' read -r name url path <<< "$app_info"
    update_app "$name" "$url" "$path"
done

# Cleanup
rm -rf "$TMP_DIR"
echo "Update process complete."
