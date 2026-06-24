# Feature Specification: Importação de Treino por Texto Livre

**Feature Branch**: `007-workout-text-import`

**Created**: 2026-06-23

**Status**: Draft

**Input**: Permitir que o usuário cole textos livres de treino (WhatsApp, notas, logs manuais) e o sistema transforme isso em treinos estruturados automaticamente, com validação humana obrigatória antes de salvar. A interpretação automática nunca persiste dados — apenas sugere; o usuário valida e o sistema grava a versão final.

**Escopo de produto**: Iron Log (app mobile) + serviço de interpretação associado. Entrada por texto colado na v1; áudio, imagem e coaching automático ficam fora do escopo inicial.

---

## User Scenarios & Testing

### User Story 1 - Colar texto e receber treino estruturado para revisão (Priority: P1)

Como usuário que registra treinos em mensagens ou notas informais, quero colar o texto bruto no app e ver uma versão organizada por sessões, exercícios e séries, para transformar histórico desorganizado em dados utilizáveis sem digitar tudo de novo.

**Why this priority**: Sem interpretação inicial, o fluxo não existe; é o núcleo do valor da feature.

**Independent Test**: Usuário cola um texto com pelo menos um exercício, cargas e repetições; o sistema exibe uma pré-visualização estruturada separada por sessão, sem gravar nada no histórico até confirmação explícita.

**Acceptance Scenarios**:

1. **Given** um usuário autenticado na tela de importação, **When** cola um texto descrevendo um treino com exercícios, séries e cargas, **Then** o sistema processa o conteúdo e apresenta uma estrutura revisável com sessões, exercícios, séries e anotações associadas.
2. **Given** um texto processado com sucesso, **When** o usuário ainda não confirmou, **Then** nenhum treino é salvo no histórico permanente.
3. **Given** um texto com dados ambíguos ou incompletos, **When** o sistema interpreta, **Then** campos incertos são marcados explicitamente em vez de preenchidos com valores inventados.

---

### User Story 2 - Revisar, corrigir e confirmar antes de salvar (Priority: P1)

Como usuário, quero editar a interpretação sugerida (cargas, repetições, exercícios, anotações) e só então confirmar o salvamento, para manter controle total sobre o que entra no meu histórico.

**Why this priority**: O princípio central é "IA sugere → humano valida → sistema persiste"; sem revisão obrigatória a feature viola a confiança do produto.

**Independent Test**: Após processamento, o usuário altera carga de uma série, remove um exercício incorreto, confirma e verifica que apenas a versão editada aparece no histórico.

**Acceptance Scenarios**:

1. **Given** uma pré-visualização de treino interpretado, **When** o usuário ajusta cargas, repetições ou remove um exercício, **Then** as alterações são refletidas na pré-visualização antes do salvamento.
2. **Given** uma pré-visualização revisada, **When** o usuário confirma o salvamento, **Then** o sistema persiste a versão final validada pelo usuário (não a sugestão bruta da interpretação).
3. **Given** uma pré-visualização em revisão, **When** o usuário cancela ou abandona o fluxo, **Then** nenhum dado é gravado no histórico de treinos.

---

### User Story 3 - Separar múltiplos treinos no mesmo texto (Priority: P2)

Como usuário que cola registros acumulados (ex.: vários dias ou Upper/Lower no mesmo bloco), quero que o sistema detecte e separe sessões distintas, para não misturar treinos diferentes em um único registro.

**Why this priority**: Um dos problemas centrais descritos é texto com múltiplos treinos; separação incorreta corrompe análise de progressão.

**Independent Test**: Usuário cola texto com dois blocos claramente distintos (ex.: "Upper 1" e "Lower 1"); o sistema exibe duas sessões separadas na revisão.

**Acceptance Scenarios**:

1. **Given** um texto contendo indícios de mais de um treino, **When** o sistema interpreta, **Then** apresenta cada treino como sessão separada na interface de revisão.
2. **Given** um texto com padrões Upper/Lower reconhecíveis, **When** a separação é confiável, **Then** cada sessão é rotulada de forma coerente (ex.: Upper 1, Lower 1).
3. **Given** um texto onde data ou ordem cronológica não podem ser determinadas, **When** o sistema apresenta as sessões, **Then** marca ordem/data como "não determinado" em vez de atribuir valores arbitrários.

---

### User Story 4 - Preservar contexto, falhas e incertezas (Priority: P2)

Como usuário que anota sensações, dores, ajustes técnicos e falhas de execução, quero que nada do texto original seja descartado e que tentativas falhas ou regressões de carga apareçam no exercício correto, para manter um histórico fiel à minha evolução real.

**Why this priority**: Perder contexto ou ignorar falhas impede análise confiável e contradiz a promessa de preservação total.

**Independent Test**: Texto com comentário subjetivo, série de aquecimento, tentativa falha e redução de carga resulta em anotações preservadas, tipos de esforço distintos e nenhum trecho original inacessível.

**Acceptance Scenarios**:

1. **Given** um texto com comentários técnicos, sensações ou dores associados a um exercício, **When** o sistema interpreta, **Then** essas anotações permanecem vinculadas ao exercício correspondente na revisão.
2. **Given** séries de aquecimento, preparatórias e válidas no mesmo fluxo, **When** o sistema classifica o esforço, **Then** distingue tipos de série (leve/aquecimento, válido, falha, incerto) priorizando séries próximas do esforço máximo como válidas quando aplicável.
3. **Given** uma tentativa falha seguida de regressão de carga ou ajuste por dor, **When** o sistema interpreta, **Then** registra esses eventos como parte do exercício, sem normalizá-los como séries válidas de progressão.
4. **Given** qualquer importação concluída ou em revisão, **When** o usuário solicita ver a origem, **Then** o texto original colado permanece rastreável e recuperável.

---

### User Story 5 - Corrigir exercícios não reconhecidos (Priority: P3)

Como usuário cujo texto usa abreviações ou nomes informais, quero renomear ou associar exercícios interpretados incorretamente durante a revisão, para alinhar ao meu vocabulário e catálogo sem perder o registro.

**Why this priority**: Nomes informais são comuns em textos de WhatsApp; a correção na revisão fecha o ciclo sem exigir reescrita manual completa.

**Independent Test**: Texto com nome de exercício ambíguo permite edição do nome na revisão antes do salvamento.

**Acceptance Scenarios**:

1. **Given** um exercício interpretado com nome incerto ou informal, **When** o usuário edita o nome na revisão, **Then** a versão salva reflete o nome corrigido.
2. **Given** um exercício que não corresponde a nenhum item conhecido, **When** apresentado na revisão, **Then** o sistema mantém o nome extraído do texto e sinaliza que a correspondência é incerta, sem inventar um exercício não mencionado.

---

### Edge Cases

- Texto vazio ou apenas espaços: o sistema impede processamento e informa que é necessário colar conteúdo.
- Texto sem nenhum exercício ou série identificável: o sistema informa que não foi possível estruturar o treino e preserva o texto original para nova tentativa ou edição manual.
- Texto extremamente longo (múltiplos treinos/semanas): o sistema processa e separa em sessões; se exceder limites práticos de revisão, informa o usuário e permite importação parcial ou divisão manual do texto.
- Mistura Upper e Lower no mesmo bloco sem separadores claros: sessões são separadas quando possível; caso contrário, uma sessão é marcada como incerta com alternativas visíveis na revisão.
- Cargas em unidades mistas (kg e lb) ou formatos informais ("2pl", "20 cada lado"): valores são extraídos como aparecem; campos ambíguos ficam marcados para edição.
- Repetições ou cargas ausentes: campos permanecem vazios ou incertos — nunca preenchidos por inferência sem evidência no texto.
- Falha temporária no processamento (rede, serviço indisponível): o usuário recebe mensagem clara, o texto colado não é perdido e pode tentar novamente.
- Usuário fecha o app durante a revisão: o rascunho de importação em andamento pode ser recuperado ou descartado explicitamente; o histórico permanente não é alterado até confirmação.
- Texto duplicado importado duas vezes: cada importação é independente; o usuário decide se mantém ambas as versões no histórico.

---

## Requirements

### Functional Requirements

**Entrada e processamento**

- **FR-001**: O sistema MUST permitir que o usuário autenticado cole ou digite texto livre descrevendo um ou mais treinos.
- **FR-002**: O sistema MUST enviar o texto para interpretação automática que organiza o conteúdo em estrutura de sessões, exercícios, séries e anotações.
- **FR-003**: O sistema MUST NOT persistir treinos no histórico permanente com base apenas na interpretação automática — salvamento exige confirmação explícita do usuário após revisão.
- **FR-004**: O sistema MUST preservar o texto original colado de forma rastreável, vinculada à importação correspondente.

**Regras de interpretação (comportamento esperado da sugestão)**

- **FR-005**: A interpretação MUST NOT inventar exercícios, cargas, repetições ou séries não mencionados ou sem evidência no texto.
- **FR-006**: A interpretação MUST NOT preencher lacunas ambíguas com valores assumidos; lacunas MUST ser marcadas como incertas ou deixadas em branco para edição.
- **FR-007**: Quando o texto contiver mais de um treino, a interpretação MUST separar em sessões distintas e MUST NOT forçar tudo em um único treino.
- **FR-008**: Quando padrões de divisão corporal forem reconhecíveis (ex.: Upper/Lower), a interpretação SHOULD rotular sessões de forma coerente; quando ambíguo, MUST sinalizar incerteza.
- **FR-009**: A interpretação MUST classificar séries por tipo de esforço: leve/aquecimento, preparatória, válida (foco de progressão), falha, incerto.
- **FR-010**: Quando múltiplas séries próximas em carga existirem para o mesmo exercício, a interpretação SHOULD priorizar como válidas as mais próximas do esforço máximo, conforme evidência no texto.
- **FR-011**: A interpretação MUST preservar comentários técnicos, sensações, dores, ajustes de execução e observações subjetivas, associados ao exercício mais provável.
- **FR-012**: A interpretação MUST reconhecer falhas de execução, regressões de carga, reduções por dor/limitação e tentativas falhas, sem descartá-las nem convertê-las silenciosamente em séries válidas.
- **FR-013**: Quando data ou ordem cronológica não puderem ser determinadas, a interpretação MUST marcar como "não determinado" em vez de atribuir valores arbitrários.

**Interface de revisão**

- **FR-014**: Após processamento, o sistema MUST apresentar treinos separados por sessão em tela de revisão dedicada.
- **FR-015**: O usuário MUST poder editar cargas, repetições e nomes de exercícios na revisão.
- **FR-016**: O usuário MUST poder remover exercícios ou séries incorretas na revisão.
- **FR-017**: O usuário MUST poder visualizar campos e sessões marcados como incertos ou com data/ordem não determinada.
- **FR-018**: O usuário MUST poder acessar ou consultar o texto original da importação durante a revisão.
- **FR-019**: O sistema MUST oferecer ação explícita de confirmar salvamento e ação de cancelar/descartar a importação em andamento.

**Persistência e domínio**

- **FR-020**: Ao confirmar, o sistema MUST persistir apenas a versão final validada pelo usuário como registro(s) de treino no histórico.
- **FR-021**: O modelo persistido MUST expressar conceitos de domínio: sessão de treino, exercício, série, tipo de esforço e anotações associadas — independentemente do formato do texto de entrada.
- **FR-022**: Toda incerteza relevante que permaneça após revisão MUST ser representada de forma explícita no registro salvo (ex.: tipo de esforço incerto, data não determinada) ou resolvida pelo usuário antes do salvamento.
- **FR-023**: Nenhum dado relevante do texto original MUST ser descartado silenciosamente; conteúdo não estruturável MUST permanecer acessível via anotação ou vínculo ao texto original.

**Extensibilidade (v1 prepara, não implementa)**

- **FR-024**: O desenho do fluxo MUST permitir evolução futura para outras fontes de entrada (áudio, imagem) e análises derivadas (progressão, fadiga, coaching), sem acoplar a persistência ao formato de texto colado.

### Key Entities

- **Importação de treino (rascunho)**: Representa uma tentativa de importação em andamento; contém o texto original, estado do fluxo (processando, em revisão, descartada, concluída) e vínculo com a sugestão interpretada. Não equivale a treino salvo até confirmação.
- **Texto original**: Conteúdo bruto colado pelo usuário; fonte de verdade para rastreabilidade e auditoria.
- **Sessão de treino (sugerida ou final)**: Unidade de um treino (ex.: Upper 1, dia específico); pode ter data/ordem determinada ou marcada como não determinada.
- **Exercício**: Movimento ou atividade dentro de uma sessão; agrupa séries e anotações; nome editável na revisão.
- **Série**: Registro de uma execução com carga, repetições (quando informadas) e tipo de esforço.
- **Tipo de esforço**: Classificação da série — leve/aquecimento, preparatória, válida, falha ou incerto.
- **Anotação**: Comentário preservado do texto (técnico, subjetivo, dor, ajuste) vinculado a exercício ou sessão.
- **Marcador de incerteza**: Indicação explícita de ambiguidade em campo, sessão, exercício ou classificação de série.

---

## Success Criteria

### Measurable Outcomes

- **SC-001**: Em testes com usuários reais, pelo menos 80% conseguem colar um texto de treino informal e chegar à tela de revisão estruturada em menos de 2 minutos (excluindo tempo de edição manual extensa).
- **SC-002**: Em um conjunto de referência de textos representativos (mínimo 20, incluindo multi-sessão e anotações misturadas), pelo menos 85% das sessões são separadas corretamente na sugestão inicial, medido por validação humana em revisão.
- **SC-003**: 100% das importações confirmadas mantêm o texto original recuperável e rastreável até o registro salvo.
- **SC-004**: Nenhum treino é gravado no histórico permanente sem ação explícita de confirmação do usuário após revisão (0 salvamentos automáticos pós-interpretação em testes de aceitação).
- **SC-005**: Em textos de referência com anotações subjetivas e falhas de execução, pelo menos 90% das anotações e eventos de falha/regressão aparecem na revisão vinculados ao exercício correto, sem perda silenciosa.
- **SC-006**: Pelo menos 70% dos usuários em teste de usabilidade conseguem corrigir um erro evidente na interpretação (exercício errado ou carga incorreta) e salvar em menos de 3 minutos adicionais.
- **SC-007**: Após adoção, usuários que importam histórico reportam capacidade de consultar progressão nos treinos importados sem necessidade de reestruturação manual completa do texto original.

---

## Assumptions

- A v1 cobre apenas entrada por texto colado; importação por áudio, OCR e coaching automático ficam para fases futuras.
- Usuários estão autenticados e importam treinos para o próprio histórico de execução (registros de treino realizados), não para edição automática de planos de rotina.
- Textos de entrada são predominantemente em português brasileiro, com notação informal comum em mensagens de treino (abreviações, emojis opcionais, separadores variados).
- O processamento interpretativo requer conectividade; em offline, o usuário pode colar e reter o texto localmente até conseguir processar, sem gravar treino estruturado antes disso.
- O catálogo de exercícios existente pode auxiliar correspondência de nomes, mas nomes não encontrados são preservados como informados no texto, para decisão do usuário na revisão.
- Limites práticos de tamanho de texto serão definidos na fase de planejamento com base em usabilidade; textos muito longos podem exigir divisão manual pelo usuário.
- A interpretação automática é um serviço externo ao fluxo de persistência; falhas desse serviço não corrompem o histórico existente do usuário.

---

## Out of Scope (v1)

- Importação por áudio ou imagem (OCR)
- Sugestão automática de progressão, análise semanal de desempenho, detecção de fadiga ou coaching automático baseado em histórico importado
- Salvamento automático sem etapa de revisão humana
- Edição em massa de rotinas/planos a partir do texto importado
- Importação colaborativa ou compartilhamento de textos entre usuários
