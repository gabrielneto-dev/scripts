# Auditoria técnica e plano de testes — Migrador v1.3.0

## Alteração implementada

**Requisito:** cada pasta de backup deve funcionar de maneira independente, sem precisar de `migrador.sh` no Mint.

**Implementação:**

- `migrador.sh` agora cria `PopOS-AAAAMMDD-HHMMSS-HOST-ID/` e, dentro dela, **somente** `backup/`, `restaurar.sh`, `USO.md`.
- Arquivos originais e inventários anteriores continuam separados em seis diretórios sob `backup/`.
- O restaurador incorporado é gerado pelo script principal usando um *heredoc* literal; não depende de acesso ao código original e descobre seus dados com base na própria localização.
- A opção antiga **5 — extrair/restaurar** foi removida. Os autotestes Wi-Fi/Docker, antes opção 6, passaram a ocupar a opção **5**.
- **Sem menu de restauração:** `bash restaurar.sh` realiza verificações e a extração imediatamente, solicitando confirmação específica apenas antes de copiar arquivos novos para a Home.
- `--verificar` não escreve dados; `--somente-conferir` extrai os dados sem integrá-los.
- Arquivos existentes no Mint nunca são substituídos na etapa `rsync --ignore-existing`. Os caminhos existentes são listados em `CONFLITOS-HOME.txt` para revisão manual. Configurações COSMIC/dconf não são importadas.
- O relatório `ORIGEM.md` identifica máquina, data/hora, UID/GID, versão e identificador da execução.

## Plano de testes

| ID | Situação | Critério de aprovação | Resultado |
|---|---|---|---|
| T01 | Sintaxe de `migrador.sh` e do script gerado | `bash -n` sem erros | **Aprovado** |
| T02 | Geração de backup com caminho que contém espaços | Nova pasta criada corretamente | **Aprovado — ambiente isolado** |
| T03 | Estrutura portátil | Somente `backup/`, `restaurar.sh`, `USO.md` na raiz | **Aprovado** |
| T04 | Restaurador executado de pasta independente | Encontra `backup/` relativo ao script | **Aprovado** |
| T05 | Verificação sem extração | Nenhuma alteração na Home | **Aprovado** |
| T06 | Home com projetos e arquivos ocultos | Arquivos recuperados corretamente | **Aprovado** |
| T07 | Pasta adicional externa com espaço no nome | Extração separada e conteúdo preservado | **Aprovado** |
| T08 | Perfis Wi-Fi no arquivo de sistema | Extraídos somente para conferência | **Aprovado — dados fictícios** |
| T09 | Confirmação explícita de integração | Copia dados novos somente com `RESTAURAR` | **Aprovado** |
| T10 | Arquivos da Home que já existem no Mint | Originais mantidos | **Aprovado** |
| T11 | Configurações COSMIC/dconf | Não importadas automaticamente | **Aprovado** |
| T12 | SSH, shell e pastas com caracteres especiais | Arquivos e conteúdos restaurados | **Aprovado** |
| T13 | Corrupção de TAR após manifesto | Verificação falha e bloqueia restauração | **Aprovado** |
| T14 | Backup marcado INCOMPLETO | Restaurador bloqueia | **Aprovado** |
| T15 | Opção 4 do migrador com nova estrutura | Verifica `backup/checksums.sha256` | **Aprovado** |
| T16 | Script separado da pasta do backup | Não restaura dados sem seu `backup/` | **Aprovado** |
| T17 | Membro TAR contendo `../` | Extração impedida | **Aprovado** |
| T18 | Fluxo integrado de backup (com cópias simuladas) | Cria estrutura, manifesto e restaurador verificável | **Aprovado** |
| T19 | Docker Engine e volumes reais no equipamento de origem | Exportação de volume de teste e restauração | **Pendente no Pop!_OS real** |
| T20 | NetworkManager e Wi-Fi real no equipamento de origem | Perfis arquivados e extraídos sem alterar conexão | **Pendente no Pop!_OS real** |
| T21 | Linux Mint real e mídia externa NTFS/exFAT | Testar execução por Bash e caminhos montados | **Pendente** |
| T22 | Bancos ativos, Compose e volumes de produção | Dump consistente e recuperação de aplicação | **Fora da automação; requer teste específico** |
| T23 | Volume de dados muito grande / disco cheio | Estado parcial e diagnóstico visíveis | **Pendente com dados reais** |
| T24 | Falhas de sudo e caminhos sem acesso | Backup marcado INCOMPLETO, sem aprovar indevidamente | **Aprovado em testes anteriores/simulados; retestar no Pop!_OS** |

### Execuções automatizadas

- **24 de 24 verificações funcionais de restauração, bloqueios e geração de arquivos** passaram em diretórios temporários; incluem algumas verificações de estrutura repetidas para estados diferentes.
- **8 de 8 testes de integração anteriores de Wi-Fi fictício e Docker simulado** passaram novamente.
- **1 fluxo integrado de `backup()`** passou com implementação de cópia/inventário substituída por dados fictícios, em destino com espaços no caminho. Gerou manifesto válido e script funcional.
- O serviço Docker e o NetworkManager da instalação de origem **não estão acessíveis** neste ambiente. Nada aqui atesta a recuperação de suas credenciais reais ou de bancos/volumes de produção.

## Riscos remanescentes (obrigatório antes de formatar)

1. **Sem criptografia nativa:** SSH, tokens, Wi-Fi, histórico de ferramentas e credenciais podem estar nos TARs. Use HD criptografado e mantenha controle físico.
2. **Consistência:** uma cópia TAR de Home ou de um volume não substitui snapshots nem dumps consistentes de bancos. Aplicativos em execução podem alterar arquivos durante a cópia.
3. **Limite da restauração:** a Home é integrada apenas com arquivos ausentes. Itens globais, Docker, pacotes, idiomas/SDKs e atalhos COSMIC não são importados/reinstalados automaticamente, pois poderiam danificar a instalação Mint.
4. **Permissões e mídia:** sistemas FAT/exFAT não preservam proprietário/permissões Linux no diretório do ZIP e podem estar montados `noexec`. Os arquivos dentro dos TARs preservam metadados. Prefira `bash restaurar.sh`.
5. **Integridade vs abrangência:** `SUCESSO` significa que as operações solicitadas retornaram sucesso, não que cada arquivo do sistema foi descoberto. Verifique os relatórios e recupere dados representativos.
6. **Espaço no Mint:** a extração de conferência exige espaço para uma cópia adicional dos dados, antes da integração. Testar isso com dados reais ainda é necessário.
7. **Execução de código:** não execute um `restaurar.sh` vindo de fonte não confiável. O manifesto do backup não autentica o próprio restaurador.
8. **Dados perigosos:** arquivos especiais, caminhos anômalos e links simbólicos provenientes de backups intencionalmente maliciosos não devem ser considerados confiáveis. Esta ferramenta é destinada a **backups criados no próprio computador e mantidos sob controle do usuário**, não arquivos recebidos de terceiros.

## Aceite para a migração real

A formatação só deve ocorrer depois que: `STATUS.md` for conferido; `--verificar` e `--somente-conferir` funcionarem sobre o **backup real no HD**; projetos e chaves forem recuperados em amostra; redes/SSH forem conferidos; bancos de dados e containers forem tratados separadamente; e houver certeza de que o HD externo não será formatado.
