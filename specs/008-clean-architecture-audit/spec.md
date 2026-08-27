# Feature Specification: Auditoria e Organização Clean Architecture

**Feature Branch**: `008-clean-architecture-audit`

**Created**: 2026-08-20

**Status**: Implementation complete — SC-005 smoke awaiting device confirmation (T077)

**Input**: User description: "quero organizar a estrutura do aplicativo na questão de clean architecture, imagino que tem coisas sem estar no lugar correto, consegue verificar pra mim?"

**Relação com 006**: A feature `006-flutter-architecture-standard` **definiu** o padrão oficial. Esta feature **audita o código atual** contra esse padrão, inventaria desvios e define remediação incremental sem rewrite em massa.

---

## Resumo Executivo

O Iron Log já tem um padrão arquitetural oficial (feature-first + três camadas `domain` / `data` / `presentation`, referências `routines/` e `workout_day/`). Na prática, várias features ainda misturam responsabilidades: telas e controllers chamam rede diretamente, pastas incompletas, stubs mortos e uma tela de treino legada ainda exportada.

Esta feature entrega:

1. **Inventário verificável** do que está fora do lugar
2. **Priorização** (alto / médio / baixo) alinhada a risco de manutenção e regressão
3. **Critérios de “done”** por fatia, para corrigir de forma incremental e segura

**Não é** um big bang nem uma nova constituição — é a aplicação prática da 006 no código existente.

## Clarifications

### Session 2026-08-20

- Q: Quando a feature 008 será considerada concluída? → A: Tudo (P1 + P2 + P3) precisa estar feito para encerrar a 008
- Q: O que fazer com stubs mortos (`analytics`, `workout_session`) e arquivos órfãos? → A: Remover do código de produto após confirmação de zero imports
- Q: O que fazer com a tela legada de sessão de treino (`WorkoutSessionScreen`)? → A: Isolar (ex.: deprecated / sem export de produto), sem deletar ainda
- Q: Providers de `workout_day`/`routines` com HTTP na presentation — escopo nesta feature? → A: Migrar todo HTTP da presentation listado em alta (`home` + `workout_day` + `routines`)
- Q: Migração de estado legado (`StateNotifier`) entra no done da 008? → A: Sim — migrar todos os `StateNotifier` listados no inventário antes de fechar a 008 (em PRs pequenos por arquivo/módulo)

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Time vê o mapa do que está errado (Priority: P1)

Como desenvolvedor ou revisor do Iron Log, quero um inventário claro por feature do que viola o padrão clean architecture, para saber o que corrigir primeiro e o que pode esperar.

**Why this priority**: Sem inventário compartilhado, cada pessoa “acha” problemas diferentes e o esforço se dispersa.

**Independent Test**: Um membro do time consegue listar, só com este documento, as violações de alta prioridade e o módulo canônico a espelhar (`routines` / `workout_day`).

**Acceptance Scenarios**:

1. **Given** o inventário desta spec, **When** alguém escolhe a feature `home`, **Then** vê que falta fronteira de repositório e que a apresentação fala com a API diretamente.
2. **Given** o inventário, **When** alguém busca stubs mortos, **Then** identifica módulos que não devem ser usados como referência (`analytics`, `workout_session`).
3. **Given** o inventário, **When** alguém planeja um PR, **Then** consegue pegar apenas itens de uma prioridade sem depender de outras fatias.

---

### User Story 2 - Remediação das violações de alta prioridade (Priority: P1)

Como mantenedor, quero corrigir primeiro os desvios que mais misturam camadas e mais confundem navegação de treino, sem parar o produto.

**Why this priority**: HTTP na UI e tela legada de treino aumentam bugs e onboarding difícil.

**Independent Test**: Após a fatia P1, `home` deixa de chamar HTTP/DTOs direto da apresentação; a tela legada de sessão de treino fica **isolada** (sem export/caminho de produto); fluxos de treino usam as rotas canônicas de execução.

**Acceptance Scenarios**:

1. **Given** a feature `home` com chamadas de rede na apresentação, **When** a remediação P1 conclui, **Then** a UI só consome estado/controllers e o acesso à API passa por fronteira de dados/repositório.
2. **Given** a existência de tela de sessão de treino legada além da tela canônica do dia de treino, **When** a remediação P1 conclui, **Then** a tela legada **não é exportada nem referenciada** por rotas/barrels de produto; o caminho oficial usa apenas a tela canônica e as rotas documentadas.
3. **Given** um fluxo de ir ao resumo do treino a partir da execução, **When** o usuário finaliza, **Then** a navegação segue o roteador oficial — sem atalho imperativo paralelo não documentado.

---

### User Story 3 - Alinhamento das features parciais e estado legado (Priority: P2)

Como desenvolvedor, quero alinhar `auth`, `workout_history`, `workout_creation` e resíduos em `routines`/`workout_day` ao padrão, e migrar o estado legado listado no inventário para o padrão oficial de estado, em PRs pequenos.

**Why this priority**: Reduz dívida estrutural e de estado sem um único PR monstro (vários PRs, escopo completo).

**Independent Test**: Features P2 atendem estrutura mínima; busca por `StateNotifier` / `StateNotifierProvider` nos pontos do inventário retorna zero após a fatia correspondente.

**Acceptance Scenarios**:

1. **Given** `auth` com controllers na raiz da feature, **When** a fatia P2 de auth conclui, **Then** estado/controllers vivem sob `presentation/` e a tela de login não chama serviço HTTP diretamente.
2. **Given** `workout_history` com montagem de datasource na pasta de providers de UI, **When** a fatia P2 conclui, **Then** a injeção segue o padrão de overrides da feature (como `routines`).
3. **Given** providers de treino/rotina que ainda acessam rede na camada de apresentação e constam na alta prioridade, **When** a fatia de alta desta feature conclui, **Then** **todos** esses I/O (`home`, `workout_day`, `routines`) já passaram por datasource/repositório.
4. **Given** providers ainda em padrão de estado legado listados no inventário, **When** a fatia de migração de estado conclui, **Then** esses providers usam o padrão oficial de estado (sem `StateNotifier` / `StateNotifierProvider` nos pontos listados).

---

### User Story 4 - Limpeza de stubs e arquivos mortos (Priority: P3)

Como mantenedor, quero remover ou marcar claramente stubs e arquivos órfãos para que ninguém copie estrutura errada.

**Why this priority**: Baixo risco funcional, alto risco de “copiar o exemplo errado”.

**Independent Test**: Busca no código por imports dos stubs removidos/isolados retorna zero usos de produto; documentação aponta só `routines` e `workout_day` como referência.

**Acceptance Scenarios**:

1. **Given** módulos stub sem uso de produto, **When** a limpeza P3 conclui, **Then** os módulos são **removidos** do código de produto (não apenas marcados).
2. **Given** arquivo órfão/vazio em onboarding e campo de busca de exercício deprecado, **When** a limpeza conclui, **Then** esses artefatos são **removidos** e deixam de existir como caminhos no projeto.

---

### Edge Cases

- Feature só de UI (ex.: `settings` fino): pode permanecer só com `presentation/` se não houver regra de negócio nem persistência própria.
- Feature que reutiliza entidades de outra (ex.: histórico reusa entidades de treino): não precisa duplicar entidades; MUST ter fronteira de repositório própria se falar com API.
- Migração de estado legado: nesta feature o inventário de `StateNotifier` MUST ser esgotado antes do encerramento; a entrega MUST continuar em PRs pequenos (arquivo/módulo), não um único rewrite monólito.
- Código gerado e overrides em `main`: NÃO mover para “lugar errado” só por estética; manter o padrão de overrides documentado na 006.
- Trabalho paralelo em outras branches: remediações MUST ser PRs pequenos por feature/prioridade para reduzir conflito.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O time MUST ter um inventário por feature listando: estrutura atual, violações, severidade e remediação sugerida (esta spec + artefatos de plano/tarefas).
- **FR-002**: A remediação MUST usar como referência canônica as features `routines` e `workout_day` e as regras da constituição / spec 006 — MUST NOT criar um terceiro “estilo” paralelo.
- **FR-003**: Features com lógica de negócio e/ou rede MUST progressiveente expor fronteira `domain` (contratos) + `data` (acesso) + `presentation` (UI/estado), conforme aplicável.
- **FR-004**: Camada de apresentação MUST NOT chamar HTTP/API diretamente para fluxos remediados nesta feature; MUST passar por repositório/datasource.
- **FR-005**: A UI MUST NOT observar repositórios como estado reativo nos pontos remediados; DI de infraestrutura MUST ser leitura pontual, não “watch” de repositório.
- **FR-006**: O caminho oficial de execução/edição/registro de treino MUST ser a tela canônica de dia de treino + rotas oficiais; a tela legada de sessão MUST ser **isolada** (sem export de barrel de produto, sem rota ativa) — MUST NOT ser deletada nesta feature (remoção definitiva fica fora do escopo imediato).
- **FR-007**: Entidades de domínio MUST NOT depender de conceitos visuais da UI (ex.: cor de tema) nos pontos remediados.
- **FR-008**: Stubs e arquivos mortos identificados (`analytics`, `workout_session`, órfãos, busca de exercício deprecada) MUST ser **removidos** do código de produto após confirmação de zero imports de uso — MUST NOT permanecer apenas com marcação “não copiar”.
- **FR-009**: Remediação MUST ser incremental por prioridade (P1 → P2 → P3) e MAY usar vários PRs; a feature 008 MUST NOT ser encerrada enquanto itens de P1, P2 e P3 do inventário permanecerem abertos (exceto exceção documentada pontual).
- **FR-010**: Critérios de aceite de cada fatia MUST ser verificáveis em review (checklist de PR alinhado à 006).
- **FR-011**: Comportamento de produto observável pelo usuário (login, home, treino, histórico) MUST permanecer equivalente após cada fatia — sem “melhorias” de UX acopladas à remediação estrutural.
- **FR-013**: Nesta feature, MUST migrar para datasource/repositório **todo** o acesso HTTP ainda presente na camada de presentation das áreas de alta prioridade do inventário: `home`, `workout_day` e `routines` (entrega pode ser em PRs separados, mas o item permanece aberto até concluir o conjunto).
- **FR-014**: Nesta feature, MUST migrar **todos** os providers de estado legado (`StateNotifier` / `StateNotifierProvider`) listados no inventário para o padrão oficial de estado da 006/constituição, em PRs pequenos por arquivo ou módulo — a feature MUST NOT encerrar com esses itens abertos.

### Key Entities

- **Inventário de desvio**: feature, violação, severidade, remediação sugerida, status (aberto / feito).
- **Feature canônica**: módulo de referência (`routines`, `workout_day`) usado como gabarito estrutural.
- **Fatia de remediação**: conjunto de arquivos/módulos corrigidos juntos com critério de done independente.

---

## Inventário Inicial (auditoria 2026-08-20)

### Alta prioridade

| Área | Problema | Remediação sugerida |
|------|----------|---------------------|
| `home` | Sem repositório; apresentação chama API/DTOs | Introduzir datasource/repositório; controllers só consomem fronteira de dados |
| Treino legado | Tela de sessão paralela + navegação imperativa ao resumo | **Isolar** (sem export/rota de produto); manter só tela canônica + rotas oficiais |
| `workout_day` / `routines` (parcial) | Providers de apresentação ainda fazem HTTP | **Migrar todo** o I/O HTTP da presentation listado (PRs ok); não deixar “só ao tocar” |

### Média prioridade

| Área | Problema | Remediação sugerida |
|------|----------|---------------------|
| `auth` | Controllers na raiz; login com HTTP direto | Mover para `presentation/providers`; página só fala com controller |
| `workout_history` | Wiring de datasource nos providers de UI | DI no padrão de overrides da feature |
| `workout_creation` / `onboarding` | Camadas incompletas / inconsistentes | Documentar UI-only ou completar data; limpar órfãos |
| Domínio | Entidade de tag de exercício acoplada a cor de UI | Extrair aspecto visual para presentation |
| Core ↔ features | Serviços/core importando datasources/entidades de feature | Explicitar dependência ou mover contrato compartilhado |
| `StateNotifier` legado | Ainda presente em vários providers | **Migrar todos** os listados nesta feature (PRs pequenos por arquivo/módulo) |

### Baixa prioridade

| Área | Problema | Remediação sugerida |
|------|----------|---------------------|
| `analytics`, `workout_session` | Stubs mortos | **Remover** após zero imports |
| Busca de exercício deprecada | Widget legado ainda no código | **Remover** em favor do componente unificado |
| `settings` | Só presentation | Aceitável se permanecer fino |
| Pastas duplicadas de organisms / estilos soltos | Organização cosmética | Unificar quando tocar os arquivos |

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% das violações do inventário (P1 + P2 + P3) têm status “feito” ou “aceito com exceção documentada” antes de encerrar a feature.
- **SC-002**: Um desenvolvedor novo identifica, em até 15 minutos lendo esta spec + 006, quais pastas são referência e quais não copiar.
- **SC-003**: Após fatia de alta, busca por chamadas diretas de API a partir de páginas/controllers/providers de presentation em `home`, `workout_day` e `routines` (itens do inventário) retorna zero ocorrências nos fluxos remediados.
- **SC-004**: Após fatia P1, a tela legada de sessão de treino não tem export nem rota de produto ativos (arquivo pode permanecer isolado).
- **SC-005**: Cada PR de remediação altera preferencialmente uma feature (ou um cluster P1), e o smoke dos fluxos login → home → treino → histórico passa sem regressão funcional.
- **SC-007**: Antes de encerrar a 008, busca pelos padrões de estado legado listados no inventário (`StateNotifier` / `StateNotifierProvider` nos providers inventariados) retorna zero ocorrências nesses pontos.

---

## Assumptions

- A spec **006** e a constituição Flutter permanecem a fonte de verdade do “como deve ser”; esta feature não redefine o padrão — só aplica e limpa.
- Para **estado legado**, a 008 faz uma **exceção de escopo** à regra “só ao tocar o arquivo”: o inventário de `StateNotifier` MUST ser migrado até o encerramento, ainda assim em PRs pequenos (não um único commit monólito).
- `settings` fino e features só-UI podem omitir `data/`/`domain/` se não houver regra de negócio.
- Backend NestJS está fora do escopo desta feature (apenas app Flutter `iron_log`).
- Stubs `analytics` / `workout_session` não têm uso de produto; **remoção** é a política desta feature (após confirmação de imports zero), não apenas marcação.
- Comportamento de produto deve permanecer o mesmo; esta feature não inclui redesign de telas.
- Trabalho local não commitado em `workout_day` (inputs/performance) é ortogonal e NÃO bloqueia esta spec; conflitos de arquivo devem ser resolvidos em PRs separados. **Reatividade / rebuilds** (analyze U1): hotspots inventariados em `inventory-status.md` (RX-*) + tasks T072–T074 — follow-up opcional, não bloqueia SC-001.
- O escopo de conclusão da 008 inclui **todas** as prioridades do inventário (P1, P2 e P3), ainda que entregues em PRs sequenciais. Greps de presentation MUST incluir `httpServiceProvider` (não só `HttpService`/`AuthService`); `GoogleAuthService` MUST NOT aparecer em pages/widgets (controller OK).
