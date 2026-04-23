#!/bin/bash
# cl4ud3-cr4ck uninstaller

INSTALL_DIR="$HOME/.cl4ud3-cr4ck"
CLAUDE_SETTINGS="$HOME/.claude/settings.json"

echo ""
echo "  cl4ud3-cr4ck un1nst4ll3r"
echo "  ========================"
echo ""

read -p "  Remove cl4ud3-cr4ck? This deletes $INSTALL_DIR (y/N) " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "  Aborted. cr4ck l1v3s 0n."
    exit 0
fi

# Remove installed files
if [ -d "$INSTALL_DIR" ]; then
    rm -rf "$INSTALL_DIR"
    echo "  [+] Removed $INSTALL_DIR"
fi

# Remove hooks from Claude settings
if [ -f "$CLAUDE_SETTINGS" ] && command -v jq >/dev/null 2>&1; then
    # Remove our specific hooks by checking command paths
    jq 'walk(
        if type == "array" then
            map(select(
                if type == "object" and .hooks then
                    (.hooks | map(select(.command | tostring | contains(".cl4ud3-cr4ck") | not)) | length) > 0
                else true end
            ))
            | map(if type == "object" and .hooks then
                .hooks = (.hooks | map(select(.command | tostring | contains(".cl4ud3-cr4ck") | not)))
              else . end)
        else . end
    )' "$CLAUDE_SETTINGS" > "$CLAUDE_SETTINGS.tmp" 2>/dev/null

    if [ $? -eq 0 ]; then
        mv "$CLAUDE_SETTINGS.tmp" "$CLAUDE_SETTINGS"
        echo "  [+] Removed hooks from $CLAUDE_SETTINGS"
    else
        rm -f "$CLAUDE_SETTINGS.tmp"
        echo "  [!] Could not auto-clean settings.json. Remove cl4ud3-cr4ck hooks manually."
    fi
fi

echo ""
echo "  cl4ud3-cr4ck removed. f4r3w3ll, h4ck3r."
echo ""
