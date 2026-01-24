# 📋 Comandos Úteis - Ilha Europinha

## 🔥 Firebase

### Configuração Inicial
```bash
# Instalar Firebase CLI
npm install -g firebase-tools

# Fazer login
firebase login

# Instalar FlutterFire CLI
dart pub global activate flutterfire_cli

# Configurar Firebase no projeto
flutterfire configure

# Reconfigurar (se precisar mudar algo)
flutterfire configure --force
```

### Gerenciar Firestore
```bash
# Deploy das Security Rules
firebase deploy --only firestore:rules

# Deploy dos indexes
firebase deploy --only firestore:indexes

# Backup do Firestore (requer configuração)
gcloud firestore export gs://[BUCKET_NAME]
```

## 📱 Flutter

### Instalação e Configuração
```bash
# Verificar instalação do Flutter
flutter doctor

# Instalar dependências
flutter pub get

# Atualizar dependências
flutter pub upgrade

# Verificar pacotes desatualizados
flutter pub outdated

# Limpar cache de build
flutter clean

# Obter dependências após limpar
flutter clean && flutter pub get
```

### Desenvolvimento
```bash
# Rodar app em modo debug
flutter run

# Rodar em device específico
flutter run -d [device_id]

# Listar devices disponíveis
flutter devices

# Rodar com hot reload ativado
flutter run --hot

# Rodar em modo release
flutter run --release

# Rodar em modo profile (para análise de performance)
flutter run --profile
```

### Build
```bash
# Build APK (Android)
flutter build apk

# Build APK em modo release
flutter build apk --release

# Build App Bundle (recomendado para Play Store)
flutter build appbundle

# Build iOS
flutter build ios

# Build para Web
flutter build web
```

### Análise e Qualidade
```bash
# Analisar código
flutter analyze

# Formatar código
dart format .

# Formatar arquivo específico
dart format lib/main.dart

# Verificar formatação sem alterar
dart format --output=none --set-exit-if-changed .

# Rodar testes
flutter test

# Rodar testes com coverage
flutter test --coverage

# Ver coverage report (requer lcov)
genhtml coverage/lcov.info -o coverage/html
```

### Debugging
```bash
# Ativar DevTools
flutter pub global activate devtools

# Rodar DevTools
flutter pub global run devtools

# Logs do app
flutter logs

# Conectar ao DevTools enquanto app roda
flutter run --debug
```

## 🔍 Firestore Debug

### Via Firebase Console
1. Acesse: https://console.firebase.google.com
2. Selecione seu projeto
3. Firestore Database > Data

### Via Firebase CLI (Emulator)
```bash
# Inicializar emuladores
firebase init emulators

# Rodar emulador do Firestore
firebase emulators:start --only firestore

# Rodar todos os emuladores
firebase emulators:start
```

## 📊 Monitoramento

### Performance
```bash
# Perfil de performance
flutter run --profile

# Build size analysis
flutter build apk --analyze-size
flutter build appbundle --analyze-size
```

### Logs do Firebase
```bash
# Ver logs em tempo real
firebase functions:log

# Ver logs de deploy
firebase deploy --debug
```

## 🔧 Utilitários

### Gerenciar Packages Globais Dart
```bash
# Listar packages globais
dart pub global list

# Atualizar package global
dart pub global activate [package_name]

# Remover package global
dart pub global deactivate [package_name]
```

### Git
```bash
# Commit inicial
git add .
git commit -m "chore: initial setup with Firebase and models"

# Verificar status
git status

# Ver diferenças
git diff

# Criar branch para feature
git checkout -b feature/authentication
```

### Limpar Projeto
```bash
# Limpar tudo e reinstalar
flutter clean
rm -rf pubspec.lock
rm -rf .dart_tool/
flutter pub get
```

## 🐛 Solução de Problemas

### Problema: "CocoaPods not installed"
```bash
# macOS/iOS
sudo gem install cocoapods
pod setup
```

### Problema: "Android licenses not accepted"
```bash
flutter doctor --android-licenses
```

### Problema: "Gradle build failed"
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

### Problema: "Firebase not initialized"
```bash
# Reconfigurar Firebase
flutterfire configure --force

# Verificar se import está correto no main.dart
# import 'firebase_options.dart';
```

### Problema: "Package version conflict"
```bash
# Resolver dependências
flutter pub get
flutter pub upgrade --major-versions

# Se persistir, deletar pubspec.lock
rm pubspec.lock
flutter pub get
```

## 📝 Dicas de Produtividade

### Aliases Úteis (adicione no .bashrc ou .zshrc)
```bash
alias frun="flutter run"
alias fpub="flutter pub get"
alias fclean="flutter clean && flutter pub get"
alias ftest="flutter test"
alias fbuild="flutter build apk --release"
alias fanalyze="flutter analyze"
```

### VS Code Shortcuts
- `Ctrl + Shift + R` - Hot Reload
- `Ctrl + F5` - Run without debugging
- `F5` - Start debugging
- `Shift + F5` - Stop debugging

### Comandos Flutter no VS Code
1. `Ctrl + Shift + P` (Command Palette)
2. Digite "Flutter"
3. Veja comandos disponíveis

## 🚀 Deploy para Produção

### Android
```bash
# 1. Configurar keystore (primeira vez)
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# 2. Configurar key.properties
# Ver: android/key.properties

# 3. Build release
flutter build appbundle --release

# 4. Upload para Play Console
# Arquivo gerado: build/app/outputs/bundle/release/app-release.aab
```

### iOS
```bash
# 1. Abrir no Xcode
open ios/Runner.xcworkspace

# 2. Configurar certificados e provisioning
# 3. Build for release
flutter build ios --release

# 4. Archive via Xcode
# Product > Archive > Distribute App
```

## 📚 Recursos

- [Flutter Docs](https://docs.flutter.dev/)
- [FlutterFire Docs](https://firebase.flutter.dev/)
- [Firebase CLI Reference](https://firebase.google.com/docs/cli)
- [Dart Packages](https://pub.dev/)
