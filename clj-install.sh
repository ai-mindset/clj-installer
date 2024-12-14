#!/usr/bin/env zsh

# Clojure Development Environment Setup Script
#
# This script sets up a complete Clojure development environment on Linux systems,
# including JDK, Clojure, and editor configuration.
#
# Features:
#   - Installs Temurin JDK 21 if no Java is present
#   - Installs latest stable Clojure
#   - Configures either VSCode or Vim as the development environment
#   - Sets up deps-new template for project creation
#   - Installs Sean Corfield's dot-clojure configuration
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
#      curl -O https://raw.githubusercontent.com/your-repo/clojure-setup.sh
#
#   2. Make it executable:
#      chmod +x clojure-setup.sh
#
#   3. Run the script:
#      ./clojure-setup.sh
#
# The script will:
#   1. Install JDK 21 if needed
#   2. Install Clojure to ~/.clojure (customizable)
#   3. Set up your preferred editor:
#      - For VSCode: installs Calva and Joyride extensions + configurations
#      - For Vim: installs a Vim setup including vim-iced
#   4. Configure deps-new template for project creation
#
# Editor Setup Details:
#   VSCode:
#   - Installs Calva and Joyride extensions
#   - Configures key bindings and settings
#   - Sets up Joyride scripts
#
#   Vim:
#   - Installs https://github.com/ai-mindset/vimrc/blob/vim-iced/vimrcs/basic.vim
#
# Configuration:
#   - The script will prompt for:
#     * Custom Clojure installation directory (optional)
#     * GitHub username (for deps-new template)
#
# After Installation:
#   1. Restart your shell or run: source ~/.zshrc
#   2. Create a new project: deps-new my-project
#
# Note: This script creates backups of existing configurations before making changes:
#   - VSCode: .config/Code/User/*.json.bak
#   - Vim: .vim.bak
#
# Author: ai-mindset
# License: MIT
# Repository: https://github.com/mindset/clj-installer

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
    read -r "?Use different directory? [y/N] " response

    # Create .clojure directory
    if [[ "$response" =~ ^[Yy]$ ]]; then
        read -r "?Enter new directory path: " clj_dir
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
        echo "## Clojure installation path"
        echo ""
    } >> "$HOME/.zshrc"

    # Source the updated zshrc
    source "$HOME/.zshrc"

    echo "Clojure installation complete!"
fi


echo "\nChecking editor setup..."

# Helper function for VSCode extension checks
is_extension_installed() {
    local extension_id="$1"
    code --list-extensions | grep -q "^${extension_id}$"
    return $?
}

# Function to set up vim-iced and related plugins
setup_vim_iced() {
    local vimrc="$HOME/.vimrc"
    local vim_plug_script="$HOME/.vim/autoload/plug.vim"
    local vimrc_url="https://raw.githubusercontent.com/ai-mindset/vimrc/vim-iced/vimrcs/basic.vim"

    # Install vim-plug if not present
    if [[ ! -f "$vim_plug_script" ]]; then
        echo "Installing vim-plug..."
        curl -fLo "$vim_plug_script" --create-dirs \
            https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    fi

    curl -fLo "$vimrc" "$vimrc_url" || {
        echo "Failed to download .vimrc" >&2
        return 1
    }
    vim +PlugInstall +qall

    # Add vim-iced to PATH in .zshrc if not present
    if ! grep -q "vim-iced/bin" "$HOME/.zshrc"; then
        echo '
# Vim-iced PATH
export PATH=$PATH:~/.vim/plugged/vim-iced/bin' >> "$HOME/.zshrc"
    fi

    echo "Vim-iced setup complete!"
}


## 2. Check Vim installation and setup
if command -v vim &>/dev/null; then
    echo "Found Vim installation"
    read -r "?Would you like to set up Vim for Clojure development? [y/N] " setup_vim

    if [[ "$setup_vim" =~ ^[Yy]$ ]]; then
        if [[ -f "$HOME/.vimrc" ]]; then
            read -q "REPLY?Existing .vimrc found. Would you like to back it up and install new configuration? (y/n) "
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                cp "$HOME/.vimrc" "$HOME/.vimrc.bak"
                echo "Backed up existing .vimrc to $HOME/.vimrc.bak"
                setup_vim_iced
            else
                echo "Keeping existing Vim configuration"
            fi
        else
            echo "No existing Vim configuration found. Setting up new configuration..."
            setup_vim_iced
        fi
    fi
else
    echo "Vim is not installed"
fi

## 3. Ask about VSCode setup
read -r "?Would you like to setup VSCode with Calva and Joyride? [y/N] " setup_vscode

if [[ "$setup_vscode" =~ ^[Yy]$ ]]; then
    if command -v code &>/dev/null; then
        echo "\nSetting up VSCode for Clojure development..."

        # Define VSCode configuration paths
        vscode_config="$HOME/.config/Code/User"

        # Check if VSCode is properly installed
        if [[ ! -d "$vscode_config" ]]; then
            echo "Warning: VSCode config directory not found. Is VSCode installed correctly?"
            exit 1
        fi

        # Install or verify VSCode extensions
        for ext in "betterthantomorrow.calva" "betterthantomorrow.joyride"; do
            if is_extension_installed "$ext"; then
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
        echo "VSCode is not installed. Please install it first."
        exit 1
    fi
fi

## 5. Setup deps-new
# Prompt for GitHub username for deps-new setup
echo "\nSetting up deps-new template..."

if ! grep -q "GH_USER" "$HOME/.zshrc"; then
    read -r "?Enter your GitHub username: " gh_user
fi

# Add deps-new function to .zshrc if it doesn't exist
if ! grep -q "deps-new()" "$HOME/.zshrc"; then
    cat >> "$HOME/.zshrc" << EOF

# deps-new function for creating new Clojure projects
export GH_USER="$gh_user"

deps-new() {
    if [[ -z "\$1" ]]; then
        echo "Please provide a project name."
        echo "Usage: deps-new <project-name>"
        return 1
    fi
    clojure -T:deps-new :template app :name "\$GH_USER/\$1"
}
EOF
echo "Added deps-new function to .zshrc"
fi

## 6. Cleanup
# Function to clean up temporary directories
cleanup() {
    local -a dirs
    dirs=("$@")
    for dir in $dirs; do
        if [[ -d "$dir" ]]; then
            echo "Cleaning up $dir..."
            rm -rf "$dir"
        fi
    done
}

# Set up trap to ensure cleanup on script exit
trap 'cleanup "$HOME/vscode-calva-setup" "$HOME/dot-clojure"' EXIT

## 7. Setup Sean Corfield's Clojure configuration
echo "\nSetting up Clojure configuration..."
temp_dir="$HOME/dot-clojure"

# Remove the directory if it exists
if [ -d "$temp_dir" ]; then
    echo "Removing existing dot-clojure directory..."
    rm -rf "$temp_dir"
fi

git clone https://github.com/seancorfield/dot-clojure "$temp_dir"
cp "$temp_dir/deps.edn" "$clj_dir/"
[[ -d "$temp_dir/tools" ]] && cp -r "$temp_dir/tools/" "$clj_dir/"
rm -rf "$temp_dir"

echo "\nSetup complete! Please restart your shell for the changes to take effect."
