#!/usr/bin/env bash
# Instala Neovim en macOS con tu configuración (base NvChad v2.5 + tus cambios).
#
# Uso:  bash install-neovim.sh
# La config se reconstruye así: clona NvChad/starter, fija el commit base de tu
# repo original y copia encima dotfiles/nvim/. Los plugins se instalan según lazy-lock.json.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

NVIM_DIR="$HOME/.config/nvim"
NVIM_STARTER_URL="https://github.com/NvChad/starter"
NVIM_BASE_COMMIT="c3d1fb646a04aaa97b2929b90269f8a7bf8e8dc4"

require_macos
ensure_brew

log "Instalando Neovim y herramientas que usa NvChad (telescope, etc.)..."
brew install neovim ripgrep fd

if ! brew list --cask font-hack-nerd-font >/dev/null 2>&1; then
  log "Instalando Hack Nerd Font (los iconos de NvChad la necesitan)..."
  brew install --cask font-hack-nerd-font
fi

if ! xcode-select -p >/dev/null 2>&1; then
  warn "Faltan las Xcode Command Line Tools (compilador para telescope-fzf-native). Ejecuta: xcode-select --install"
fi

# Base de NvChad en ~/.config/nvim. Si ya existe otra cosa, se mueve al respaldo.
if [[ -d "$NVIM_DIR/.git" ]] && [[ "$(git -C "$NVIM_DIR" rev-parse HEAD 2>/dev/null)" == "$NVIM_BASE_COMMIT" ]]; then
  log "La base de NvChad ya está en ~/.config/nvim"
else
  if [[ -e "$NVIM_DIR" || -L "$NVIM_DIR" ]]; then
    mkdir -p "$BACKUP_DIR"
    mv "$NVIM_DIR" "$BACKUP_DIR/nvim"
    warn "Movido ~/.config/nvim a $BACKUP_DIR/nvim"
  fi
  log "Clonando NvChad starter y fijando el commit base..."
  git clone --quiet "$NVIM_STARTER_URL" "$NVIM_DIR"
  git -C "$NVIM_DIR" checkout --quiet "$NVIM_BASE_COMMIT"
fi

# Tus archivos encima de la base. install_file respalda los que difieran.
log "Aplicando tu configuración de Neovim..."
(cd "$SCRIPT_DIR/dotfiles/nvim" && find . -type f | sed 's|^\./||') | while IFS= read -r rel; do
  install_file "$SCRIPT_DIR/dotfiles/nvim/$rel" "$NVIM_DIR/$rel"
done

# Instala los plugins. Primero intenta restaurar las versiones de lazy-lock.json.
log "Instalando plugins con lazy.nvim (puede tardar unos minutos)..."
if ! nvim --headless "+Lazy! restore" +qa 2>/dev/null; then
  nvim --headless "+Lazy! sync" +qa || warn "lazy.nvim terminó con errores. Revisa con: nvim +Lazy"
fi

log "Listo. Versión instalada: $(nvim --version | head -1)"
