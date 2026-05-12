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
