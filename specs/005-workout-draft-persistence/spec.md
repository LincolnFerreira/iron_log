# Feature Specification: Persistência de Rascunhos de Treino

**Feature Branch**: `005-workout-draft-persistence`

**Created**: 2026-06-22

**Status**: Draft

**Input**: User description: "Preciso que mesmo que dê erro a requisição de workout, precisa salvar isso como um rascunho localmente e não apagar de maneira alguma para que o usuário possa recuperar isso caso o app feche. Manter o rascunho diante do fluxo já feito atual no app, recuperar o estado da tela de workout caso queira voltar, e na home colocar botão 'Continuar' onde hoje é 'Começar treino' quando ainda não finalizou. O usuário pode finalizar um rascunho (ficando local aguardando envio) ou mantê-lo em andamento ('fazendo')."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Salvar treino quando a API falha (Priority: P1)

Como usuário que acabou de registrar um treino (iniciar, finalizar ou editar), quero que meus dados sejam guardados localmente mesmo quando o servidor rejeitar ou não responder à requisição, para não perder o trabalho que fiz na academia.

**Why this priority**: É o cenário central — falha na API hoje pode significar perda total dos dados do treino. Sem isso, a proposta offline-first do produto fica comprometida.

**Independent Test**: Simular falha de API (sem rede, erro 500 ou validação 400) ao finalizar um treino com exercícios e séries preenchidas; verificar que os dados permanecem acessíveis localmente e que o usuário recebe feedback claro de que o treino foi salvo como rascunho pendente.

**Acceptance Scenarios**:

1. **Given** um treino em execução com séries registradas, **When** o usuário finaliza e a API retorna erro (qualquer tipo: rede, servidor ou validação), **Then** o conteúdo completo do treino é persistido localmente como rascunho e o usuário é informado que o envio falhou mas os dados estão seguros.
2. **Given** um treino retroativo preenchido manualmente, **When** a tentativa de salvar falha, **Then** o rascunho local contém data, duração, exercícios, séries, pesos, repetições e observações informadas.
3. **Given** um rascunho pendente de envio, **When** a API volta a funcionar e o usuário solicita reenvio (ou o app tenta automaticamente), **Then** o treino é enviado com sucesso e o rascunho é marcado como concluído — sem duplicar o treino no histórico.

---

### User Story 2 - Continuar treino em andamento pela Home (Priority: P1)

Como usuário com um treino não finalizado, quero ver na tela inicial um botão **“Continuar”** no lugar (ou em destaque junto) ao fluxo de **“Começar treino”**, para retomar rapidamente o que estava fazendo sem procurar em menus.

**Why this priority**: É o ponto de entrada natural do app hoje; o usuário espera voltar ao treino pelo mesmo lugar de onde costuma iniciar. Integra o rascunho ao fluxo existente da Home.

**Independent Test**: Iniciar treino, registrar séries, sair da tela de execução sem finalizar, voltar à Home e verificar que o card do treino do dia oferece “Continuar” em vez de apenas “Começar treino”; ao tocar, reabre a execução.

**Acceptance Scenarios**:

1. **Given** existe exatamente um rascunho em status **em andamento** para a sessão/rotina do dia, **When** o usuário abre a Home, **Then** o card principal do treino exibe ação **“Continuar”** (substituindo ou priorizando sobre “Começar treino”) com indicação visual de treino incompleto.
2. **Given** não existe rascunho em andamento, **When** o usuário abre a Home, **Then** o fluxo permanece como hoje com **“Começar treino”** (ou equivalente atual).
3. **Given** o usuário toca em **“Continuar”**, **When** a navegação conclui, **Then** ele é levado de volta à tela de execução de treino com o mesmo contexto (sessão, rotina, modo ao vivo ou manual) que tinha ao sair.

---

### User Story 3 - Recuperar estado completo da tela de workout (Priority: P1)

Como usuário que voltou a um rascunho em andamento, quero que a tela de treino seja restaurada como eu deixei — exercícios, séries já registradas, ordem, timer quando aplicável — para continuar registrando sem recomeçar do zero.

**Why this priority**: Persistir dados no dispositivo não basta se a experiência de retomada não reflete o estado da última sessão de uso. O usuário pediu explicitamente recuperar o estado da tela de workout.

**Independent Test**: Registrar séries em dois exercícios, alterar ordem se possível, sair do app, reabrir via “Continuar” e validar que lista de exercícios, valores das séries e progresso visual correspondem ao momento da saída.

**Acceptance Scenarios**:

1. **Given** um rascunho em andamento com séries parcialmente preenchidas, **When** o usuário retoma pela Home ou após reabrir o app, **Then** a tela de execução exibe os mesmos exercícios, ordem e valores de séries já informados.
2. **Given** um treino ao vivo com timer em curso antes da interrupção, **When** o usuário retoma, **Then** o tempo decorrido é restaurado de forma coerente (continuar de onde parou ou exibir duração acumulada já registrada no rascunho).
3. **Given** o usuário estava em modo retroativo (data manual), **When** retoma o rascunho, **Then** a data e o modo manual permanecem como no rascunho salvo.

---

### User Story 4 - Finalizar rascunho ou mantê-lo em andamento (Priority: P1)

Como usuário com um rascunho, quero poder **seguir treinando** (mantendo status em andamento) **ou finalizar** o treino (passando para aguardando envio local), para escolher o momento certo de encerrar sem perder a flexibilidade do fluxo atual.

**Why this priority**: O usuário deixou claro que finalizar e manter local é válido, mas também deve poder continuar “fazendo” o treino. São dois estados distintos do mesmo rascunho.

**Independent Test**: Criar rascunho em andamento → opção A: sair e voltar ainda em andamento; opção B: finalizar com API falhando → rascunho muda para aguardando envio mas permanece no dispositivo.

**Acceptance Scenarios**:

1. **Given** um rascunho **em andamento**, **When** o usuário sai da tela de treino sem finalizar, **Then** o rascunho permanece em andamento e **“Continuar”** continua disponível na Home.
2. **Given** um rascunho **em andamento**, **When** o usuário aciona finalizar (com sucesso ou falha de API), **Then** o rascunho passa para status **aguardando envio** (finalizado localmente), deixa de aparecer como “em andamento” na Home, mas os dados permanecem salvos para reenvio.
3. **Given** um rascunho **aguardando envio**, **When** o usuário acessa a lista ou detalhe de pendentes, **Then** ele pode reenviar ao servidor mas **não** é tratado como treino ainda em execução (sem botão “Continuar” na Home para esse item, salvo se reabrir explicitamente para edição conforme fluxo de edição existente).

---

### User Story 5 - Reenviar rascunhos quando a API estiver corrigida (Priority: P2)

Como usuário, quero que treinos finalizados localmente (aguardando envio) possam ser enviados depois, para que o histórico fique completo sem retrabalho.

**Why this priority**: Complementa a finalização local quando a API está instável.

**Independent Test**: Finalizar treino com API indisponível, restaurar API, acionar reenvio e validar histórico.

**Acceptance Scenarios**:

1. **Given** um ou mais rascunhos aguardando envio, **When** o usuário aciona reenvio, **Then** o app tenta enviar e atualiza o status conforme o resultado.
2. **Given** reenvio bem-sucedido, **When** o servidor confirma, **Then** o rascunho deixa a lista de pendentes.
3. **Given** reenvio que falha novamente, **When** a API ainda está com problema, **Then** o rascunho permanece intacto.

---

### User Story 6 - Salvamento contínuo durante a execução (Priority: P2)

Como usuário registrando séries durante o treino, quero que cada progresso relevante seja guardado automaticamente no dispositivo, para minimizar perda mesmo antes de clicar em “finalizar”.

**Why this priority**: Alimenta as stories de “Continuar” e recuperação de tela — o rascunho precisa refletir o estado atual enquanto o usuário ainda está “fazendo”.

**Independent Test**: Registrar séries, simular encerramento do app sem finalizar, reabrir via “Continuar” e verificar séries preservadas.

**Acceptance Scenarios**:

1. **Given** um treino em execução, **When** o usuário registra ou altera séries, **Then** o progresso é persistido localmente em tempo hábil, sem ação manual de “salvar”.
2. **Given** salvamento contínuo ativo, **When** ocorre falha de rede durante o treino, **Then** o usuário continua registrando e o rascunho em andamento é atualizado.

---

### Edge Cases

- Existe no máximo **um** rascunho **em andamento** por usuário por vez; se o usuário tentar iniciar outro treino, o app deve orientar (continuar o atual ou encerrar/descartar com confirmação — política de descarte explícito fica fora do escopo mínimo).
- Rascunho **em andamento** de ontem + treino do dia de hoje: **“Continuar”** na Home prioriza o rascunho em andamento; treino do dia pode aparecer com indicação secundária ou em outra área de pendentes.
- Múltiplos rascunhos **aguardando envio**: listados separadamente do treino em andamento; Home foca em “Continuar” só para em andamento.
- Erro de validação na API: rascunho mantido; usuário pode corrigir dados na tela antes de novo envio quando em andamento, ou via fluxo de edição quando já finalizado localmente.
- Payload corrompido: nunca descartar silenciosamente; informar o usuário.
- Troca de conta: rascunhos isolados por usuário; **“Continuar”** não aparece para rascunhos de outra conta.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O sistema MUST persistir localmente o conteúdo completo de um treino sempre que uma tentativa de envio ao servidor falhar, independentemente do tipo de falha.
- **FR-002**: O sistema MUST NOT apagar automaticamente rascunhos por falha de envio, expiração ou limpeza em background; remoção da lista de pendentes só após envio bem-sucedido confirmado pelo servidor.
- **FR-003**: O sistema MUST distinguir pelo menos dois status de rascunho: **em andamento** (usuário ainda pode treinar) e **aguardando envio** (finalizado localmente, pendente de sincronização).
- **FR-004**: O sistema MUST persistir o progresso de treinos em andamento de forma que sobreviva ao fechamento do app e permita restaurar o estado da tela de execução de treino.
- **FR-005**: Quando existir rascunho **em andamento**, a Home MUST oferecer ação **“Continuar”** integrada ao card de treino do dia (substituindo ou priorizando sobre “Começar treino”), alinhada ao fluxo visual atual do app.
- **FR-006**: Ao acionar **“Continuar”**, o sistema MUST reabrir a tela de execução de treino restaurando: lista de exercícios, ordem, séries registradas, contexto de sessão/rotina, modo (ao vivo vs. manual) e timer/duração quando aplicável.
- **FR-007**: O sistema MUST permitir que o usuário saia da tela de treino mantendo o rascunho **em andamento** (sem exigir finalização).
- **FR-008**: O sistema MUST permitir finalizar um rascunho em andamento; após finalização (com ou sem sucesso de API), o status MUST passar para **aguardando envio** enquanto os dados permanecem locais em caso de falha.
- **FR-009**: O sistema MUST informar claramente a diferença entre treino **em andamento**, **aguardando envio** e **sincronizado com sucesso**.
- **FR-010**: O sistema MUST armazenar metadados por rascunho: identificador local, usuário, início, status, tipo de operação pendente (criar/atualizar), referência à sessão/rotina, e snapshot suficiente para reconstruir a UI de execução.
- **FR-011**: O sistema MUST preservar exercícios, ordem, séries, pesos, repetições, técnicas, RIR, descanso e observações no rascunho.
- **FR-012**: O sistema MUST permitir reenvio manual de rascunhos aguardando envio e SHOULD tentar reenvio automático quando a API estiver disponível.
- **FR-013**: O sistema MUST evitar duplicação no histórico ao reenviar rascunhos que já possuem identificador remoto.
- **FR-014**: O sistema MUST isolar rascunhos por usuário autenticado.
- **FR-015**: O sistema SHOULD estender o fluxo de workout já existente no app (Home → execução → finalizar) em vez de criar jornada paralela desconectada; o usuário não precisa entender conceitos internos como “outbox” vs. “rascunho”.

### Key Entities

- **Rascunho de treino (Workout Draft)**: Representação local de um treino. Status principal: **em andamento** ou **aguardando envio**. Inclui snapshot de execução (exercícios, séries, UI) e contexto de navegação (sessão, rotina, modo).
- **Snapshot de tela de execução**: Estado serializável necessário para reconstruir a experiência da tela de treino ao retomar — não apenas o payload de envio ao servidor.
- **Item pendente de envio**: Porção do rascunho usada para reenvio após finalização local; associada a rascunhos em status aguardando envio.
- **Estado na Home**: Deriva da existência de rascunho em andamento — determina se o card exibe “Continuar” ou “Começar treino”.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Em testes com falha simulada de API, 100% das tentativas de salvar/finalizar resultam em rascunho local recuperável com todos os exercícios e séries informados.
- **SC-002**: Após sair ou encerrar o app com treino em andamento, o usuário retoma via **“Continuar”** com dados intactos em menos de 30 segundos.
- **SC-003**: Em 100% dos casos de retomada, a tela de execução exibe o mesmo conjunto de exercícios e séries registradas que existiam antes da interrupção (validação por checklist de campos visíveis ao usuário).
- **SC-004**: Usuários com rascunho em andamento veem **“Continuar”** na Home em até 2 interações (abrir app → tocar continuar) para voltar ao treino.
- **SC-005**: Rascunhos permanecem disponíveis por pelo menos 30 dias ou até envio bem-sucedido, sem remoção automática por falha.
- **SC-006**: Pelo menos 95% dos reenvios após restauração da API são aceitos sem duplicar histórico.

## Assumptions

- O escopo cobre treinos de musculação nos fluxos atuais (Home → tela de execução → finalizar); não inclui cardio, dias de descanso nem “salvar rascunho” do template de sessão no editor de rotina.
- A Home já possui card de treino do dia com botão de iniciar; **“Continuar”** reutiliza esse mesmo card e fluxo de navegação, alterando apenas a ação primária quando há rascunho em andamento.
- Por padrão, há no máximo um rascunho **em andamento** ativo por usuário; múltiplos rascunhos **aguardando envio** são permitidos.
- “Não apagar automaticamente” não impede remoção após sync bem-sucedido; descarte manual pelo usuário pode ser versão futura.
- Infraestrutura parcial existente (fila offline de workout, repositório local, providers em memória) será estendida — especialmente para persistir snapshot de UI e status em andamento, hoje ausentes.
- Reenvio automático em background é desejável; reenvio manual sempre disponível para rascunhos aguardando envio.

## Dependencies

- Fluxos atuais de Home, iniciar/executar/finalizar treino e navegação para tela de execução.
- Endpoints de criação e atualização de treino no backend (quando estáveis).
- Autenticação para associar rascunhos ao usuário.
