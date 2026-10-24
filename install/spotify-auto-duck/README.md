# Spotify Auto Duck — Linux Mint / Ubuntu

Sistema independente do Mint Media Focus. Diminui **somente o volume do fluxo do Spotify** quando outro aplicativo é identificado como reproduzindo áudio e restaura os valores originais dos canais quando o outro fluxo termina. Spotify em 70% → 30% → 70%, por exemplo. Não altera volume geral nem volume do YouTube.

## Instalação

1. Extraia o ZIP em Downloads e abra um terminal:

```bash
cd ~/Downloads
unzip -o spotify-auto-duck.zip
cd spotify-auto-duck
bash install.sh
```

2. Inicia automaticamente após o login do usuário via systemd.

## Configurar

```bash
spotify-auto-duck set volume 30  # volume do Spotify durante outro áudio
spotify-auto-duck set volume 20  # outro exemplo
spotify-auto-duck set delay 2    # segundos para aguardar ao terminar outro áudio
spotify-auto-duck status         # volume salvo / fluxos identificados
spotify-auto-duck list           # diagnóstico dos fluxos
```

Configuração editável: `~/.config/spotify-auto-duck/config.json`. Mudanças são lidas a cada ciclo (até ~0,5 s). `duck_volume` é o volume **absoluto** do Spotify durante ducking, não uma redução proporcional. `release_delay_seconds` evita flutuação ao trocar de vídeos. O volume original é salvo por fluxo e por canal, e recuperado quando não há outros fluxos ativos.

## Comandos úteis

```bash
systemctl --user status spotify-auto-duck --no-pager
systemctl --user is-enabled spotify-auto-duck
journalctl --user -u spotify-auto-duck -f
systemctl --user restart spotify-auto-duck
systemctl --user stop spotify-auto-duck   # restaura volume normalmente
bash uninstall.sh
```

## Limitações importantes

- **Detecção aproximada de áudio:** a versão 1 utiliza fluxos `sink-inputs` do PulseAudio/PipeWire e os estados `corked` e `mute`. Alguns navegadores mantêm o fluxo como ativo mesmo com o vídeo pausado/silencioso; nesse caso o Spotify pode continuar reduzido até o navegador liberar o fluxo. Isso também pode acontecer com WhatsApp Web. A identificação de áudio efetivamente audível exige monitoramento de sinal/integração mais profunda e deverá ser validada no computador.
- A versão 1 reconhece o Spotify **desktop** pelo campo `application.name` ou binário, não Spotify Web tocando dentro do navegador.
- Outros aplicativos com fluxos ativos também disparam a redução, inclusive notificações do sistema. Ajuste `ignore_apps` se quiser excluir aplicativos (veja `spotify-auto-duck list`).
- Se você alterar manualmente o volume do Spotify *enquanto estiver reduzido*, o programa reaplica o volume configurado e depois restaura o valor original anterior, não o ajuste feito durante a redução.
- Não misture dois sistemas diferentes que alterem simultaneamente o volume individual do Spotify.
- Em caso de desligamento abrupto, o volume original por fluxo é salvo temporariamente para tentar restaurar no próximo início; um fluxo recriado receberá novo identificador e poderá não ser restaurável.

## Desinstalar

Dentro da pasta extraída: `bash uninstall.sh`. As preferências permanecem em `~/.config/spotify-auto-duck` para facilitar reinstalação.
