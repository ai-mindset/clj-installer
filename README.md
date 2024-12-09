# clj-installer

Automated JDK and Clojure installer script for Debian/Ubuntu and RHEL/Fedora Linux systems

## Features
- Detects and installs Temurin JDK 21 if no Java is present
- Installs Clojure in user's home directory (no sudo required)
- Configures PATH in .zshrc
- Supports custom installation directory

## Requirements
- Debian/Ubuntu or RHEL/Fedora Linux
- Zsh shell
- curl
- Internet connection

## Usage
```bash
curl -O https://raw.githubusercontent.com/ai-mindset/clj-installer/main/install-clojure.sh
chmod +x install-clojure.sh
./install-clojure.sh
```

## License
MIT License for the installer script

Note: Clojure itself is [licensed](https://clojure.org/community/license) under the [Eclipse Public License 1.0](https://opensource.org/license/epl-1-0)  
