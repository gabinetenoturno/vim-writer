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

O atalho "Escrita" abre o Neovide com o dashboard de boas-vindas. Na tela inicial:

- `1` a `5` — abre um dos arquivos recentes listados
- `<Space>e` — abre o NERDTree para navegar pelos projetos (fecha o dashboard automaticamente)
- `<Space>f` — busca fuzzy por nome de arquivo

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
| Normal  | Tab         | navegar, copiar, salvar   |
| Insert  | i           | digitar texto             |
| Visual  | v           | selecionar texto          |

Regra de ouro: pressione **Tab** sempre que quiser parar de digitar (Tab e Esc estão trocados nesta configuração).

---

## Editar texto

```
i     → Insert antes do cursor
a     → Insert após o cursor
o     → nova linha abaixo + Insert
Tab   → volta para Normal  (Esc físico insere tab)
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

A largura do Goyo persiste entre sessões. Para alterar:

```
:Goyo 80   → redefine a largura para 80 colunas (funciona com o Goyo aberto ou fechado)
```

O valor é salvo automaticamente e usado na próxima vez que `<Space>w` for pressionado.

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

## Limpeza automática de espaços

Ao sair do modo inserção, o editor remove automaticamente espaços extras em todo o buffer: espaços duplos (ou mais) entre palavras são colapsados em um único espaço, e espaços no final das linhas são apagados.

```
:Sw   → liga/desliga a limpeza automática de espaços
```

O comportamento vem habilitado por padrão.

---

## Sessão de foco

Inicia um countdown no canto inferior esquerdo. Ao fim do tempo, uma notificação do KDE exibe as estatísticas e o Neovim abre um popup para confirmar o registro.

```
:Sn 25   → inicia sessão de 25 minutos
:Sn      → padrão de 15 minutos
:Sn      → enquanto ativo: cancela a sessão
:Sd      → mostra o total de palavras salvas hoje
```

Ao fim da sessão, o popup exibe:

- **Total de palavras do dia** (sessões salvas + sessão atual) em negrito
- Tempo, palavras escritas e média por minuto da sessão
- Prompt `[y] sim / [n] não` para salvar no histórico

As estatísticas são salvas em `~/WriteDir/sessoes.csv` (entrada mais recente no topo):

```
data,hora,minutos,palavras,ppm,documento
2026-05-09,14:32,25,612,24,"/home/pin/WriteDir/romance/cap01.md"
```

Se estiver digitando quando o tempo esgotar, o popup aparece ao sair do Insert — as palavras extras não são contabilizadas.

---

## Navegar para outro arquivo

```
<Space>e   → abre/fecha o explorador de arquivos (NERDTree)
<Space>f   → busca fuzzy por nome (Telescope)
:e caminho → abre arquivo pelo caminho
```

No NERDTree: `j`/`k` navegam entre arquivos, Enter abre e fecha o explorador automaticamente. Ao navegar, o conteúdo do arquivo selecionado aparece na janela ao lado após 250ms (preview automático).

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
<Space>F   → liga/desliga tela cheia (também: F11)
<Space>r   → liga/desliga modo leitura (highlights de revisão)
<Space>s   → liga/desliga correção ortográfica
<Space>x   → exporta arquivo atual para PDF (requer xelatex)
<Space>n   → abre o wiki de notas
<Space>/   → busca texto dentro do manuscrito (ripgrep)
]s / [s    → navega entre erros ortográficos
zg         → adiciona palavra ao dicionário pessoal
zw         → marca palavra como errada
L          → vai para o fim da linha (equivale a $)
```

---

## Exportar livro completo para PDF

O comando `:ExportBook` exporta toda a pasta `Draft/` do projeto para um PDF polido em `~/WriteDir/exportado/`.

Se houver mais de um perfil em `export-settings/`, um menu numerado é exibido:

```
Perfil de exportação:
1. settings (padrão)
2. home-print
```

Digite o número e pressione Enter. Se só existir o perfil padrão, exporta direto sem perguntar.

O script sobe a árvore de diretórios a partir do arquivo aberto até encontrar uma pasta `Draft/`.

### Perfis de exportação

As configurações ficam em `~/DevDir/vim-writer/export-settings/`. Cada arquivo `.toml` é um perfil.

```
export-settings/
├── settings.default.toml  ← referência, nunca editar
├── settings.toml          ← perfil padrão (editável)
└── home-print.toml        ← perfil alternativo (exemplo: A4 para impressão doméstica)
```

Para criar um novo perfil: copie `settings.toml` e renomeie.

```bash
cp export-settings/settings.toml export-settings/fancy.toml
```

Para restaurar o padrão após edições acidentais:

```bash
cp export-settings/settings.default.toml export-settings/settings.toml
```

### Opções do arquivo de configuração

```toml
[font]
family      = "Whitman"          # nome da fonte
path        = "/usr/local/share/fonts/w/"
upright     = "Whitman_RomanOsF"
italic      = "Whitman_ItalicOsF"
bold        = "Whitman_BoldOsF"
bold_italic = "Whitman_ItalicOsF"
extension   = ".ttf"
size_pt     = 13                 # tamanho do corpo em pt
leading_pt  = 16.9               # entrelinha (1.3× o tamanho é referência)

[page]
width_cm         = 16            # largura do papel (A4 = 21)
height_cm        = 23            # altura do papel  (A4 = 29.7)
margin_top_cm    = 1.5
margin_bottom_cm = 1.5
margin_inner_cm  = 2.0           # margem da lombada
margin_outer_cm  = 1.5

[content]
include_front_matter = true      # false → só os contos, sem capa/sumário
language             = "pt-BR"
paragraph_indent_cm  = 1.0
toc_depth            = 0         # 0 = só capítulos, 1 = capítulos + subcapítulos
```

### Estrutura esperada de `Draft/`

```
Draft/
├── Front-matter/          ← dir sem número inicial: páginas pré-textuais
│   ├── 1a - Folha de Rosto.md   → folha de rosto (centralizada, com data)
│   ├── 1b - Dados.md            → verso da folha de rosto (pág. 2, alinhada à esquerda)
│   ├── 2 - Sumario.md           → sumário gerado automaticamente
│   └── 3 - Agradecimentos.md   → qualquer outra página pré-textual (centralizada)
└── 1 - Nome do Conto/     ← dir com número inicial: capítulo/conto
    ├── 01 - cena.md
    └── 02 - cena.md
```

Convenção de sufixos nos arquivos de `Front-matter/`:
- `Xa` → página ímpar (a folha de rosto deve ser sempre o primeiro `a`)
- `Xb` → página par — sempre o verso (página 2 quando seguir a folha de rosto)
- `X`  → página ímpar (cleardoublepage)

A numeração de páginas começa invisível desde a folha de rosto (página 1) e só aparece impressa a partir do primeiro capítulo, mostrando o número real da página física.

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
Tab             → volta ao Normal
:w              → salva
<Space>w        → desliga modo foco

<Space>f        → busca outro arquivo
"capitulo-02"   → digita para filtrar
Enter           → abre

i               → escreve no novo arquivo
Tab
:wq             → salva e fecha
```
