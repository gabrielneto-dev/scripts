# Mint Media Focus

Instalar: `bash install.sh`

Configure em Configurações do Sistema > Teclado > Atalhos > Atalhos personalizados:

- Ctrl + ]: `/home/SEU_USUARIO/.local/bin/mint-media-focus play-pause`
- Próxima: `/home/SEU_USUARIO/.local/bin/mint-media-focus next`
- Anterior: `/home/SEU_USUARIO/.local/bin/mint-media-focus previous`

Teste: `~/.local/bin/mint-media-focus status`

Logs: `journalctl --user -u mint-media-focus -f`

Desinstalar: `bash uninstall.sh` e remover atalhos.

## Lógica

- Um player que inicia a reprodução ou muda de Playing para Paused/Stopped recebe prioridade.
- O player pausado retém a prioridade por até 300 segundos.
- Se após esse período houver outro player em Playing, ele assume.
- Se não houver, mantém o último foco.
- O comando de teclado também reforça o foco selecionado.

## Limitações

- Detecta mudanças de estado MPRIS, não cliques que não alteram o estado.
- O polling de ~0,7 s pode não capturar estados transitórios muito curtos.
- Alguns navegadores agregam várias abas em um player; a seleção por aba depende da implementação MPRIS do navegador.
- Quando um player estava pausado e é reiniciado, o comando é enviado ao serviço MPRIS correspondente.
- Não altera nem captura fluxos de áudio PipeWire/PulseAudio; somente controla aplicativos com MPRIS.
