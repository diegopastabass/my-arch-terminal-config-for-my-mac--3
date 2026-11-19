#!/usr/bin/env bash
# Instala el entorno LaTeX para VS Code en macOS:
#   - TeX Live completo (MacTeX sin apps GUI), equivalente al texlive-meta de Arch
#   - latexmk y biber, que usa LaTeX Workshop
#   - extensiones de VS Code: LaTeX Workshop, visor de PDF y contador de palabras
#
# Uso:  bash install-latex.sh      (requiere haber corrido antes install-vscode.sh)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

TEXBIN="/Library/TeX/texbin"
LATEX_EXTENSIONS=(
  james-yu.latex-workshop
  tomoki1207.pdf
  yongke.latex-wordcount
)

require_macos
ensure_brew

if [[ -x "$TEXBIN/pdflatex" ]]; then
  log "TeX Live ya está instalado en $TEXBIN"
else
  log "Instalando MacTeX sin apps GUI. Es una descarga grande (~4 GB) y pedirá tu contraseña..."
  brew install --cask mactex-no-gui
fi
export PATH="$TEXBIN:$PATH"

for bin in pdflatex lualatex xelatex latexmk biber; do
  command -v "$bin" >/dev/null 2>&1 || die "No encuentro '$bin' en $TEXBIN. Revisa la instalación de MacTeX."
done

if command -v code >/dev/null 2>&1; then
  CODE="code"
elif [[ -x "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" ]]; then
  CODE="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
else
  die "No encuentro VS Code. Corre primero: bash install-vscode.sh"
fi

log "Instalando extensiones de LaTeX en VS Code..."
for ext in "${LATEX_EXTENSIONS[@]}"; do
  "$CODE" --install-extension "$ext" >/dev/null || warn "No se pudo instalar la extensión $ext"
done

# Prueba de humo: compila un documento mínimo con latexmk, igual que haría LaTeX Workshop.
log "Compilando un documento de prueba con latexmk..."
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
printf '%s\n' '\documentclass{article}' '\begin{document}Hola, LaTeX.\end{document}' > "$TMP_DIR/test.tex"
if (cd "$TMP_DIR" && latexmk -pdf -interaction=nonstopmode test.tex >/dev/null 2>&1) && [[ -f "$TMP_DIR/test.pdf" ]]; then
  log "Compilación de prueba correcta"
else
  warn "La compilación de prueba falló. Revisa el entorno con: latexmk -pdf test.tex"
fi

log "Listo. Abre un .tex en VS Code y LaTeX Workshop compilará con latexmk."
