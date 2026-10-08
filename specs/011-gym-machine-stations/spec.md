# Feature Specification: Academia e Estação da Máquina

**Feature Branch**: `011-gym-machine-stations`

**Created**: 2026-10-07

**Status**: Draft

**Input**: User description: "O mesmo movimento é feito em máquinas diferentes (a primeira, a preta, a da ponta) e em academias diferentes, e a carga muda conforme a máquina. O histórico e a sugestão tratam tudo como um exercício só. A mudança deve ser leve: a rotina continua escolhendo o movimento; na execução a pessoa indica a academia e a máquina, para o histórico e a carga sugerida acompanharem aquela estação."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Marcar a máquina e ver a última carga dela (Priority: P1)

Como pessoa que faz o mesmo movimento em máquinas diferentes da academia, quero indicar qual máquina usei neste treino e ver a última carga daquela máquina, para não misturar a pilha da “preta” com a da “ponta”.

**Why this priority**: É o problema do dia a dia. Sem separar a máquina, o histórico e o ponto de partida da carga ficam errados mesmo para quem treina sempre no mesmo lugar.

**Independent Test**: Registrar o mesmo movimento duas vezes, cada vez numa estação com apelido diferente e cargas diferentes. Ao abrir de novo com a primeira estação selecionada, a “última vez” mostra só a carga daquela estação.

**Acceptance Scenarios**:

1. **Given** um treino em execução com um movimento de máquina, cabo ou Smith, **When** a pessoa abre o controle de estação, **Then** vê até as três estações mais recentes daquele movimento no lugar atual e um campo curto para criar outra pelo apelido, sem uma segunda busca no catálogo de exercícios.
2. **Given** a pessoa escolhe ou cria uma estação, **When** o treino é salvo, **Then** todas as séries daquele movimento naquele treino ficam ligadas à mesma estação, e a rotina planejada continua com o movimento uma única vez.
3. **Given** o movimento já foi feito antes na estação “preta”, **When** a pessoa inicia o treino de novo, **Then** a estação “preta” já vem selecionada e a “última vez” mostra reps e carga só dessa estação.
4. **Given** a estação escolhida nunca foi usada, **When** a pessoa olha a última vez e a carga sugerida, **Then** o app não usa o número de outra máquina como se fosse desta; pode apenas informar que o movimento já foi feito em outra máquina.
5. **Given** um movimento de barra, haltere, anilha, elástico ou peso corporal, **When** a pessoa executa o treino, **Then** não aparece pedido de estação.
6. **Given** um treino já salvo com a estação errada, **When** a pessoa edita esse treino e troca a estação, **Then** os treinos seguintes usam a estação corrigida ao calcular a última vez.
7. **Given** a pessoa escolheu academia e estação sem conexão, **When** o treino é guardado e depois enviado, **Then** academia e estação continuam no treino e no histórico.
8. **Given** uma estação selecionada, **When** a pessoa limpa a estação de propósito, **Then** a “última vez” volta ao desempenho mais recente daquele movimento, em qualquer máquina.

---

### User Story 2 - Separar academias (Priority: P2)

Como pessoa que treina em mais de um lugar, quero associar o treino a uma academia, para que a máquina “preta” de um lugar não se misture com a “preta” de outro.

**Why this priority**: A estação sozinha resolve várias máquinas no mesmo lugar. A academia entra quando o mesmo apelido, ou a mesma sensação de carga, não vale em outro endereço.

**Independent Test**: Criar duas academias, registrar o mesmo movimento com o mesmo apelido de estação em cada uma e cargas diferentes. Com a primeira academia selecionada, a última vez não mostra a carga da segunda.

**Acceptance Scenarios**:

1. **Given** a pessoa tem mais de uma academia, **When** inicia um treino, **Then** pode escolher o lugar, e o app lembra o último lugar usado.
2. **Given** a pessoa tem só uma academia, **When** inicia um treino, **Then** não é obrigada a escolher nem a nomear o lugar para usar estações.
3. **Given** duas academias e o mesmo apelido de estação no mesmo movimento, **When** a pessoa treina em cada lugar, **Then** são duas estações distintas, cada uma com o próprio histórico.
4. **Given** a pessoa nunca criou uma academia, **When** cria a primeira estação, **Then** consegue usá-la sem cadastrar um lugar.

---

### User Story 3 - Sugestão de carga da máquina escolhida (Priority: P3)

Como pessoa que segue a carga sugerida, quero que a sugestão olhe só o histórico da estação selecionada, para o app não mandar subir carga com base numa máquina mais leve ou mais pesada.

**Why this priority**: A sugestão errada é consequência direta do histórico misturado. Só faz sentido depois que a estação existe e tem registros próprios.

**Independent Test**: Ter histórico recente em duas estações do mesmo movimento, com cargas bem diferentes. Abrir o treino com cada estação e conferir que a carga sugerida muda junto com a estação e não repete o número da outra.

**Acceptance Scenarios**:

1. **Given** uma estação com histórico de séries válidas, **When** ela está selecionada, **Then** a carga sugerida e o peso inicial do movimento saem só desse histórico.
2. **Given** uma estação sem histórico, **When** ela está selecionada, **Then** a sugestão informa que ainda não há histórico naquela máquina e não propõe a carga de outra estação como meta.
3. **Given** um movimento sem nenhuma estação e sem estação selecionada, **When** a pessoa treina, **Then** a última vez e a sugestão continuam como hoje, usando o desempenho mais recente daquele movimento.

---

### User Story 4 - Ajustar o nome das máquinas (Priority: P2)

Como pessoa que apelidou a máquina às pressas, quero renomear ou esconder uma estação, para a lista continuar curta e o histórico antigo não perder o nome.

**Why this priority**: A lista de três recentes só presta se a pessoa puder corrigir um apelido ruim sem apagar o passado. Não bloqueia o primeiro treino com estação.

**Independent Test**: Criar uma estação, registrar um treino, renomear a estação e confirmar que o treino antigo mostra o nome novo. Ocultar outra estação e confirmar que ela some da escolha e o treino antigo ainda mostra o nome.

**Acceptance Scenarios**:

1. **Given** uma estação já usada em treinos, **When** a pessoa renomeia o apelido, **Then** os treinos que a usaram passam a mostrar o nome novo.
2. **Given** uma estação que a pessoa não quer mais ver, **When** ela oculta a estação, **Then** a estação sai das próximas escolhas e os treinos já registrados continuam exibindo o nome.

---

### Edge Cases

- Trocar a estação no meio do treino atualiza o movimento inteiro naquele treino, não só a série da vez.
- Limpar a estação de propósito volta a “última vez” para o desempenho mais recente do movimento, em qualquer máquina.
- Treinos gravados antes desta feature permanecem sem estação. Eles não são atribuídos sozinhos a uma máquina nova e continuam visíveis quando nenhuma estação está selecionada.
- Renomear uma estação atualiza o nome nos treinos passados que já a usavam.
- Ocultar uma estação tira ela da lista de escolha; os treinos antigos continuam mostrando o nome.
- O apelido cabe num chip de uma linha; nomes longos são limitados e cortados na exibição.
- Sem conexão no momento do treino, a academia e a estação escolhidas permanecem no treino e entram no histórico quando os dados forem enviados.
- Cardio e descanso não pedem estação.
- Movimento cujo tipo de equipamento é desconhecido não obriga estação.
- Fazer o mesmo movimento em duas máquinas no mesmo treino não é suportado: cada ocorrência planejada do movimento tem uma estação por treino.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O sistema MUST permitir ligar uma estação a um movimento durante a execução do treino, sem alterar o exercício planejado na rotina.
- **FR-002**: A estação escolhida MUST valer para todas as séries daquele movimento naquele treino.
- **FR-003**: Movimentos de máquina, cabo ou Smith MUST oferecer o controle de estação. Movimentos de barra, haltere, anilha, elástico e peso corporal MUST NOT pedir estação.
- **FR-004**: Movimento com tipo de equipamento desconhecido MUST NOT exigir estação.
- **FR-005**: A lista de estações MUST mostrar no máximo as três mais recentes daquele movimento no lugar atual, mais um campo para criar outra com apelido curto, sem abrir outra busca de exercício.
- **FR-006**: Criar estação MUST exigir só o apelido. Marca e observação são opcionais e em texto livre. O sistema MUST NOT oferecer um catálogo de marcas ou modelos.
- **FR-007**: Se o movimento já tiver estação usada na academia atual (ou a última estação, quando não houver academia), o treino MUST pré-selecionar essa estação.
- **FR-008**: Com uma estação selecionada, a “última vez” MUST usar apenas treinos anteriores da mesma estação.
- **FR-009**: Estação sem histórico MUST NOT herdar carga de outra estação como última vez nem como sugestão. O sistema MAY informar, em separado, que o movimento já ocorreu em outra máquina.
- **FR-010**: Sem estação selecionada e sem estações criadas para o movimento, a última vez e a sugestão MUST permanecer o comportamento atual: o desempenho mais recente daquele movimento.
- **FR-011**: Treinos anteriores a esta feature MUST permanecer sem estação e MUST NOT ser atribuídos automaticamente a uma estação criada depois.
- **FR-012**: A pessoa MUST poder dar nome às academias onde treina. Um treino MUST poder estar ligado a uma academia, e o app MUST lembrar a última academia usada.
- **FR-013**: Com uma única academia, o início do treino MUST NOT obrigar a escolha nem o cadastro do lugar.
- **FR-014**: O mesmo apelido de estação no mesmo movimento em academias diferentes MUST ser tratado como estações distintas.
- **FR-015**: A pessoa MUST poder criar e usar estação sem nunca cadastrar uma academia.
- **FR-016**: A carga sugerida e o peso inicial, quando houver estação selecionada, MUST considerar só o histórico dessa estação.
- **FR-017**: Renomear uma estação MUST atualizar o nome exibido nos treinos que já a usaram.
- **FR-018**: Ocultar uma estação MUST tirá-la das próximas escolhas e MUST manter o nome visível no histórico já registrado.
- **FR-019**: Trocar a estação durante o treino, ou ao editar um treino passado, MUST atualizar o bloco inteiro daquele movimento naquele treino.
- **FR-020**: A rotina MUST continuar listando cada movimento uma vez. Esta feature MUST NOT exigir um exercício duplicado para distinguir máquinas.
- **FR-021**: Academia e estação escolhidas MUST permanecer no treino mesmo sem conexão, e MUST seguir com o treino quando ele for enviado.
- **FR-022**: A pessoa MUST poder limpar a estação. Nesse caso, a última vez volta ao desempenho mais recente do movimento, independentemente da máquina.
- **FR-023**: Cada ocorrência planejada de um movimento MUST ter no máximo uma estação por treino.

### Key Entities

- **Academia**: Lugar onde a pessoa treina. Tem nome e pertence à pessoa. Um treino pode apontar para uma academia.
- **Estação**: Apelido que a pessoa dá a uma máquina física de um movimento, opcionalmente dentro de uma academia. Pode ter marca e observação em texto livre. Guarda o próprio histórico de carga.
- **Treino executado**: Pode estar ligado a uma academia. Cada movimento registrado nele pode estar ligado a uma estação, compartilhada por todas as séries daquele movimento.
- **Movimento planejado**: Continua sendo o exercício da rotina. Não vira uma linha por máquina.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A pessoa escolhe uma estação recente em até dois toques, ou cria uma nova digitando o apelido e confirmando, em menos de 15 segundos.
- **SC-002**: Depois de registrar o mesmo movimento em duas estações com cargas diferentes, a “última vez” com a primeira estação selecionada nunca mostra a carga da segunda.
- **SC-003**: A carga sugerida com uma estação selecionada vem só do histórico dessa estação, ou deixa claro que aquela máquina ainda não tem histórico.
- **SC-004**: Quem treina em um único lugar registra estações sem ser obrigado a nomear a academia.
- **SC-005**: Movimentos de barra e haltere no treino não exibem pedido de estação.
- **SC-006**: Treinos já existentes, sem estação, continuam mostrando uma “última vez” do movimento quando nenhuma estação está selecionada.
- **SC-007**: A rotina da pessoa continua com cada movimento uma vez; distinguir máquinas não exige criar outro exercício.

## Assumptions

- O valor principal é “o que eu coloquei nesta máquina da última vez”, não comparar pilhas diferentes numa carga equivalente.
- Catálogo global de marcas, fator de polia, gráfico de carga equivalente entre máquinas e duas linhas do mesmo movimento na mesma rotina ficam fora desta versão.
- A estação só é pedida quando o número do equipamento não é comparável entre aparelhos: máquina, cabo e Smith. Barra, haltere e peso corporal seguem o fluxo atual.
- Quem tem uma academia só, ou nenhuma cadastrada, usa estação direto. O seletor de academia aparece quando existe mais de um lugar.
- A última estação usada naquele movimento e naquele lugar vem pré-selecionada, para o caso comum não exigir escolha toda vez.
- Histórico antigo permanece num grupo “sem estação”. Só entra numa máquina se a pessoa editar o treino e escolher a estação.
- Marca é texto opcional na estação (“Life Fitness”, “preta”), não uma lista fechada.
- Cardio e descanso não participam desta feature.
- Fazer o mesmo movimento em duas máquinas no mesmo treino fica fora: a pessoa registra uma estação por movimento naquele treino e, se trocar de máquina, atualiza a estação do bloco.
- Academias e estações são pessoais. Uma pessoa não vê as máquinas de outra.
