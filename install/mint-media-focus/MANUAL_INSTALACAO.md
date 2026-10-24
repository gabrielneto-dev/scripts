# Manual de instalação — Mint Media Focus

**Versão:** 1.0 (experimental)  
**Ambiente recomendado:** Linux Mint 22.x com Cinnamon.  
**Outros sistemas:** Ubuntu, Pop!_OS e derivados podem funcionar, mas os menus de atalhos e as dependências devem ser verificados.

## 1. O que o programa faz

O Mint Media Focus controla players compatíveis com MPRIS (por exemplo, Spotify e a sessão de mídia do navegador). O último player que **começa a tocar ou muda seu estado para pausado/parado** ganha a prioridade. Se o player prioritário permanecer pausado por **5 minutos** e outro estiver tocando, o foco passa para o player ativo. Sem outro player ativo, o foco permanece no último utilizado.

**Importante:** o sistema observa mudanças de estado, não todos os cliques do mouse. A detecção é feita aproximadamente a cada 0,7 segundo e alguns navegadores expõem várias abas como um único player.

## 2. Requisitos

- Sessão gráfica Linux com D-Bus de usuário e `systemd --user`.
- Gerenciador de pacotes `apt` (para o instalador incluído).
- Internet para instalar as dependências `playerctl` e `python3`.
- Spotify/navegador habilitado a expor controles MPRIS.

O instalador solicita senha de administrador **somente para instalar pacotes via apt**. O serviço roda na sessão do usuário, sem `sudo`.

## 3. Instalação

1. Baixe o arquivo `mint-media-focus.zip` e salve-o na pasta `Downloads`.
2. Abra o terminal e execute:

```bash
cd ~/Downloads
sudo apt update && sudo apt install -y unzip
unzip -o mint-media-focus.zip
cd mint-media-focus
bash install.sh
```

O script instala as dependências, copia o programa para `~/.local/bin/mint-media-focus`, cria a unidade `~/.config/systemd/user/mint-media-focus.service` e a habilita para iniciar quando você entra na sessão.

**Não execute `sudo bash install.sh`:** o instalador deve rodar como seu usuário normal.

## 4. Configurar os atalhos no Linux Mint Cinnamon

Abra **Configurações do Sistema → Teclado → Atalhos → Atalhos personalizados**. Adicione três atalhos personalizados, um para cada comando abaixo.

| Nome | Comando | Tecla sugerida |
|---|---|---|
| Media Focus — Reproduzir/Pausar | `/home/SEU_USUARIO/.local/bin/mint-media-focus play-pause` | `Ctrl + ]` |
| Media Focus — Próxima faixa | `/home/SEU_USUARIO/.local/bin/mint-media-focus next` | `Ctrl + [` |
| Media Focus — Faixa anterior | `/home/SEU_USUARIO/.local/bin/mint-media-focus previous` | `Ctrl + ´` (se reconhecido pelo layout) |

Substitua `SEU_USUARIO` pelo nome da sua conta. Para descobrir o caminho correto, execute:

```bash
printf '%s\n' "$HOME/.local/bin/mint-media-focus"
```

**Exemplo para usuário `neto`:**

```text
/home/neto/.local/bin/mint-media-focus play-pause
/home/neto/.local/bin/mint-media-focus next
/home/neto/.local/bin/mint-media-focus previous
```

Os atalhos são sugestões: escolha combinações reconhecidas pelo seu teclado. Desative atalhos existentes que utilizem as mesmas teclas; um conflito pode causar disparos duplicados. Os comandos `next` e `previous` só funcionam quando o player fornece essas operações MPRIS.

## 5. Verificar a instalação

Cheque se o serviço está habilitado para iniciar automaticamente:

```bash
systemctl --user is-enabled mint-media-focus.service
```

**Esperado:** `enabled`.

Cheque se o serviço está funcionando agora:

```bash
systemctl --user is-active mint-media-focus.service
```

**Esperado:** `active`.

Cheque os players detectados e qual tem o foco:

```bash
~/.local/bin/mint-media-focus status
playerctl --list-all
```

O resultado do comando `status` é um objeto com `focus`, `timeout_seconds` (300) e `players`. Se `players` estiver vazio, abra Spotify ou YouTube e inicie um áudio para testar o MPRIS.

## 6. Testar as três ações

Com música/vídeo aberto em um player reconhecido:

```bash
~/.local/bin/mint-media-focus play-pause
~/.local/bin/mint-media-focus next
~/.local/bin/mint-media-focus previous
```

Teste também clicando nos botões dos aplicativos para mudar a prioridade. Para validar o temporizador, mantenha Spotify tocando, pause o YouTube (deixando-o como foco) e não interaja com o YouTube por 5 minutos. O foco deverá passar ao Spotify.

Para observar o estado a cada segundo:

```bash
watch -n 1 "$HOME/.local/bin/mint-media-focus status"
```

Saia do monitoramento com `Ctrl + C`.

## 7. Reiniciar, parar ou ativar novamente

```bash
# Reiniciar o serviço após alterações:
systemctl --user restart mint-media-focus.service

# Parar temporariamente:
systemctl --user stop mint-media-focus.service

# Iniciar manualmente:
systemctl --user start mint-media-focus.service

# Habilitar inicialização automática e iniciar imediatamente:
systemctl --user enable --now mint-media-focus.service
```

O serviço é iniciado **ao entrar na sessão do usuário**, não antes da tela de login.

## 8. Diagnóstico e erros comuns

### Serviço indisponível

```bash
systemctl --user status mint-media-focus.service --no-pager
journalctl --user -u mint-media-focus.service -n 80 --no-pager
```

### Nenhum player detectado

```bash
playerctl --list-all
playerctl -a status
```

Verifique se o áudio está sendo reproduzido no Spotify ou no navegador. Algumas configurações do navegador não disponibilizam MPRIS.

### Tecla não executa nada

Teste o comando diretamente no terminal. Se funcionar, revise o atalho no Cinnamon, confira o caminho completo e elimine conflitos com outros atalhos.

### Próxima/anterior não funcionam em algum vídeo

Isso depende do suporte do aplicativo a `Next` e `Previous`; nem toda sessão MPRIS permite avançar ou retroceder faixas.

## 9. Desinstalar

A partir da pasta extraída:

```bash
cd ~/Downloads/mint-media-focus
bash uninstall.sh
```

Remova também os três atalhos personalizados nas configurações do teclado. A desinstalação não modifica os aplicativos Spotify ou navegador.

## 10. Segurança e limitações

- O serviço roda como usuário normal e não necessita de root em execução.
- O programa se comunica com a sessão MPRIS local e não controla diretamente os fluxos PipeWire/PulseAudio.
- O recurso de foco baseado em pausa pode não capturar transições muito rápidas (menores que o intervalo de verificação).
- O comportamento pode variar entre browsers, aplicativos e ambientes Wayland/X11.
- Esta é uma implementação inicial; antes de distribuir como ferramenta universal, convém testar em outras distribuições e interfaces gráficas.
