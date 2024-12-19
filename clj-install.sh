#!/usr/bin/env zsh

# Clojure Development Environment Setup Script
#
# This script sets up a complete Clojure development environment on Linux systems,
# including JDK, Clojure, and editor configuration.
#
# Features:
#   - Installs Temurin JDK 21 if no Java is present
#   - Installs latest stable Clojure
#   - Configures either VSCode or Neovim as the development environment
#   - Installs a simple system-wide deps.edn configuration
#
# Requirements:
#   - Linux (Debian/Ubuntu or RHEL/Fedora)
#   - Zsh shell
#   - curl
#   - git
#   - Internet connection
#
# Usage:
#   1. Download the script:
#      curl -O https://raw.githubusercontent.com/ai-mindset/clj-installer/refs/heads/main/clj-install.sh
#
#   2. Make it executable:
#      chmod +x clj-install.sh
#
#   3. Run the script:
#      ./clj-install.sh
#
# The script will:
#   1. Install JDK 21 if needed
#   2. Install Clojure to ~/.clojure (customizable)
#   3. Set up your preferred editor:
#      - For Neovim: installs a Neovim setup including Conjure 
#      - For VSCode: installs Calva and Joyride extensions + configurations
#
# Editor Setup Details:
#   Neovim:
#   - Installs https://github.com/ai-mindset/init.vim
#
#   VSCode:
#   - Installs Calva and Joyride extensions
#   - Configures key bindings and settings
#
# Configuration:
#   - The script will prompt for:
#     * Custom Clojure installation directory (optional)
#
# After Installation:
#   1. `$ source ~/.zshrc` if changes haven't taken place already
#
# Note: This script creates backups of existing configurations before making changes:
#   - VSCode: .config/Code/User/*.json.bak
#
# Author: ai-mindset
# License: MIT
# Repository: https://github.com/mindset/clj-installer

## -1: Colour codes
GREEN=$(tput setaf 2)
RESET=$(tput sgr0)

## 0. Check which shell is used
RC=".$(basename $SHELL)rc"

## 1. Check if the distribution is Debian or RHEL based
if command -v dnf &>/dev/null; then
    PKG_MANAGER="dnf"
elif command -v apt &>/dev/null; then
    PKG_MANAGER="apt"
else
    echo "No supported package manager found"
    exit 1
fi

## 2. Check if a JDK is installed. If it's not, install the latest Adoptium Temurin LTS JDK
if ! command -v javac &>/dev/null; then
    case $PKG_MANAGER in
        dnf)
            [[ ! -f /etc/yum.repos.d/adoptium.repo ]] && sudo tee /etc/yum.repos.d/adoptium.repo > /dev/null <<EOF
[Adoptium]
name=Adoptium
baseurl=https://packages.adoptium.net/artifactory/rpm/\$releasever/\$basearch
enabled=1
gpgcheck=1
gpgkey=https://packages.adoptium.net/artifactory/api/gpg/key/public
EOF
sudo dnf install -y temurin-21-jdk
;;
apt)
    sudo apt install -y wget apt-transport-https gpg
    wget -qO - https://packages.adoptium.net/artifactory/api/gpg/key/public | \
        sudo gpg --dearmor | \
        sudo tee /etc/apt/trusted.gpg.d/adoptium.gpg > /dev/null
            echo "deb https://packages.adoptium.net/artifactory/deb $(lsb_release -cs) main" | \
                sudo tee /etc/apt/sources.list.d/adoptium.list
                            sudo apt update
                            sudo apt install -y temurin-21-jdk
                            ;;
                    esac
fi

## 3. Check if Clojure is installed, otherwise install the latest version
if command -v clj >/dev/null 2>&1; then
    echo "Clojure is already installed 👍"
    clj_path=$(which clj)
    clj_dir=${clj_path%/bin/clj}
else
    # Confirm directory choice
    echo "Default Clojure directory: $HOME/.clojure"
    read -r "?${GREEN}Use different directory? [y/N] ${RESET}" response

    # Create .clojure directory
    if [[ "$response" =~ ^[Yy]$ ]]; then
        read -r "?${GREEN}Enter new directory path: ${RESET}" clj_dir
        echo "Creating Clojure directory..."
        mkdir -p "$clj_dir"
        cd "$clj_dir" || exit 1
    else
        echo "Creating Clojure directory..."
        clj_dir="$HOME/.clojure"
        mkdir -p "$clj_dir"
        cd "$clj_dir" || exit 1
    fi

    echo "Downloading Clojure installer..."
    curl -L -O https://github.com/clojure/brew-install/releases/latest/download/linux-install.sh
    chmod +x linux-install.sh

    echo "Running Clojure installer..."
    ./linux-install.sh --prefix "$clj_dir"

    echo "Adding Clojure to PATH..."
    {
        echo ""
        echo "## Clojure installation path"
        echo "export PATH=$clj_dir/bin:\$PATH"
        echo "alias clj_rebel='clj -M:repl'"
        echo "export TERM=xterm-256color # For Tmux to show correct colours"
        echo "## Clojure installation path"
        echo ""
    } >> "$HOME/$RC"

    # Source the updated rc file 
    source "$HOME/$RC"

    echo "Clojure installation complete!"
fi

echo "Checking editor setup..."
is_vscode_extension_installed() {
    local extension_id="$1"
    code --list-extensions | grep -q "^${extension_id}$"
    return $?
}

setup_nvim_conjure() {
    local nvim_dir="$HOME/.config/nvim"
    local init_vim_url="https://raw.githubusercontent.com/ai-mindset/init.vim/refs/heads/main/init.vim"

    curl -fLo "$nvim_dir/init.vim" "$init_vim_url" || {
        echo "Failed to download init.vim" >&2
        return 1
    }
    nvim +PlugInstall +qall
    
    # Install Nerd Fonts for Neovim
    if ! fc-list | grep -q "Nerd Font"; then
        echo "Nerd Fonts are not installed."
        local FONT_URL="https://github.com/ryanoasis/nerd-fonts/blob/17dcbea754bced423652ecda54bbd5bf8476b36b/patched-fonts/FiraCode/Regular/FiraCodeNerdFont-Regular.ttf"
        local FONT_NAME="$(basename ${FONT_URL})"
        mkdir -p ~/.local/share/fonts
        cd ~/.local/share/fonts 
        curl -fLO "${FONT_URL}"
        echo "Installing ${FONT_NAME}..."
        if [[ ! -f ~/.config/fontconfig/fonts.conf ]]; then
            echo "Creating fontconfig directory..."
            mkdir -p ~/.config/fontconfig
            # create a fonts.conf file that contains the following 
            {
                echo "<?xml version=\"1.0\"?>"                
                echo "<!DOCTYPE fontconfig SYSTEM \"fonts.dtd\">"
                echo "<fontconfig>"
                echo "  <dir>~/.local/share/fonts</dir>"
                echo "</fontconfig>"
            } >> ~/.config/fontconfig/fonts.conf
        fi
        echo "Refresh font cache..."
        fc-cache -fv
        echo "Nerd Font ${FONT_NAME} installed!"
    fi

    echo "Neovim setup complete!"
}

## 4. Check Neovim installation and setup
if command -v nvim &>/dev/null; then
    echo "Neovim is already installed 👍"
    read -r "?${GREEN}Would you like to set up Neovim for Clojure development? [y/N] ${RESET}" setup_nvim

    if [[ "$setup_nvim" =~ ^[Yy]$ ]]; then
        echo "Setting up your new Neovim configuration..."
        setup_nvim_conjure
    fi
else
    echo "Neovim is not installed"
fi

## 5. Ask about VSCode setup
read -r "?${GREEN}Would you like to setup VSCode with Calva and Joyride? [y/N] ${RESET}" setup_vscode

if [[ "$setup_vscode" =~ ^[Yy]$ ]]; then
    if command -v code &>/dev/null; then
        echo "Setting up VSCode for Clojure development..."
        haven:

        # Define VSCode configuration paths
        vscode_config="$HOME/.config/Code/User"

        # Check if VSCode is properly installed
        if [[ ! -d "$vscode_config" ]]; then
            echo "Warning: VSCode config directory not found. Is VSCode installed correctly?"
            exit 1
        fi

        # Install or verify VSCode extensions
        for ext in "betterthantomorrow.calva" "betterthantomorrow.joyride"; do
            if is_vscode_extension_installed "$ext"; then
                echo "$ext extension is already installed"
            else
                if ! code --install-extension "$ext"; then
                    echo "Failed to install $ext extension"
                    exit 1
                fi
                echo "Installed $ext extension"
            fi
        done

        # Setup Joyride scripts directory
        mkdir -p "$HOME/.config/joyride"
        echo "Created Joyride scripts directory"
    else
        echo "VSCode is not installed. Please install it first https://code.visualstudio.com/download/"
        exit 1
    fi
fi

## 6. Setup simple system-wide Clojure configuration
echo "Setting up Clojure configuration..."
if [[ -f "$clj_dir/deps.edn" ]]; then
    echo "deps.edn already exists"
    read -r "?${GREEN}Would you like to replace your deps.edn with a simple system-wide configuration? [y/N] ${RESET}" replace_deps
    if [[ "$replace_deps" =~ ^[Yy]$ ]]; then
        curl -L -o "$clj_dir/deps.edn" https://raw.githubusercontent.com/ai-mindset/clj-installer/refs/heads/main/deps.edn
        echo "Replaced deps.edn"
    else
        echo "Keeping existing deps.edn"
    fi
else 
    curl -L -o "$clj_dir/deps.edn" https://raw.githubusercontent.com/ai-mindset/clj-installer/refs/heads/main/deps.edn
    echo "Installed deps.edn" 
fi

echo "Restarting $(echo $0)"
source ~/$RC
echo "Setup complete!"
