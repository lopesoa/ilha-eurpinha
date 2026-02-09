# Índices Necessários no Firestore

## ⚠️ Importante

Para que os relatórios funcionem corretamente, você precisa criar os seguintes índices compostos no Firestore.

## 📋 Índices Obrigatórios

### 1. Índice para Pagamentos Fixos (fixed_payments)

**Coleção:** `fixed_payments`
**Campos:**
- `mes` (Ascending)
- `ano` (Ascending)

Este índice é necessário para as queries de relatórios mensais.

### 2. Índice para Entradas (entries)

**Coleção:** `entries`
**Campos:**
- `data` (Ascending)

Este índice permite filtrar entradas por período.

### 3. Índice para Despesas (expenses)

**Coleção:** `expenses`
**Campos:**
- `data` (Ascending)
- `pago` (Ascending)

Este índice permite filtrar despesas pagas por período.

### 4. Índice para Casas por Status (houses)

**Coleção:** `houses`
**Campos:**
- `status` (Ascending)
- `identificador` (Ascending)

Este índice permite listar casas ativas ordenadas por identificador.

### 5. Índice para Valores Fixos (fixed_values)

**Coleção:** `fixed_values`
**Campos:**
- `ativo` (Ascending)
- `tipo` (Ascending)

Este índice permite buscar valores fixos ativos por tipo.

## 🔧 Como Criar os Índices

### Opção 1: Automaticamente (Recomendado)

1. Execute a aplicação e tente gerar um relatório
2. O Firebase mostrará um erro com um link direto para criar o índice
3. Clique no link e confirme a criação
4. Aguarde alguns minutos até o índice ser criado

### Opção 2: Manualmente no Console do Firebase

1. Acesse o [Firebase Console](https://console.firebase.google.com/)
2. Selecione seu projeto
3. Vá em **Firestore Database** > **Índices**
4. Clique em **Criar Índice**
5. Configure os campos conforme especificado acima
6. Salve e aguarde a criação

## 📊 Verificando os Índices

Para verificar se os índices estão funcionando:

1. Acesse o Firebase Console
2. Vá em **Firestore Database** > **Índices**
3. Verifique se todos os índices estão com status **Habilitado** (em verde)

## 🚨 Erros Comuns

### "The query requires an index"

Este erro significa que você tentou fazer uma query que precisa de um índice composto. O erro geralmente vem com um link para criar o índice automaticamente.

### "Index creation failed"

- Verifique se você tem permissões de administrador no projeto
- Verifique se os nomes dos campos estão corretos
- Aguarde alguns minutos e tente novamente

## ✅ Alterações Recentes

### Query de Pagamentos Otimizada

O sistema foi atualizado para usar queries mais eficientes:

**Antes:** 
```dart
.where('mesReferencia', isEqualTo: '2026-01')
```

**Agora:**
```dart
.where('mes', isEqualTo: 1)
.where('ano', isEqualTo: 2026)
```

Isso evita a necessidade de índices compostos complexos e melhora a performance das queries.

## 📝 Notas

- Os índices podem levar alguns minutos para serem criados
- Índices são globais para todo o projeto Firebase
- Você pode monitorar o uso de índices na aba de métricas do Firestore
