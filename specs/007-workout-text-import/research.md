# Research: Importação de Treino por Texto Livre

**Feature**: `007-workout-text-import` | **Date**: 2026-06-23

## R1 — Onde executar a interpretação (IA)?

**Decision**: Interpretação no **backend** (`iron_log_back_end`), novo módulo `workout-import`.

**Rationale**:
- Já existe `@google/genai` + `GEMINI_API_KEY` usados em `exercise.service.ts` (padrão estabelecido).
- Prompts longos, versionamento e auditoria ficam centralizados no servidor.
- Chave de API não vai para o cliente mobile.
- O princípio "IA sugere, humano valida" combina com endpoint `POST /workout-import/parse` que retorna **rascunho estruturado**, nunca persiste treino.

**Alternatives considered**:
| Alternativa | Por que rejeitada |
|-------------|-------------------|
| Parser só no Flutter (`VoiceToWorkoutParser`) | Rule-based, single-exercise, sem separação multi-sessão; não atende FR-007–FR-013 |
| IA direto no app (SDK Gemini no Flutter) | Expõe chave, duplica infra de GenAI, dificulta evolução de prompt |
| Serviço serverless separado | Overhead operacional; NestJS já tem o padrão |

**Model**: `gemini-2.5-flash` (mesmo do find-or-create de exercício). Resposta **JSON estruturado** validada com Zod/class-validator após parse.

---

## R2 — Persistência de treinos importados sem rotina do usuário

**Decision**: Criar/usar rotina oculta por usuário **"Histórico importado"** (`source: import`, não listada na UI de rotinas) com uma sessão template **"Importado"**. No `confirm`, exercícios são resolvidos via `find-or-create` e `SessionExercise` é criado sob demanda nessa sessão.

**Rationale**:
- `SerieLog.sessionExerciseId` é obrigatório no schema Prisma.
- `resolveSessionExercise` atual exige exercício já presente na sessão template — incompatível com histórico colado sem plano.
- Cardio/rest já permitem `sessionId: null`; training importado precisa de âncora técnica sem forçar o usuário a escolher Push/Pull/Legs para cada bloco de WhatsApp.

**Alternatives considered**:
| Alternativa | Por que rejeitada |
|-------------|-------------------|
| Exigir `SessionPickerSheet` por sessão importada | UX ruim para bulk histórico; spec assume datas incertas |
| `sessionExerciseId` nullable em `SerieLog` | Migração invasiva; quebra invariantes de sync e edição |
| Um `WorkoutSession` por texto sem séries estruturadas | Não atende FR-020/FR-021 |

**UX**: Usuário **não** vê a rotina oculta; treinos aparecem no histórico como manuais (`isManual: true`). Opcional na revisão: vincular a rotina/sessão real se o usuário quiser (P3/futuro).

---

## R3 — Rastreabilidade do texto original

**Decision**: Nova entidade PostgreSQL `WorkoutTextImport` (Prisma) com `rawText`, `userId`, `status`, `parsedSnapshot` (JSON), timestamps. Cada `WorkoutSession` confirmada referencia `importId` (campo opcional `importId` em `WorkoutSession` ou tabela de junção `WorkoutTextImportSession`).

**Rationale**: FR-004, FR-018, FR-023 e SC-003 exigem texto original recuperável após salvamento.

**Alternatives considered**:
| Alternativa | Por que rejeitada |
|-------------|-------------------|
| Só Drift local | Perde rastreio após sync em outro device |
| `notes` do workout com texto inteiro | Limite de campo, mistura domínio com auditoria |

**Retenção**: texto original mantido indefinidamente (mesmo critério de histórico de treino); sem purge automático na v1.

---

## R4 — Mapeamento tipo de esforço → modelo existente

**Decision**: Mapear domínio da spec para campos já existentes em `SerieLog`:

| Spec (tipo de esforço) | Persistência |
|------------------------|--------------|
| leve / aquecimento | `label: "Warm-up"`, `setType: "warmup"` |
| preparatória | `label: "Feeder"`, `setType: "feeder"` |
| válida | `label: "Top Set"` ou null, `setType: "work"` |
| falha | `isFailure: true`, `setType: "failure"` |
| incerto | `setType: "uncertain"` + flag `uncertain` no JSON de revisão |

Anotações subjetivas → `exerciseNotes` (exercício) ou `rirNote` (série) conforme contexto; overflow → `WorkoutSession.notes` + trecho preservado em `WorkoutTextImport`.

**Rationale**: Evita migração de schema; alinha com `CreateWorkoutDto.label[]` e campos Drift `setType`/`isFailure` já gerados.

---

## R5 — Rascunho de importação no cliente (offline / revisão)

**Decision**: Tabela Drift `WorkoutImportDrafts` no Flutter — espelha padrão `WorkoutDrafts` (005): texto original, snapshot JSON da sugestão + edições do usuário, `status: parsing | reviewing | confirming | discarded`.

**Rationale**:
- FR: usuário fecha app durante revisão → recuperar rascunho.
- Parse exige rede; texto colado fica local até sucesso do parse.
- Confirm escreve Drift primeiro (`pendingSync`) depois POST batch — offline-first.

**Alternatives considered**:
| Alternativa | Por que rejeitada |
|-------------|-------------------|
| Estado só em memória Riverpod | Perde revisão ao kill do app |
| Draft só no servidor | Offline-first violado na etapa de revisão |

---

## R6 — Limite de tamanho do texto

**Decision**: Máximo **16.000 caracteres** por importação na v1 (~4–8 treinos típicos de WhatsApp).

**Rationale**: Balanceia UX (textarea único), timeout Gemini e tamanho de payload. Textos maiores: mensagem orientando dividir em partes (edge case da spec).

---

## R7 — Ponto de entrada na UI

**Decision**: Ação **"Importar de texto"** no `WorkoutHistoryPage` (app bar ou FAB secundário) → rota GoRouter `/workout/import` → após parse `/workout/import/review/:draftId`.

**Rationale**: Spec assume importação para histórico de execução; página de histórico já é o hub de treinos passados. Evita poluir Home.

---

## R8 — Confirmação e criação de treinos

**Decision**: `POST /workout-import/confirm` recebe array de sessões validadas pelo usuário; backend executa `$transaction` criando N `WorkoutSession` + séries (reuso `buildExerciseSeries` / `persistExerciseSeries` com resolver estendido para import).

**Rationale**: Uma round-trip para múltiplas sessões; atomicidade por confirmação; cliente não chama N× `POST /workout` manualmente.

**Alternatives considered**:
| Alternativa | Por que rejeitada |
|-------------|-------------------|
| N× `POST /workout` existente | Exige routineId/sessionId por chamada; sem `importId` linkage |
| Só persistência local | Histórico não disponível em outro device sem sync backend |

---

## R9 — Relação com `VoiceToWorkoutParser`

**Decision**: **Não estender** o parser rule-based para este fluxo. Manter `VoiceToWorkoutParser` apenas para input de voz em `workout_day` (legado). Testes de regressão do parser permanecem; import usa contrato API novo.

**Rationale**: Escopos diferentes (voz ao vivo vs bulk histórico); unificar aumentaria acoplamento sem ganho na v1.

---

## R10 — Catálogo de exercícios na interpretação

**Decision**: Prompt inclui lista resumida de nomes do catálogo (top match / fuzzy hints) como **referência opcional** para a IA; nomes não encontrados permanecem como texto com `exerciseMatchConfidence: low`. Na confirmação, backend usa `exercises/find-or-create` para IDs reais.

**Rationale**: FR-005 (não inventar) + User Story 5 (nomes informais). Find-or-create já existe e usa Gemini só quando necessário.
