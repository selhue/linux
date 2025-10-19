#!/bin/bash
set -e

# --- Splash Screen ---
clear
echo -e "\e[1;34m
   ██████   █████████ ███        ███        ███ ███     ███ █████████
 ███    ███ ███       ███        ███        ███ ███     ███ ███      
  ███       ███       ███        ███        ███ ███     ███ ███      
    ███     ███████   ███        ███     ██████ ███     ███ ███████  
       ███  ███       ███        ███        ███ ███     ███ ███      
 ███    ███ ███       ███        ███        ███ ███     ███ ███      
   ██████   █████████ ██████████ ███████    ███   ██████    █████████                                
\e[0m"

# --- Ask for sudo once ---
echo "selhue os installer"
sudo -v

# Check if GNOME is installed
if ! command -v gnome-shell >/dev/null 2>&1; then
echo "[+] GNOME not detected, installing GNOME desktop environment..."

# Detect distribution and install GNOME accordingly
if [ -f /etc/os-release ]; then
. /etc/os-release
case "$ID" in
ubuntu|debian|linuxmint)
sudo apt update && sudo apt install -y gnome ubuntu-gnome-desktop
;;
centos|rhel|fedora)
sudo yum -y groups install "GNOME Desktop"
;;
arch|manjaro)
sudo pacman -Syu --noconfirm gnome gnome-extra
;;
*)
echo " unsupported distro $ID. Please install GNOME manually."
exit 1
;;
esac
else
echo "Cannot detect Linux distribution. Install GNOME manually."
exit 1
fi

# Optionally set graphical target for systemd systems
if command -v systemctl >/dev/null 2>&1; then
sudo systemctl set-default graphical.target
fi

echo "[+] GNOME installed. Please log out and back in or reboot before continuing."
exit 0
else
echo "[+] GNOME is installed, continuing setup."
fi



# --- Settings ---
WALLPAPER_URL="https://raw.githubusercontent.com/selhue/linux/refs/heads/WEBOPL/selhueos.png"
GTK_THEME_REPO="https://github.com/vinceliuice/WhiteSur-gtk-theme.git"
ICON_THEME_REPO="https://github.com/vinceliuice/WhiteSur-icon-theme.git"
OS_NAME="selhueOS"

# --- Ensure Dependencies ---
for cmd in gext git wget; do
    command -v $cmd >/dev/null || { echo "$cmd not found. Please install it first."; exit 1; }
done

# --- Clean up old clones ---
rm -rf /tmp/WhiteSur-gtk-theme /tmp/WhiteSur-icon-theme

# --- Set Wallpaper ---
echo "[+] Just the vibe..."
mkdir -p ~/Pictures/Wallpapers
wget -q "$WALLPAPER_URL" -O ~/Pictures/Wallpapers/naimacos.png
gsettings set org.gnome.desktop.background picture-uri "file://$HOME/Pictures/Wallpapers/naimacos.png"
gsettings set org.gnome.desktop.background picture-uri-dark "file://$HOME/Pictures/Wallpapers/naimacos.png"

# --- Theme Installation ---
echo "[+] Theming..."
if [ ! -d "$HOME/.themes/selhue" ]; then
    git clone --depth=1 "$GTK_THEME_REPO" /tmp/WhiteSur-gtk-theme
    /tmp/WhiteSur-gtk-theme/install.sh -n selhue -l
fi

echo "[+] Icons..."
if [ ! -d "$HOME/.icons/selhue" ]; then
    git clone --depth=1 "$ICON_THEME_REPO" /tmp/WhiteSur-icon-theme
    /tmp/WhiteSur-icon-theme/install.sh -a
fi

# --- Install Extensions with gext ---
echo "[+] Installing recommended GNOME extensions..."
for ext in dash-to-dock@micxgx.gmail.com user-theme@gnome-shell-extensions.gcampax.github.com ding@rastersoft.com; do
    gext install $ext || true
    gext enable $ext || true
done


# --- Apply Theme & Icons (Dark) ---
echo "[+] Applying theme and icons (dark)..."
gsettings set org.gnome.desktop.interface gtk-theme 'selhue-Dark'
gsettings set org.gnome.desktop.wm.preferences theme 'selhue-Dark'
gsettings set org.gnome.desktop.interface icon-theme 'WhiteSur-dark'



# --- Change OS Name to selhueOS ---
echo "[+] Setting OS name to selhueOS..."
sudo bash -c "sed -i '/^PRETTY_NAME=/d' /etc/os-release && echo 'PRETTY_NAME=\"$OS_NAME\"' >> /etc/os-release"

# --- bsh function to safely add to bashrc ---
bsh() {
    local identifier="$1"   # Unique string to check in bashrc
    local content="$2"      # Multiline string to append

    if ! grep -q "$identifier" "$HOME/.bashrc"; then
        echo -e "\n# Added by selhueOS installer: $identifier" >> "$HOME/.bashrc"
        echo -e "$content" >> "$HOME/.bashrc"
    fi
}

# --- Add selhueOS logo on terminal start ---
bsh "selhue-on_start()" 'selhue-on_start() {
echo -e "\e[1;34m
   ██████   █████████ ███        ███        ███ ███     ███ █████████
 ███    ███ ███       ███        ███        ███ ███     ███ ███      
  ███       ███       ███        ███        ███ ███     ███ ███      
    ███     ███████   ███        ███     ██████ ███     ███ ███████  
       ███  ███       ███        ███        ███ ███     ███ ███      
 ███    ███ ███       ███        ███        ███ ███     ███ ███      
   ██████   █████████ ██████████ ███████    ███   ██████    █████████                                
\e[0m"

}
selhue-on_start'

bsh "selhueos-history-alias" 'alias hh="history | less"'

bsh "selhueos-info" '
selhueos_info() {
echo ""
echo -e "  \e[1;34mOS:\e[0m $(hostnamectl --static) OS"
echo -e "  \e[1;34mKernel:\e[0m $(uname -r)"
echo -e "  \e[1;34mUptime:\e[0m $(uptime -p)"
echo -e "  \e[1;34mCPU:\e[0m $(lscpu | grep "Model name" | awk -F: "{print \$2}" | xargs)"
echo -e "  \e[1;34mMemory:\e[0m $(free -h | grep Mem | awk "{print \$3 \"/\" \$2}")"
echo -e "  \e[1;34mDisk:\e[0m $(df -h / | tail -1 | awk "{print \$3 \"/\" \$2}")"
echo ""
}

alias "?"="selhueos_info"
'
bsh "selhueos-prompt" 'PS1="\[\e[34m\]\h - \[\e[0m\]"'
bsh "selhueos-shortcuts" '
  ,,() { source ~/.bashrc; }
  ..() { clear && ,,; }
  xx() { exit; }
'


# --- Done ---
echo -e "\n🎉 Your GNOME desktop is now transformed into selhueOS (macOS-style) with desktop icons!"
