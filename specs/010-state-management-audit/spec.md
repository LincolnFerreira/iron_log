# Feature Specification: Auditoria e Padronização de Gerenciamento de Estado

**Feature Branch**: `010-state-management-audit`

**Created**: 2026-08-27

**Status**: Draft

**Input**: User description: "verificar onde temos problema de gerenciamento de estado e corrigir — o problema pode ser até algo que não respeite o ciclo do widget de forma correta, ou uso incorreto — pra que tenhamos um padrão"

**Relação com features anteriores**:

- **`006-flutter-architecture-standard`**: define o padrão oficial de estado (Riverpod, `ref.watch` vs `ref.read`, `AsyncNotifier`, side-effects via `ref.listen`).
- **`008-clean-architecture-audit`**: migrou `StateNotifier` e corrigiu parte da reatividade em `home` (fatia RX-*). **Não esgotou** violações de ciclo de widget, side-effects na UI nem cobertura de `select`/DI em todo o app.

Esta feature **audita e corrige** o uso prático de estado e ciclo de widget — não redefine arquitetura nem reabre remediação estrutural da 008.

---

## Resumo Executivo

O Iron Log já tem padrão de estado documentado (constituição + spec 006), mas o código ainda mistura práticas que causam rebuilds desnecessários, side-effects no lugar errado e risco de operar após dispose do widget. Exemplos observáveis hoje: snackbars disparados direto em callbacks/`build` sem listener; ausência de `ref.listen` no projeto; dezenas de `setState` convivendo com Riverpod; verificações `mounted` espalhadas como remendo.

Esta feature entrega:

1. **Inventário verificável** de anti-padrões de estado e ciclo de widget, por feature e severidade
2. **Remediação incremental** dos casos de maior risco (side-effects, lifecycle, watch indevido)
3. **Gabaritos documentados** para o time seguir em código novo e em review

**Princípio guia**: estado de negócio e efeitos colaterais (feedback, navegação) MUST ficar nos controllers/providers; widgets MUST respeitar o ciclo de vida e rebuild mínimo. `setState` permanece aceitável **apenas** para estado efêmero estritamente local (animação, foco, drag temporário) — MUST NOT duplicar estado já exposto por provider.

**Referências canônicas no código**: `lib/features/home/presentation/` (pós-RX da 008), `WorkoutTimer` / `elapsedTimeProvider` (isolamento de rebuild), `lib/features/routines/presentation/providers/` (controllers `@riverpod`).

**Fora de escopo**: reescrever `WorkoutSessionScreen` legada (isolada na 008); migrar backend; alterar contratos de API; criar nova biblioteca de estado.

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Time vê mapa de problemas de estado (Priority: P1)

Como desenvolvedor ou revisor, quero um inventário claro dos anti-padrões de gerenciamento de estado e ciclo de widget, para priorizar correções e evitar regressões.

**Why this priority**: Sem mapa compartilhado, cada PR repete os mesmos erros (snackbar no `build`, `ref.watch` em repositório, `setState` para dado de domínio).

**Independent Test**: Um membro do time consegue, só com esta spec e o artefato de inventário, listar os hotspots de alta severidade e o padrão correto a aplicar.

**Acceptance Scenarios**:

1. **Given** o inventário desta feature, **When** alguém inspeciona `workout_day`, **Then** vê violações classificadas (ex.: side-effect na UI, `setState` para estado de treino) com severidade e remediação sugerida.
2. **Given** o inventário, **When** alguém busca uso incorreto de DI vs estado, **Then** identifica arquivos onde repositório/serviço é observado com `watch` em vez de `read`.
3. **Given** o inventário, **When** alguém planeja um PR, **Then** consegue pegar apenas itens de uma prioridade sem depender de outras fatias.

---

### User Story 2 - Side-effects e feedback fora do `build` (Priority: P1)

Como usuário do app, quero que mensagens de erro/sucesso e navegação pós-ação apareçam de forma confiável, sem duplicar snackbars nem falhar após sair da tela.

**Why this priority**: Side-effects no `build` ou sem listener causam bugs intermitentes e difíceis de reproduzir — impacto direto na experiência.

**Independent Test**: Após remediação P1, fluxos críticos (login, finalizar treino, criar rotina) disparam feedback via padrão único (`ref.listen` + `AppSnackbar` ou equivalente documentado), não via `ScaffoldMessenger`/`AppSnackbar` solto no `build` ou em lógica síncrona de rebuild.

**Acceptance Scenarios**:

1. **Given** um controller que transita para `AsyncError`, **When** a tela está montada, **Then** o usuário vê **uma** mensagem de erro via listener registrado no ciclo correto do widget — MUST NOT disparar snackbar dentro do método `build`.
2. **Given** o usuário navega para fora da tela enquanto uma operação async termina, **When** o resultado chega, **Then** MUST NOT ocorrer side-effect em contexto inválido (snackbar/navegação após dispose).
3. **Given** grep de conformidade P1, **When** executado nos diretórios de presentation das features prioritárias, **Then** zero ocorrências de side-effect documentado como proibido nos gabaritos desta spec.

---

### User Story 3 - Rebuild mínimo e fronteira watch/read (Priority: P2)

Como usuário, quero telas fluidas sem recomputar listas inteiras quando só um campo muda; como desenvolvedor, quero DI estável sem rebuild cascata.

**Why this priority**: Performance percebida e clareza de código — confunde estado com injeção de dependência.

**Independent Test**: Features remediadas na fatia P2 usam `ref.read` para repositórios/serviços em notifiers e providers de wiring; widgets usam `ref.watch` só em providers de estado, preferindo `.select` quando apenas um campo dispara UI.

**Acceptance Scenarios**:

1. **Given** um widget que só exibe o nome do usuário no header, **When** outro campo do perfil muda, **Then** MUST NOT rebuildar o header inteiro se `.select` ou provider derivado isolam o campo.
2. **Given** um `@riverpod` controller que chama repositório, **When** executa operação async, **Then** MUST usar `ref.read(repositoryProvider)` — MUST NOT `ref.watch` repositório no notifier.
3. **Given** a fatia P2 concluída para uma feature, **When** grep de `ref.watch` em providers de repositório/HTTP na presentation, **Then** retorna zero (exceto exceções documentadas no inventário).

---

### User Story 4 - Ciclo de widget e fronteira setState/Riverpod (Priority: P2)

Como mantenedor, quero que estado efêmero local e estado de negócio tenham fronteiras claras, com operações async seguras após `dispose`.

**Why this priority**: Mistura de `setState` com Riverpod para o mesmo dado gera dessincronia; callbacks async sem guarda de lifecycle causam crashes ou warnings.

**Independent Test**: Para cada hotspot P2, ou o estado migrou para provider/controller, ou está documentado como exceção local legítima (ex.: posição de drag). Async callbacks MUST respeitar `mounted` / cancelamento documentado.

**Acceptance Scenarios**:

1. **Given** um bottom sheet que altera dados persistidos de treino, **When** o usuário confirma, **Then** a mutação MUST passar pelo controller/repositório — MUST NOT persistir só via `setState` local.
2. **Given** operação async iniciada em `initState` ou callback, **When** o widget é removido da árvore antes da conclusão, **Then** MUST NOT chamar `setState` nem side-effect de UI.
3. **Given** o inventário de exceções `setState`, **When** revisado, **Then** cada entrada tem justificativa (estado estritamente local) ou plano de migração.

---

### User Story 5 - Revisor e código novo seguem o padrão (Priority: P3)

Como revisor de PR, quero checklist objetivo de estado para bloquear anti-padrões antes do merge.

**Why this priority**: Sustentabilidade — auditoria só vale se o padrão for aplicado daqui pra frente.

**Independent Test**: Checklist derivado desta spec + contrato 006 cobre side-effects, watch/read, lifecycle e setState; desenvolvedor consegue validar PR em minutos com greps documentados.

**Acceptance Scenarios**:

1. **Given** PR que adiciona `AppSnackbar` no `build`, **When** revisor aplica checklist, **Then** MUST solicitar mover para `ref.listen`.
2. **Given** PR que adiciona `ref.watch` em provider de repositório na UI, **When** revisor aplica checklist, **Then** MUST solicitar `ref.read` ou provider de estado derivado.
3. **Given** documentação de gabarito publicada, **When** novo controller é criado, **Then** segue template AsyncNotifier + listener na page documentado nesta feature.

---

### Edge Cases

- **Estado puramente visual** (expansão de tile, foco de campo, animação): `setState` ou `StatefulWidget` local é aceitável; MUST NOT persistir nem espelhar provider de domínio.
- **Telas legadas isoladas** (`WorkoutSessionScreen`): remediação MAY ser mínima (documentar exceção) se não houver rota de produto — MUST NOT bloquear conclusão da feature por rewrite completo.
- **Providers keepAlive** (auth, sync, HTTP): `watch` com `.select` fino é aceitável para reatividade global; `watch` amplo de repositório inteiro na UI continua proibido.
- **Bottom sheets e modais**: listener MUST ser registrado no widget que possui `ref` válido; MAY usar `ConsumerStatefulWidget` com `ref.listen` em `initState`/`build` conforme gabarito — MUST NOT duplicar listener a cada rebuild sem necessidade.
- **Testes**: overrides de provider MUST continuar seguindo `getTestProviderOverrides()`; remediação MUST NOT quebrar testes existentes sem atualização correspondente.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O time MUST ter inventário por feature de anti-padrões de estado e ciclo de widget, com severidade (alta / média / baixa), evidência (arquivo/grep) e remediação sugerida.
- **FR-002**: A remediação MUST seguir constituição v1.2.3 e spec/contratos da **006** — MUST NOT introduzir biblioteca de estado alternativa nem novo estilo paralelo.
- **FR-003**: Side-effects de UI (snackbar, navegação pós-estado) MUST usar `ref.listen` (ou padrão equivalente documentado) — MUST NOT ocorrer no método `build` sem listener.
- **FR-004**: Repositories, datasources e `HttpService` MUST ser acessados com `ref.read` em notifiers e wiring — MUST NOT `ref.watch` na UI para providers de DI.
- **FR-005**: Operações async iniciadas por widgets MUST respeitar ciclo de vida (`mounted`, cancelamento ou listener desmontado) antes de side-effects.
- **FR-006**: Estado de negócio compartilhado ou persistido MUST viver em providers/controllers — MUST NOT duplicar em `setState` local sem exceção documentada.
- **FR-007**: Remediação MUST ser entregue em PRs pequenos por feature ou cluster de inventário — MUST NOT big bang.
- **FR-008**: MUST publicar gabarito mínimo (page + controller + listener) e checklist de review derivável desta spec.
- **FR-009**: Hotspots de alta severidade identificados no inventário MUST ser corrigidos antes do encerramento da feature.
- **FR-010**: Itens de severidade média MUST ser corrigidos ou registrados como exceção aceita com justificativa no inventário.

### Key Entities

- **Item de inventário**: unidade auditável (arquivo, provider ou widget) com tipo de violação, severidade, status (`open` / `done` / `accepted_exception`) e slice de remediação.
- **Hotspot de side-effect**: ponto onde feedback ou navegação é disparado fora do padrão listener — rastreado até remediação ou exceção.
- **Fronteira setState**: decisão documentada se estado local permanece em widget ou migra para provider.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% dos itens de inventário com severidade **alta** estão `done` ou `accepted_exception` documentada antes do close-out.
- **SC-002**: Zero side-effects proibidos (snackbar/navegação reativa a provider) no `build` de pages/widgets nas features remediadas — verificável por grep/checklist.
- **SC-003**: Zero `ref.watch` em providers de repositório/HTTP/datasource em `presentation/pages`, `presentation/widgets` e `presentation/components` das features remediadas.
- **SC-004**: Fluxos smoke críticos (login → home → iniciar/continuar treino → histórico) completam sem snackbar duplicado nem erro de contexto após navegação rápida — validação manual ou E2E existente.
- **SC-005**: Checklist de review de estado publicado; revisor consegue auditar PR típico em menos de 10 minutos usando greps documentados.
- **SC-006**: Pelo menos um gabarito referenciável (ex.: home pós-008 ou timer de treino) citado no inventário como “copiar este padrão”.

---

## Assumptions

- Migração `StateNotifier` da **008** está concluída; esta feature não reabre esse trabalho.
- Riverpod 3 com `@riverpod` permanece stack única; `provider`, Bloc, GetIt continuam proibidos em código novo.
- `AppSnackbar` é o componente canônico de feedback; substituir `ScaffoldMessenger` solto faz parte da remediação onde aplicável.
- Features prioritárias para P1/P2: `auth`, `home`, `workout_day`, `routines`, `workout_creation`, `workout_history` — demais features entram se violações forem encontradas na auditoria inicial.
- Performance: meta pragmática é eliminar anti-padrões e rebuilds óbvios, não otimização micro de cada widget.
- Testes existentes MUST passar após cada fatia; novos testes widget são desejáveis nos hotspots P1 mas não bloqueiam close-out se smoke manual passar.

---

## Inventário Inicial (snapshot — refinar na fase de plano)

| id | área | problema | severidade | notas |
|----|------|----------|------------|-------|
| SM-se-no-listen | app-wide | Ausência de `ref.listen` para side-effects | alta | grep `ref.listen` → 0; snackbars espalhados |
| SM-snackbar-build | várias | `AppSnackbar` / `ScaffoldMessenger` fora de listener | alta | login, workout_day, routines, sheets |
| SM-setstate-domain | workout_day, routines, creation | `setState` convivendo com estado de treino/rotina | média | migrar ou documentar exceção |
| SM-watch-di | routines | `ref.watch` em wiring de repositório | média | `routine_providers.dart`, exercise browse |
| SM-select-coverage | app-wide | Poucos `.select`; rebuild amplo | média | 008 corrigiu home; ampliar ao tocar |
| SM-lifecycle-async | workout_day, sheets | callbacks async com `mounted` ad hoc | média | padronizar guarda/cancelamento |
| SM-legacy-session | workout_session_screen | setState + snackbars legados | baixa | exceção isolada; não bloquear close-out |

*Inventário vivo MUST ser atualizado em `inventory-status.md` durante implementação.*
