#!/usr/bin/env bash
# Instala en macOS la configuración de terminal (zsh + Powerlevel10k + kitty)
# replicada desde el equipo Linux.
#
# Uso:  bash install.sh
# Es idempotente: puedes ejecutarlo varias veces. Si un archivo de destino
# ya existe y es distinto, se guarda una copia en ~/.terminal-setup-backup/.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$SCRIPT_DIR/dotfiles"
BACKUP_DIR="$HOME/.terminal-setup-backup/$(date +%Y%m%d-%H%M%S)"

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m  %s\n' "$*"; }
die()  { printf '\033[1;31mERROR:\033[0m %s\n' "$*" >&2; exit 1; }

[[ "$(uname -s)" == "Darwin" ]] || die "Este script es solo para macOS."

# Copia un archivo de la configuración a su destino, con respaldo si ya existe y difiere.
install_file() {
  local src="$1" dst="$2" rel
  rel="${dst#"$HOME"/}"

  if [[ -f "$dst" ]] && cmp -s "$src" "$dst"; then
    log "Sin cambios: ~/$rel"
    return
  fi

  mkdir -p "$(dirname "$dst")"
  if [[ -e "$dst" || -L "$dst" ]]; then
    mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
    cp -p "$dst" "$BACKUP_DIR/$rel"
    warn "Respaldo de ~/$rel en $BACKUP_DIR/$rel"
  fi

  cp "$src" "$dst"
  log "Instalado: ~/$rel"
}

# 1. Homebrew
if ! command -v brew >/dev/null 2>&1 && [[ ! -x /opt/homebrew/bin/brew && ! -x /usr/local/bin/brew ]]; then
  log "Instalando Homebrew (puede pedir tu contraseña y las herramientas de Xcode)..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi
command -v brew >/dev/null 2>&1 || die "Homebrew no quedó disponible en esta sesión."

# 2. Herramientas de línea de comandos que usan los alias y funciones del zshrc
log "Instalando herramientas de terminal con Homebrew..."
brew install zsh-autosuggestions zsh-syntax-highlighting lsd bat fzf coreutils scrub
for pkg in thefuck highlight; do
  brew install "$pkg" || warn "No se pudo instalar '$pkg' (opcional). Revisa 'brew info $pkg'."
done

# 3. kitty y la fuente que usa su configuración
log "Instalando kitty y Hack Nerd Font..."
brew install --cask kitty || warn "kitty no se instaló por Homebrew (¿ya lo tienes en /Applications?)."
brew install --cask font-hack-nerd-font || warn "No se pudo instalar la fuente Hack Nerd Font."

# 4. Powerlevel10k (el zshrc lo carga desde ~/powerlevel10k)
if [[ ! -d "$HOME/powerlevel10k" ]]; then
  log "Clonando Powerlevel10k en ~/powerlevel10k..."
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$HOME/powerlevel10k"
else
  log "Powerlevel10k ya existe en ~/powerlevel10k"
fi

# 5. Archivos de configuración
log "Copiando configuración de zsh y kitty..."
install_file "$DOTFILES/zshrc"                  "$HOME/.zshrc"
install_file "$DOTFILES/p10k.zsh"               "$HOME/.p10k.zsh"
install_file "$DOTFILES/kitty/kitty.conf"       "$HOME/.config/kitty/kitty.conf"
install_file "$DOTFILES/kitty/color.ini"        "$HOME/.config/kitty/color.ini"
install_file "$DOTFILES/zsh/sudo.plugin.zsh"    "$HOME/.zsh/plugins/zsh-sudo/sudo.plugin.zsh"

# 6. Comprobaciones
if ! zsh -n "$HOME/.zshrc"; then
  die "~/.zshrc tiene errores de sintaxis."
fi

user_shell="$(dscl . -read "/Users/$USER" UserShell 2>/dev/null | awk '{print $2}')"
if [[ "$user_shell" != "/bin/zsh" && "$user_shell" != "/opt/homebrew/bin/zsh" && "$user_shell" != "/usr/local/bin/zsh" ]]; then
  warn "Tu shell por defecto es '$user_shell'. Para cambiarla: chsh -s /bin/zsh"
fi

if ! brew list --cask font-hack-nerd-font >/dev/null 2>&1; then
  warn "La fuente Hack Nerd Font no aparece instalada. kitty caerá a otra fuente."
fi

log "Listo."
echo
echo "Siguientes pasos:"
echo "  1. Cierra y vuelve a abrir kitty (o escribe: exec zsh)."
echo "  2. Si quieres re-configurar el prompt: p10k configure"
if [[ -d "$BACKUP_DIR" ]]; then
  echo "  3. Tus configuraciones anteriores están en: $BACKUP_DIR"
fi
