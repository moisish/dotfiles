# Path to your oh-my-zsh configuration.
ZSH=$HOME/.oh-my-zsh

# Path to custom themes and plugins
ZSH_CUSTOM=$HOME/.dotfiles/oh-my-zsh-custom

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
ZSH_THEME="agnoster"

# Hide username in prompt
DEFAULT_USER=`whoami`

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
plugins=(git docker docker-compose composer macos vagrant zsh-autosuggestions)

source $ZSH/oh-my-zsh.sh

# Removed old RVM path
#set numeric keys
# 0 . Enter
bindkey -s "^[Op" "0"
bindkey -s "^[Ol" "."
bindkey -s "^[OM" "^M"
# 1 2 3
bindkey -s "^[Oq" "1"
bindkey -s "^[Or" "2"
bindkey -s "^[Os" "3"
# 4 5 6
bindkey -s "^[Ot" "4"
bindkey -s "^[Ou" "5"
bindkey -s "^[Ov" "6"
# 7 8 9
bindkey -s "^[Ow" "7"
bindkey -s "^[Ox" "8"
bindkey -s "^[Oy" "9"
# + -  * /
bindkey -s "^[Ok" "+"
bindkey -s "^[Om" "-"
bindkey -s "^[Oj" "*"
bindkey -s "^[Oo" "/"

# Load the shell dotfiles, and then some:
# * ~/.dotfiles-custom can be used for other settings you don’t want to commit.
for file in ~/.dotfiles/home/.{exports,aliases,functions}; do
	[ -r "$file" ] && [ -f "$file" ] && source "$file"
done

for file in ~/.dotfiles-custom/shell/.{exports,aliases,functions,zshrc}; do
	[ -r "$file" ] && [ -f "$file" ] && source "$file"
done
unset file

# Directory jumping with z.sh fallback until zoxide is verified
if [ -f ~/.dotfiles/home/z.sh ]; then
    . ~/.dotfiles/home/z.sh
fi

# Alias hub to git
eval "$(hub alias -s)"

# Sudoless npm https://github.com/sindresorhus/guides/blob/master/npm-global-without-sudo.md
NPM_PACKAGES="${HOME}/.npm-packages"
export PATH="$PATH:$NPM_PACKAGES/bin"
# Preserve MANPATH if you already defined it somewhere in your config.
# Otherwise, fall back to `manpath` so we can inherit from `/etc/manpath`.
export MANPATH="${MANPATH-$(manpath)}:$NPM_PACKAGES/share/man"

export PATH=$HOME/.dotfiles/bin:$PATH

# Import ssh keys in keychain
ssh-add -A 2>/dev/null;

# Setup xdebug
export XDEBUG_CONFIG="idekey=VSCODE"

# Enable autosuggestions (installed via brew)
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh


# Extra paths
export PATH="$HOME/.rvm/bin:$PATH"
export PATH="/opt/homebrew/opt/mariadb@10.6/bin:$PATH"
export PATH="$HOME/.composer/vendor/bin:$PATH"
export PATH=/usr/local/bin:$PATH
export PATH="$HOME/.yarn/bin:$PATH"
export PATH="$HOME/.codeium/windsurf/bin:$PATH"
export PATH="$HOME/.spin/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

# do not update all homebrew stuff automatically
export HOMEBREW_NO_AUTO_UPDATE=1

export PATH=$HOME/bin:~/.config/phpmon/bin:$PATH
export JAVA_HOME="$(brew --prefix)/opt/openjdk@17"
export ANDROID_HOME="$HOME/Library/Android/sdk"
export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$PATH"

# Initialize modern tools
# zoxide - smarter cd
if command -v zoxide &> /dev/null; then
    eval "$(zoxide init zsh)"
fi

# NVM - Node Version Manager
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"

# fnm - Fast Node Manager (preferred, with NVM fallback)
if command -v fnm &> /dev/null; then
    eval "$(fnm env --use-on-cd)"
fi
