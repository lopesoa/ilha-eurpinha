# 🔥 Guia de Configuração do Firebase

## Passo 1: Instalar o FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
```

## Passo 2: Fazer Login no Firebase

```bash
firebase login
```

Se você não tem Firebase CLI instalado, instale antes:

```bash
npm install -g firebase-tools
```

## Passo 3: Configurar o Firebase no Projeto

No diretório do projeto, execute:

```bash
flutterfire configure
```

Este comando irá:
1. Perguntar qual conta Google usar
2. Perguntar se quer criar um novo projeto ou usar existente
3. Sugerir um nome (pode aceitar ou modificar)
4. Selecionar plataformas (Android, iOS, Web, etc)
5. Gerar automaticamente o arquivo `firebase_options.dart`

**Importante:** Selecione pelo menos:
- ✅ Android
- ✅ iOS
- ✅ Web (opcional, mas recomendado)

## Passo 4: Ativar Serviços no Firebase Console

Acesse: https://console.firebase.google.com

### 4.1 Authentication

1. No menu lateral, clique em **Authentication**
2. Clique em **Get Started** (se for a primeira vez)
3. Vá em **Sign-in method**
4. Clique em **Email/Password**
5. Ative a opção
6. Clique em **Save**

### 4.2 Firestore Database

1. No menu lateral, clique em **Firestore Database**
2. Clique em **Create database**
3. Escolha localização (ex: `southamerica-east1` para São Paulo)
4. Comece em **test mode** (vamos configurar as regras depois)
5. Clique em **Enable**

### 4.3 Configurar Security Rules

1. Em Firestore Database, vá na aba **Rules**
2. Copie o conteúdo do arquivo `firestore.rules` do projeto
3. Cole no editor de regras
4. Clique em **Publish**

## Passo 5: Descomentar Código no main.dart

Abra `lib/main.dart` e:

1. Descomente a linha:
```dart
import 'firebase_options.dart';
```

2. Descomente o bloco:
```dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

## Passo 6: Criar Primeiro Usuário Admin

Como o sistema exige permissões, você precisa criar o primeiro usuário manualmente:

### Via Firebase Console:

1. Vá em **Authentication** > **Users**
2. Clique em **Add user**
3. Adicione email e senha
4. Copie o **UID** do usuário criado

### Via Firestore Console:

1. Vá em **Firestore Database**
2. Clique em **Start collection**
3. Collection ID: `users`
4. Document ID: [Cole o UID copiado]
5. Adicione os campos:
   - `nome` (string): "Admin"
   - `email` (string): [o email que você criou]
   - `perfil` (string): "admin"
   - `ativo` (boolean): true
   - `createdAt` (timestamp): [data atual]
6. Clique em **Save**

## Passo 7: Testar

```bash
flutter run
```

## ✅ Checklist de Configuração

- [ ] FlutterFire CLI instalado
- [ ] `flutterfire configure` executado
- [ ] `firebase_options.dart` gerado
- [ ] Authentication ativado (Email/Password)
- [ ] Firestore Database criado
- [ ] Security Rules configuradas
- [ ] Primeiro usuário admin criado
- [ ] Código do main.dart descomentado
- [ ] App rodando sem erros

## 🆘 Problemas Comuns

### "firebase_options.dart not found"
- Execute `flutterfire configure` novamente

### "Permission denied" no Firestore
- Verifique se as Security Rules foram publicadas
- Verifique se o usuário tem o perfil correto no Firestore

### "No Firebase App '[DEFAULT]' has been created"
- Verifique se descomentou o `Firebase.initializeApp()` no main.dart
- Verifique se o import do `firebase_options.dart` está correto

### "Platform-specific configuration files missing"
- Execute `flutterfire configure` e selecione as plataformas necessárias

## 📚 Recursos

- [Documentação FlutterFire](https://firebase.flutter.dev/)
- [Firebase Console](https://console.firebase.google.com/)
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/get-started)
