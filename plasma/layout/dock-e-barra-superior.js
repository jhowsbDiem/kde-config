// Layout dos painéis do Plasma: dock inferior só com os apps + barra superior fina.
//
// Script da API de scripts do Plasma. Pode ser executado mais de uma vez:
// reaproveita os painéis existentes em vez de criar duplicados.
//
// Como rodar:
//   qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$(cat plasma/layout/dock-e-barra-superior.js)"

var TELA_PRINCIPAL = 0;

// Widgets que ficam na barra de cima, da esquerda para a direita
var WIDGETS_BARRA = [
    "org.kde.plasma.kickoff",       // menu de aplicativos
    "org.kde.plasma.pager",         // áreas de trabalho
    "org.kde.plasma.panelspacer",   // espaço elástico
    "org.kde.plasma.systemtray",    // bandeja do sistema
    "org.kde.plasma.digitalclock",  // relógio
    "org.kde.plasma.showdesktop"    // mostrar área de trabalho
];

// Único widget que permanece no dock
var WIDGET_DOCK = "org.kde.plasma.icontasks";

function procurarPainel(posicao) {
    var todos = panels();
    for (var i = 0; i < todos.length; i++) {
        if (todos[i].location == posicao && todos[i].screen == TELA_PRINCIPAL) {
            return todos[i];
        }
    }
    return null;
}

// ---------- Dock (painel de baixo) ----------
var dock = procurarPainel("bottom");
if (dock == null) {
    dock = new Panel;
    dock.location = "bottom";
}

var temTarefas = false;
dock.widgets().forEach(function (w) {
    if (w.type == WIDGET_DOCK) {
        temTarefas = true;
    } else {
        w.remove();
    }
});
if (!temTarefas) {
    dock.addWidget(WIDGET_DOCK);
}

dock.lengthMode = "fit";         // largura do tamanho do conteúdo
dock.alignment = "center";       // centralizado
dock.floating = true;            // afastado da borda, cantos arredondados
dock.height = 54;
dock.hiding = "autohide";        // oculta até o mouse encostar na borda
dock.opacity = "translucent";

// ---------- Barra de cima ----------
var barra = procurarPainel("top");
if (barra == null) {
    barra = new Panel;
    barra.screen = TELA_PRINCIPAL;
    barra.location = "top";
    WIDGETS_BARRA.forEach(function (tipo) {
        barra.addWidget(tipo);
    });
}

barra.lengthMode = "fill";       // de ponta a ponta
barra.floating = false;          // colada na borda
barra.height = 28;
barra.hiding = "none";           // sempre visível
barra.opacity = "translucent";

print("Dock: painel " + dock.id + " | Barra superior: painel " + barra.id + "\n");
