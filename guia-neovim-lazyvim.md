# Guia rapido do seu Neovim com LazyVim

Este guia explica como usar a configuracao atual do seu Neovim. Ele foi escrito para uso diario, sem assumir que voce ja conhece terminal ou Neovim.

## Ideia principal

O Neovim tem modos. Os mais importantes sao:

- `Normal`: modo de comando. Use para navegar, abrir arquivos, buscar, salvar e executar atalhos.
- `Insert`: modo de escrita. Use para digitar texto no arquivo.
- `Terminal`: modo em que voce esta dentro de um terminal aberto no Neovim.

Para entrar no modo de escrita, aperte `i`.

Para voltar ao modo normal, aperte `Esc`.

No terminal, aperte `Esc Esc` para sair do modo terminal e voltar ao modo normal.

## Tecla leader

Quando este guia falar em `<leader>`, leia como `Espaco`.

Exemplo: `<leader>e` significa apertar `Espaco` e depois `e`.

## Abrir e navegar por arquivos

- `<leader>e`: abre o explorador de arquivos na raiz do projeto.
- `<leader>E`: abre o explorador na pasta atual.
- `<leader><space>`: busca arquivos do projeto pelo nome.
- `<leader>ff`: busca arquivos do projeto.
- `<leader>fd`: busca arquivos incluindo ocultos e ignorados pelo `.gitignore`.
- `<leader>sg`: busca texto dentro dos arquivos do projeto.
- `<leader>fw`: busca a palavra onde o cursor esta no projeto.

No explorador:

- `Enter` ou `l`: abre arquivo ou pasta.
- `h`: fecha uma pasta.
- `a`: cria arquivo ou pasta.
- `d`: apaga.
- `r`: renomeia.
- `c`: copia.
- `m`: move.
- `p`: cola.
- `H`: mostra ou esconde arquivos ocultos.
- `I`: mostra ou esconde arquivos ignorados pelo `.gitignore`.

## Salvar arquivos

O auto-save esta ativo.

Mesmo assim, voce pode salvar manualmente com:

- `Ctrl+s`: salva o arquivo atual.

## Terminal dentro do Neovim

- `<leader>tt`: abre terminal flutuante.
- `<leader>tH`: abre terminal horizontal embaixo.
- `<leader>tV`: abre terminal vertical na direita.
- `Ctrl+/`: abre ou foca o terminal padrao do LazyVim.
- `Esc Esc`: sai do modo terminal.

Navegacao entre terminal e janelas:

- `Ctrl+h`: vai para a janela da esquerda.
- `Ctrl+l`: vai para a janela da direita.
- `Ctrl+j`: vai para a janela de baixo.
- `Ctrl+k`: vai para a janela de cima.

Comandos basicos de terminal:

- `pwd`: mostra a pasta atual.
- `ls`: lista arquivos da pasta.
- `cd nome-da-pasta`: entra em uma pasta.
- `cd ..`: volta uma pasta.
- `npm install`: instala dependencias de projeto JavaScript/Node.
- `npm run dev`: inicia muitos projetos web.
- `clear`: limpa a tela do terminal.

## Janelas, abas e buffers

Uma janela e uma divisao visual da tela.

Um buffer e um arquivo aberto na memoria.

Uma aba e um conjunto de janelas.

Janelas:

- `<leader>sv`: cria split vertical.
- `<leader>sh`: cria split horizontal.
- `<leader>wc`: fecha a janela atual.
- `<leader>wo`: mantem somente a janela atual.
- `Ctrl+h/j/k/l`: navega entre janelas.

Buffers:

- `]b`: proximo buffer.
- `[b`: buffer anterior.
- `<leader>bd`: fecha o buffer atual.
- `<leader>bo`: fecha outros buffers.
- `<leader>bn`: cria um buffer novo.

Abas:

- `<leader>tn`: nova aba.
- `<leader>tc`: fecha aba atual.
- `<leader>tl`: proxima aba.
- `<leader>th`: aba anterior.
- `]t`: proxima aba.
- `[t`: aba anterior.

## Codigo e LSP

LSP e o recurso que entende o codigo. Ele permite ir para definicoes, renomear variaveis, ver erros e aplicar correcoes.

Atalhos uteis:

- `gd`: ir para definicao.
- `gr`: ver referencias.
- `K`: mostrar documentacao.
- `<leader>rn`: renomear simbolo.
- `<leader>ca`: mostrar acoes de codigo.
- `<leader>lf`: formatar codigo.
- `<leader>le`: mostrar erro da linha atual.
- `<leader>ld`: abrir lista de erros do projeto.
- `]e`: proximo erro.
- `[e`: erro anterior.

## Git

Git e o sistema que controla alteracoes do projeto.

Atalhos uteis:

- `<leader>gg`: abre LazyGit, uma interface visual para Git.
- `<leader>gp`: mostra a alteracao da linha/bloco atual.
- `<leader>gs`: adiciona a alteracao atual ao stage.
- `<leader>gr`: desfaz a alteracao atual.
- `<leader>gb`: mostra quem alterou a linha atual.

Se voce ainda nao conhece Git, use `<leader>gg` com cuidado. Ele e poderoso e pode alterar o estado do projeto.

## Fluxo diario recomendado

1. Abra o Neovim na pasta do projeto.
2. Use `<leader>e` para ver os arquivos.
3. Use `<leader><space>` para abrir arquivos pelo nome.
4. Aperte `i` para editar.
5. Aperte `Esc` para voltar ao modo normal.
6. Use `<leader>sg` para procurar texto no projeto.
7. Use `<leader>tt` para abrir terminal quando precisar rodar comandos.
8. Use `Esc Esc` para sair do terminal.
9. Use `<leader>ld` para ver erros.
10. Use `<leader>lf` para formatar o arquivo.

## Quando travar

- Se estiver digitando comandos sem querer, aperte `Esc`.
- Se estiver preso no terminal, aperte `Esc Esc`.
- Se abriu uma tela e nao sabe sair, tente `q`.
- Se quer salvar, use `Ctrl+s`.
- Se quer fechar um buffer, use `<leader>bd`.
- Se quer ver atalhos possiveis, aperte `Espaco` e espere o menu aparecer.

## Configuracoes feitas

- Foi mantido apenas um explorador de arquivos: Snacks Explorer.
- Arquivos ocultos e ignorados pelo `.gitignore` aparecem no explorer e nas buscas.
- O autosave duplicado foi removido; ficou apenas `auto-save.nvim`.
- O extra de VSCode foi removido, pois nao e necessario para Neovim normal.
- Foram adicionados atalhos para terminal, busca, LSP, diagnosticos e Git.
