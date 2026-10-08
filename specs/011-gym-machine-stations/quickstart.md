# Quickstart: Academia e Estação da Máquina

Guia de validação da feature. Contratos em [contracts/training-place-api.md](./contracts/training-place-api.md). Campos em [data-model.md](./data-model.md).

## Pré-requisitos

- Branch `011-gym-machine-stations` nos dois repositórios quando a implementação existir nos dois.
- API local com migração aplicada e app apontando para ela.
- Usuário autenticado com um movimento de máquina (tipo `maquina`, `cabo` ou `smith`) e um movimento de barra na mesma sessão.

## Automatizado

Backend, a partir de `iron_log_back_end`:

- Testes do serviço de treino: gravar um exercício com `stationId` persiste o mesmo id em todas as séries; sem o campo, as séries ficam nulas.
- Testes de última vez: duas estações do mesmo movimento devolvem cargas diferentes quando `stationId` é informado; sem o parâmetro, devolve o treino mais recente do movimento.
- Testes de sugestão: estação sem série não devolve a carga da outra estação como `suggestedWeight`.
- Testes de estação: o mesmo apelido no mesmo movimento e na mesma academia não cria duas linhas; em academias diferentes, cria.

App, a partir de `iron_log`:

- Unitário do portão: equipamento normalizado `maquina`, `cabo` e `smith` pedem estação; barra, haltere e vazio não pedem.
- Unitário do rascunho: `gymId` e `stationId` sobrevivem ao snapshot e à retomada.
- Widget do card em modo execução: movimento de máquina mostra o chip; movimento de barra não mostra.

## Manual

1. **Máquina diferente, mesma academia**  
   Iniciar o treino de um movimento de máquina. Criar a estação “preta” e anotar 40 kg. Finalizar. Iniciar de novo, criar “da ponta” e anotar 55 kg. Abrir outra vez: “preta” já vem selecionada e a última vez mostra 40 kg, não 55 kg. Repetir selecionando “da ponta” e ver 55 kg.

2. **Barra**  
   No mesmo treino, o movimento de barra não mostra chip de estação. A última vez dele continua a do movimento.

3. **Uma academia só**  
   Com nenhuma ou uma academia cadastrada, o início do treino não pede o lugar. A estação ainda pode ser escolhida.

4. **Dois lugares**  
   Cadastrar duas academias. Confirmar o chip de lugar. Registrar “preta” com cargas diferentes em cada uma. Trocar a academia e ver que a última vez não cruza.

5. **Estação nova**  
   Criar “fundo do salão” sem histórico. A sugestão não propõe a carga da “preta”. Pode citar a outra máquina só como aviso.

6. **Sem estação**  
   Limpar a estação. A última vez volta ao número mais recente do movimento, qualquer máquina. Um treino antigo, de antes da feature, continua aparecendo nesse modo.

7. **Editar, renomear, ocultar**  
   Editar o treino passado e trocar a estação; o próximo treino usa a corrigida. Renomear “preta” para “preta da janela” e ver o nome novo no treino antigo. Ocultar “da ponta” e confirmar que ela sai do picker e o treino antigo ainda mostra o nome.

8. **Sem rede**  
   Modo avião: escolher academia (se houver duas) e estação, finalizar. O treino continua no aparelho com essas escolhas. Com rede de volta, o envio leva academia, estação e séries, e a última vez online bate com o que foi registrado.

9. **Rotina**  
   Abrir o editor da sessão. O movimento continua uma vez só, sem seletor de máquina.
