# Data Model: Academia e Estação da Máquina

Espelho conceitual. Nomes de coluna canônicos no Prisma; o Drift repete os mesmos campos no schema v8. Campos de sync (`version`, `pendingSync`, `syncedAt`) seguem o restante do produto.

## Gym

Lugar nomeado pela pessoa.

| Campo | Regras |
|-------|--------|
| `id` | Cuid gerado no cliente. Imutável. |
| `userId` | Dono. Toda leitura e escrita filtra por esse usuário. |
| `name` | Obrigatório, 1–40 caracteres, trim. |
| `createdAt` / `updatedAt` | Auditoria. |

Relação: um usuário tem várias academias. Um treino aponta para no máximo uma.

Não há exclusão nesta feature. Renomear é o único ajuste.

## ExerciseStation

Apelido de uma máquina física de um movimento.

| Campo | Regras |
|-------|--------|
| `id` | Cuid gerado no cliente. Imutável. |
| `userId` | Dono. |
| `exerciseId` | Movimento do catálogo. Obrigatório. Não muda depois de criada. |
| `gymId` | Opcional. Nulo = estação ainda sem lugar. |
| `nickname` | Obrigatório, 1–40, trim. Único por (`userId`, `exerciseId`, `gymId` ou “sem lugar”, apelido normalizado). |
| `brand` | Opcional, texto livre, até 60. |
| `note` | Opcional, até 200. |
| `archivedAt` | Nulo = aparece no picker. Preenchido = oculta, histórico continua. |

Índice de leitura do picker: (`userId`, `exerciseId`, `gymId`) onde `archivedAt` é nulo.

Criar a primeira academia pode, com confirmação da pessoa, preencher `gymId` das estações que ainda estão nulas. Não é automático no segundo lugar.

## WorkoutSession (campo novo)

| Campo | Regras |
|-------|--------|
| `gymId` | Opcional. FK para `Gym` do mesmo usuário. `ON DELETE` não se aplica (academia não é apagada). Treino antigo permanece nulo. |

Cardio e descanso não usam o campo.

## SerieLog (campo novo)

| Campo | Regras |
|-------|--------|
| `stationId` | Opcional. FK para `ExerciseStation` do mesmo usuário e do mesmo `exerciseId` da série. |

Invariante: no mesmo treino, todas as séries não derivadas daquele movimento têm o mesmo `stationId` (ou todas nulas). Trocar ou limpar a estação atualiza o bloco inteiro. Arquivar a estação não apaga o id nas séries.

Índice de última vez: (`exerciseId`, `stationId`).

## O que não muda

- `SessionExercise` segue único por movimento na sessão. Sem `stationId`.
- `SessionExerciseConfig.variation` continua técnica.
- `Equipment` continua tipo global do catálogo.
- `ExerciseRecord` continua recorde do movimento, não da estação.

## Estados da estação

```text
ativa (archivedAt nulo) --ocultar--> arquivada (archivedAt preenchido)
arquivada --não volta nesta feature-->
nickname muda in-place em qualquer estado; treinos que apontam o id mostram o nome atual
```

## Estados do treino em relação ao lugar

```text
sem academia e sem estação     → comportamento atual de última vez e sugestão
sem academia, com estação      → histórico daquela estação (gymId nulo)
com academia, com estação      → histórico só daquela estação naquela academia
com academia, estação limpa    → última vez do movimento inteiro
estação nova, zero séries      → sem carga sugerida; aviso opcional de outra estação
```

## Validação na gravação do treino

- `gymId` e `stationId`, quando presentes, pertencem ao usuário autenticado.
- `stationId.exerciseId` é o movimento daquelas séries.
- Se `stationId.gymId` não é nulo, é igual ao `gymId` do treino.
- Estação arquivada pode permanecer em treino antigo; picker de treino novo não a oferece.
- Payload sem os campos novos grava como hoje (`null`).
