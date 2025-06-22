#!/bin/bash

THEME="$1"
THEMES_DIR="$HOME/.config/hypr/themes"
CURRENT_THEME="$THEMES_DIR/current"

KITTY_TEMPLATE="kitty.template.conf"
KITTY_OUTPUT="$HOME/.config/kitty/kitty.conf"
WAYBAR_STYLE="$HOME/.config/waybar/style.css"
WOFI_STYLE="$HOME/.config/wofi/style.css"
HYPRLOCK_CONF="$HOME/.config/hypr/hyprlock.conf"
WLOGOUT_STYLE="$HOME/.config/wlogout/style.css"

if [ -z "$THEME" ]; then
    echo "❌ Please provide a theme name. Usage: $0 <theme-name>"
    exit 1
fi

if [ ! -d "$THEMES_DIR/$THEME" ]; then
    echo "❌ Theme '$THEME' not found in $THEMES_DIR"
    exit 1
fi

echo "🔗 Linking theme '$THEME'..."
ln -sfn "$THEMES_DIR/$THEME" "$CURRENT_THEME"

echo "🧪 Sourcing color variables..."
source "$CURRENT_THEME/colors.conf"

if [ -f "$CURRENT_THEME/$KITTY_TEMPLATE" ]; then
    echo "🎨 Generating kitty config..."
    envsubst < "$CURRENT_THEME/$KITTY_TEMPLATE" > "$KITTY_OUTPUT"
fi

if [ -f "$CURRENT_THEME/wofi.css" ]; then
    echo "🎨 Applying Wofi theme..."
    cp "$CURRENT_THEME/wofi.css" "$WOFI_STYLE"
fi

if [ -f "$CURRENT_THEME/hyprlock.conf" ]; then
    echo "🔒 Applying Hyprlock config..."
    cp "$CURRENT_THEME/hyprlock.conf" "$HYPRLOCK_CONF"
fi

if [ -f "$CURRENT_THEME/wlogout.css" ]; then
    echo "🚪 Applying Wlogout theme..."
    cp "$CURRENT_THEME/wlogout.css" "$WLOGOUT_STYLE"
fi

echo "🔄 Reloading Waybar and Hyprland..."
killall waybar 2>/dev/null && waybar &
hyprctl reload

echo "✅ Theme '$THEME' applied!"
