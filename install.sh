#!/usr/bin/env bash
#
# Instala as personalizações do KDE Plasma deste repositório:
#   - tema do Plasma "Vidro Azul"
#   - perfil e esquema de cores do Konsole "Vidro Azul"
#   - layout dos painéis (dock inferior + barra superior)
#
# Tudo o que for substituído é copiado antes para uma pasta de backup.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
BACKUP_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/kde-config/backup-$(date +%Y%m%d-%H%M%S)"

TEMA="vidro-azul"
PERFIL_KONSOLE="VidroAzul.profile"

# ---------- Saída ----------

info()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
ok()    { printf '\033[1;32m  ✓\033[0m %s\n' "$*"; }
erro()  { printf '\033[1;31mErro:\033[0m %s\n' "$*" >&2; }

uso() {
    cat <<EOF
Uso: ./install.sh [opções]

Sem opções, instala tudo.

Opções:
  --tema      instala e aplica o tema do Plasma Vidro Azul
  --konsole   instala o perfil do Konsole e o define como padrão
  --layout    aplica o layout dos painéis (dock + barra superior)
  --ajuda     mostra esta mensagem
EOF
}

# ---------- Utilitários ----------

verificar_dependencias() {
    local faltando=()
    for cmd in kwriteconfig6 qdbus6 plasma-apply-desktoptheme; do
        command -v "$cmd" >/dev/null 2>&1 || faltando+=("$cmd")
    done
    if ((${#faltando[@]})); then
        erro "comandos não encontrados: ${faltando[*]}"
        erro "este script requer uma sessão do KDE Plasma 6."
        exit 1
    fi
}

# Copia um arquivo ou pasta para o backup, mantendo o caminho relativo ao $HOME.
fazer_backup() {
    local alvo="$1"
    [[ -e "$alvo" ]] || return 0
    local destino="$BACKUP_DIR/${alvo#"$HOME"/}"
    mkdir -p "$(dirname "$destino")"
    cp -a "$alvo" "$destino"
    ok "backup: $alvo"
}

# ---------- Instalação ----------

instalar_tema() {
    info "Tema do Plasma: $TEMA"
    local destino="$DATA_DIR/plasma/desktoptheme/$TEMA"

    fazer_backup "$destino"
    rm -rf "$destino"
    mkdir -p "$(dirname "$destino")"
    cp -r "$REPO_DIR/plasma/desktoptheme/$TEMA" "$destino"
    ok "copiado para $destino"

    # Se o tema já estiver ativo, troca e volta para o Plasma reler os arquivos.
    plasma-apply-desktoptheme breeze-dark >/dev/null
    plasma-apply-desktoptheme "$TEMA" >/dev/null
    ok "tema aplicado"
}

instalar_konsole() {
    info "Konsole: perfil Vidro Azul"
    local destino="$DATA_DIR/konsole"

    mkdir -p "$destino"
    for arquivo in VidroAzul.colorscheme VidroAzul.profile; do
        fazer_backup "$destino/$arquivo"
        cp "$REPO_DIR/konsole/$arquivo" "$destino/"
    done
    ok "copiado para $destino"

    fazer_backup "$CONFIG_DIR/konsolerc"
    kwriteconfig6 --file konsolerc --group "Desktop Entry" --key DefaultProfile "$PERFIL_KONSOLE"
    ok "definido como perfil padrão (reabra o Konsole para ver)"
}

aplicar_layout() {
    info "Layout dos painéis"

    fazer_backup "$CONFIG_DIR/plasma-org.kde.plasma.desktop-appletsrc"
    fazer_backup "$CONFIG_DIR/plasmashellrc"

    qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript \
        "$(cat "$REPO_DIR/plasma/layout/dock-e-barra-superior.js")"
    ok "layout aplicado"
}

# ---------- Principal ----------

main() {
    local tema=false konsole=false layout=false

    if (($# == 0)); then
        tema=true; konsole=true; layout=true
    fi

    while (($#)); do
        case "$1" in
            --tema)    tema=true ;;
            --konsole) konsole=true ;;
            --layout)  layout=true ;;
            -h|--ajuda|--help) uso; exit 0 ;;
            *) erro "opção desconhecida: $1"; uso; exit 1 ;;
        esac
        shift
    done

    verificar_dependencias

    $tema    && instalar_tema
    $konsole && instalar_konsole
    $layout  && aplicar_layout

    echo
    if [[ -d "$BACKUP_DIR" ]]; then
        info "Concluído. Backup dos arquivos substituídos em: $BACKUP_DIR"
    else
        info "Concluído. Nenhum arquivo precisou de backup."
    fi
}

main "$@"
