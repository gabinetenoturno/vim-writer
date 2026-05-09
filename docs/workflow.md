# Workflow básico — Neovim para escrita

## Diretório padrão

Todos os projetos ficam em `~/WriteDir/`. Cada projeto é uma pasta:

```
~/WriteDir/
├── the-notebook/     → contos, rascunhos avulsos
├── romance-titulo/   → capítulos de um romance
├── notas/            → wiki global de worldbuilding
└── ...
```

## Abrir pelo atalho do KDE

O atalho "Escrita" no KDE já abre o Neovide dentro de `~/WriteDir/`.
Use `<Space>e` ou `<Space>f` para navegar até o projeto desejado.

## Abrir no terminal

```
cd ~/WriteDir
neovide .
```

Ou um arquivo específico:
```
neovide ~/WriteDir/the-notebook/conto.md
```

Navegue com j/k, entre em pastas com Enter, abra arquivo com Enter.

---

## Modos — a ideia central do Vim

| Modo    | Como entrar | Para quê                  |
|---------|-------------|---------------------------|
| Normal  | Esc         | navegar, copiar, salvar   |
| Insert  | i           | digitar texto             |
| Visual  | v           | selecionar texto          |

Regra de ouro: pressione Esc sempre que quiser parar de digitar.

---

## Editar texto

```
i     → Insert antes do cursor
a     → Insert após o cursor
o     → nova linha abaixo + Insert
Esc   → volta para Normal
```

j/k movem por linha visual (funciona corretamente com texto corrido).

---

## Salvar e sair

Sempre em modo Normal (Esc antes):

```
:w    → salva
:q    → fecha (sem mudanças pendentes)
:wq   → salva e fecha
:q!   → fecha sem salvar
```

---

## Modo foco

```
<Space>w   → liga (Goyo + Limelight + correção ortográfica)
<Space>w   → desliga
```

---

## Modo leitura

Ativa highlights visuais para revisão de prosa: diálogos (—), itálicos (*), comentários de revisão ([]), discurso direto com aspas.

```
<Space>r   → liga/desliga modo leitura
```

Cores por tipo de marcação:

| Padrão | Exemplo | Cor |
|--------|---------|-----|
| Linha de diálogo | `— Ela disse...` | azul |
| Diálogo curto inline | `—assim—` | azul itálico |
| Itálico | `*palavra*` | roxo itálico |
| Comentário de revisão | `[verificar]` | cinza |
| Discurso direto | `"assim"` ou `"assim"` | âmbar |

---

## Navegar para outro arquivo

```
<Space>e   → explorador de arquivos (netrw)
<Space>f   → busca fuzzy por nome (Telescope)
:e caminho → abre arquivo pelo caminho
```

Dentro do netrw: j/k para mover, Enter para abrir, - para subir um nível.

---

## Navegar entre arquivos abertos (buffers)

```
<Space>b   → lista buffers abertos
:bn        → próximo buffer
:bp        → buffer anterior
:bd        → fecha buffer atual
```

---

## Outros atalhos úteis

```
<Space>r   → liga/desliga modo leitura (highlights de revisão)
<Space>s   → liga/desliga correção ortográfica
<Space>x   → exporta arquivo atual para PDF (requer xelatex)
<Space>n   → abre o wiki de notas
<Space>/   → busca texto dentro do manuscrito (ripgrep)
]s / [s    → navega entre erros ortográficos
zg         → adiciona palavra ao dicionário pessoal
zw         → marca palavra como errada
```

---

## Sessão completa de exemplo

```
# Abrir pelo atalho KDE "Escrita" — já entra em ~/WriteDir/

<Space>f        → busca arquivo (Telescope)
"conto"         → digita para filtrar
Enter           → abre

<Space>w        → liga modo foco
i               → começa a escrever
...texto...
Esc             → volta ao Normal
:w              → salva
<Space>w        → desliga modo foco

<Space>f        → busca outro arquivo
"capitulo-02"   → digita para filtrar
Enter           → abre

i               → escreve no novo arquivo
Esc
:wq             → salva e fecha
```
