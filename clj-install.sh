#!/usr/bin/env zsh

# Clojure Development Environment Setup Script
#
# This script sets up a complete Clojure development environment on Linux systems,
# including JDK, Clojure, and editor configuration.
#
# Features:
#   - Installs Temurin JDK 21 if no Java is present
#   - Installs latest stable Clojure
#   - Configures either VSCode or Emacs as the development environment
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
#      - For Emacs: installs Spacemacs with Practicalli configuration
#   4. Configure deps-new template for project creation
#
# Editor Setup Details:
#   VSCode:
#   - Installs Calva and Joyride extensions
#   - Configures key bindings and settings
#   - Sets up Joyride scripts
#
#   Emacs:
#   - Installs Spacemacs
#   - Sets up Practicalli's configuration
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
#   - Emacs: .emacs.d.bak
#
# Author: mygithub
# License: MIT
# Repository: https://github.com/mygithub/installer

if command -v dnf &>/dev/null; then
    PKG_MANAGER="dnf"
elif command -v apt &>/dev/null; then
    PKG_MANAGER="apt"
else
    echo "No supported package manager found"
    exit 1
fi

# Check if the latest Adoptium Temurin LTS JDK is installed
if ! command -v java &>/dev/null; then
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

echo "\nSetting up development environment..."

# Function definition here
is_extension_installed() {
    local extension_id="$1"
    code --list-extensions | grep -q "^${extension_id}$"
    return $?
}

# Check for VSCode and handle editor setup
echo "\nChecking development environment..."
has_vscode=false

if command -v code &>/dev/null; then
    has_vscode=true
    echo "Found VSCode installation"
fi

# Ask about Emacs installation
read -r "?Would you like to install Emacs with Spacemacs and Practicalli config? [y/N] " install_emacs

# Setup VSCode if present
if [[ "$has_vscode" == "true" ]]; then
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
fi

check_and_install_font() {
    if ! fc-list | grep -i "Fira Code" > /dev/null; then
        echo "Installing Fira Code font..."
        case $PKG_MANAGER in
            dnf)
                sudo dnf install -y fira-code-fonts
                ;;
            apt)
                sudo apt update
                sudo apt install -y fonts-firacode
                ;;
        esac
        # Refresh font cache
        fc-cache -f
        echo "Fira Code font installed"
    else
        echo "Fira Code font already installed"
    fi
}

# Setup Emacs if requested
if [[ "$install_emacs" =~ ^[Yy]$ ]]; then
    echo "\nSetting up Emacs for Clojure development..."

    # Install Emacs if not present
    if ! command -v emacs &>/dev/null; then
        case $PKG_MANAGER in
            dnf)
                sudo dnf install -y emacs
                ;;
            apt)
                sudo apt update && sudo apt install -y emacs
                ;;
        esac
        echo "Installed Emacs"
    fi

    # Check and install Fira Code font
    check_and_install_font

    # Backup existing Emacs configuration
    [[ -d "$HOME/.emacs.d" ]] && mv "$HOME/.emacs.d" "$HOME/.emacs.d.bak"

    # Install Spacemacs and Practicalli configuration
    git clone https://github.com/syl20bnr/spacemacs "$HOME/.emacs.d"
    git clone https://github.com/practicalli/spacemacs-config.git "$HOME/.spacemacs.d"
    echo "Installed Spacemacs and Practicalli configuration"
fi

# Error if no editors were set up
if [[ "$has_vscode" == "false" ]] && [[ ! "$install_emacs" =~ ^[Yy]$ ]]; then
    echo "Error: No editors were configured. Please install either VSCode or Emacs and run the script again."
    exit 1
fi

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

# Check for VSCode installation
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
    echo "\nSetting up Emacs for Clojure development..."

    # Install Emacs if not present
    if ! command -v emacs &>/dev/null; then
        case $PKG_MANAGER in
            dnf)
                sudo dnf install -y emacs
                ;;
            apt)
                sudo apt update && sudo apt install -y emacs
                ;;
        esac
        echo "Installed Emacs"
    fi

    # Backup existing Emacs configuration
    [[ -d "$HOME/.emacs.d" ]] && mv "$HOME/.emacs.d" "$HOME/.emacs.d.bak"

    # Install Spacemacs and Practicalli configuration
    git clone https://github.com/syl20bnr/spacemacs "$HOME/.emacs.d"
    git clone https://github.com/practicalli/spacemacs-config.git "$HOME/.spacemacs.d"
    echo "Installed Spacemacs and Practicalli configuration"
fi

# Setup Sean Corfield's Clojure configuration
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
