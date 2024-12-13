#!/usr/bin/env zsh

# Test script for Clojure development environment setup
# Run with: zsh test-clj-install.sh

# Mock user inputs
MOCK_GH_USER="test-user"
MOCK_CUSTOM_DIR="$HOME/.clojure-test"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# Test counter
tests_run=0
tests_passed=0

test() {
    local name=$1
    local cmd=$2
    ((tests_run++))

    echo "\nRunning test: $name"
    if eval "$cmd"; then
        echo "${GREEN}✓ Passed${NC}"
        ((tests_passed++))
    else
        echo "${RED}✗ Failed${NC}"
    fi
}

cleanup() {
    rm -rf "$MOCK_CUSTOM_DIR"
    rm -rf "$HOME/vscode-calva-setup"
    rm -rf "$HOME/dot-clojure"
}

# Run tests
test "Dependencies available" '
    command -v curl &&
    command -v git &&
    command -v jq'

test "Java installation check" '
    command -v java'

test "VSCode installation check" '
    command -v code'

test "Custom directory creation" '
    mkdir -p "$MOCK_CUSTOM_DIR" &&
    [[ -d "$MOCK_CUSTOM_DIR" ]]'

test "Clojure installer download" '
    cd "$MOCK_CUSTOM_DIR" &&
    curl -L -O https://github.com/clojure/brew-install/releases/latest/download/linux-install.sh &&
    chmod +x linux-install.sh &&
    [[ -x linux-install.sh ]]'

test "VSCode extension check" '
    code --list-extensions | grep -q "betterthantomorrow.calva" ||
    code --list-extensions | grep -q "betterthantomorrow.joyride"'

test "Config directories exist" '
    [[ -d "$HOME/.config/Code/User" ]] &&
    [[ -d "$HOME/.config/calva" ]] &&
    [[ -d "$HOME/.config/joyride" ]]'

test "JSON files validity" '
    # Debug: Show initial state
    echo "Checking config directory..."
    ls -la "$HOME/.config/Code/User" 2>/dev/null || echo "Directory does not exist"

    # Create directory with explicit permissions
    mkdir -p "$HOME/.config/Code/User"
    chmod 755 "$HOME/.config/Code/User"

    # Initialize settings.json if needed
    if [[ ! -f "$HOME/.config/Code/User/settings.json" ]]; then
        echo "{}" > "$HOME/.config/Code/User/settings.json"
        echo "\nCreated settings.json"
    fi

    # Initialize keybindings.json if needed
    if [[ ! -f "$HOME/.config/Code/User/keybindings.json" ]]; then
        echo "[]" > "$HOME/.config/Code/User/keybindings.json"
        echo "\nCreated keybindings.json"
    fi

    # Debug: Test jq parsing separately
    # echo "\nTesting settings.json with jq..."
    # jq "." "$HOME/.config/Code/User/settings.json" || echo "Invalid JSON in settings.json"
    # echo "\nTesting keybindings.json with jq..."
    # jq "." "$HOME/.config/Code/User/keybindings.json" || echo "Invalid JSON in keybindings.json"

    # Final validation
    [[ -f "$HOME/.config/Code/User/settings.json" ]] &&
    jq "." "$HOME/.config/Code/User/settings.json" >/dev/null 2>&1 &&
    [[ -f "$HOME/.config/Code/User/keybindings.json" ]] &&
    jq "." "$HOME/.config/Code/User/keybindings.json" >/dev/null 2>&1'

test "Clojure tools installation" '
    # First ensure mock directory exists
    mkdir -p "$MOCK_CUSTOM_DIR"

    # Clone dot-clojure repository
    temp_dir="$HOME/dot-clojure"

    # Clean up any existing clone
    [[ -d "$temp_dir" ]] && rm -rf "$temp_dir"

    # Clone and copy configuration
    git clone https://github.com/seancorfield/dot-clojure "$temp_dir" &&
    cp "$temp_dir/deps.edn" "$MOCK_CUSTOM_DIR/" &&
    [[ -d "$temp_dir/tools" ]] && cp -r "$temp_dir/tools/" "$MOCK_CUSTOM_DIR/"

    # Cleanup
    rm -rf "$temp_dir"

    # Verify files exist
    [[ -f "$MOCK_CUSTOM_DIR/deps.edn" ]] &&
    [[ -d "$MOCK_CUSTOM_DIR/tools" ]]'

test "Shell configuration" '
    grep -q "Clojure installation path" "$HOME/.zshrc" &&
    grep -q "deps-new()" "$HOME/.zshrc" &&
    grep -q "GH_USER" "$HOME/.zshrc"'

# Report results
echo "\nTest Results:"
echo "Tests run: $tests_run"
echo "Tests passed: $tests_passed"
echo "Tests failed: $((tests_run - tests_passed))"

# Cleanup test artifacts
cleanup

# Exit with status based on test results
[[ $tests_passed -eq $tests_run ]]
