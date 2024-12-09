#!/usr/bin/env zsh

## JDK & Clojure Installer for Linux
# Installs Temurin JDK 21 (if no Java present) and Clojure on Debian/Ubuntu or RHEL/Fedora
#
# Usage:
#   chmod +x clj-install.sh
#   ./clj-install.sh
#
# Features:
#   - Auto-detects package manager
#   - Installs JDK if needed
#   - Installs Clojure in $HOME/.clojure (customizable)
#   - Updates PATH in .zshrc
#
# Requirements:
#   - Debian/Ubuntu or RHEL/Fedora
#   - Zsh shell
#   - curl
#   - Internet connection

# Check if the latest Adoptium Temurin LTS JDK is installed
if ! command -v java &>/dev/null; then
    # Install Java only if needed
    if command -v dnf &>/dev/null; then
        PKG_MANAGER="dnf"
    elif command -v apt &>/dev/null; then
        PKG_MANAGER="apt"
    else
        echo "No supported package manager found"
        exit 1
    fi

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
./linux-install.sh --prefix $clj_dir

echo "Adding Clojure to PATH..."
echo "" >> "$HOME/.zshrc"
echo "## Clojure installation path" >> "$HOME/.zshrc"
echo 'export PATH=$HOME/.clojure/bin:$PATH' >> "$HOME/.zshrc"
echo "## Clojure installation path" >> "$HOME/.zshrc"
echo "" >> "$HOME/.zshrc"
source $HOME/.zshrc

echo "Clojure installation complete!"
