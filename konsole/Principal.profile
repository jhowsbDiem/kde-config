# Perfil principal do Konsole: fonte JetBrains Mono e cores do CLion/IntelliJ.
# A lista de opções disponíveis aparece com: konsole --list-profile-properties

[Appearance]
ColorScheme=IslandsDark
# Variante "Mono" da Nerd Font: os ícones ocupam a largura de um caractere
Font=JetBrainsMono Nerd Font Mono,12
# Modo palavra: agrupa sequências como -> e != antes de desenhar, para a
# fonte formar as ligaduras (já é o padrão do Konsole 26; fica explícito aqui)
WordMode=true
WordModeCoding=true

[General]
Name=Principal
Parent=FALLBACK/
# Espaço, em pixels, entre o texto e a borda da janela
TerminalMargin=8

[Interaction Options]
# Copia texto puro, sem formatação HTML e sem espaços sobrando no fim das linhas
CopyTextAsHTML=false
TrimTrailingSpacesInSelectedText=true
# Ctrl+clique em um caminho de arquivo (ex.: main.c:42) abre no VS Code na linha.
# TextEditorCmd=6 é o "comando personalizado" definido na linha seguinte.
UnderlineFilesEnabled=true
TextEditorCmd=6
TextEditorCmdCustom=code --goto PATH:LINE:COLUMN

[Scrolling]
# Histórico com tamanho fixo de 10.000 linhas (o padrão é 1.000)
HistoryMode=1
HistorySize=10000
