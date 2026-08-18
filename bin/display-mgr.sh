#!/bin/bash

# Configuration
OLLAMA_MODEL="gemma4:e4b" 
CONFIG_DIR="$HOME/.config/display-mgr"
MEM_FILE="$CONFIG_DIR/history.json"
mkdir -p "$CONFIG_DIR"

# Ensure required tools
for tool in xrandr jq curl sha256sum; do
    if ! command -v $tool >/dev/null; then echo "Error: $tool is not installed."; exit 1; fi
done

# --- HELPER FUNCTIONS ---

cleanup_disconnected() {
    echo "Cleaning up ghost monitors..."
    local disconnected=$(xrandr | grep " disconnected" | awk '{print $1}')
    for output in $disconnected; do 
        xrandr --output "$output" --off
    done
}

get_res() {
    xrandr | grep -A 1 "$1 connected" | grep "*" | awk '{print $1}'
}

apply_layout() {
    local cmd=$1
    cleanup_disconnected
    eval "$cmd"
}

# --- DISPLAY DETECTION & HASHING ---
FULL_XRANDR_STATE=$(xrandr)
HW_ID=$(echo "$FULL_XRANDR_STATE" | grep " connected" | sha256sum | awk '{print $1}')
MONITORS=($(echo "$FULL_XRANDR_STATE" | grep " connected" | awk '{print $1}'))
NUM_MONITORS=${#MONITORS[@]}

if [ "$NUM_MONITORS" -eq 0 ]; then echo "No displays found."; exit 1; fi
PRIMARY=${MONITORS[0]}

# --- MEMORY FUNCTIONS ---
save_layout() {
    local layout_json=$1
    if [ ! -s "$MEM_FILE" ]; then echo "{}" > "$MEM_FILE"; fi
    jq -n --arg id "$HW_ID" --arg layout "$layout_json" '{( $id ): $layout}' > "$MEM_FILE.tmp"
    if jq -s '.[0] * .[1]' "$MEM_FILE" "$MEM_FILE.tmp" > "$MEM_FILE.tmp.merged"; then
        mv "$MEM_FILE.tmp.merged" "$MEM_FILE"
    fi
    rm -f "$MEM_FILE.tmp"
}

get_saved_layout() {
    if [ -f "$MEM_FILE" ]; then
        jq -r ".\"$HW_ID\"" "$MEM_FILE"
    fi
}

# --- OLLAMA INTEGRATION ---
request_layouts() {
    local user_prompt=$1
    local connected_details=$(echo "$FULL_XRANDR_STATE" | grep -A 10 " connected")

    if [ "$NUM_MONITORS" -eq 1 ]; then
        local prompt="You are a Linux Xrandr expert. I only have one monitor connected.
        
        --- XRANDR OUTPUT ---
        $connected_details
        --- XRANDR OUTPUT END ---

        Please suggest the top 3 modes for this single monitor.

	$user_prompt
        
        Output ONLY a JSON object with a single root key 'layouts' containing an array of objects with 'name' and 'cmd' keys.
        The 'cmd' should be a valid xrandr command to set the mode.
        
        Example: {\"layouts\": [{\"name\": \"Highest Quality (Native)\", \"cmd\": \"xrandr --output eDP --primary --mode 2880x1920\"}]}
	
	DO NOT include any other markup"
    else
        local prompt="You are a Linux Xrandr expert. I am providing the full output of the 'xrandr' command for my connected monitors:

        --- XRANDR OUTPUT START ---
        $connected_details
        --- XRANDR OUTPUT END ---

        The first monitor listed is the Primary. Please suggest 3 distinct layout options.

	$user_prompt

        Output ONLY a JSON object with a single root key 'layouts' containing an array of objects with 'name' and 'cmd' keys.
        The 'cmd' should be a valid xrandr command to set the mode.

        Example: {\"layouts\": [{\"name\": \"Stacked\", \"cmd\": \"xrandr --output eDP --primary --mode 2880x1920 --pos 0x1080 --output DisplayPort-3 --mode 1920x1080 --above eDP\"}]}
	
	DO NOT include any other markup"
    fi

    local payload_file=$(mktemp)
    jq -n --arg model "$OLLAMA_MODEL" --arg prompt "$prompt" '{model: $model, prompt: $prompt, stream: false, format: "json"}' > "$payload_file"
    local response=$(curl -s -X POST http://localhost:11434/api/generate -H "Content-Type: application/json" -d @"$payload_file")
    rm "$payload_file"
    echo "$response" | jq -r '.response'
}

# --- UI RESTART ---
restart_ui() {
    echo "Restarting UI components..."
    killall xmobar trayer >/dev/null 2>&1
    nohup xmobar >/dev/null 2>&1 & 
    if [ "$NUM_MONITORS" -gt 1 ]; then
        nohup xmobar "$HOME/.xmobarrc-secondary" -x 1 >/dev/null 2>&1 &
        nohup trayer --edge top --align right --width 10 --height 14 --monitor 1 >/dev/null 2>&1 &
    else
        nohup trayer --edge top --align right --width 10 --height 14 >/dev/null 2>&1 &
    fi
    sleep 0.1
    echo "UI restarted."
}

# --- MAIN EXECUTION ---

# 1. HANDLE STARTUP MODE (-s / --startup)
if [ "$1" == "-s" ] || [ "$1" == "--startup" ]; then
    echo "Running in Startup Mode..."
    # Now $PRIMARY is guaranteed to be defined
    apply_layout "xrandr --output \"$PRIMARY\" --primary --auto"
    restart_ui
    exit 0
fi

# 2. Handle Saved Layouts
saved=$(get_saved_layout)
if [ "$saved" != "null" ] && [ -n "$saved" ]; then
    echo "Found a saved layout for this exact hardware state. ($saved)"
    if [ "$1" == "-a" ] || [ "$1" == "--auto" ]; then
        apply_layout "$saved"
        restart_ui
        echo "Applied from memory."
        echo "--------------------------------------------------------------------------------"
        echo "Press any key to close this window..."
        read -n 1 -s
        exit 0
    else
        read -p "Apply saved layout? (y/n): " choice
        if [[ "$choice" == "y" ]]; then
            apply_layout "$saved"
            restart_ui
            exit 0
        fi
    fi
fi

# 3. Handle Ollama Layouts
if [ "$1" == "-a" ] || [ "$1" == "--auto" ]; then
  layouts_json=$(request_layouts)
else
  detected_displays=$(xrandr | awk '/ connected/{if(name)print line;name=$1;line=name":";count=0;next}/^[[:space:]]+[0-9]+x[0-9]+/&&count<5{gsub("x","×",$1);line=line" "$1;count++}END{if(name)print line}')
  echo "Detected displays:"
  echo "$detected_displays"
  read -p "Describe desired layout: " user_prompt
  layouts_json=$(request_layouts "$user_prompt")
fi
parsed_layouts=$(echo "$layouts_json" | jq -r '.layouts')

if [ -z "$parsed_layouts" ] || [ "$parsed_layouts" == "null" ]; then
    echo "Error: Ollama did not return a valid 'layouts' root object: $layouts_json"
    echo "--------------------------------------------------------------------------------"
    echo "Press any key to close this window..."
    read -n 1 -s
    exit 0
fi

if [ "$1" == "-a" ] || [ "$1" == "--auto" ]; then
    cmd=$(echo "$parsed_layouts" | jq -r '.[0].cmd')
    name=$(echo "$parsed_layouts" | jq -r '.[0].name')
    echo "Auto-applying best suggestion: $name ($cmd)"
    apply_layout "$cmd"
    save_layout "$cmd"
    restart_ui
else
    echo "Available Layouts suggested by Ollama:"
    echo "$parsed_layouts" | jq -r 'to_entries[] | "\(.key)): \(.value.name) \(.value.cmd)"'
    read -p "Select a layout number: " idx
    cmd=$(echo "$parsed_layouts" | jq -r ".[$idx].cmd")
    if [ "$cmd" != "null" ] && [ -n "$cmd" ]; then
        apply_layout "$cmd"
        save_layout "$cmd"
        restart_ui
    else
        echo "Invalid selection."
    fi
fi

echo "--------------------------------------------------------------------------------"
echo "Press any key to close this window..."
read -n 1 -s
