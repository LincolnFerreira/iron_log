# Research: Academia e Estação da Máquina

Decisões da Phase 0. Nenhum item do Technical Context ficou em aberto.

## 1. Onde vive a estação

**Decision**: A estação fica na execução. `WorkoutSession.gymId` (uma academia por treino) e `SerieLog.stationId` (o mesmo valor em todas as séries daquele movimento naquele treino). `SessionExercise` e `variation` não mudam.

**Rationale**: A rotina precisa continuar com um movimento só. `variation` hoje é técnica (`Traditional`) e nem é editável na execução. Gravar o id em cada série permite filtrar última vez e sugestão sem uma tabela nova de “bloco”, e a troca de estação reescreve o bloco inteiro na mesma transação que já regrava as séries.

**Alternatives considered**: Coluna em `SessionExercise` (mistura plano com a máquina do dia). Tabela `WorkoutExerciseContext` (fonte única, porém entidade e sync a mais para um campo que já viaja com a série). Exercício duplicado por máquina (fragmenta histórico e contradiz a spec).

## 2. Nome da entidade

**Decision**: `ExerciseStation` no banco e na API. Na interface, “estação” ou o apelido (“preta”, “da ponta”).

**Rationale**: `Equipment` já é o tipo global do catálogo (barra, máquina, cabo). Reusar esse nome confundiria tipo com aparelho físico.

**Alternatives considered**: Reusar `Equipment` com escopo de usuário. Campo livre em `exerciseNotes` (não dá para filtrar sugestão nem pré-selecionar).

## 3. Quando o chip aparece

**Decision**: Mostrar o controle só se o tipo de equipamento do movimento, normalizado (minúsculas, sem acento), for `maquina`, `cabo` ou `smith`. Tipo ausente ou desconhecido não pede estação. Barra, haltere, anilha, elástico e peso corporal também não.

**Rationale**: A spec limita o pedido ao número que não se compara entre aparelhos. No catálogo pt-BR o slug já sai como `maquina`; Smith cadastrado como máquina continua coberto. O editor de rotina (`template`) não mostra o chip. Execução ao vivo, retroativo e edição mostram.

**Alternatives considered**: Pedir estação em todo exercício (ruído em barra). Inferir pelo nome do exercício (“smith” no título) além do equipamento (frágil; o tipo basta).

## 4. Academia opcional

**Decision**: `ExerciseStation.gymId` é nulo quando a pessoa nunca nomeou um lugar. Com uma academia só, o treino não pede escolha. Com duas ou mais, o chip de academia aparece e a lista de estações filtra pelo lugar selecionado. Criar a primeira academia oferece, uma vez, vincular as estações ainda sem lugar àquela academia. A segunda academia começa vazia. Estações sem lugar não aparecem dentro de uma academia nomeada.

**Rationale**: O caso comum é uma academia e várias máquinas. Obrigar nome de lugar nesse caso atrasa o P1. Sem o vínculo da primeira academia, as estações antigas sumiriam dos dois lugares assim que surgisse o segundo.

**Alternatives considered**: Academia obrigatória no primeiro uso. Copiar estações sem lugar para toda academia (mistura “preta” de endereços diferentes).

## 5. Histórico antigo e pré-seleção

**Decision**: Série sem `stationId` continua no grupo “sem estação”. Nada é atribuído sozinho. Se já existe estação usada naquele movimento na academia atual (ou a última estação, se não houver academia), o treino já abre com ela selecionada. Limpar a estação volta a última vez para o desempenho mais recente do movimento, em qualquer máquina.

**Rationale**: A spec exige os dois comportamentos: não reescrever o passado e não obrigar escolha toda vez depois que a máquina já é conhecida.

**Alternatives considered**: Chutar a estação pelo peso mais próximo (errado e opaco). Sempre abrir sem estação (o chip vira atrito diário).

## 6. Sugestão e “outra máquina”

**Decision**: Com `stationId`, a sugestão usa só séries dessa estação. Sem séries nessa estação, a resposta explica que não há histórico naquela máquina e não devolve a carga de outra como meta. Pode incluir um aviso separado (`otherStation`) com apelido e última carga, só para leitura. Sem `stationId`, o cálculo atual permanece. `ExerciseRecord` (PR por movimento) não muda nesta feature.

**Rationale**: Os critérios de sucesso falam de última vez e carga sugerida, não de recorde. Avisar a outra máquina evita a pessoa achar que o app esqueceu o movimento, sem contaminar a meta.

**Alternatives considered**: Recalcular PR por estação agora (escopo maior, spec não pede). Usar a outra máquina como fallback da sugestão (é o bug atual).

## 7. Offline e ordem de sync

**Decision**: O cliente gera o id (cuid) de academia e estação. Drift grava primeiro, com `version`, `pendingSync` e `syncedAt`. O `SyncManager` envia academias e estações pendentes antes do `flushWorkoutOutbox`. O POST/PATCH do treino só referencia ids. A API aceita o id enviado no create e rejeita treino cuja estação ainda não existe, para o outbox tentar de novo depois do flush.

**Rationale**: O treino já sai por outbox próprio. Encaixar o upsert da estação dentro do payload do treino mistura catálogo com execução. A ordem no flush evita FK quebrada no caso sem rede.

**Alternatives considered**: Estação só dentro do JSON do treino, sem entidade (não dá para renomear nem ocultar). Sync único `/sync` genérico para essas duas entidades (o app já separa treino no outbox; catálogo pequeno cabe em REST dedicado na frente da fila).

## 8. Renomear e ocultar

**Decision**: Renomear altera `nickname` da estação; os treinos apontam para o id, então passam a mostrar o nome novo. Ocultar preenche `archivedAt` e tira a estação do picker; o histórico resolve o nome pelo id. Não há delete físico.

**Rationale**: Apagar quebraria o passado ou obrigaria copiar o apelido para cada série. A spec pede nome novo no passado e nome preservado depois de esconder — os dois cabem no mesmo id se “esconder” for arquivo, não exclusão.

**Alternatives considered**: Snapshot do apelido em cada série (renomear não atualizaria o passado, o que a spec pede que aconteça).

## 9. Apelido e marca

**Decision**: Apelido obrigatório, 1–40 caracteres, trim, comparação sem diferenciar maiúsculas na unicidade. Marca opcional, texto livre, até 60 caracteres. Observação opcional, até 200. Unicidade: mesma pessoa, mesmo movimento, mesma academia (ou ambas sem academia), mesmo apelido normalizado.

**Rationale**: O chip é de uma linha. Marca não vira catálogo. Dois “preta” na mesma academia e no mesmo movimento seriam a mesma estação.

**Alternatives considered**: Apelido livre sem limite (quebra o chip). Lista de fabricantes.
