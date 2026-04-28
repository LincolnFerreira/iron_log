# Iron Log — Design System

Este documento reúne o design system atualmente aplicado no app Iron Log (tela Workout Day e componentes relacionados). Contém tokens de cor, tipografia, espaçamentos, formas, dimensões de componentes e diretrizes de uso. Use como referência para implementar temas, gerar tokens exportáveis e manter consistência visual.

---

## 1. Paleta de Cores (tokens)
As cores são definidas em `lib/core/app_colors.dart`.

- Primary (brand)
  - `primaryLight`: #2E5BFF (AppColors.primaryLight / blue100)
  - `primaryDark`:  #99B7FF (AppColors.primaryDark / blue40)

- Escala de azul (tons usados para estados e variações)
  - blue10: #E6EDFF
  - blue20: #CCDBFF
  - blue30: #B3C9FF
  - blue40: #99B7FF
  - blue50: #80A5FF
  - blue60: #6693FF
  - blue70: #4D81FF
  - blue80: #336FFF
  - blue90: #1A5DFF
  - blue100: #2E5BFF (Base)
  - blue110: #2951E6
  - blue120: #2547CC
  - blue130: #203DB3
  - blue140: #1C3399
  - blue150: #172980

- Neutros (Light)
  - white: #FFFFFF
  - gray10: #F5F7FA (background light)
  - gray20: #E6EAEF
  - gray30: #D3D9E0 (borders / disabled)
  - gray40: #C1C9D2
  - gray50: #8A96B3 (secondary text)
  - gray60: #6E7B9B
  - gray70: #4D5B7C
  - gray80: #2D3A5C
  - gray90: #1B243D
  - gray100: #09122E (text primary light)

- Neutros (Dark)
  - dark5:  #1F1F1F
  - dark10: #121212 (background dark)
  - dark20: #1E1E1E (surface dark)
  - dark30: #2A2A2A
  - dark40: #363636
  - dark50: #424242

- Semânticas
  - success: #06C270
  - error:   #FF3B3B
  - warning: #FFCC00
  - info:    #0063F7

**Recomendações de uso**
- `primaryLight` / `primaryDark` — botões principais, links, indicadores ativos.
- `backgroundLight` (`gray10`) / `backgroundDark` (`dark10`) — telas.
- `surfaceLight` (`white`) / `surfaceDark` (`dark20`) — cards e entradas.
- `textPrimaryLight` / `textPrimaryDark` — texto principal.
- `gray30` — bordas e dividers.
- Use tons mais claros/escuros da escala azul para estados de hover, pressed e focus.

---

## 2. Tipografia
Fontes presentes em `assets/fonts`: Inter e Barlow (ver `pubspec.yaml`).

Tokens tipográficos recomendados (mobile first):

- Font Family
  - `font-primary`: Inter
  - `font-display`: Barlow (uso em títulos quando desejar estilo mais robusto)

- Weights
  - Regular: 400
  - Medium: 500
  - Semibold: 600
  - Bold: 700

- Scale (pt)
  - Display / H1: 28 (Barlow Semibold) — uso: headers principais
  - H2: 22 (Inter Semibold)
  - H3: 18 (Inter Medium)
  - Body Large: 16 (Inter Regular)
  - Body: 14 (Inter Regular)
  - Small: 12 (Inter Regular)
  - Caption / UI: 11

- Line-height
  - Body: 1.4 — 1.6 para títulos quando necessário.

**Atenção**: para a tela Workout Day, `ExerciseCard` usa texto 16 semibold para o nome (ver `lib/features/workout_day/presentation/organisms/exercise_card.dart`). Ajuste font-family/weight conforme necessidade de hierarquia.

---

## 3. Espaçamento e Grid (Spacing System)
Base unit: 4px (1 unit = 4px). Tokens:

- spacing-1: 4
- spacing-2: 8
- spacing-3: 12
- spacing-4: 16
- spacing-5: 20
- spacing-6: 24
- spacing-8: 32
- spacing-10: 40
- spacing-12: 48

Layout breakpoints (sugestão)
- mobile: up to 599
- tablet: 600–1023
- desktop: 1024+

Container max-widths: usar constraints responsivos por página; listas (cards) em full-width no mobile, grid 2-col em tablet, 3-col em desktop quando aplicável.

---

## 4. Formas / Radii / Borders
- Corner radius small: 8px (buttons, inputs)
- Corner radius card: 16px (ExerciseCard e cards principais)
- Border width: 1px (borders / input outlines)
- Focus ring: 2px outline com `primaryLight` 20% opacity

---

## 5. Elevation / Sombras
Aplicação baseada no uso em `ExerciseCard`.
- Elevation low (cards):
  - box-shadow: 0px 2px 10px rgba(13, 20, 44, 0.05) — utilizado em `ExerciseCard` (ver `exercise_card.dart`)
- Elevation medium (dialogs / modals):
  - 0px 6px 20px rgba(13, 20, 44, 0.08)
- Elevation high (floating elements):
  - 0px 12px 40px rgba(13, 20, 44, 0.12)

---

## 6. Componentes (tokens e guidelines)

### 6.1 Exercise Card (Workouts list)
- Padding interno: spacing-4 (16px)
- Corner radius: 16px
- Background: `surfaceLight` / `surfaceDark`
- Shadow: Elevation low (ver seção acima)
- Title: 16pt Semibold; truncated with ellipsis
- Subtitle (muscles): 14pt regular, color `gray70`
- Chips row: compact spacing (8px entre chips)
- Series table dentro do card: rows altura ~48px, células com peso/reps center aligned

### 6.2 Custom Input (TextFormField)
Referência: `lib/features/workout_day/presentation/atoms/custom_input_field.dart`
- Border radius: 8px
- Border color: `gray30` (#D3D9E0)
- Fill color: white (surface)
- Focus border color: `primaryLight`
- Padding interno: 12–16px

### 6.3 Buttons
- Primary button
  - Height: 44px
  - Border radius: 8px
  - Background: `primaryLight` (#2E5BFF)
  - Text: 16pt Bold / Semibold, white
- Secondary (outlined)
  - Height: 40–44px
  - Border: 1px `gray30`
  - Text: 14–16pt Medium
- Icon buttons: 36px square, centered icon 18–20px

### 6.4 Bottom Sheet / Dialogs
- Corner radius top: 16px
- Max width (mobile): full width minus 24px margin
- Content padding: spacing-4 (16px)

### 6.5 Chips / Badges
- Height: 28px
- Padding horizontal: 8–12px
- Corner radius: 12px
- Text: 12–13pt Medium
- Color: contextual (tag color with 10% background) — `CustomBadge` usa tag color com opacity.

---

## 7. Forms & Interaction
- Disabled state: reduce opacity to 60% and use `gray30` border
- Error state: border color `error` (#FF3B3B) and small message text in caption color
- Success state: `success` (#06C270)
- Focus & hover: primary tint for focus; subtle elevation increase on hover for desktop

---

## 8. Accessibility
- Garantir contraste mínimo 4.5:1 para textos principais; usar `textPrimaryLight` sobre `backgroundLight`.
- Tamanho de toque mínimo: 44x44dp para botões e itens interativos.
- Suporte a fontes escaláveis (respeitar `textScaleFactor`).
- Localização: layout e textos em Português pt-BR; evitar imagens que contenham texto.

---

## 9. Tokens Flutter / Exemplo rápida (ThemeData)
Sugestão rápida para mapear tokens no `ThemeData` (Flutter):

```dart
final ThemeData light = ThemeData(
  primaryColor: Color(0xFF2E5BFF),
  scaffoldBackgroundColor: Color(0xFFF5F7FA),
  cardColor: Colors.white,
  textTheme: TextTheme(
    headline6: TextStyle(fontFamily: 'Barlow', fontSize: 16, fontWeight: FontWeight.w600),
    bodyText1: TextStyle(fontFamily: 'Inter', fontSize: 16),
    bodyText2: TextStyle(fontFamily: 'Inter', fontSize: 14),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Color(0xFFD3D9E0))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Color(0xFF2E5BFF))),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Color(0xFF2E5BFF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      minimumSize: Size.fromHeight(44),
    ),
  ),
);
```

---

## 10. Component-specific notes para Workflow de Voice Input
- O `VoiceInputBottomSheet` usa elementos de dialog com padding 16 e título médio; manter consistência com tokens de dialog.
- Preview list: usar `ListTile` com `subtitle` em `bodyText2` e ação `Selecionar` como `TextButton` (14pt)
- Feedback após aplicar: usar `SnackBar` padrão com background `surfaceDark` / `primaryLight` text color white.

---

## 11. Como evoluir
- Exportar tokens para JSON/SCSS/Flutter (ThemeData) para facilitar sincronização entre design e código.
- Documentar componentes atômicos (atoms/molecules/organisms) com exemplos visuais e states (hover, focus, disabled, error).
- Adotar sistema de tokens (design-tokens) e gerar automaticamente para multiplataforma.

---

## Referências de código
- `lib/core/app_colors.dart` — tokens de cor
- `lib/features/workout_day/presentation/organisms/exercise_card.dart` — formato do card de exercício
- `lib/features/workout_day/presentation/atoms/custom_input_field.dart` — inputs
- `lib/features/workout_day/presentation/widgets/voice_input_bottom_sheet.dart` — bottom sheet / dialogs

---

Se desejar, eu posso:
- gerar os tokens em JSON/SCSS/Flutter automaticamente,
- adicionar exemplos visuais (screenshots ou storybook-like),
- ou extrair valores exatos para cada componente e criar snippets reutilizáveis.
