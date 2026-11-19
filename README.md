# Configuración de terminal para macOS

Replica en un Mac la terminal del equipo Linux: zsh con Powerlevel10k, plugins, alias y funciones, y kitty con su esquema de colores y fuente.

## Contenido

```
mac-terminal-setup/
├── install.sh                      # terminal: zsh + kitty (solo macOS)
├── install-vscode.sh               # VS Code + extensiones + settings.json
├── install-neovim.sh               # Neovim + tu config (NvChad)
├── install-latex.sh                # TeX Live + extensiones LaTeX para VS Code
├── lib/
│   └── common.sh                   # funciones compartidas por los instaladores
├── README.md
└── dotfiles/
    ├── zshrc                       # ~/.zshrc (adaptado a macOS)
    ├── p10k.zsh                    # ~/.p10k.zsh (copia exacta)
    ├── kitty/
    │   ├── kitty.conf              # ~/.config/kitty/kitty.conf (adaptado a macOS)
    │   └── color.ini               # ~/.config/kitty/color.ini (copia exacta)
    ├── zsh/
    │   └── sudo.plugin.zsh         # plugin zsh-sudo (copia exacta)
    ├── vscode/
    │   ├── settings.json           # ajustes de VS Code (terminal adaptada a macOS)
    │   └── extensions.txt          # lista de extensiones
    └── nvim/                       # tu config de Neovim (sin .git)
```

## Terminal (zsh y kitty)

Copia la carpeta `mac-terminal-setup` al Mac (AirDrop, USB, git, etc.) y ejecuta:

```bash
cd ~/Downloads/mac-terminal-setup
bash install.sh
```

El script:

1. Instala Homebrew si no existe.
2. Instala con Homebrew: `zsh-autosuggestions`, `zsh-syntax-highlighting`, `lsd`, `bat`, `fzf`, `coreutils`, `scrub`, y opcionalmente `thefuck` y `highlight`.
3. Instala los casks `kitty` y `font-hack-nerd-font`.
4. Clona Powerlevel10k en `~/powerlevel10k`.
5. Copia los archivos de `dotfiles/` a su destino. Si ya existe un archivo distinto, lo respalda en `~/.terminal-setup-backup/<fecha>/`.
6. Valida la sintaxis de `~/.zshrc`.

Es idempotente: puedes volver a ejecutarlo sin problema.

## VS Code, Neovim y LaTeX

Cada entorno tiene su propio script y son independientes entre sí:

```bash
bash install-vscode.sh   # VS Code, extensiones y settings.json
bash install-neovim.sh   # Neovim y tu config de NvChad
bash install-latex.sh    # MacTeX, latexmk, biber y extensiones LaTeX (requiere VS Code)
```

- **VS Code**: instala la app con Homebrew, las extensiones de `dotfiles/vscode/extensions.txt` y `settings.json`. Las claves de terminal pasaron de `linux` a `osx` (`profiles`, `defaultProfile`) y `linuxExec` a `osxExec`.
- **Neovim**: tu config es un fork de NvChad v2.5 con un cambio de tema (`onedark` → `gruvbox`). El script clona `NvChad/starter` en el commit base `c3d1fb6`, copia encima tus archivos y restaura los plugins según `lazy-lock.json`. Si ya existe `~/.config/nvim`, lo mueve al respaldo.
- **LaTeX**: tu `settings.json` no tiene ajustes de LaTeX Workshop, así que el entorno lo definen las extensiones y TeX Live. El script instala MacTeX sin apps GUI (~4 GB), que equivale al `texlive-meta` de tu Arch, y compila un documento de prueba al final.

Notas para revisar:

- `terminal.external.osxExec` quedó en `kitty`. No lo pude probar en macOS.
- Tu `settings.json` referencia Dart (`[dart]`) y Prettier (`editor.defaultFormatter`), pero esas extensiones no están en tu lista. No las agregué.
- La config de Neovim usa NvChad `v2.5`. No la actualices al starter v3 sin revisar `chadrc.lua`.
- El `argv.json` de VS Code tiene flags de Linux y no se copió.
- `install-neovim.sh` necesita acceso HTTPS a GitHub para clonar el starter.

## Qué cambió respecto a Linux

Estas son las modificaciones necesarias para que la configuración funcione en macOS:

| Elemento | Linux | macOS |
|---|---|---|
| `PATH` fijo (`/root/.local/bin`, `/snap/bin`…) | Sobrescribía el `PATH` | Eliminado. macOS y Homebrew ya lo configuran |
| Plugins de zsh | `/usr/share/zsh/plugins/...` | Rutas de Homebrew (`$HOMEBREW_PREFIX/share/...`) |
| `zsh-sudo` | `/usr/share/zsh-sudo/` | Copiado a `~/.zsh/plugins/zsh-sudo/` |
| `dircolors` (GNU) | `dircolors -b` | `gdircolors` de `coreutils`, con comprobación |
| `extractPorts` | `xclip` y `grep -P` | `pbcopy` y `grep -E` (portable) |
| `rmk` | `shred` | `gshred` de `coreutils` |
| Android SDK | `~/Android/Sdk` | `~/Library/Android/sdk` (ruta por defecto de Android Studio) |
| `CHROME_EXECUTABLE` | `/usr/bin/chromium` | Google Chrome, solo si está instalado |
| `source powerlevel10k` | Aparecía dos veces, y `.p10k.zsh` se cargaba antes del tema | Una sola vez, antes de `~/.p10k.zsh` (orden recomendado por Powerlevel10k) |
| `zsh-syntax-highlighting` | Se cargaba primero | Se carga último (requisito del plugin) |
| `fzf` | `~/.fzf.zsh` (no existía) | `source <(fzf --zsh)` si está instalado |
| `thefuck` | Sin comprobación | Solo se activa si está instalado |
| kitty `font_family` | `HackNerdFont` | `Hack Nerd Font` (nombre de la familia en macOS) |
| kitty `linux_display_server` | `wayland` | Eliminado (solo aplica a Linux) |
| kitty `macos_option_as_alt` | No existía | `yes`, para que funcionen los atajos Alt de zsh y fzf (como Alt+C) |

Lo que **no** se copió a propósito:

- `~/.zsh_history` (historial personal).
- `~/.cache/p10k-instant-prompt-*` (caché que se regenera sola).
- `~/.bashrc`, `~/.bash_profile`, `~/.gitconfig` (no son parte de zsh ni de kitty; dímelo si quieres incluirlos).
- `~/.config/thefuck/`: solo tiene `settings.py` con todo comentado (valores por defecto) y una carpeta `rules/` vacía.

## Después de instalar

- Abre kitty. Si la fuente no se ve con iconos, comprueba que `Hack Nerd Font` aparezca en Libro de Fuentes.
- Para retocar el prompt: `p10k configure`.

## Limitaciones conocidas

- **No probado en un Mac real.** Validé la sintaxis de `install.sh` y `zshrc` (`bash -n`, `zsh -n`), que kitty 0.49 carga `kitty.conf` sin errores, y que zsh arranca con alias y funciones disponibles. Lo que no pude probar aquí es la instalación con Homebrew y el comportamiento de kitty con la fuente en macOS.
- `thefuck` podría estar deprecado o deshabilitado en Homebrew. El script lo trata como opcional; si falla, el resto sigue funcionando.
- `rmk` sobrescribe el archivo antes de borrarlo, pero en APFS (SSD) esa sobrescritura no garantiza que los datos no sean recuperables.
- `fzf-lovely` usa `highlight`, `coderay` y `rougify` como respaldo para la vista previa; `coderay` y `rougify` no se instalan y el script no los trae, así que si no están, cae a `cat`.
