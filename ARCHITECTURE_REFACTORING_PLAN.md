# 🏗️ PLANO DE REFATORAÇÃO ARQUITETURAL

## 🚨 PROBLEMAS IDENTIFICADOS

### 1. Inconsistência nos Padrões de Estado
- **Rotinas**: StateNotifierProvider + Clean Architecture ✅
- **Home**: StateNotifier + HttpService direto ❌
- **Workout Creation**: StateNotifier simples ❌
- **Onboarding**: Riverpod Generator (@riverpod) ❌

### 2. Violações de Clean Architecture
- HomeNotifier acessa HttpService diretamente
- Mistura de responsabilidades entre camadas
- Providers em locais inconsistentes

## 🎯 PADRÃO ESTABELECIDO

### Estrutura Obrigatória:
```
features/[feature_name]/
├── domain/
│   ├── entities/          # Obrigatório
│   ├── repositories/      # Interface quando necessário
│   └── usecases/          # Apenas para lógica complexa
├── data/
│   ├── models/            # Extends entities
│   └── repositories/      # Implementações
└── presentation/
    ├── providers/         # StateNotifierProvider + State + Notifier
    ├── pages/             # Páginas principais
    └── widgets/           # Componentes (sem lógica de estado)
```

### Padrão de Providers:
```dart
// 1. State
class FeatureState {
  final bool isLoading;
  final String? error;
  final List<Entity> items;

  const FeatureState({...});

  FeatureState copyWith({
    bool? isLoading,
    String? error,
    List<Entity>? items,
    bool clearError = false,
  }) => FeatureState(...);
}

// 2. Notifier
class FeatureNotifier extends StateNotifier<FeatureState> {
  final UseCase1 _useCase1;
  final UseCase2 _useCase2;

  FeatureNotifier(this._useCase1, this._useCase2) : super(const FeatureState());

  // Métodos públicos que retornam resultado ou null/bool
  Future<Entity?> createItem(...) async { ... }
  Future<bool> deleteItem(String id) async { ... }
}

// 3. Provider
final featureNotifierProvider = StateNotifierProvider<FeatureNotifier, FeatureState>((ref) {
  final useCase1 = ref.watch(useCase1Provider);
  final useCase2 = ref.watch(useCase2Provider);
  return FeatureNotifier(useCase1, useCase2);
});
```

## 📋 FEATURES A REFATORAR

### 1. Home Feature ❌
**Problema**: HomeNotifier usa HttpService diretamente
**Solução**:
- Criar RoutineRepository injection
- Mover para presentation/providers/
- Seguir padrão StateNotifier

### 2. Workout Creation Feature ❌
**Problema**: StateNotifier simples sem Clean Architecture
**Solução**:
- Implementar domain/entities
- Criar repositories se necessário
- Reestruturar providers

### 3. Onboarding Feature ❌
**Problema**: Usa Riverpod Generator inconsistente
**Solução**:
- Migrar para StateNotifierProvider
- Seguir estrutura padrão

## ✅ STATUS ATUAL

### Features Conformes:
- ✅ **Routines**: Arquitetura correta (referência)
- ✅ **Sessions**: Arquitetura correta (novo)

### Features Não Conformes:
- ❌ **Home**: Precisa refatoração
- ❌ **Workout Creation**: Precisa refatoração
- ❌ **Onboarding**: Precisa refatoração

## 🔧 PRÓXIMOS PASSOS

1. **Implementar edição de sessões** ✅ (Concluído)
2. **Refatorar Home Feature** (Próximo)
3. **Refatorar Workout Creation Feature**
4. **Refatorar Onboarding Feature**
5. **Documentar padrões no README**

## 📚 REGRAS DE ARQUITETURA

### Obrigatório:
- Entities tipadas (nunca Map<String, dynamic> na UI)
- StateNotifierProvider para gerenciamento de estado
- Providers em presentation/providers/
- Separação clara de responsabilidades

### Proibido:
- HttpService direto nos Notifiers
- Riverpod Generator (@riverpod)
- Métodos privados que retornam Widget
- Estados misturados entre features
