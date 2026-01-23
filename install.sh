#!/bin/zsh

# Define a function which rename a `target` file to `target.backup` if the file
# exists and if it's a 'real' file, ie not a symlink
backup() {
  target=$1
  if [ -e "$target" ]; then
    if [ ! -L "$target" ]; then
      mv "$target" "$target.backup"
      echo "-----> Moved your old $target config file to $target.backup"
    fi
  fi
}

symlink() {
  file=$1
  link=$2
  if [ ! -e "$link" ]; then
    echo "-----> Symlinking your new $link"
    ln -s $file $link
  fi
}

# For all files `$name` in the present folder except `*.sh`, `README.md`, `settings.json`,
# and `config`, backup the target file located at `~/.$name` and symlink `$name` to `~/.$name`
# Shell configuration
for name in zprofile zshrc aliases; do
  if [ ! -d "shell/$name" ]; then
    target="$HOME/.$name"
    backup $target
    symlink $PWD/shell/$name $target
  fi
done

# Git configuration
target="$HOME/.gitconfig"
backup $target
symlink $PWD/git/gitconfig $target
# git_setup.sh is just a script, no need to link it, we run it manually or it's run by user

# Check for Homebrew and install if we don't have it
CURRENT_DIR=`pwd`
if test ! $(which brew); then
  echo "-----> Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  
  # Add Homebrew to PATH for the current session (assuming Apple Silicon / default install path)
  if [ -f "/opt/homebrew/bin/brew" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
fi

# Update Homebrew recipes
echo "-----> Updating Homebrew..."
brew update

# Install dependencies from Brewfile
echo "-----> Installing dependencies from Brewfile..."
brew bundle --file="$CURRENT_DIR/Brewfile"

# Install zsh-syntax-highlighting and zsh-completions plugins
ZSH_PLUGINS_DIR="$HOME/.oh-my-zsh/custom/plugins"
mkdir -p "$ZSH_PLUGINS_DIR" && cd "$ZSH_PLUGINS_DIR"
if [ ! -d "$ZSH_PLUGINS_DIR/zsh-syntax-highlighting" ]; then
  echo "-----> Installing zsh plugin 'zsh-syntax-highlighting'..."
  git clone https://github.com/zsh-users/zsh-autosuggestions
  git clone https://github.com/zsh-users/zsh-syntax-highlighting
fi

if [ ! -d "$ZSH_PLUGINS_DIR/zsh-completions" ]; then
  echo "-----> Installing zsh plugin 'zsh-completions'..."
  git clone https://github.com/zsh-users/zsh-completions
fi
cd "$CURRENT_DIR"

# Node.js (via nvm)
echo "-----> Configuring nvm..."
mkdir -p ~/.nvm
export NVM_DIR="$HOME/.nvm"
# Source nvm from Homebrew install location
if [ -s "/opt/homebrew/opt/nvm/nvm.sh" ]; then
  . "/opt/homebrew/opt/nvm/nvm.sh"
elif [ -s "/usr/local/opt/nvm/nvm.sh" ]; then
  . "/usr/local/opt/nvm/nvm.sh"
fi

# Install latest LTS
if command -v nvm &> /dev/null; then
  echo "-----> Installing Node.js LTS via nvm..."
  nvm install --lts
  nvm alias default 'lts/*'
  nvm use default
else
  echo "nvm not found. Make sure brew installed it correctly."
fi

# Python (via uv)
echo "-----> Configuring Python via uv..."
if command -v uv &> /dev/null; then
  echo "-----> Installing latest Python via uv..."
  uv python install
else
  echo "uv not found. Make sure brew installed it correctly."
fi

# macOS Defaults
if [[ `uname` =~ "Darwin" ]]; then
  echo "-----> macOS Defaults"
  read -q "response?Do you want to apply macOS defaults (requires sudo and will restart Finder/Dock)? [y/N] "
  echo
  if [[ "$response" =~ ^[QqYy]$ ]]; then
    echo "-----> Applying macOS defaults..."
    chmod +x ./macos/defaults.sh
    ./macos/defaults.sh
  fi
fi

# Post-install messages
echo "-----> ni package manager installed."
echo "Please visit https://github.com/antfu-collective/ni to link it to your package manager."

# Symlink VS Code settings and keybindings
if [[ `uname` =~ "Darwin" ]]; then
  CODE_PATH=~/Library/Application\ Support/Code/User
else
  CODE_PATH=~/.config/Code/User
  if [ ! -e $CODE_PATH ]; then
    CODE_PATH=~/.vscode-server/data/Machine
  fi
fi

# Symlink settings.json and keybindings.json
target="$CODE_PATH/settings.json"
backup $target
symlink $PWD/vscode/settings.json $target

target="$CODE_PATH/keybindings.json"
backup $target
symlink $PWD/vscode/keybindings.json $target

# Install VS Code Extensions
echo "-----> Installing VS Code extensions..."
extensions=(
  astro-build.astro-vscode
  be5invis.vscode-custom-css
  biomejs.biome
  bradlc.vscode-tailwindcss
  bungcip.better-toml
  christian-kohler.npm-intellisense
  christian-kohler.path-intellisense
  dbaeumer.vscode-eslint
  editorconfig.editorconfig
  enkia.tokyo-night
  esbenp.prettier-vscode
  file-icons.file-icons
  johnnymorganz.stylua
  lawrencegrant.cql
  shd101wyy.markdown-preview-enhanced
  mikestead.dotenv
  unifiedjs.vscode-mdx
  naumovs.color-highlight
  redhat.vscode-yaml
  streetsidesoftware.code-spell-checker
  tamasfe.even-better-toml
  timonwong.shellcheck
  usernamehw.errorlens
)

for extension in "${extensions[@]}"; do
  if command -v code &> /dev/null; then
    code --install-extension "$extension"
  else
    echo "VS Code 'code' command not found. Skipping extension: $extension"
  fi
done

# Symlink SSH config file to the present `config` file for macOS and add SSH passphrase to the keychain
if [[ `uname` =~ "Darwin" ]]; then
  target=~/.ssh/config
  backup $target
  symlink $PWD/config $target
  ssh-add --apple-use-keychain ~/.ssh/id_ed25519
fi

# Git setup
echo "-----> Git Setup"
if [ ! -f "$HOME/.gitconfig.local" ]; then
  echo "Setting up your identity in ~/.gitconfig.local..."
  read "git_name?What is your name? "
  read "git_email?What is your email? "
  
  git config -f "$HOME/.gitconfig.local" user.name "$git_name"
  git config -f "$HOME/.gitconfig.local" user.email "$git_email"
  echo "Identity saved to ~/.gitconfig.local"
else
  echo "~/.gitconfig.local already exists. Skipping identity setup."
fi

# Refresh the current terminal with the newly installed configuration
exec zsh

echo "👌 Carry on with git setup!"
