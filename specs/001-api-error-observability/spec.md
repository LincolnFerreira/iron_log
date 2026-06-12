# Feature Specification: Observabilidade de Erros (API, UI e Crashlytics)

**Feature Branch**: `001-api-error-observability`

**Created**: 2026-06-11

**Status**: Draft

**Input**: User description: "Integrar firebase_crashlytics ^5.2.3 se ainda não estiver completo; registrar log JSON de qualquer erro de API; retenção de 7 dias com purge automático; configurar ErrorWidget.builder; atuar no workspace como um todo; banco de produção é único e proibido apagar dados ou o banco."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Registro persistente de falhas de API (Priority: P1)

Como usuário do Iron Log, quando uma chamada à API falha (timeout, sem rede, 4xx, 5xx ou resposta inválida), quero que o app registre automaticamente um histórico estruturado do incidente para que a equipe possa diagnosticar problemas sem depender apenas de relatos vagos.

**Why this priority**: Falhas de API impactam sync, treinos e login — sem registro local estruturado, erros intermitentes (especialmente offline) são impossíveis de reproduzir.

**Independent Test**: Simular falhas de API (401, 500, timeout) e verificar que cada incidente gera um registro JSON consultável localmente com método, rota, status/código de erro, timestamp e corpo/resumo da resposta quando existir.

**Acceptance Scenarios**:

1. **Given** o usuário autenticado e o app online, **When** a API retorna erro 500 com corpo JSON, **Then** o app grava um registro com timestamp, endpoint, status, payload de erro serializado e tipo de falha.
2. **Given** o usuário sem conectividade, **When** uma requisição falha por timeout ou connection error, **Then** o app grava registro equivalente indicando falha de rede (sem depender de resposta HTTP).
3. **Given** qualquer erro de API tratado pelo pipeline central de HTTP, **When** o interceptor conclui o tratamento, **Then** o registro é persistido uma única vez por requisição falha (sem duplicatas por retry automático na mesma tentativa).

---

### User Story 2 - Crashlytics completo para erros fatais e de API (Priority: P1)

Como equipe de produto, quero que erros críticos do app (incluindo falhas de API relevantes) sejam enviados ao Firebase Crashlytics com contexto suficiente para priorizar correções em produção.

**Why this priority**: O app já usa Crashlytics parcialmente; a feature deve completar e padronizar a integração (incluindo versão atualizada do SDK) para que erros não fiquem só no console em debug.

**Independent Test**: Forçar erro fatal e erro de API; confirmar eventos no console Firebase Crashlytics com breadcrumbs ou custom keys (endpoint, status) em builds release.

**Acceptance Scenarios**:

1. **Given** build release em dispositivo físico, **When** ocorre exceção não tratada na UI ou zone guard, **Then** Crashlytics recebe o stack trace como fatal.
2. **Given** build release, **When** ocorre erro de API não recuperável (ex.: 500 repetido ou erro inesperado), **Then** Crashlytics recebe evento não fatal com metadados da requisição (sem token de autenticação).
3. **Given** dependência Crashlytics desatualizada no projeto, **When** a feature for entregue, **Then** o pacote está na versão ^5.2.3 (ou compatível resolvida pelo pub) e a inicialização permanece funcional em Android e iOS.

---

### User Story 3 - Tela amigável quando um widget quebra (Priority: P2)

Como usuário, quando um widget falha ao renderizar, quero ver uma mensagem clara em português e opção de continuar usando o app, em vez de tela vermelha de debug ou app travado.

**Why this priority**: Erros de build em produção destroem confiança; `ErrorWidget.builder` padroniza recuperação e alimenta Crashlytics.

**Independent Test**: Injetar widget que lança exceção no build; verificar UI customizada, registro no Crashlytics e que o restante do app permanece utilizável quando possível.

**Acceptance Scenarios**:

1. **Given** app em release, **When** um widget filho lança exceção no build, **Then** o usuário vê fallback visual alinhado ao tema Iron Log (mensagem amigável, sem stack trace).
2. **Given** falha de build de widget, **When** o fallback é exibido, **Then** o erro é reportado ao Crashlytics com contexto do widget/rota quando disponível.
3. **Given** app em modo debug, **When** ocorre erro de build, **Then** desenvolvedores ainda podem inspecionar detalhes (console ou overlay de debug) sem expor stack ao usuário final em release.

---

### User Story 4 - Retenção e limpeza automática de logs locais (Priority: P2)

Como usuário, quero que o histórico de erros de API no dispositivo não cresça indefinidamente; registros com mais de 7 dias devem ser removidos automaticamente.

**Why this priority**: Logs JSON acumulados consomem armazenamento e podem reter dados sensíveis além do necessário.

**Independent Test**: Inserir registros com datas artificiais (>7 dias) e executar rotina de purge; confirmar que apenas entradas expiradas são removidas.

**Acceptance Scenarios**:

1. **Given** registros com idade superior a 7 dias, **When** o app inicia ou executa rotina de manutenção agendada, **Then** esses registros são apagados do armazenamento local de logs.
2. **Given** registros dentro do prazo de 7 dias, **When** a rotina de purge roda, **Then** nenhum registro válido é removido.
3. **Given** política de retenção configurável no futuro, **When** implementado v1, **Then** o valor padrão é 7 dias documentado como constante ajustável sem migration de banco de produção.

---

### Edge Cases

- Requisição falha antes de enviar body: registrar URL, método e tipo Dio/network sem corpo de resposta.
- Resposta muito grande: registrar truncamento com indicador de tamanho original (evitar estourar SQLite local).
- Token Bearer ou headers sensíveis: MUST NOT aparecer nos logs nem no Crashlytics.
- Usuário deslogado: logs locais ainda funcionam; Crashlytics pode usar identificador anônimo de instalação.
- Web (se build web existir): Crashlytics pode ser no-op ou limitado — registrar localmente quando remote não disponível.
- Purge durante sync offline: purge só afeta tabela local de logs; nunca toca dados de treino/rotina nem banco PostgreSQL de produção.
- Erro 401 em loop: deduplicar ou rate-limit reportes Crashlytics para não inundar dashboard.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O app MUST interceptar todas as falhas de requisição HTTP/API no pipeline central existente e disparar registro estruturado.
- **FR-002**: Cada registro de erro de API MUST conter no mínimo: identificador único, timestamp UTC, método HTTP, path/URL relativa, código ou tipo de erro, e payload JSON serializado quando houver resposta.
- **FR-003**: Registros MUST ser persistidos apenas no armazenamento local do dispositivo (offline-first); MUST NOT criar tabelas nem migrations no banco PostgreSQL de produção para esta feature.
- **FR-004**: O sistema MUST NOT executar DELETE, DROP ou truncate em dados de produção (PostgreSQL); purge aplica-se exclusivamente aos logs locais de erro.
- **FR-005**: O app MUST remover automaticamente registros de erro local com idade superior a 7 dias.
- **FR-006**: A retenção de 7 dias MUST ser configurável via constante interna sem exigir alteração de schema de produção.
- **FR-007**: O app MUST garantir integração Firebase Crashlytics atualizada para ^5.2.3, mantendo captura de erros fatais já existente em `main.dart` e estendendo para erros de API e de widget.
- **FR-008**: Erros de API enviados ao Crashlytics MUST ser não fatais por padrão, exceto quando classificados como corrupção crítica de estado.
- **FR-009**: O app MUST configurar `ErrorWidget.builder` global com UI amigável pt-BR em release e reporte ao Crashlytics.
- **FR-010**: Logs e reportes MUST sanitizar dados sensíveis (Authorization, tokens, senhas, PII desnecessária).
- **FR-011**: Mensagens exibidas ao usuário (snackbar/toast existente) MUST continuar usando textos amigáveis; o registro JSON é complementar para diagnóstico.
- **FR-012**: A feature MUST funcionar em flavor prod e dev; coleta Crashlytics em prod/release conforme política atual (`!kDebugMode`).

### Key Entities

- **ApiErrorLog**: Registro local de incidente de API — timestamp, método, path, status/tipo, body JSON (ou truncado), userId opcional (Firebase UID hash ou anon), appVersion, flavor.
- **ErrorReport**: Evento enviado ao Crashlytics — mensagem, stack quando aplicável, custom keys (endpoint, status), fatal vs non-fatal.
- **RetentionPolicy**: Regra de 7 dias para purge de `ApiErrorLog` local.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% das falhas de API simuladas em testes (401, 404, 500, timeout) geram registro JSON local consultável em até 2 segundos após a falha.
- **SC-002**: Após 7 dias simulados, 100% dos registros expirados são removidos em uma execução de purge sem afetar registros mais recentes.
- **SC-003**: Em build release, erros fatais de widget exibem fallback amigável em português em 100% dos casos testados (sem tela vermelha padrão Flutter).
- **SC-004**: Zero ocorrências de token de autenticação em amostra auditada de 50 logs gerados em testes.
- **SC-005**: Equipe consegue identificar endpoint e status de erro no dashboard Crashlytics para ≥90% dos erros de API reportados em testes de integração.

## Assumptions

- Crashlytics já está parcialmente configurado (Firebase, Gradle, `main.dart`); a feature completa e atualiza o SDK, não inicia do zero.
- Histórico JSON de erros de API fica no SQLite local (Drift), separado do schema Prisma/PostgreSQL de produção.
- Não há requisito de UI para o usuário final consultar logs (v1 = persistência + purge + Crashlytics); tela de diagnóstico para devs é out of scope.
- Retenção de 7 dias aplica-se apenas a logs de erro de API locais, não a dados de treino, rotinas ou histórico do usuário.
- Backend NestJS não precisa de nova tabela em produção para v1; erros server-side continuam no log do servidor Render/local.
- Purge roda no startup do app e opcionalmente após sync bem-sucedido (detalhe de implementação).
- iOS e Android são targets; web trata Crashlytics de forma degradada se SDK não suportar.
- Versão ^5.2.3 de `firebase_crashlytics` pode exigir bump coordenado de `firebase_core` — resolvido na fase de plano sem alterar escopo funcional.

## Out of Scope

- Painel admin web para visualizar logs de todos os usuários.
- Alterações de schema ou migrations no PostgreSQL de produção.
- Apagar ou arquivar dados de treino, rotinas ou usuários.
- Aumentar retenção além de 7 dias na v1 (previsto como ajuste futuro de constante).
- Substituir Sentry ou outras ferramentas APM no backend.
