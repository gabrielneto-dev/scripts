# Context Engineering — Universal Project Bootstrap Prompt

> **Uso:** execute este prompt uma única vez na raiz de um projeto novo ou existente.  
> Ele deve instalar uma arquitetura persistente de contexto, integrar as instruções globais do projeto e deixar o repositório preparado para que futuras sessões de agentes de IA recuperem apenas o contexto necessário, sem depender da conversa original.

---

# PAPEL

Você atuará como um **Senior Context Engineer / Knowledge Architect / Agent Memory Engineer**.

Sua função é projetar, instalar e validar uma infraestrutura de contexto persistente para este projeto.

Você não está apenas criando documentação.

Você está construindo a **memória operacional do projeto**, de forma que diferentes agentes de IA — Codex, Claude Code ou outros agentes com acesso aos arquivos do projeto — consigam:

1. entender o que é o projeto;
2. saber onde encontrar cada tipo de informação;
3. recuperar contexto seletivamente;
4. entender decisões anteriores e seus motivos;
5. identificar fatos, hipóteses, perguntas, pesquisas, riscos e planos;
6. saber o estado atual do projeto;
7. preservar aprendizados importantes entre sessões;
8. evitar repetir investigações ou erros já resolvidos;
9. registrar novo conhecimento de forma estruturada;
10. continuar o trabalho mesmo depois que a sessão anterior for apagada.

A arquitetura deve funcionar para **qualquer tipo de projeto**, incluindo, sem se limitar a:

- desenvolvimento de software;
- infraestrutura;
- pesquisa;
- produto;
- negócio;
- automação;
- telecom;
- estudos;
- fitness;
- planejamento pessoal;
- experimentos;
- documentação técnica;
- projetos criativos;
- análise;
- operações.

Adapte a taxonomia e as branches ao domínio real encontrado.

---

# 1. OBJETIVO PRINCIPAL

Transforme a raiz atual em um projeto com três camadas distintas:

```text
PROJECT ROOT
│
├── AGENTS.md              # contrato operacional compartilhado dos agentes
├── CLAUDE.md              # adaptador do Claude Code para AGENTS.md
│
├── Context/               # memória persistente e pesquisável do projeto
│   ├── README.md
│   ├── MAP.md
│   ├── STATE.md
│   ├── ...
│
└── arquivos normais do projeto
```

As responsabilidades devem ser separadas:

```text
AGENTS.md
= COMO os agentes devem trabalhar neste projeto.

CLAUDE.md
= ponte específica do Claude Code para as instruções compartilhadas.

Context/
= O QUE o projeto sabe, decidiu, descobriu, tentou, planeja e precisa lembrar.

Sessão atual
= memória de trabalho temporária.
```

Princípio obrigatório:

> **SESSION ≠ MEMORY**

A sessão pode desaparecer.

A continuidade intelectual do projeto deve permanecer nos arquivos.

---

# 2. REQUISITO DE REINICIALIZAÇÃO

Projete tudo assumindo:

```text
NEW SESSION = ZERO CONVERSATIONAL MEMORY
```

Depois da instalação, uma nova sessão que tenha apenas acesso aos arquivos do projeto deverá conseguir descobrir:

- o propósito do projeto;
- o estado atual;
- a arquitetura de contexto;
- como pesquisar contexto;
- quais branches existem;
- quais decisões estão ativas;
- quais perguntas continuam abertas;
- quais riscos existem;
- onde o projeto parou;
- quais próximos passos são conhecidos;
- como salvar novamente o contexto;
- quais regras permanentes o agente deve obedecer.

Não dependa de qualquer informação que exista somente na conversa que executou este bootstrap.

---

# 3. PRINCÍPIOS ARQUITETURAIS

Toda a implementação deve seguir estes princípios.

## 3.1 Progressive Context Loading

Nunca carregue toda a memória do projeto por padrão.

Utilize:

```text
L0 — orientação global
L1 — contexto da branch
L2 — registros atômicos
L3 — evidências/fontes
```

Fluxo:

```text
TAREFA
  ↓
MAP + STATE
  ↓
BRANCH RELEVANTE
  ↓
REGISTROS ESPECÍFICOS
  ↓
RELAÇÕES NECESSÁRIAS
  ↓
FONTES, SOMENTE SE NECESSÁRIO
```

O objetivo é:

```text
máxima informação relevante
───────────────────────────
mínimo contexto carregado
```

## 3.2 Atomicidade

Prefira unidades pequenas e especializadas de conhecimento.

Não crie documentos gigantes contendo assuntos independentes.

## 3.3 Descoberta

Toda informação persistida deve ser localizável por pelo menos alguns destes atributos:

- ID;
- tipo;
- branch;
- título;
- tags;
- status;
- palavras-chave;
- relações;
- origem;
- temporalidade.

## 3.4 Rastreabilidade

Quando relevante, deve ser possível entender:

- de onde a informação veio;
- quando surgiu;
- se foi validada;
- qual seu nível de confiança;
- quais decisões dependem dela.

## 3.5 Separação epistemológica

Nunca trate como equivalentes:

```text
Fact
Assumption
Question
Research
Decision
Plan
Risk
Note
Experiment
Source
```

Hipótese não é fato.

Pesquisa não é decisão.

Ideia futura não é plano aprovado.

## 3.6 Preservação histórica

Informações importantes que deixarem de valer devem ser marcadas como substituídas, obsoletas ou arquivadas.

Não destrua silenciosamente o histórico de decisões.

## 3.7 Persistência seletiva

Não transforme `Context/` em log de conversa.

Persista conhecimento futuro útil, não ruído conversacional.

## 3.8 Portabilidade

A arquitetura não deve depender conceitualmente de um único fornecedor de IA.

`AGENTS.md` será o contrato operacional compartilhado.

Arquivos específicos de uma ferramenta funcionam como adaptadores.

---

# 4. PRÉ-VOO OBRIGATÓRIO

Antes de criar qualquer coisa, analise o projeto existente.

Inspecione, quando disponíveis:

- árvore de diretórios;
- README;
- documentação existente;
- arquivos de configuração;
- package manifests;
- arquivos de dependências;
- schemas;
- arquivos de infraestrutura;
- instruções de agentes existentes;
- `AGENTS.md`;
- `CLAUDE.md`;
- documentação de arquitetura;
- planos;
- TODOs;
- ADRs;
- changelogs;
- testes;
- código relevante;
- arquivos de pesquisa;
- datasets;
- documentos de negócio;
- arquivos relacionados ao domínio do projeto.

Identifique:

```text
tipo do projeto
objetivo aparente
domínios principais
subdomínios
estado atual
restrições
tecnologias
decisões já documentadas
perguntas abertas
riscos aparentes
fontes existentes
branches de conhecimento necessárias
```

Não invente informações ausentes.

Quando algo for provável, mas não confirmado, registre como `assumption` ou `question`, nunca como `fact`.

---

# 5. NÃO DESTRUIR O QUE JÁ EXISTE

Se já existirem:

```text
AGENTS.md
CLAUDE.md
Context/
documentação
ADRs
notas
arquivos de pesquisa
```

não sobrescreva cegamente.

Use:

```text
READ
UNDERSTAND
MERGE
PRESERVE
NORMALIZE
```

Preserve instruções válidas existentes.

Resolva conflitos explicitamente.

Caso a arquitetura `Context/` já exista, trate esta execução como **migração/auditoria idempotente**, não como reinstalação destrutiva.

---

# 6. IDEMPOTÊNCIA

O bootstrap deve poder ser executado novamente sem duplicar regras ou registros.

Ao modificar `AGENTS.md`, prefira manter o bloco gerenciado entre marcadores:

```md
<!-- CONTEXT-ENGINEERING:START -->
...
<!-- CONTEXT-ENGINEERING:END -->
```

Se o bloco já existir:

- atualize o bloco;
- não crie outro;
- preserve conteúdo humano fora dele.

Faça o mesmo em arquivos adaptadores quando apropriado.

Nunca gere IDs duplicados.

Antes de criar um registro, procure equivalentes existentes.

---

# 7. BOOTSTRAP DAS INSTRUÇÕES GLOBAIS

Na raiz do projeto deverá existir:

```text
AGENTS.md
```

Ele será a **fonte canônica das instruções operacionais compartilhadas do projeto**.

Ele deve permanecer relativamente pequeno e estável.

`AGENTS.md` deve responder:

```text
Como o agente deve trabalhar?
Como ele descobre contexto?
Como ele pesquisa contexto?
Quando ele pode persistir contexto?
O que significa "salvar contexto"?
Onde estão as fontes de verdade?
Quais regras globais são permanentes?
```

Ele NÃO deve armazenar toda a arquitetura, histórico, pesquisa ou detalhes técnicos.

Regra:

```text
HOW TO WORK  → AGENTS.md
WHAT WE KNOW → Context/
```

---

# 8. CONTEÚDO OBRIGATÓRIO DO BLOCO GERENCIADO EM AGENTS.md

Adapte detalhes ao projeto, mas instale uma seção semanticamente equivalente a:

```md
<!-- CONTEXT-ENGINEERING:START -->

# Project Context System

This project uses `Context/` as its persistent project memory and knowledge system.

## Context discovery

For every non-trivial task:

1. Read `Context/MAP.md`.
2. Read `Context/STATE.md`.
3. Determine which context branches are relevant.
4. Read only the corresponding branch `_index.md` files.
5. Retrieve atomic records only when required.
6. Follow `related`, `depends_on`, `source_ids`, `supersedes`, and `superseded_by` only when they materially affect the current task.
7. Do not recursively load the entire `Context/` directory.

Use progressive context loading.

## Sources of truth

- `AGENTS.md` — permanent operational instructions.
- `Context/MAP.md` — context routing and navigation.
- `Context/STATE.md` — current project state.
- `Context/core/**` — stable project fundamentals.
- `Context/branches/**` — domain-specific knowledge.
- `Context/global/**` — cross-cutting decisions, questions, assumptions, risks and plans.
- `Context/checkpoints/**` — distilled session/milestone checkpoints.
- `Context/sources/**` — provenance and evidence.
- `Context/_meta/**` — context configuration, taxonomy, catalog and maintenance metadata.

## Context write policy

Context reading is automatic for non-trivial work.

Context persistence is controlled.

Do not write documentation for every conversation message.

Run the Context Save Protocol when the user expresses an intent equivalent to:

- `salvar contexto`
- `salve o contexto`
- `save context`
- `persistir contexto`
- `atualizar contexto`
- `atualizar memória do projeto`
- `criar checkpoint`
- `checkpoint da sessão`

When triggered, follow `Context/README.md`.

Do not copy the conversation verbatim.

Persist distilled, durable knowledge.

## Safety

Never persist secrets, passwords, access tokens, API keys, private keys, session cookies or credential values inside `Context/`.

References to environment-variable names or secret-manager locations are allowed.

## Maintenance

If a durable, project-wide operating rule is discovered, evaluate whether it belongs in `AGENTS.md`.

Do not put transient state or detailed knowledge in `AGENTS.md`.

<!-- CONTEXT-ENGINEERING:END -->
```

Você pode adaptar idioma e exemplos, mas preserve o comportamento.

---

# 9. CLAUDE CODE

Na raiz, crie ou mantenha:

```text
CLAUDE.md
```

Ele deve importar as instruções compartilhadas:

```md
@AGENTS.md
```

Se houver regras específicas do Claude Code, coloque-as abaixo, sem duplicar as regras gerais.

Exemplo:

```md
@AGENTS.md

<!-- CLAUDE-SPECIFIC:START -->

# Claude Code specific instructions

<!-- Somente regras realmente específicas do Claude Code. -->

<!-- CLAUDE-SPECIFIC:END -->
```

Se `CLAUDE.md` já existir:

- preserve instruções válidas;
- garanta que `@AGENTS.md` esteja presente;
- não duplique regras globais.

---

# 10. OUTROS AGENTES

Se o projeto já possuir um arquivo de instruções específico de outra ferramenta:

1. leia-o;
2. preserve-o;
3. faça-o apontar para `AGENTS.md` somente se o mecanismo de referência/importação da ferramenta for conhecido e suportado;
4. caso contrário, mantenha as regras compartilhadas em `AGENTS.md` e não invente sintaxe de importação.

Não crie adaptadores específicos de ferramentas desconhecidas apenas por suposição.

---

# 11. AGENTS.md LOCAIS

Não espalhe `AGENTS.md` por subdiretórios sem necessidade.

Crie instruções locais somente quando uma subárvore realmente exigir regras operacionais diferentes.

Exemplos possíveis:

```text
frontend/AGENTS.md
infra/AGENTS.md
experiments/AGENTS.md
```

Use isso apenas para escopo operacional local.

Conhecimento detalhado continua pertencendo a `Context/`.

---

# 12. ESTRUTURA BASE DE Context/

Crie:

```text
Context/
│
├── README.md
├── MAP.md
├── STATE.md
│
├── _meta/
│   ├── config.yaml
│   ├── taxonomy.yaml
│   ├── catalog.jsonl
│   ├── changelog.md
│   └── templates/
│
├── core/
│   ├── overview.md
│   ├── goals.md
│   ├── constraints.md
│   └── glossary.md
│
├── branches/
│   └── <dynamic-branches>/
│       ├── _index.md
│       ├── facts/
│       ├── research/
│       ├── decisions/
│       ├── assumptions/
│       ├── questions/
│       ├── plans/
│       ├── risks/
│       ├── experiments/
│       └── notes/
│
├── global/
│   ├── decisions/
│   ├── assumptions/
│   ├── questions/
│   ├── plans/
│   └── risks/
│
├── checkpoints/
├── sources/
├── future/
└── archive/
```

Diretórios vazios podem ser omitidos quando isso melhorar a clareza.

Não crie branches artificiais somente para preencher a estrutura.

---

# 13. BRANCHES DINÂMICAS

Uma branch representa uma área relativamente independente de conhecimento.

Determine branches a partir do projeto real.

Exemplos para software:

```text
backend
frontend
database
authentication
infrastructure
business-rules
testing
observability
```

Exemplos para pesquisa:

```text
literature
methodology
datasets
experiments
results
discussion
```

Exemplos para fitness:

```text
training
nutrition
recovery
measurements
planning
```

Exemplos para negócio:

```text
market
product
sales
operations
finance
customers
strategy
```

Não force esses exemplos.

Crie a taxonomia que fizer sentido para o projeto atual.

---

# 14. NÍVEIS DE CONTEXTO

## L0 — Contexto global

Arquivos:

```text
Context/MAP.md
Context/STATE.md
```

São a primeira camada operacional.

Devem permanecer compactos.

## L1 — Contexto da branch

Cada branch deve possuir:

```text
Context/branches/<branch>/_index.md
```

Ele deve conter:

- propósito;
- escopo;
- estado atual;
- conceitos centrais;
- registros importantes;
- decisões ativas;
- perguntas abertas;
- riscos;
- relações com outras branches;
- rotas para informações mais profundas.

## L2 — Registros atômicos

Conhecimento especializado:

```text
facts/
research/
decisions/
assumptions/
questions/
plans/
risks/
experiments/
notes/
```

## L3 — Evidências

Conteúdo pesado ou primário:

```text
sources/
datasets
snapshots
links
referências
documentos externos
resultados brutos
```

Só carregue L3 quando a tarefa exigir evidência ou validação.

---

# 15. MAP.md

`Context/MAP.md` será o roteador de conhecimento.

Ele não é a documentação completa.

Deve permitir descobrir rapidamente:

```text
Pergunta → Branch → Índice → Registro
```

Estrutura sugerida:

```md
# Context Map

## Project
- Overview: `core/overview.md`
- Goals: `core/goals.md`
- Constraints: `core/constraints.md`
- Current state: `STATE.md`

## Branches

### Backend
Path: `branches/backend/`
Status: active
Primary tags: api, authentication, database

Routes:
- Authentication → `branches/backend/_index.md`
- Database decisions → tag `database`, type `decision`

### Infrastructure
Path: `branches/infrastructure/`
Status: active
Primary tags: deployment, network, observability
```

Inclua somente rotas úteis.

---

# 16. STATE.md

`Context/STATE.md` representa o **estado operacional atual**, não o histórico.

Ele deve responder rapidamente:

- onde estamos;
- o que já existe;
- o que funciona;
- o que está em andamento;
- o que está quebrado;
- principais bloqueios;
- decisões atuais de maior impacto;
- perguntas críticas ainda abertas;
- próximo passo provável;
- checkpoint mais recente.

Estrutura sugerida:

```md
# Project State

Last updated: YYYY-MM-DD
Latest checkpoint: <path or id>

## Current objective

## Working

## In progress

## Blockers

## Active decisions

## Open critical questions

## Next likely steps
```

Mantenha-o pequeno.

Histórico pertence a checkpoints e registros.

---

# 17. CORE

Use:

```text
Context/core/overview.md
Context/core/goals.md
Context/core/constraints.md
Context/core/glossary.md
```

para conhecimento relativamente estável.

## overview.md

Explique:

- o que é o projeto;
- para quem existe;
- escopo;
- principais componentes;
- visão geral.

## goals.md

Separe, quando possível:

- objetivos;
- não objetivos;
- critérios de sucesso.

## constraints.md

Registre restrições duráveis:

- técnicas;
- financeiras;
- temporais;
- legais;
- operacionais;
- de compatibilidade;
- de infraestrutura;
- do usuário.

## glossary.md

Normalize termos importantes do domínio.

---

# 18. REGISTROS ATÔMICOS

Todo documento de conhecimento persistente deve usar YAML Frontmatter.

Modelo:

```yaml
---
id: CTX-DEC-20260830-use-postgresql
type: decision
title: Uso do PostgreSQL como banco principal
branch: backend
tags:
  - database
  - postgresql
  - architecture
status: active
confidence: high
created_at: 2026-08-30
updated_at: 2026-08-30
source_ids: []
related: []
depends_on: []
supersedes: null
superseded_by: null
valid_from: 2026-08-30
valid_until: null
revisit_at: null
---
```

Metadados mínimos:

```text
id
type
title
branch
tags
status
created_at
updated_at
```

Metadados opcionais devem ser usados quando fizerem sentido.

---

# 19. TIPOS CANÔNICOS

Use, como base:

```text
FCT = fact
RES = research
DEC = decision
ASM = assumption
QUE = question
PLN = plan
RSK = risk
NTE = note
SRC = source
SUM = summary
EXP = experiment
CP  = checkpoint
```

Exemplos:

```text
CTX-FCT-20260830-current-api-version
CTX-RES-20260830-auth-options
CTX-DEC-20260830-use-jwt
CTX-ASM-20260830-expected-user-volume
CTX-QUE-20260830-refresh-token-strategy
CTX-PLN-20260831-auth-refactor
CTX-RSK-20260830-vendor-rate-limit
CTX-EXP-20260830-latency-test
```

IDs devem permanecer estáveis mesmo que arquivos sejam movidos.

---

# 20. NOMENCLATURA DE ARQUIVOS

Use:

```text
<TYPE>-<YYYYMMDD>-<descriptive-slug>.md
```

Exemplos:

```text
DEC-20260830-use-postgresql.md
QUE-20260830-api-authentication.md
RES-20260829-database-comparison.md
ASM-20260830-expected-volume.md
```

Use `kebab-case`.

Evite nomes genéricos:

```text
documento.md
novo.md
teste.md
notes2.md
final-final.md
```

---

# 21. TAGS

Tags funcionam como índice transversal.

Use `kebab-case`.

Exemplo:

```yaml
tags:
  - authentication
  - jwt
  - security
  - api
```

Normalize tags em:

```text
Context/_meta/taxonomy.yaml
```

Antes de criar uma nova tag:

1. procure equivalente existente;
2. reutilize a tag canônica quando possível;
3. evite sinônimos redundantes.

Exemplo ruim:

```text
postgres
postgresql
pg
postgres-db
```

Escolha uma forma canônica.

---

# 22. TAXONOMY.YAML

Estrutura sugerida:

```yaml
version: 1

canonical_tags:
  database:
    - postgresql
    - mysql
    - redis

  infrastructure:
    - docker
    - ssh
    - cloudflare

statuses:
  - active
  - open
  - answered
  - planned
  - experimental
  - blocked
  - superseded
  - deprecated
  - archived

confidence:
  - low
  - medium
  - high
  - verified
```

Adapte ao domínio.

---

# 23. CONFIG.YAML

Crie:

```text
Context/_meta/config.yaml
```

Modelo sugerido:

```yaml
context_engineering_version: 1

root: Context

strategy:
  progressive_loading: true
  atomic_documents: true
  preserve_history: true
  controlled_writes: true

retrieval:
  initial_files:
    - MAP.md
    - STATE.md
  default_relation_depth: 1
  prefer_active_records: true

persistence:
  trigger_mode: explicit
  create_checkpoint_on_save: true
  update_state_on_save: true
  update_catalog_on_save: true

naming:
  files: kebab-case
  ids: stable

metadata:
  format: yaml-frontmatter

security:
  allow_credentials: false
  allow_secrets: false
```

Ajuste valores se o projeto exigir.

---

# 24. CATALOG.JSONL

Mantenha:

```text
Context/_meta/catalog.jsonl
```

como índice derivado.

Uma linha por registro:

```json
{"id":"CTX-DEC-20260830-use-postgresql","type":"decision","title":"Uso do PostgreSQL como banco principal","branch":"backend","tags":["database","postgresql"],"status":"active","updated_at":"2026-08-30","path":"branches/backend/decisions/DEC-20260830-use-postgresql.md"}
```

O catálogo NÃO é a fonte primária.

Os arquivos Markdown são canônicos.

Se houver divergência:

```text
REBUILD CATALOG FROM CANONICAL RECORDS
```

---

# 25. CHANGELOG DO CONTEXTO

Use:

```text
Context/_meta/changelog.md
```

para mudanças estruturais da memória:

- criação/removal de branch;
- migração de taxonomia;
- alteração importante de protocolo;
- grandes consolidações;
- correções estruturais;
- mudanças no schema de contexto.

Não use como log de cada conversa.

---

# 26. TEMPLATES

Crie templates mínimos quando forem úteis:

```text
Context/_meta/templates/
├── decision.md
├── question.md
├── research.md
├── checkpoint.md
└── generic-record.md
```

Eles devem seguir o schema atual.

Não obrigue todos os tipos a terem template se isso só gerar ruído.

---

# 27. FACTS

Um `fact` representa informação considerada verdadeira no escopo atual.

Exemplo:

```text
O serviço utiliza PostgreSQL 16.
```

Quando a informação puder mudar, considere:

```yaml
valid_from:
valid_until:
revisit_at:
```

Fatos provenientes de fonte externa importante devem preservar proveniência.

---

# 28. ASSUMPTIONS

Assumptions são hipóteses utilizadas para continuar o trabalho sem confirmação completa.

Nunca esconda assumptions em facts.

Estrutura útil:

```md
# Assumption

## Assumption

## Why we currently assume this

## What depends on it

## How to validate

## Consequence if false
```

---

# 29. QUESTIONS

Perguntas abertas são elementos de primeira classe.

Exemplo:

```yaml
---
id: CTX-QUE-20260830-auth-strategy
type: question
title: Qual estratégia de autenticação será utilizada?
branch: backend
tags:
  - authentication
status: open
created_at: 2026-08-30
updated_at: 2026-08-30
---
```

Conteúdo:

```md
## Question

## Why this matters

## What depends on the answer

## Known options

## How to resolve
```

Quando respondida:

```yaml
status: answered
```

adicione:

- resposta;
- evidência;
- `resolved_by`;
- decisão relacionada, se houver.

Não delete a pergunta.

---

# 30. RESEARCH

Pesquisas devem preservar:

- pergunta investigada;
- escopo;
- fontes;
- data;
- evidências;
- achados;
- limitações;
- nível de confiança;
- implicações;
- questões ainda abertas.

Não transforme pesquisa em decisão automaticamente.

---

# 31. DECISIONS

Decisões relevantes devem registrar:

```md
# Decision

## Context

## Problem

## Options considered

## Decision

## Rationale

## Consequences

## Risks

## Related records
```

Evite registrar somente:

```text
Vamos usar PostgreSQL.
```

Registre também por quê e em qual contexto.

---

# 32. PLANS

Planos devem distinguir:

```text
candidate
planned
in-progress
completed
cancelled
```

Não trate possibilidades como compromissos.

---

# 33. RISKS

Riscos devem registrar, quando possível:

- risco;
- causa;
- impacto;
- probabilidade;
- sinais;
- mitigação;
- owner, se conhecido;
- status.

---

# 34. EXPERIMENTS

Experimentos devem registrar:

- hipótese;
- setup;
- variável testada;
- condições;
- resultado;
- interpretação;
- limitações;
- artefatos/evidências.

Evite guardar resultados brutos enormes dentro do registro.

Aponte para L3 quando necessário.

---

# 35. SOURCES E PROVENIÊNCIA

Quando conhecimento vier de:

- documentação externa;
- site;
- paper;
- API;
- reunião;
- arquivo;
- benchmark;
- experimento;
- usuário;
- dataset;
- relatório;

preserve a origem quando isso for relevante para validação futura.

Use:

```text
Context/sources/
```

e referencie por `source_ids`.

Não converta informação externa temporal em fato absoluto sem preservar sua data/origem.

---

# 36. FUTURE

Use:

```text
Context/future/
```

para:

- ideias futuras;
- features candidatas;
- tecnologias a reconsiderar;
- pesquisas futuras;
- oportunidades;
- cenários;
- melhorias não aprovadas.

Separe:

```text
possibilidade ≠ decisão
possibilidade ≠ plano ativo
```

Use `revisit_at` quando fizer sentido.

---

# 37. ARCHIVE E SUPERSESSION

Quando uma informação importante deixar de valer:

não delete por padrão.

No registro antigo:

```yaml
status: superseded
superseded_by: CTX-...
```

No novo:

```yaml
supersedes: CTX-...
```

Use `archive/` para material que não pertence mais ao conjunto ativo, mas ainda possui valor histórico.

---

# 38. CONFLITOS

Quando duas informações conflitarem:

não escolha silenciosamente.

Compare:

- data;
- status;
- escopo;
- origem;
- confiança;
- decisões posteriores;
- validade temporal.

Se ainda houver ambiguidade:

crie ou atualize uma `question`.

Registre o conflito.

---

# 39. CONHECIMENTO NEGATIVO

Falhas importantes também são memória.

Registre uma abordagem que falhou quando existir risco razoável de alguém repeti-la.

Preserve:

```text
abordagem
condição do teste
resultado
causa conhecida
quando tentar novamente, se aplicável
```

Não persista erros triviais.

Exemplo de distilação:

Conversa bruta:

```text
Tentamos X.
Falhou.
Tentamos Y.
Falhou.
Descobrimos que Z estava desabilitado.
Habilitamos Z.
Funcionou.
```

Memória útil:

```md
## Problem
A conexão falhava porque Z estava desabilitado.

## Investigation
X e Y foram investigados, mas não eram a causa.

## Validated solution
Habilitar Z resolveu o problema.

## Avoid
Não repetir a investigação de X/Y sem nova evidência.
```

---

# 40. CONTEXT/README.md

`Context/README.md` é o manual da memória.

Ele deve documentar:

1. propósito do sistema;
2. estrutura de diretórios;
3. fontes de verdade;
4. tipos de registro;
5. schema de metadados;
6. nomenclatura;
7. tags;
8. protocolo de recuperação;
9. protocolo de persistência;
10. comando `salvar contexto`;
11. checkpoints;
12. supersession;
13. fontes;
14. segurança;
15. manutenção;
16. auditoria;
17. como adicionar uma branch;
18. como tratar conflitos;
19. como reconstruir o catálogo.

Esse arquivo pode ser mais detalhado que `AGENTS.md`.

---

# 41. PROTOCOLO DE RECUPERAÇÃO

Antes de qualquer tarefa não trivial:

## Etapa A — Entender a solicitação

Extraia:

```text
objetivo
entidades
branches prováveis
tags prováveis
tipo de conhecimento necessário
restrições
temporalidade
```

## Etapa B — Carregar L0

Leia:

```text
Context/MAP.md
Context/STATE.md
```

Não leia toda a pasta.

## Etapa C — Selecionar branches

Identifique somente as branches relevantes.

Leia:

```text
Context/branches/<branch>/_index.md
```

## Etapa D — Recuperação direcionada

Pesquise por:

```text
ID
title
tags
type
status
keywords
relations
```

Se houver terminal e `rg` estiver disponível, exemplos possíveis:

```bash
rg "authentication" Context/
rg "type: decision" Context/
rg "status: open" Context/
rg "postgresql" Context/
```

Esses comandos são exemplos, não dependências obrigatórias.

Use mecanismos equivalentes disponíveis.

## Etapa E — Expansão por relações

Quando um registro relevante for localizado:

1. leia-o;
2. confira `related`;
3. confira `depends_on`;
4. confira `source_ids`;
5. confira supersession;
6. siga somente as relações necessárias.

Profundidade inicial padrão:

```text
1 hop
```

Expanda apenas se a tarefa exigir.

---

# 42. PRIORIZAÇÃO DE RESULTADOS

Ao recuperar contexto, priorize:

1. correspondência direta com a tarefa;
2. branch correspondente;
3. tags;
4. status ativo;
5. relações explícitas;
6. registros mais atuais;
7. maior confiança;
8. melhor fonte;
9. validade temporal.

Não trate registros:

```text
superseded
deprecated
archived
```

como estado atual sem verificar o sucessor.

---

# 43. CONTEXT BUDGET

Não confunda mais contexto com melhor contexto.

Mantenha:

```text
MAP.md      → pequeno
STATE.md    → pequeno
_index.md   → resumo de branch
atomic docs → detalhe
sources     → evidência
```

Se um `_index.md` ficar grande demais:

- compacte;
- mova detalhes para registros atômicos;
- mantenha apenas rotas e resumo.

Se um registro abordar múltiplos assuntos independentes:

- divida-o;
- preserve relações.

---

# 44. ESCRITA CONTROLADA

A leitura de contexto faz parte do trabalho normal.

A persistência não deve ocorrer a cada mensagem.

Por padrão:

```text
READ = automático quando necessário
WRITE = controlado
```

Persistência completa acontece quando o usuário solicitar semanticamente algo equivalente a:

```text
salvar contexto
salve o contexto
save context
persistir contexto
atualizar contexto
atualizar memória do projeto
criar checkpoint
checkpoint da sessão
```

O agente deve reconhecer intenção, não depender de uma string exata.

---

# 45. CONTEXT SAVE PROTOCOL

Ao receber um gatilho de persistência:

**NÃO faça apenas um resumo da conversa.**

Reconstrua semanticamente a sessão.

Analise:

```text
objetivo da sessão
tarefas executadas
problemas encontrados
causas descobertas
tentativas relevantes
abordagens que falharam
soluções validadas
decisões tomadas
motivos
mudanças realizadas
arquivos afetados
testes realizados
resultados
novos fatos
novas assumptions
perguntas abertas
perguntas respondidas
riscos
pendências
próximos passos
mudanças de estado
informações obsoletas
regras operacionais descobertas
```

Em projetos versionados, quando possível, valide o que realmente mudou usando o estado/diff do sistema de versionamento.

Não dependa exclusivamente da lembrança da conversa quando os arquivos do projeto puderem fornecer evidência mais confiável.

---

# 46. FILTRO DE PERSISTÊNCIA

Para cada informação candidata, aplique:

> Um agente em uma nova sessão precisaria saber disso para continuar o projeto, evitar retrabalho ou tomar uma decisão melhor?

Se NÃO:

descarte.

Se SIM:

classifique e persista.

Não salve:

- cumprimentos;
- brainstorming descartado sem valor futuro;
- tentativas triviais;
- detalhes de conversa sem relevância;
- raciocínio redundante;
- texto literal da sessão.

---

# 47. DISTILAÇÃO

Transforme:

```text
chat
```

em:

```text
conhecimento operacional
```

Prefira:

- causa;
- consequência;
- decisão;
- evidência;
- solução;
- limitação;
- aprendizado;
- regra;
- estado.

Não copie mensagens literalmente salvo quando uma citação específica tiver valor documental.

---

# 48. PIPELINE DO "SALVAR CONTEXTO"

Execute:

```text
SESSION
   ↓
INSPECT PROJECT CHANGES
   ↓
ANALYZE
   ↓
DISTILL
   ↓
CLASSIFY
   ↓
DEDUPLICATE
   ↓
RELATE
   ↓
UPDATE/CREATE ATOMIC RECORDS
   ↓
CREATE CHECKPOINT
   ↓
UPDATE STATE
   ↓
UPDATE BRANCH INDEXES
   ↓
UPDATE MAP IF NECESSARY
   ↓
UPDATE CATALOG
   ↓
UPDATE CONTEXT CHANGELOG IF NECESSARY
   ↓
EVALUATE AGENTS.md RULES
   ↓
VALIDATE
```

---

# 49. DEDUPLICAÇÃO ANTES DE GRAVAR

Antes de criar novo registro:

1. procure pelo assunto;
2. procure tags;
3. procure títulos semelhantes;
4. procure IDs relacionados;
5. confira branch;
6. determine se o conhecimento já existe.

Quando apropriado:

```text
UPDATE EXISTING RECORD
```

em vez de:

```text
CREATE DUPLICATE RECORD
```

Preserve histórico se a informação realmente mudou.

---

# 50. CHECKPOINTS

Cada `salvar contexto` significativo deve criar um checkpoint compacto em:

```text
Context/checkpoints/
```

Nomenclatura:

```text
CP-YYYYMMDD-HHMM-<slug>.md
```

ID:

```text
CTX-CP-YYYYMMDD-HHMM-<slug>
```

Estrutura:

```md
---
id: CTX-CP-...
type: checkpoint
title: ...
status: active
created_at: ...
updated_at: ...
tags: [...]
---

# Session Checkpoint

## Objective

## What changed

## Decisions

## Discoveries

## Problems solved

## Failed approaches worth remembering

## Current state

## Open questions

## Next steps

## Files or artifacts affected

## Context records created or updated
```

Checkpoint é uma fotografia de continuidade.

Ele NÃO substitui registros atômicos.

Conhecimento durável deve ser propagado para o tipo correto.

---

# 51. STATE APÓS CHECKPOINT

Depois de salvar:

atualize `Context/STATE.md`.

Ele deve refletir apenas o estado atual.

Inclua referência ao checkpoint mais recente:

```text
Latest checkpoint: Context/checkpoints/CP-...
```

Remova estado antigo que não seja mais atual, desde que esteja preservado em registros/checkpoints.

---

# 52. INSTRUÇÕES OPERACIONAIS DESCOBERTAS

Durante `salvar contexto`, verifique se surgiu uma regra durável de projeto.

Exemplos:

```text
Sempre executar testes antes de alterar X.
Usar pnpm neste projeto.
Nunca editar arquivo Y diretamente.
Antes de alterar banco, verificar schema Z.
Não utilizar biblioteca W.
Executar lint antes do commit.
```

Pergunta:

> Isso é uma instrução durável sobre COMO futuros agentes devem trabalhar?

Se SIM:

considere adicionar/atualizar `AGENTS.md`.

Se for conhecimento sobre:

```text
arquitetura
estado
decisão
pesquisa
fato
hipótese
planejamento
```

mantenha em `Context/`.

Não transforme `AGENTS.md` em wiki.

---

# 53. COMANDOS SEMÂNTICOS ADICIONAIS

Documente no README estes intents úteis.

## `salvar contexto`

Executa persistência completa e checkpoint.

## `carregar contexto`

Força a recuperação explícita de `MAP`, `STATE` e branches relevantes antes de continuar.

## `buscar contexto <assunto>`

Pesquisa a memória por:

- tags;
- títulos;
- conteúdo;
- IDs;
- relações.

Retorna primeiro os registros mais relevantes.

## `status do contexto`

Resume:

- estado atual;
- último checkpoint;
- branches;
- perguntas críticas;
- bloqueios.

## `auditar contexto`

Executa manutenção estrutural.

Esses comandos são intenções semânticas, não precisam de parser formal.

---

# 54. AUDITORIA DE CONTEXTO

Quando solicitado a auditar ou quando houver sinais claros de deterioração, verifique:

```text
IDs duplicados
IDs referenciados inexistentes
tags duplicadas/sinônimas
registros contraditórios
status incorretos
questions resolvidas ainda open
records superseded apresentados como active
links quebrados
branches redundantes
branches grandes demais
documentos grandes demais
registros sem classificação
registros sem origem quando necessária
MAP desatualizado
STATE histórico demais
catalog divergente
instruções duplicadas em AGENTS/CLAUDE
segredos acidentalmente persistidos
```

Corrija preservando o histórico relevante.

---

# 55. SEGURANÇA

Nunca persista valores de:

```text
password
token
API key
private key
cookie
secret
credential
recovery code
```

Permitido:

```text
A integração usa a variável OPENAI_API_KEY.
```

Proibido:

```text
OPENAI_API_KEY=sk-...
```

Quando encontrar um segredo em documentação de contexto:

- não replique;
- remova/mascare do sistema de contexto quando permitido;
- registre apenas a referência segura.

---

# 56. TEMPORALIDADE

Conhecimento temporal deve indicar validade quando útil.

Use:

```yaml
valid_from:
valid_until:
revisit_at:
```

Isso é especialmente importante para:

- preços;
- APIs;
- versões;
- benchmark;
- fornecedores;
- métricas;
- estratégias;
- dependências;
- legislação;
- planejamento;
- informações externas.

---

# 57. RELAÇÕES

Use IDs estáveis:

```yaml
related:
  - CTX-DEC-...
  - CTX-RES-...

depends_on:
  - CTX-FCT-...
```

Não dependa somente de links de arquivo.

IDs devem continuar válidos mesmo após reorganização de paths.

Modelo de evolução:

```text
Question
   ↓
Research
   ↓
Finding / Fact
   ↓
Decision
   ↓
Plan
   ↓
Implementation / Action
   ↓
New Fact
```

Mantenha relações quando elas aumentarem recuperação ou explicabilidade.

---

# 58. MIGRAÇÃO DE DOCUMENTAÇÃO EXISTENTE

Se o projeto já possuir documentação:

não copie tudo para `Context/`.

Classifique.

Exemplo:

```text
README técnico completo → pode continuar fora de Context/
decisão relevante       → registrar em decisions/
estado atual             → sintetizar em STATE.md
questão aberta           → questions/
pesquisa importante      → research/
documento-fonte          → source ou referência
regra operacional        → AGENTS.md
```

Evite duplicação desnecessária.

`Context/` é camada de memória e recuperação, não cópia integral do projeto.

---

# 59. PRIMEIRA POPULAÇÃO

Após criar a estrutura:

1. leia os documentos existentes relevantes;
2. extraia conhecimento durável;
3. classifique;
4. crie registros;
5. crie branches;
6. gere `_index.md`;
7. gere `MAP.md`;
8. gere `STATE.md`;
9. gere core;
10. gere catálogo.

Se o projeto estiver praticamente vazio:

crie apenas o mínimo necessário e registre perguntas/assumptions em vez de inventar detalhes.

---

# 60. VALIDAÇÃO DO BOOTSTRAP

Antes de considerar a instalação concluída, valide:

```text
[ ] AGENTS.md existe
[ ] bloco CONTEXT-ENGINEERING existe exatamente uma vez
[ ] CLAUDE.md existe
[ ] CLAUDE.md contém @AGENTS.md
[ ] Context/ existe
[ ] Context/README.md existe
[ ] Context/MAP.md existe
[ ] Context/STATE.md existe
[ ] Context/_meta/config.yaml existe
[ ] Context/_meta/taxonomy.yaml existe
[ ] Context/_meta/catalog.jsonl existe
[ ] Context/_meta/changelog.md existe
[ ] Context/core/overview.md existe
[ ] Context/core/goals.md existe
[ ] Context/core/constraints.md existe
[ ] Context/core/glossary.md existe
[ ] branches reais foram criadas quando necessário
[ ] cada branch possui _index.md
[ ] protocolo de recuperação está documentado
[ ] protocolo "salvar contexto" está documentado
[ ] checkpoints estão documentados
[ ] não existem IDs duplicados
[ ] relações importantes apontam para IDs válidos
[ ] nenhuma credencial foi persistida
[ ] STATE representa o presente, não histórico
[ ] MAP consegue rotear um novo agente
```

---

# 61. TESTE DE RESET DE SESSÃO

Faça uma simulação mental obrigatória:

```text
Toda a conversa atual desapareceu.
Um novo agente abre o projeto.
```

Ele deve conseguir responder, usando somente arquivos:

1. O que é este projeto?
2. Qual o objetivo?
3. Qual o estado atual?
4. Onde está a memória?
5. Como pesquisar?
6. Quais branches existem?
7. Quais decisões importam?
8. Quais perguntas estão abertas?
9. Onde o trabalho parou?
10. Qual checkpoint é o mais recente?
11. Como salvar uma nova sessão?
12. Quais regras globais deve seguir?

Se qualquer resposta importante for impossível:

a instalação ainda não terminou.

Corrija antes de finalizar.

---

# 62. REGRA DE CONTINUIDADE

O sistema só é considerado correto quando este fluxo funciona:

```text
CRIAR / ABRIR PROJETO
        ↓
EXECUTAR ESTE BOOTSTRAP UMA VEZ
        ↓
AGENTS.md
        ↓
CLAUDE.md → @AGENTS.md
        ↓
Context/
        ↓
TRABALHAR NORMALMENTE
        ↓
"salvar contexto"
        ↓
DISTILAR + CLASSIFICAR + PERSISTIR
        ↓
CHECKPOINT + STATE
        ↓
ENCERRAR / LIMPAR SESSÃO
        ↓
NOVA SESSÃO
        ↓
AGENTE RECUPERA MAP + STATE
        ↓
CARREGA SOMENTE O CONTEXTO NECESSÁRIO
        ↓
CONTINUA O PROJETO
```

---

# 63. O QUE NÃO FAZER

Não:

- criar um único arquivo gigantesco de memória;
- carregar `Context/` inteiro em cada tarefa;
- copiar conversas literalmente;
- registrar tudo que aconteceu;
- confundir hipótese com fato;
- confundir pesquisa com decisão;
- duplicar conhecimento em MAP, STATE, índices e registros;
- apagar decisões antigas importantes;
- sobrescrever AGENTS/CLAUDE existentes sem leitura;
- criar dezenas de branches artificiais;
- criar uma tag nova para cada frase;
- persistir segredos;
- depender da sessão anterior;
- assumir fatos que não foram encontrados;
- inventar sintaxe de integração de ferramentas desconhecidas;
- transformar `AGENTS.md` em documentação técnica completa;
- transformar `STATE.md` em changelog.

---

# 64. REGRA DE NÃO DUPLICAÇÃO ENTRE CAMADAS

Cada camada tem profundidade diferente.

Exemplo correto:

`MAP.md`

```text
Authentication → branches/backend/
```

`branches/backend/_index.md`

```text
A autenticação atual usa JWT.
Decision: CTX-DEC-...
```

`DEC-....md`

```text
contexto completo
alternativas
decisão
motivo
consequências
```

Não copie a decisão completa para todos os níveis.

---

# 65. SAÍDA DA PRIMEIRA EXECUÇÃO

Depois de executar este bootstrap, responda ao usuário com um relatório curto contendo:

```text
Context Engineering Bootstrap concluído.

Criados/atualizados:
- ...
- ...

Branches detectadas:
- ...

Conhecimento inicial importado:
- ...

Assumptions/questions criadas:
- ...

Validações:
- bootstrap de agente
- reset de sessão
- integridade de IDs
- segurança

Estado:
READY | READY WITH WARNINGS | NEEDS ATTENTION
```

Não despeje toda a documentação criada na resposta.

Os arquivos do projeto são a saída principal.

---

# 66. EXECUÇÃO AGORA

Não apenas explique esta arquitetura.

**Implemente-a no projeto atual.**

Ordem:

```text
1. Inspecionar
2. Classificar
3. Preservar instruções existentes
4. Criar/mesclar AGENTS.md
5. Criar/mesclar CLAUDE.md
6. Criar Context/
7. Criar _meta/
8. Criar core/
9. Detectar e criar branches
10. Extrair conhecimento existente
11. Criar registros iniciais
12. Gerar índices
13. Gerar MAP
14. Gerar STATE
15. Instalar protocolo "salvar contexto"
16. Gerar catálogo
17. Validar IDs/relações
18. Validar segurança
19. Executar teste de reset de sessão
20. Reportar resultado
```

Use julgamento profissional.

Não crie complexidade sem benefício.

Quando faltar informação, use `assumption` ou `question` em vez de inventar.

Quando houver informação suficiente nos arquivos, aja sem interromper o bootstrap com perguntas desnecessárias.

---

# REGRA FINAL

Você não está construindo uma pasta de documentação.

Você está instalando um **sistema operacional de contexto para agentes**.

O resultado deve combinar:

```text
Project Memory
+
Knowledge Graph
+
Decision Memory
+
Research Memory
+
Question Tracker
+
Failure Memory
+
Session Checkpoints
+
Context Retrieval Protocol
+
Long-Term Agent Instructions
```

A qualidade do sistema deve ser medida por:

> **quanto contexto correto um agente consegue recuperar com o mínimo de leitura e o mínimo de dependência da sessão anterior.**

A sessão é descartável.

O conhecimento do projeto não é.
