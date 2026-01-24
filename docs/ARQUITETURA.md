# 🏗️ Arquitetura do Sistema - Ilha Europinha

## 📋 Visão Geral

Sistema mobile-first desenvolvido em Flutter com Firebase, seguindo arquitetura em camadas com separação clara de responsabilidades.

## 🎯 Padrões de Arquitetura

### Estrutura em Camadas

```
┌─────────────────────────────────────┐
│         Presentation Layer          │
│     (Screens, Widgets, Providers)   │
├─────────────────────────────────────┤
│         Business Logic Layer        │
│         (Services, Validators)      │
├─────────────────────────────────────┤
│           Data Layer                │
│      (Models, Repositories)         │
├─────────────────────────────────────┤
│         External Services           │
│    (Firebase Auth, Firestore)       │
└─────────────────────────────────────┘
```

## 📁 Estrutura de Pastas Detalhada

```
lib/
├── main.dart                    # Entry point
├── firebase_options.dart        # Gerado pelo FlutterFire
│
├── models/                      # Modelos de dados
│   ├── user_model.dart
│   ├── house_model.dart
│   ├── resident_model.dart
│   ├── fixed_value_model.dart
│   ├── fixed_payment_model.dart
│   ├── entry_model.dart
│   └── expense_model.dart
│
├── services/                    # Lógica de negócio
│   ├── auth_service.dart        # Autenticação
│   ├── house_service.dart       # CRUD casas
│   ├── resident_service.dart    # CRUD moradores
│   ├── payment_service.dart     # Gestão pagamentos
│   ├── entry_service.dart       # Gestão entradas
│   ├── expense_service.dart     # Gestão despesas
│   └── report_service.dart      # Geração relatórios
│
├── providers/                   # State Management
│   ├── auth_provider.dart       # Estado de autenticação
│   ├── user_provider.dart       # Usuário atual
│   └── theme_provider.dart      # Tema da aplicação
│
├── screens/                     # Telas da aplicação
│   ├── splash_screen.dart
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── forgot_password_screen.dart
│   ├── home/
│   │   └── home_screen.dart
│   ├── users/
│   │   ├── users_list_screen.dart
│   │   ├── user_form_screen.dart
│   │   └── user_details_screen.dart
│   ├── houses/
│   │   ├── houses_list_screen.dart
│   │   ├── house_form_screen.dart
│   │   └── house_details_screen.dart
│   ├── residents/
│   │   ├── residents_list_screen.dart
│   │   └── resident_form_screen.dart
│   ├── financial/
│   │   ├── monthly_charges_screen.dart
│   │   ├── fixed_values_screen.dart
│   │   ├── entries_screen.dart
│   │   └── expenses_screen.dart
│   ├── reports/
│   │   ├── monthly_report_screen.dart
│   │   └── annual_report_screen.dart
│   └── map/
│       └── island_map_screen.dart
│
├── widgets/                     # Widgets reutilizáveis
│   ├── common/
│   │   ├── custom_app_bar.dart
│   │   ├── loading_indicator.dart
│   │   ├── error_widget.dart
│   │   └── empty_state.dart
│   ├── auth/
│   │   └── login_form.dart
│   ├── houses/
│   │   ├── house_card.dart
│   │   └── house_list_tile.dart
│   ├── financial/
│   │   ├── payment_table.dart
│   │   ├── payment_row.dart
│   │   └── financial_summary_card.dart
│   └── map/
│       └── interactive_map.dart
│
├── utils/                       # Utilitários
│   ├── constants.dart           # Constantes
│   ├── validators.dart          # Validações
│   ├── formatters.dart          # Formatadores
│   └── date_utils.dart          # Utilidades de data
│
└── routes/                      # Rotas nomeadas
    └── app_routes.dart
```

## 🔄 Fluxo de Dados

### 1. Authentication Flow

```
LoginScreen
    ↓
AuthService.signIn()
    ↓
Firebase Auth
    ↓
AuthProvider (notifica listeners)
    ↓
Navigation → HomeScreen
```

### 2. Data Read Flow (Exemplo: Listar Casas)

```
HousesListScreen
    ↓
HouseService.getHouses()
    ↓
Firestore Query
    ↓
Stream<List<HouseModel>>
    ↓
StreamBuilder atualiza UI
```

### 3. Data Write Flow (Exemplo: Marcar Pagamento)

```
PaymentRow (toggle)
    ↓
PaymentService.markAsPaid()
    ↓
Validações (permissões, regras)
    ↓
Firestore Update
    ↓
Stream notifica
    ↓
UI atualiza automaticamente
```

## 🔐 Segurança e Permissões

### Camadas de Segurança

1. **Frontend (Flutter)**
   - Verificação de perfil do usuário
   - UI condicional baseada em permissões
   - Validação de inputs

2. **Backend (Firestore Rules)**
   - Validação server-side
   - Controle de acesso por perfil
   - Validação de dados

3. **Authentication**
   - Firebase Auth
   - Session management
   - Token refresh automático

### Matriz de Permissões (implementada em UserModel)

```dart
class UserModel {
  bool get canManageUsers => 
    perfil == UserProfile.admin || 
    perfil == UserProfile.presidencia;
    
  bool get canDeleteUsers => 
    perfil == UserProfile.admin;
    
  bool get canManageFinances => 
    perfil == UserProfile.admin || 
    perfil == UserProfile.tesouraria;
    
  // etc...
}
```

## 📊 Modelos de Dados

### Relacionamentos

```
User
  ↓
  manages
  ↓
House ←→ Resident
  ↓
  generates
  ↓
FixedPayment
```

### Coleções Firestore

```
users/
  {userId}
    - nome, email, perfil, ativo, createdAt

houses/
  {houseId}
    - identificador, status, isenções, mapX, mapY

residents/
  {residentId}
    - nome, dataNascimento, houseId, tipo

fixed_values/
  {valueId}
    - tipo, valorPorCasa, dataInicio, ativo

fixed_payments/
  {paymentId}
    - houseId, tipo, mesReferencia, pago

entries/
  {entryId}
    - tipo, valor, data, mesReferencia, houseId?

expenses/
  {expenseId}
    - categoria, valor, data, mesReferencia
```

## 🎨 UI/UX Architecture

### Telas Responsivas

```dart
// Breakpoints
const mobileBreakpoint = 600;
const tabletBreakpoint = 900;
const desktopBreakpoint = 1200;

// Layout adaptativo
LayoutBuilder(
  builder: (context, constraints) {
    if (constraints.maxWidth < mobileBreakpoint) {
      return MobileLayout();
    } else if (constraints.maxWidth < tabletBreakpoint) {
      return TabletLayout();
    } else {
      return DesktopLayout();
    }
  },
)
```

### Navigation

```dart
// Rotas nomeadas
MaterialApp(
  routes: {
    '/': (_) => SplashScreen(),
    '/login': (_) => LoginScreen(),
    '/home': (_) => HomeScreen(),
    '/houses': (_) => HousesListScreen(),
    // etc...
  },
)
```

## 🔄 State Management (Provider)

### Estrutura de Provider

```dart
MultiProvider(
  providers: [
    Provider<AuthService>(
      create: (_) => AuthService(),
    ),
    StreamProvider<User?>(
      create: (context) => context.read<AuthService>().authStateChanges,
      initialData: null,
    ),
    ChangeNotifierProvider<ThemeProvider>(
      create: (_) => ThemeProvider(),
    ),
  ],
  child: MyApp(),
)
```

### Acessar dados

```dart
// Leitura única
final authService = context.read<AuthService>();

// Com rebuild
final user = context.watch<User?>();

// Sem rebuild
final theme = context.select<ThemeProvider, bool>(
  (provider) => provider.isDarkMode,
);
```

## 📱 Exemplo de Feature Completa: Pagamentos

### 1. Model
```dart
// models/fixed_payment_model.dart
class FixedPaymentModel { ... }
```

### 2. Service
```dart
// services/payment_service.dart
class PaymentService {
  Future<void> markAsPaid(String paymentId, String userId) { ... }
  Stream<List<FixedPaymentModel>> getPaymentsByMonth(String month) { ... }
}
```

### 3. Screen
```dart
// screens/financial/monthly_charges_screen.dart
class MonthlyChargesScreen extends StatelessWidget {
  Widget build(BuildContext context) {
    return StreamBuilder<List<FixedPaymentModel>>( ... );
  }
}
```

### 4. Widget
```dart
// widgets/financial/payment_row.dart
class PaymentRow extends StatelessWidget {
  final FixedPaymentModel payment;
  // Toggle para marcar como pago
}
```

## 🧪 Testes

### Estrutura de Testes

```
test/
├── unit/
│   ├── models/
│   │   └── house_model_test.dart
│   └── services/
│       └── payment_service_test.dart
├── widget/
│   └── payment_row_test.dart
└── integration/
    └── payment_flow_test.dart
```

## 🚀 Performance

### Otimizações

1. **Lazy Loading**: Carregar dados sob demanda
2. **Pagination**: Limitar queries grandes
3. **Caching**: Usar StreamBuilder para cache automático
4. **Const Widgets**: Usar const sempre que possível
5. **Image Optimization**: Comprimir assets

### Monitoramento

- Firebase Performance Monitoring
- Crashlytics para crashes
- Analytics para uso

## 📚 Boas Práticas

### Código Limpo

1. **Single Responsibility**: Uma classe, uma responsabilidade
2. **DRY**: Don't Repeat Yourself
3. **Nomenclatura clara**: Nomes descritivos
4. **Comentários**: Apenas quando necessário
5. **Formatação**: Usar `dart format`

### Firebase

1. **Indexes**: Criar indexes necessários
2. **Security Rules**: Sempre validar server-side
3. **Batch Operations**: Usar batch para múltiplas escritas
4. **Offline Support**: Habilitar persistência

### Flutter

1. **Keys**: Usar keys quando necessário
2. **BuildContext**: Usar corretamente
3. **Dispose**: Sempre liberar recursos
4. **Async**: Tratar erros de async/await

## 🔍 Debugging

### Tools

- Flutter DevTools
- Firebase Console
- VS Code Debugger
- Logging (print → logger package)

### Estratégias

1. Breakpoints
2. Hot Reload/Restart
3. Widget Inspector
4. Network Monitor

---

**Esta arquitetura garante:**
- ✅ Escalabilidade
- ✅ Manutenibilidade
- ✅ Testabilidade
- ✅ Performance
- ✅ Segurança
