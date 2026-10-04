#!/usr/bin/env bash
#
# Instala as personalizações do KDE Plasma deste repositório:
#   - programas das listas em pacotes/ (distribuições baseadas no Arch)
#   - tema do Plasma "Vidro Azul"
#   - aparência: esquema de cores, ícones e efeitos do KWin
#   - perfil e esquema de cores do Konsole "Vidro Azul"
#   - layout dos painéis (dock inferior + barra superior)
#   - atalhos globais de teclado
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
aviso() { printf '\033[1;33m  !\033[0m %s\n' "$*"; }
erro()  { printf '\033[1;31mErro:\033[0m %s\n' "$*" >&2; }

uso() {
    cat <<EOF
Uso: ./install.sh [opções]

Sem opções, instala tudo.

Opções:
  --pacotes   instala os programas de pacotes/ (requer pacman e sudo)
  --tema     instala e aplica o tema do Plasma Vidro Azul
  --aparencia aplica esquema de cores, ícones e efeitos do KWin
  --konsole   instala o perfil do Konsole e o define como padrão
  --layout    aplica o layout dos painéis (dock + barra superior)
  --atalhos   aplica os atalhos globais de kde/atalhos.conf
  --ajuda     mostra esta mensagem
EOF
}

# ---------- Utilitários ----------

verificar_dependencias() {
    local faltando=()
    for cmd in kwriteconfig6 qdbus6 plasma-apply-desktoptheme busctl; do
        command -v "$cmd" >/dev/null 2>&1 || faltando+=("$cmd")
    done
    if ((${#faltando[@]})); then
        erro "comandos não encontrados: ${faltando[*]}"
        erro "este script requer uma sessão do KDE Plasma 6."
        exit 1
    fi
}

# Fora de um terminal (ex.: duplo clique no Dolphin) o sudo não tem onde pedir
# a senha, e cada falha conta para o bloqueio temporário do pam_faillock.
# Nesse caso, reabre o script em uma janela do Konsole.
exigir_terminal() {
    [[ -t 0 ]] && return 0
    if command -v konsole >/dev/null 2>&1; then
        exec konsole --hold -e "$REPO_DIR/install.sh" "$@"
    fi
    erro "a instalação de pacotes pede a senha do sudo e precisa de um terminal."
    erro "abra um terminal nesta pasta e rode ./install.sh"
    exit 1
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

# Lê uma lista de pacotes ignorando comentários, espaços e linhas vazias.
ler_lista() {
    sed 's/#.*//; s/[[:space:]]//g; /^$/d' "$1"
}

instalar_pacotes() {
    info "Pacotes"
    if ! command -v pacman >/dev/null 2>&1; then
        aviso "pacman não encontrado: instale manualmente os programas listados em pacotes/"
        return
    fi

    local -a lista

    mapfile -t lista < <(ler_lista "$REPO_DIR/pacotes/arch.txt")
    if ((${#lista[@]})); then
        sudo pacman -S --needed "${lista[@]}"
        ok "repositórios oficiais: ${lista[*]}"
    fi

    mapfile -t lista < <(ler_lista "$REPO_DIR/pacotes/cachyos.txt")
    if ((${#lista[@]})); then
        if grep -q '^\[cachyos\]' /etc/pacman.conf; then
            sudo pacman -S --needed "${lista[@]}"
            ok "repositório do CachyOS: ${lista[*]}"
        else
            aviso "repositório do CachyOS não configurado; instale por outra fonte: ${lista[*]}"
        fi
    fi

    mapfile -t lista < <(ler_lista "$REPO_DIR/pacotes/aur.txt")
    if ((${#lista[@]})); then
        local ajudante=""
        if command -v paru >/dev/null 2>&1; then
            ajudante=paru
        elif command -v yay >/dev/null 2>&1; then
            ajudante=yay
        fi

        if [[ -n "$ajudante" ]]; then
            "$ajudante" -S --needed "${lista[@]}"
            ok "AUR ($ajudante): ${lista[*]}"
        else
            aviso "nenhum ajudante do AUR (paru ou yay) encontrado; instale manualmente: ${lista[*]}"
        fi
    fi
}

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

tema_icones_instalado() {
    [[ -d "$DATA_DIR/icons/$1" || -d "/usr/share/icons/$1" ]]
}

# Troca o tema de ícones avisando os apps abertos. O plasma-changeicons fica
# em pastas internas que variam entre distribuições; sem ele, grava só a
# configuração, que passa a valer ao reabrir os apps.
aplicar_icones() {
    local caminho
    for caminho in /usr/lib/plasma-changeicons \
                   /usr/libexec/plasma-changeicons \
                   /usr/lib/*/libexec/plasma-changeicons; do
        if [[ -x "$caminho" ]]; then
            "$caminho" "$1" >/dev/null
            return
        fi
    done
    kwriteconfig6 --file kdeglobals --group Icons --key Theme "$1"
}

aplicar_aparencia() {
    info "Aparência: cores, ícones e efeitos do KWin"
    # shellcheck source=kde/aparencia.conf
    source "$REPO_DIR/kde/aparencia.conf"

    fazer_backup "$CONFIG_DIR/kdeglobals"
    fazer_backup "$CONFIG_DIR/kwinrc"

    plasma-apply-colorscheme "$ESQUEMA_CORES" >/dev/null
    ok "esquema de cores: $ESQUEMA_CORES"

    if tema_icones_instalado "$TEMA_ICONES"; then
        aplicar_icones "$TEMA_ICONES"
        ok "ícones: $TEMA_ICONES"
    else
        aviso "tema de ícones '$TEMA_ICONES' não encontrado; instale-o e rode ./install.sh --aparencia"
    fi

    local efeito
    for efeito in "${EFEITOS_LIGADOS[@]}"; do
        kwriteconfig6 --file kwinrc --group Plugins --key "${efeito}Enabled" true
    done
    for efeito in "${EFEITOS_DESLIGADOS[@]}"; do
        kwriteconfig6 --file kwinrc --group Plugins --key "${efeito}Enabled" false
    done
    # O reconfigure só relê o kwinrc, que vale a partir do próximo login. Na
    # sessão atual os efeitos são trocados pelo D-Bus, desligando antes de
    # ligar para o substituto não conviver com o efeito que ele substitui.
    qdbus6 org.kde.KWin /KWin reconfigure
    for efeito in "${EFEITOS_DESLIGADOS[@]}"; do
        qdbus6 org.kde.KWin /Effects unloadEffect "$efeito" >/dev/null
    done
    local -a falharam=()
    for efeito in "${EFEITOS_LIGADOS[@]}"; do
        qdbus6 org.kde.KWin /Effects loadEffect "$efeito" >/dev/null
        [[ "$(qdbus6 org.kde.KWin /Effects isEffectLoaded "$efeito")" == true ]] || falharam+=("$efeito")
    done
    if ((${#falharam[@]})); then
        aviso "efeitos que o KWin não carregou: ${falharam[*]}"
    fi
    ok "efeitos do KWin: $((${#EFEITOS_LIGADOS[@]} - ${#falharam[@]})) ligados, ${#EFEITOS_DESLIGADOS[@]} desligados"
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

# Remove espaços do início e do fim.
aparar() {
    local s="$1"
    s="${s#"${s%%[![:space:]]*}"}"
    s="${s%"${s##*[![:space:]]}"}"
    printf '%s' "$s"
}

# Converte um atalho escrito (ex.: "Ctrl+Alt+T") no código numérico do Qt
# usado pelo serviço de atalhos do KDE: modificadores somados ao código da tecla.
codigo_tecla() {
    local -a partes
    IFS='+' read -ra partes <<< "$1"
    local tecla="${partes[-1]}" codigo=0 mod

    for mod in "${partes[@]:0:${#partes[@]}-1}"; do
        case "$mod" in
            Shift) ((codigo |= 0x02000000)) ;;
            Ctrl)  ((codigo |= 0x04000000)) ;;
            Alt)   ((codigo |= 0x08000000)) ;;
            Meta)  ((codigo |= 0x10000000)) ;;
            *) return 1 ;;
        esac
    done

    case "$tecla" in
        [A-Za-z0-9])     ((codigo |= $(printf '%d' "'${tecla^^}"))) ;;
        F[1-9]|F[1-3][0-9]) ((codigo |= 0x01000030 + ${tecla#F} - 1)) ;;
        Space)  ((codigo |= 0x20)) ;;
        Meta)   ((codigo |= 0x01000022)) ;;
        Search) ((codigo |= 0x01000092)) ;;
        *) return 1 ;;
    esac

    echo "$codigo"
}

aplicar_atalhos() {
    info "Atalhos globais"
    fazer_backup "$CONFIG_DIR/kglobalshortcutsrc"

    local componente acao atalhos atalho codigo linha
    while IFS='|' read -r componente acao atalhos; do
        componente="$(aparar "${componente%%#*}")"
        [[ -z "$componente" ]] && continue
        acao="$(aparar "$acao")"
        atalhos="$(aparar "$atalhos")"

        # Cada atalho vai como uma sequência de 4 teclas: (código, 0, 0, 0)
        local -a teclas=()
        if [[ "$atalhos" != "none" ]]; then
            IFS=',' read -ra lista <<< "$atalhos"
            for atalho in "${lista[@]}"; do
                atalho="$(aparar "$atalho")"
                if ! codigo="$(codigo_tecla "$atalho")"; then
                    aviso "atalho não reconhecido, linha ignorada: $atalho ($componente / $acao)"
                    continue 2
                fi
                teclas+=(4 "$codigo" 0 0 0)
            done
        fi

        busctl --user call org.kde.kglobalaccel /kglobalaccel org.kde.KGlobalAccel \
            setForeignShortcutKeys 'asa(ai)' 4 "$componente" "$acao" "" "" \
            $((${#teclas[@]} / 5)) "${teclas[@]}"
        ok "$componente / $acao: $atalhos"
    done < "$REPO_DIR/kde/atalhos.conf"
}

# ---------- Principal ----------

main() {
    local pacotes=false tema=false aparencia=false konsole=false layout=false atalhos=false
    local -a argumentos=("$@")

    if (($# == 0)); then
        pacotes=true; tema=true; aparencia=true; konsole=true; layout=true; atalhos=true
    fi

    while (($#)); do
        case "$1" in
            --pacotes)   pacotes=true ;;
            --tema)      tema=true ;;
            --aparencia) aparencia=true ;;
            --konsole)   konsole=true ;;
            --layout)    layout=true ;;
            --atalhos)   atalhos=true ;;
            -h|--ajuda|--help) uso; exit 0 ;;
            *) erro "opção desconhecida: $1"; uso; exit 1 ;;
        esac
        shift
    done

    verificar_dependencias
    $pacotes && exigir_terminal "${argumentos[@]}"

    # Pacotes primeiro: o tema de ícones precisa estar instalado para a aparência
    $pacotes   && instalar_pacotes
    $tema      && instalar_tema
    $aparencia && aplicar_aparencia
    $konsole   && instalar_konsole
    $layout    && aplicar_layout
    $atalhos   && aplicar_atalhos

    echo
    if [[ -d "$BACKUP_DIR" ]]; then
        info "Concluído. Backup dos arquivos substituídos em: $BACKUP_DIR"
    else
        info "Concluído. Nenhum arquivo precisou de backup."
    fi
}

main "$@"
