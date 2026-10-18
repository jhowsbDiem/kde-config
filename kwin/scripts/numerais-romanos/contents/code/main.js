// Nomeia cada área de trabalho com o numeral romano da sua posição (I, II, III...).
// Só renomeia áreas com o nome padrão do KDE ou que já sejam um numeral romano,
// para não sobrescrever nomes escolhidos pelo usuário.

function romano(n) {
    const tabela = [[1000, "M"], [900, "CM"], [500, "D"], [400, "CD"], [100, "C"], [90, "XC"],
                    [50, "L"], [40, "XL"], [10, "X"], [9, "IX"], [5, "V"], [4, "IV"], [1, "I"]];
    let s = "";
    for (const [valor, letras] of tabela) {
        while (n >= valor) { s += letras; n -= valor; }
    }
    return s;
}

// "Área de trabalho 4", "Desktop 4" (nome padrão) ou um numeral romano
const nomeAutomatico = /^((Área de trabalho|Desktop) \d+|[IVXLCDM]+)$/;

function renomear() {
    workspace.desktops.forEach(function (area, i) {
        const nome = romano(i + 1);
        if (area.name !== nome && nomeAutomatico.test(area.name)) {
            area.name = nome;
        }
    });
}

workspace.desktopsChanged.connect(renomear);
renomear();
