#!/bin/bash

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (use sudo)" 
   exit 1
fi

# Find the first device of type 'wifi'
WIFI_IFACE=$(nmcli -t -f DEVICE,TYPE device | grep ":wifi" | head -n 1 | cut -d: -f1)

if [ -z "$WIFI_IFACE" ]; then
    echo "Error: No WiFi interface detected on this system."
    exit 1
fi

# Function to list available networks
list_networks() {
    echo "Scanning for available networks..."
    printf "%-30s %-20s %-15s\n" "SSID" "SECURITY" "STATUS"
    echo "--------------------------------------------------------------------------------"
    
    nmcli -f SSID,SECURITY device wifi list | tail -n +2 | while read -r line; do
        ssid=$(echo "$line" | awk '{print $1}')
        security=$(echo "$line" | awk '{print $2}')
        
        if nmcli connection show "$ssid" >/dev/null 2>&1; then
            auto=$(nmcli -g connection.autoconnect connection show "$ssid" 2>/dev/null)
            if [[ "$auto" == "no" ]]; then
                status="[DISABLED]"
            else
                status="[CONFIGURED]"
            fi
        else
            status="[NEW]"
        fi
        
        [[ -z "$security" ]] && security="Open"
        printf "%-30s %-20s %-15s\n" "$ssid" "$security" "$status"
    done
}

# Function to disable/enable a network profile
toggle_network() {
    local ssid=$1
    if [ -z "$ssid" ]; then echo "Usage: $0 -d <ssid>"; exit 1; fi

    if ! nmcli connection show "$ssid" >/dev/null 2>&1; then
        echo "Error: Network $ssid is not configured."
        exit 1
    fi

    current=$(nmcli -g connection.autoconnect connection show "$ssid" 2>/dev/null)
    if [[ "$current" == "yes" ]]; then
        nmcli connection modify "$ssid" connection.autoconnect no
        echo "Network $ssid disabled (will not auto-connect)."
    else
        nmcli connection modify "$ssid" connection.autoconnect yes
        echo "Network $ssid enabled."
    fi
}

# Function to add or update a network
add_or_update_network() {
    local ssid=$1
    if [ -z "$ssid" ]; then echo "Usage: $0 -a <ssid>"; exit 1; fi

    if nmcli connection show "$ssid" >/dev/null 2>&1; then
        echo "Network $ssid already exists. Updating password..."
        read -sp "Enter NEW password for $ssid: " password
        echo ""
        nmcli connection modify "$ssid" wifi-sec.psk "$password"
        echo "Password updated for $ssid."
    else
        echo "Configuring new network $ssid..."
        read -sp "Enter password (leave blank for open): " password
        echo ""
        if [ -z "$password" ]; then
            nmcli device wifi connect "$ssid" 
        else
            nmcli device wifi connect "$ssid" password "$password"
        fi
    fi
}

# Function to connect to a specific network
connect_wifi() {
    local ssid=$1
    if [ -z "$ssid" ]; then echo "Usage: $0 -c <ssid>"; exit 1; fi

    # Find any active ethernet connections and bring them down
    local active_eth=$(nmcli -t -f NAME,TYPE connection show --active | grep "ethernet" | cut -d: -f1)
    if [ -n "$active_eth" ]; then
        echo "Disconnecting active Ethernet ($active_eth) to prioritize WiFi..."
        nmcli connection down "$active_eth" >/dev/null 2>&1
    fi
    # --------------------------------------

    echo "Attempting to connect to: $ssid..."
    if nmcli connection up "$ssid" >/dev/null 2>&1; then
        echo "Successfully connected to $ssid."
    else
        if nmcli device wifi connect "$ssid" >/dev/null 2>&1; then
            echo "Connected to $ssid as an open network."
        else
            echo "FAIL: Could not connect to $ssid."
        fi
    fi
}

# Function to find the strongest based on Score (Signal + Rate)
connect_strongest() {
    local type=$1 # "config" or "open"
    echo "Calculating best $type network (Balancing Speed and Signal)..."
    
    best_ssid=$(nmcli -f SSID,RATE,SIGNAL device wifi list | tail -n +2 | while read -r line; do
        ssid=$(echo "$line" | awk '{print $1}')
        rate=$(echo "$line" | awk '{print $2}' | sed 's/[^0-9]*//g')
        sig=$(echo "$line" | awk '{print $3}' | sed 's/[^0-9]*//g')
        
        [[ -z "$rate" ]] && rate=0
        [[ -z "$sig" ]] && sig=0

        if [ "$type" == "config" ]; then
            if nmcli connection show "$ssid" >/dev/null 2>&1; then
                auto=$(nmcli -g connection.autoconnect connection show "$ssid" 2>/dev/null)
                [[ "$auto" == "no" ]] && continue
            else
                continue
            fi
        elif [ "$type" == "open" ]; then
            if nmcli -f SSID,SECURITY device wifi list | grep -A 1 "SSID: $ssid" | grep -qE "WPA|RSN"; then
                continue
            fi
        fi

        score=$(( (sig * 10) + (rate / 10) ))
        echo "$score $ssid"
    done | sort -nr | head -n 1 | awk '{print $2}')

    if [ -z "$best_ssid" ]; then
        echo "No suitable networks found in range."
    else
        echo "Best weighted network found: $best_ssid"
        connect_wifi "$best_ssid"
	check_quality
    fi
}

# Function to switch to Ethernet
connect_ethernet() {
    echo "Switching to Ethernet..."
    
    # Find the first profile that contains the word 'ethernet'
    local eth_profile=$(nmcli -t -f NAME,TYPE connection show | grep "ethernet" | head -n 1 | cut -d: -f1)

    if [ -z "$eth_profile" ]; then
        echo "Error: No Ethernet connection profile found."
        exit 1
    fi

    # Disconnect the dynamically detected WiFi interface
    nmcli device disconnect "$WIFI_IFACE"

    if nmcli connection up "$eth_profile"; then
        echo "Successfully switched to Ethernet ($eth_profile)."
    else
        echo "FAIL: Could not activate Ethernet. Please check the cable."
        # Fallback to WiFi if ethernet fails
        nmcli device connect "$WIFI_IFACE"
    fi
}

check_quality() {
    local target="google.ca"
    echo "Testing connection quality to $target..."
    
    # Run 10 pings with a short interval
    local stats=$(ping -c 10 -i 0.2 "$target" 2>/dev/null)
    
    if [ -z "$stats" ]; then
        echo "QUALITY: [FAILED] - No response from server."
        return
    fi

    # Extract loss percentage
    local loss=$(echo "$stats" | grep -oP '\d+(?=% packet loss)')
    
    # CORRECTED: Extract ONLY the average RTT number
    # This looks for the line containing 'rtt', then splits by '/' and takes the 2nd field
    local avg=$(echo "$stats" | grep "rtt" | cut -d' ' -f4 | cut -d'/' -f2)

    echo "--------------------------------------"
    echo "Packet Loss: $loss%"
    echo "Avg Latency: ${avg}ms"
    
    # Use a fallback for avg in case it's empty to prevent bc error
    if [ -z "$avg" ]; then avg=999; fi

    # The (bc -l) call now receives a clean number (e.g., 40.679)
    if [ "$loss" -eq 0 ] && (( $(echo "$avg < 50" | bc -l) )); then
        echo "QUALITY: [EXCELLENT]"
    elif [ "$loss" -lt 10 ]; then
        echo "QUALITY: [STABLE]"
    elif [ "$loss" -lt 30 ]; then
        echo "QUALITY: [POOR/JITTERY]"
    else
        echo "QUALITY: [UNSTABLE]"
    fi
    echo "--------------------------------------"
    echo "press any key to run gping, then q or ctrl-c to exit"
    read -n 1 -s
    gping "$target"
}

case "$1" in
    -l|--list)
        list_networks
        ;;
    -a|--add)
        add_or_update_network "$2"
        ;;
    -c|--connect)
        connect_wifi "$2"
        ;;
    -d|--disable)
        toggle_network "$2"
        ;;
    -s|--strongest-config)
        connect_strongest "config"
        ;;
    -o|--strongest-open)
        connect_strongest "open"
        ;;
    -e|--ethernet)
        connect_ethernet
	check_quality
        ;;
    *)
        echo "Usage: $0 {-l|--list} {-a|--add <ssid>} {-c|--connect <ssid>} {-d|--disable <ssid>} {-s|--strongest-config} {-o|--strongest-open} {-e|--ethernet}"
        ;;
esac
