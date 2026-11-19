#!/usr/bin/env bash
# Instala Visual Studio Code en macOS con tus extensiones y ajustes.
#
# Uso:  bash install-vscode.sh
# Es idempotente. Si settings.json ya existe y es distinto, se respalda antes de reemplazarlo.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

require_macos
ensure_brew

APP="/Applications/Visual Studio Code.app"
APP_CODE_BIN="$APP/Contents/Resources/app/bin/code"

log "Instalando Visual Studio Code..."
if [[ -d "$APP" ]]; then
  log "VS Code ya está en /Applications"
else
  brew install --cask visual-studio-code
fi

# Usa el CLI 'code' del PATH; si no está, usa el que viene dentro de la app.
if command -v code >/dev/null 2>&1; then
  CODE="code"
elif [[ -x "$APP_CODE_BIN" ]]; then
  CODE="$APP_CODE_BIN"
else
  die "No encuentro el CLI 'code'. Abre VS Code y ejecuta el comando 'Shell Command: Install 'code' command in PATH'."
fi

log "Instalando extensiones desde dotfiles/vscode/extensions.txt..."
while IFS= read -r ext; do
  [[ -z "$ext" || "$ext" == \#* ]] && continue
  "$CODE" --install-extension "$ext" >/dev/null || warn "No se pudo instalar la extensión $ext"
done < "$SCRIPT_DIR/dotfiles/vscode/extensions.txt"

log "Aplicando ajustes de VS Code..."
install_file "$SCRIPT_DIR/dotfiles/vscode/settings.json" \
  "$HOME/Library/Application Support/Code/User/settings.json"

log "Listo. Si VS Code estaba abierto, ciérralo y vuelve a abrirlo para cargar los ajustes."
