# Contract: Academia, estação e carga

Contrato aditivo. Cliente sem estes campos continua válido. Autenticação igual ao resto da API: usuário só vê e altera o próprio dado.

Detalhe de campos: [data-model.md](../data-model.md).

## Academias

`GET /gyms`  
Lista as academias do usuário, nome e id, da mais recente para a mais antiga.

`POST /gyms`  
Corpo: `{ "id", "name" }`. `id` é o cuid do cliente. Nome vazio ou acima de 40 caracteres falha validação. Id repetido do mesmo usuário devolve a academia existente.

`PATCH /gyms/:id`  
Corpo: `{ "name" }`. Academia de outra pessoa não é encontrada.

## Estações

`GET /exercise-stations?exerciseId={id}&gymId={id?}&limit={n?}`  
Estações ativas daquele movimento. Sem `gymId`, devolve só as que também não têm academia. Com `gymId`, só as daquela academia. Ordenação: uso mais recente primeiro (maior data de série ligada à estação; estação nunca usada por último, pela data de criação). `limit` padrão 3, máximo 20. Cada item: `id`, `nickname`, `brand`, `note`, `gymId`, `exerciseId`.

`POST /exercise-stations`  
Corpo: `{ "id", "exerciseId", "gymId?", "nickname", "brand?", "note?" }`.  
Unicidade do apelido normalizado: se já existe estação ativa igual, devolve essa em vez de criar outra. Movimento ou academia inexistente, ou de outro usuário, falha. Apelido fora de 1–40 falha.

`PATCH /exercise-stations/:id`  
Corpo parcial: `{ "nickname?", "brand?", "note?", "archived?" }`.  
`archived: true` preenche `archivedAt`. Não apaga a linha. Renomear respeita a mesma unicidade.

Não há `DELETE`.

## Treino (campos novos)

No corpo já usado por criar e atualizar treino:

- na raiz: `gymId` opcional (string ou ausente)
- em cada exercício: `stationId` opcional (string ou ausente)

A gravação copia `stationId` para todas as séries daquele movimento na transação do treino. Ausência grava `null` e não mexe na regra antiga. `stationId` de outro movimento, outra academia ou outro usuário falha o treino inteiro.

A leitura do treino devolve `gymId` na sessão e `stationId` em cada exercício (nulo quando não houver).

## Última vez

`GET /workout/exercise/:exerciseId/last-sets?limit={n}&stationId={id?}`

| `stationId` | Comportamento |
|-------------|---------------|
| ausente | Igual a hoje: último treino do movimento, qualquer máquina. Sem `otherStation`. |
| presente, com séries | Só séries daquela estação. |
| presente, sem séries | `sets` vazio. `otherStation` pode vir preenchido se o movimento tiver série em outra estação: `{ "stationId", "nickname", "weight", "reps", "sessionDate" }`. Esse objeto não é a última vez oficial. |

Estação de outro usuário ou de outro movimento responde como estação inexistente.

## Sugestão de carga

`GET /suggestion?exerciseId={id}&stationId={id?}`

| `stationId` | Comportamento |
|-------------|---------------|
| ausente | Cálculo atual, todas as máquinas. |
| presente, com séries de trabalho | Mesma regra de subir/manter/descer, só com essas séries. |
| presente, sem séries | `suggestedWeight` 0, ação manter, texto de que ainda não há histórico naquela máquina. Não usa peso de outra estação como meta. `otherStation` opcional, mesmo formato da última vez, só informativo. |

## Ordem no cliente

1. Gravar academia e estação no banco local.
2. Enviar `POST /gyms` e `POST /exercise-stations` pendentes.
3. Enviar o treino que referencia esses ids.

Se o treino chegar antes da estação, a API recusa e o envio do treino fica pendente para a tentativa seguinte.

## Fora deste contrato

- Fator de polia, carga equivalente, catálogo de marcas.
- Mudança em `ExerciseRecord`.
- Segunda estação no mesmo movimento do mesmo treino.
- Qualquer campo novo em exercício de sessão / rotina.
