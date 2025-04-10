#!/bin/bash
set -e

# ----------------------------
# Homebrew Installation
# ----------------------------
if ! command -v brew &> /dev/null; then
    echo "Homebrew is not installed. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    echo "Homebrew installation complete."
    echo "You need to add Homebrew to your PATH:"
    echo 'echo >> ~/.zprofile'
    echo 'echo "eval \"$(/opt/homebrew/bin/brew shellenv)\"" >> ~/.zprofile'
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"'
    echo "Please run these commands, then restart your terminal or rerun the script."
    exit 1
else
    echo "Homebrew is already installed."
fi

echo "Updating Homebrew..."
brew update

# ----------------------------
# Menu
# ----------------------------
echo ""
echo "What would you like to install/configure?"
echo "1) Essentials (git, wget)"
echo "2) Productivity Apps (Rectangle, Chrome, iTerm2, Alfred)"
echo "3) ZSH Customization (Oh My Zsh + Powerlevel10k)"
echo "4) Syntax Highlighting Tools (bat, bat-extras)"
echo "5) Exit"
echo "6) Install Obsidian (note-taking app)"

read -p "Enter your choice [1-6]: " choice

# ----------------------------
# Install Logic
# ----------------------------
case $choice in
    1)
        echo "Installing Essentials..."
        for pkg in git wget; do
            if brew list "$pkg" &> /dev/null; then
                echo "$pkg is already installed."
            else
                echo "Installing $pkg..."
                brew install "$pkg"
            fi
        done
        ;;

    2)
        echo "Installing Productivity Apps..."
        for app in rectangle google-chrome iterm2 alfred; do
            if brew list --cask "$app" &> /dev/null; then
                echo "$app is already installed."
            else
                echo "Installing $app..."
                brew install --cask "$app"
            fi
        done

        # Special note for Alfred to allow accessibility permissions manually
        echo "NOTE: After installing Alfred, you may need to enable Accessibility permissions in:"
        echo "System Preferences -> Security & Privacy -> Privacy -> Accessibility"

        # Optionally, try launching Alfred to trigger system permissions prompts
        echo "Attempting to launch Alfred..."
        osascript -e 'tell application "Alfred 5" to launch' || echo "If Alfred is not found, open it manually from Applications."
        ;;

    3)
        echo "Installing ZSH customization tools..."
        # Ensure zsh is the default shell
        if [ "$SHELL" != "/bin/zsh" ]; then
            echo "Setting zsh as the default shell..."
            chsh -s /bin/zsh
        fi

        if [ ! -d "$HOME/.oh-my-zsh" ]; then
            echo "Installing Oh My Zsh..."
            sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        else
            echo "Oh My Zsh is already installed."
        fi

        P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
        if [ ! -d "$P10K_DIR" ]; then
            echo "Installing Powerlevel10k..."
            git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
        else
            echo "Powerlevel10k is already installed."
        fi

        if grep -q '^ZSH_THEME=' "$HOME/.zshrc"; then
            sed -i '' 's/^ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$HOME/.zshrc"
        else
            echo 'ZSH_THEME="powerlevel10k/powerlevel10k"' >> "$HOME/.zshrc"
        fi

        if ! grep -q 'source ~/.p10k.zsh' "$HOME/.zshrc"; then
            echo '
# >>> powerlevel10k config >>>
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
# <<< powerlevel10k config <<<' >> "$HOME/.zshrc"
        fi

        [ ! -f "$HOME/.p10k.zsh" ] && echo "# Run 'p10k configure' to generate this file" > "$HOME/.p10k.zsh"
        echo "ZSH customization complete. Restart your terminal or run: source ~/.zshrc"
        ;;

    4)
        echo "Installing syntax highlighting tools..."
        if ! command -v bat &> /dev/null; then
            echo "Installing bat..."
            brew install bat
        else
            echo "bat is already installed."
        fi

        echo "Ensuring bat is configured for common filetypes (Python, Bash, YAML, JSON, etc.)..."
        # Install shfmt for bat-extras (if not already installed)
        if ! command -v shfmt &> /dev/null; then
            echo "Installing shfmt for script formatting..."
            brew install shfmt
        else
            echo "shfmt is already installed."
        fi

        # Clone and install bat-extras in user-local directory
        EXTRAS_DIR="$HOME/bat-extras"
        if [ ! -d "$EXTRAS_DIR" ]; then
            echo "Installing bat-extras for advanced formatting tools..."
            git clone https://github.com/eth-p/bat-extras.git "$EXTRAS_DIR"
            cd "$EXTRAS_DIR"
            ./build.sh --install --prefix="$HOME/.local"
            cd -
        else
            echo "bat-extras already installed."
        fi

        # Ensure ~/.local/bin is in PATH
        if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"
            echo "Added ~/.local/bin to PATH in .zshrc."
        fi

        # Add bat alias and theme to .zshrc if not present
        if ! grep -q "alias cat=" "$HOME/.zshrc"; then
            echo 'alias cat="bat --style=plain --paging=never"' >> "$HOME/.zshrc"
            echo 'export BAT_THEME="Monokai Extended"' >> "$HOME/.zshrc"
            echo "Added bat alias and theme to .zshrc."
        else
            echo "Alias for cat already exists in .zshrc. Skipping alias setup."
        fi

        echo "To verify supported file types, run: bat --list-languages"
        echo "Syntax highlighting setup complete. Restart your terminal or run: source ~/.zshrc"
        ;;

    5)
        echo "Exiting."
        exit 0
        ;;

    6)
        echo "Installing Obsidian..."
        if brew list --cask obsidian &> /dev/null; then
            echo "Obsidian is already installed."
        else
            echo "Installing Obsidian..."
            brew install --cask obsidian
        fi
        ;;

    *)
        echo "Invalid option. Exiting."
        exit 1
        ;;
esac
