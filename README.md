# Iron Log

Aplicativo mobile para **registrar, planejar e acompanhar treinos de musculação**, com foco em quem treina de forma consistente e quer histórico confiável — inclusive **offline**.

O projeto é dividido em dois repositórios que trabalham juntos:

| Repositório | Papel |
|-------------|--------|
| **`iron_log`** (este) | App Flutter — interface, banco local, sync |
| **`iron_log_back_end`** | API REST NestJS — persistência, regras, catálogo |

### Git hooks (Conventional Commits)

Após clonar, instale os hooks versionados uma vez:

```bash
./scripts/install-githooks.sh
```

Commits: `type(scope): descrição` (ex.: `feat(workout): adiciona timer`).

- **Auto-commit Spec Kit**: após `/speckit-specify`, `/speckit-plan`, `/speckit-tasks` — **não** após `/speckit-implement` (commit manual seu)
- **Interativo**: se não inferir o tipo com confiança, pergunta no terminal (TTY)
- **Amend**: alterações relacionadas à mesma feature nos últimos 30 min vão para o último commit (`amend_related: true`)

Guia: `specs/004-git-commit-hooks/quickstart.md` (se existir no branch).

---

## Contexto

Treinar bem exige memória: qual peso usou, quantas repetições, se progrediu. Planilhas e apps genéricos muitas vezes não refletem a rotina real do usuário (split, sessões, RIR, registro retroativo).

O **Iron Log** nasce para:

- Montar **rotinas** com **sessões** (ex.: Push, Pull, Pernas) e lista de exercícios do catálogo.
- **Executar** o treino do dia com registro série a série (peso, reps, RIR, descanso, notas).
- Manter **histórico** e métricas agregadas (volume, PRs).
- Funcionar **offline-first**: gravar no aparelho e sincronizar quando houver rede.

Não é um app de vídeo-aula: **não há mídia de execução dos movimentos** (sem fotos/vídeos demonstrativos por exercício). A identificação visual usa texto, ícones por grupo muscular e metadados (equipamento, músculo primário).

---

## Modelo de dados (visão geral)

```
Usuário
 └── Rotina (Routine)
      └── Sessão (Session)          ← plano: "Peito e Tríceps", ordem dos exercícios
           └── SessionExercise      ← vínculo exercício ↔ sessão + config opcional
                └── SessionExerciseConfig  (séries alvo, RIR, peso sugerido, etc.)

Execução no dia:
 └── WorkoutSession                 ← treino real (início/fim, timer, notas)
      └── SerieLog                  ← cada série executada (peso, reps, RIR…)
```

| Conceito | O que é |
|----------|---------|
| **Rotina** | Conjunto de sessões do usuário (split, frequência). |
| **Sessão** | Template de um dia de treino dentro da rotina. |
| **WorkoutSession** | Registro de uma execução (ao vivo, manual/retroativa, cardio ou descanso). |
| **SerieLog** | Log de uma série durante a execução. |
| **Exercise** | Item do catálogo (global + customizados do usuário). |

---

## Escopo

### Dentro do escopo (hoje)

- **Autenticação** — Firebase Auth no app; validação no backend.
- **Onboarding** — frequência e metodologia inicial.
- **Rotinas e sessões** — CRUD, editor de sessão, reordenar exercícios, busca e filtros por músculo.
- **Catálogo de exercícios** — busca, criação rápida (find-or-create), ícones por grupo muscular.
- **Execução do treino** (`workout_day`) — modos: ao vivo, retroativo (data manual), edição de treino passado.
- **Registro por série** — peso, reps, RIR, labels (aquecimento, top set, etc.), unidade kg/lb.
- **Entrada por voz** — na execução: falar cargas/reps e preencher séries (parser + preview).
- **Cardio e descanso** — tipos de `WorkoutSession` sem série de musculação.
- **Histórico** — listagem e edição de treinos anteriores.
- **Treino rápido** — criar treino avulso sem rotina fixa.
- **Offline + sync** — Drift (SQLite) local; fila e endpoint de sincronização no backend.
- **Configurações** — preferências do usuário.

### Fora do escopo (por enquanto)

- Vídeos ou imagens de **técnica/execução** dos exercícios.
- Rede social, feed ou competição entre usuários.
- Nutrição completa, wearables integrados, periodização automática (ideias em discovery, não produto atual).
- Versão web do app (mobile-first).

### Em evolução / ideias

- **Voz no editor de sessão** — falar lista de exercícios para montar a sessão (hoje a voz está na tela de execução).
- UI de **status de sync** e resolução de conflitos mais visível.
- Sugestões de carga (chips de IA) na execução — parcialmente presente no cliente.

---

## Stack

### Mobile (`iron_log`)

- Flutter 3.8+, Dart
- **Riverpod** — estado
- **go_router** — navegação
- **Drift** — SQLite local
- **Dio** — HTTP
- **Firebase** — Auth, Crashlytics

### Backend (`iron_log_back_end`)

- **NestJS** + TypeScript
- **Prisma** + PostgreSQL
- **Firebase Admin** — validação de tokens
- **Swagger** — documentação da API

---

## Estrutura do app (pastas úteis)

```
lib/
├── core/           # API, database, sync, tema, rotas
├── features/
│   ├── auth/
│   ├── home/
│   ├── onboarding/
│   ├── routines/       # rotinas, sessões, editor
│   ├── workout_day/      # execução do treino, voz, timer
│   ├── workout_history/
│   ├── workout_creation/
│   └── settings/
└── main.dart
```

Backend espelha domínios em `src/routine`, `src/session`, `src/workout`, `src/sync`, etc. Schema canônico: `iron_log_back_end/prisma/schema.prisma`.

---

## Como rodar (desenvolvimento)

### Pré-requisitos

- Flutter SDK (ver `pubspec.yaml`)
- Node.js 18+ e PostgreSQL (backend)
- Projeto Firebase configurado (Auth)

### App

```bash
cd iron_log
flutter pub get
flutter run
```

Configure URL da API e Firebase conforme ambiente local (variáveis / arquivos de config do projeto).

### API

```bash
cd ../iron_log_back_end
npm install
# configurar .env (DATABASE_URL, Firebase, etc.)
npx prisma migrate dev
npm run start:dev
```

---

## Documentação técnica

- **[docs/project-scope.md](docs/project-scope.md)** — escopo detalhado, schema, sync, pontos críticos e roadmap técnico.
- Backend: coleções Postman e análises em `iron_log_back_end/` (ex.: `POSTMAN_README.md`, `PRODUCT_DISCOVERY_ANALYSIS.md`).

---

## Princípios de produto

1. **Offline-first** — treinar sem internet não pode perder dados.
2. **Rotina → sessão → execução** — separar plano do que foi feito no dia.
3. **Registro fino** — série a série, não só “fiz peito”.
4. **Sem dependência de mídia** — catálogo e UI funcionam sem assets de movimento por exercício.

---

## Status

Projeto em desenvolvimento ativo (versão `1.0.1+1` no cliente). Não publicado como produto final; APIs e fluxos de sync podem mudar.

---

## Licença

Repositório privado — uso interno do projeto Iron Log.
