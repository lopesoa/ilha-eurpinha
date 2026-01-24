# Ilha Europinha - Sistema de Gestão

Aplicação mobile-first desenvolvida em Flutter com Firebase para gestão administrativa e financeira da Ilha Europinha.

## 🏗️ Stack Tecnológica

- **Frontend:** Flutter
- **Backend:** Firebase (Authentication, Firestore)
- **State Management:** Provider
- **Linguagem:** Dart

## 📁 Estrutura do Projeto

```
lib/
├── models/           # Modelos de dados
├── services/         # Serviços (Firebase, etc)
├── screens/          # Telas do app
├── widgets/          # Widgets reutilizáveis
└── providers/        # Providers para state management
```

## 🚀 Configuração Inicial

### 1. Instalar Dependências

```bash
flutter pub get
```

### 2. Configurar Firebase

```bash
# Instalar FlutterFire CLI
dart pub global activate flutterfire_cli

# Configurar Firebase
flutterfire configure
```

Este comando vai:
- Criar o projeto no Firebase Console (ou selecionar existente)
- Configurar Authentication, Firestore
- Gerar o arquivo `firebase_options.dart`

### 3. Ativar Serviços no Firebase Console

1. **Authentication:**
   - Ir para Authentication > Sign-in method
   - Ativar "Email/Password"

2. **Firestore Database:**
   - Ir para Firestore Database
   - Criar banco de dados em modo de teste (depois configurar Security Rules)

3. **Security Rules (Firestore):**
   - Ver arquivo `firestore.rules` para regras de segurança

### 4. Descomentar o Firebase no main.dart

Após executar `flutterfire configure`, descomentar as linhas no `lib/main.dart`:

```dart
import 'firebase_options.dart';

await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

## 📱 Executar o App

```bash
flutter run
```

## 🏠 Mapa da Ilha

O mapa da ilha é uma **imagem estática** armazenada em `assets/images/`.

### Adicionar o mapa:
1. Colocar a imagem em `assets/images/mapa_ilha.png`
2. As coordenadas das casas são relativas (0-1) no eixo X e Y
3. O mapa se adapta automaticamente a qualquer resolução

### Vantagens dessa abordagem:
- ✅ Funciona offline
- ✅ Sem custos de API
- ✅ Performance otimizada
- ✅ Customização total

## 🔐 Perfis de Usuário

- **Admin:** Controle total do sistema
- **Presidência:** Gestão de usuários e relatórios
- **Diretoria:** Visualização de relatórios
- **Tesouraria:** Gestão financeira
- **Usuário:** Acesso limitado

## 📊 Funcionalidades Principais

- ✅ Gestão de casas e moradores
- ✅ Controle de pagamentos de água e luz
- ✅ Registro de entradas financeiras
- ✅ Registro de despesas
- ✅ Relatórios mensais e anuais
- ✅ Mapa interativo da ilha

## 📅 Regras de Cobrança

- Sistema válido a partir de **janeiro/2026**
- Cobrança apenas para casas ativas
- Respeita isenções configuradas
- Histórico preservado (sem retroatividade)

## 📝 Próximos Passos

1. ✅ Estrutura base criada
2. ⏳ Configurar Firebase (`flutterfire configure`)
3. ⏳ Implementar telas de login
4. ⏳ Implementar telas principais
5. ⏳ Configurar Security Rules do Firestore
6. ⏳ Adicionar mapa da ilha
7. ⏳ Testes e validações

## 📚 Documentação

Ver `docs/requisitos.md` para detalhes completos dos requisitos do sistema.
