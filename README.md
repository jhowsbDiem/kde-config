# cachyos-kde-config

Personalizações visuais do KDE Plasma 6 para o CachyOS: tema de painéis em vidro azulado, terminal translúcido e layout com dock e barra superior. Um único script instala tudo em uma nova máquina.

## O que está incluído

| Componente | Descrição |
|---|---|
| **Tema do Plasma "Vidro Azul"** | Baseado no Breeze Escuro. Painéis translúcidos (opacidade de 40%) em azul-marinho, com o desfoque do KWin aparecendo por trás. Menus e dicas do Plasma seguem as mesmas cores. |
| **Konsole "Vidro Azul"** | Esquema de cores com fundo azul-marinho, 75% de opacidade e desfoque. Definido como perfil padrão. |
| **Layout dos painéis** | Dock inferior só com os aplicativos, centralizado, flutuante e com ocultação automática. Barra superior fina com menu de aplicativos, áreas de trabalho, bandeja, relógio e mostrar área de trabalho. |

## Requisitos

- KDE Plasma 6 (testado no 6.7, sessão Wayland)
- Efeito **Borrar** do KWin ativado (vem ativado por padrão)
- Comandos `kwriteconfig6`, `qdbus6` e `plasma-apply-desktoptheme`, que já fazem parte do Plasma

Nenhum pacote extra é necessário.

## Instalação

```bash
git clone <url-do-repositório> cachyos-kde-config
cd cachyos-kde-config
./install.sh
```

Ou, sem git: copie a pasta do projeto para a máquina e rode `./install.sh` de dentro dela.

Para instalar apenas uma parte:

```bash
./install.sh --tema      # só o tema do Plasma
./install.sh --konsole   # só o perfil do Konsole
./install.sh --layout    # só o layout dos painéis
./install.sh --ajuda     # lista as opções
```

As opções podem ser combinadas, por exemplo `./install.sh --tema --konsole`.

Depois da instalação, feche e abra o Konsole para ele carregar o novo perfil.

## Backup e como desfazer

Antes de substituir qualquer arquivo, o instalador faz uma cópia em:

```
~/.local/state/cachyos-kde-config/backup-AAAAMMDD-HHMMSS/
```

A pasta de backup mantém os caminhos relativos ao `$HOME`. Para desfazer:

**Tema:**

```bash
plasma-apply-desktoptheme breeze-dark
```

**Konsole** (volta ao perfil embutido):

```bash
kwriteconfig6 --file konsolerc --group "Desktop Entry" --key DefaultProfile --delete
```

**Layout dos painéis:** o Plasma mantém a configuração em memória, então é preciso pará-lo antes de restaurar os arquivos:

```bash
BACKUP=~/.local/state/cachyos-kde-config/backup-AAAAMMDD-HHMMSS   # ajuste a data
systemctl --user stop plasma-plasmashell
cp "$BACKUP/.config/plasma-org.kde.plasma.desktop-appletsrc" ~/.config/
cp "$BACKUP/.config/plasmashellrc" ~/.config/
systemctl --user start plasma-plasmashell
```

## Personalização

### Transparência dos painéis

O fundo do painel está em `plasma/desktoptheme/vidro-azul/translucent/widgets/panel-background.svgz`. O arquivo é um SVG compactado com gzip, então não pode ser editado diretamente em um editor de texto. Para gerar uma nova versão a partir do original do sistema (opacidade `0.85`):

```bash
zcat /usr/share/plasma/desktoptheme/default/translucent/widgets/panel-background.svgz \
  | sed 's/opacity:0.85/opacity:0.40/g' \
  | gzip > plasma/desktoptheme/vidro-azul/translucent/widgets/panel-background.svgz
./install.sh --tema
```

Valores menores deixam o painel mais transparente.

### Cores do tema

Edite as linhas `BackgroundNormal` e `BackgroundAlternate` em `plasma/desktoptheme/vidro-azul/colors`. Os valores estão no formato `vermelho,verde,azul` (0 a 255). Depois rode `./install.sh --tema`.

### Intensidade do desfoque

Configurações do Sistema → Gerenciamento de janelas → Efeitos da área de trabalho → **Borrar**. Ali ficam a intensidade do desfoque e o ruído.

### Konsole

Em `konsole/VidroAzul.colorscheme`:

- `Opacity`: de `0.0` (invisível) a `1.0` (opaco)
- `Blur`: `true` ou `false`
- `[Background]`: cor de fundo

Depois rode `./install.sh --konsole`.

### Layout dos painéis

Altura, ocultação e widgets de cada painel ficam em `plasma/layout/dock-e-barra-superior.js`, com comentários em cada opção. O script pode ser executado várias vezes: ele reaproveita os painéis existentes em vez de criar duplicados.

> Os widgets movidos para a barra superior são recriados. Configurações feitas neles antes (como o formato do relógio) voltam ao padrão.

## Estrutura

```
.
├── install.sh                          # instalador
├── konsole/
│   ├── VidroAzul.colorscheme           # cores, opacidade e desfoque do terminal
│   └── VidroAzul.profile               # perfil que usa o esquema acima
└── plasma/
    ├── desktoptheme/vidro-azul/        # tema do Plasma
    │   ├── metadata.json               # nome e descrição do tema
    │   ├── colors                      # paleta azul-marinho
    │   ├── plasmarc                    # efeitos do KWin usados pelo tema
    │   └── translucent/widgets/
    │       └── panel-background.svgz   # fundo translúcido dos painéis
    └── layout/
        └── dock-e-barra-superior.js    # script de layout dos painéis
```
