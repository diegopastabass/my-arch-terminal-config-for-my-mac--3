# Funciones compartidas por los instaladores.
# Cárgalo desde un script con: source "$SCRIPT_DIR/lib/common.sh"

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m  %s\n' "$*"; }
die()  { printf '\033[1;31mERROR:\033[0m %s\n' "$*" >&2; exit 1; }

BACKUP_DIR="${BACKUP_DIR:-$HOME/.terminal-setup-backup/$(date +%Y%m%d-%H%M%S)}"

require_macos() {
  [[ "$(uname -s)" == "Darwin" ]] || die "Este script es solo para macOS."
}

# Instala Homebrew si falta y lo activa en la sesión actual.
ensure_brew() {
  if ! command -v brew >/dev/null 2>&1 && [[ ! -x /opt/homebrew/bin/brew && ! -x /usr/local/bin/brew ]]; then
    log "Instalando Homebrew (puede pedir tu contraseña y las Xcode Command Line Tools)..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
  command -v brew >/dev/null 2>&1 || die "Homebrew no quedó disponible en esta sesión."
}

# Copia src a dst. Si dst ya existe y es distinto, lo respalda en $BACKUP_DIR
# conservando su ruta relativa a $HOME.
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
