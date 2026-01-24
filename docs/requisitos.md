# Sistema de Gestão da Ilha

## 1. Visão Geral

Aplicação **mobile-first**, desenvolvida em **Flutter** com **Firebase**, para substituir controles em papel e permitir a gestão administrativa e financeira de uma ilha.

O sistema será usado por Presidência, Tesouraria, Diretoria e usuários comuns, com regras claras de permissão, histórico financeiro confiável e foco em simplicidade.

---

## 2. Objetivos do Sistema

* Controlar casas e moradores da ilha
* Gerenciar cobranças fixas de **água e luz por casa**
* Registrar **entradas financeiras livres**
* Registrar **despesas**
* Gerar relatórios mensais e anuais
* Manter histórico confiável (sem retroatividade)
* Funcionar perfeitamente em **celular**

---

## 3. Stack Tecnológica

* **Frontend:** Flutter
* **Backend:** Firebase

  * Firebase Authentication
  * Cloud Firestore
  * Firebase Storage (mapa da ilha)
* **Controle de acesso:** RBAC por perfil de negócio

---

## 4. Perfis de Usuário (Perfil de Negócio)

Campo obrigatório no usuário: `perfil`

Valores possíveis:

* `admin` (técnico do sistema)
* `presidencia` (admin de negócio)
* `diretoria`
* `tesouraria`
* `usuario`

> Observação: o perfil de negócio é independente do nível nativo do Firebase Auth.

---

## 5. Regras de Permissão

| Ação                  | Admin | Presidência | Diretoria | Tesouraria | Usuário |
| --------------------- | ----- | ----------- | --------- | ---------- | ------- |
| Cadastrar usuários    | ✅     | ✅           | ❌         | ❌          | ❌       |
| Editar usuários       | ✅     | ✅           | ❌         | ❌          | ❌       |
| Excluir usuários      | ✅     | ❌           | ❌         | ❌          | ❌       |
| Lançar pagamentos     | ✅     | ❌           | ❌         | ✅          | ❌       |
| Lançar entradas       | ✅     | ❌           | ❌         | ✅          | ❌       |
| Lançar despesas       | ✅     | ❌           | ❌         | ✅          | ❌       |
| Excluir registros     | ✅     | ❌           | ❌         | ❌          | ❌       |
| Visualizar relatórios | ✅     | ✅           | ✅         | ✅          | ❌       |

---

## 6. Modelo de Dados (Firestore)

### 6.1 Usuário

```
users/{userId}
```

Campos:

* nome
* email
* perfil
* ativo
* createdAt

---

### 6.2 Casa

```
houses/{houseId}
```

Campos:

* identificador (ex: "Casa 12")
* status (`ativa` | `inativa`)
* isentaAgua (bool)
* isentaLuz (bool)
* dataInicioCobranca (Date)
* createdAt

Regras:

* Casas inativas não geram cobranças futuras
* Histórico é preservado

---

### 6.3 Morador

```
residents/{residentId}
```

Campos:

* nome
* dataNascimento
* houseId
* tipo (`responsavel` | `integrante`)
* status

Regras:

* Criança = idade < 12 anos (calculada)

---

### 6.4 Valor Fixo

```
fixed_values/{id}
```

Campos:

* tipo (`agua` | `luz`)
* valorPorCasa
* dataInicio
* dataFim (opcional)
* ativo

Regras:

* Apenas 1 ativo por tipo
* Histórico deve ser mantido

---

### 6.5 Pagamento Fixo

```
fixed_payments/{id}
```

Campos:

* houseId
* tipo (`agua` | `luz`)
* mesReferencia (YYYY-MM)
* pago (bool)
* dataPagamento
* marcadoPor (userId)

Regras:

* Gerado apenas para casas ativas e não isentas
* Cobrança válida apenas a partir de janeiro/2026
* Cobrança é sempre de mês inteiro
* Nunca gerar cobranças retroativas

---

### 6.6 Entradas Financeiras

```
entries/{id}
```

Campos:

* tipo (`doacao` | `contribuicao_extra` | `evento` | `multa` | `outro`)
* houseId (opcional)
* valor
* data
* mesReferencia
* observacao
* createdBy

---

### 6.7 Despesas

```
expenses/{id}
```

Campos:

* categoria (`agua` | `luz` | `manutencao` | `outro`)
* valor
* data
* mesReferencia
* observacao
* createdBy

---

### 6.8 Mapa da Ilha

**Decisão de Arquitetura:** o mapa da ilha será um **asset estático do Flutter**, não armazenado no Firebase.

* A imagem do mapa (PNG/JPG) ficará em `assets/images/`
* Registrada no `pubspec.yaml`
* Não utiliza Firebase Storage nesta fase

O backend armazenará apenas as **coordenadas das casas** relativas ao mapa.

#### Campos adicionais em Casa

```
mapX: number  // valor entre 0 e 1 (posição horizontal relativa)
mapY: number  // valor entre 0 e 1 (posição vertical relativa)
```

Regras:

* As coordenadas representam a posição da casa no mapa
* O mapa se adapta a qualquer resolução de tela
* A imagem do mapa é fixa no app

---

## 7. Regras de Cobrança (CRÍTICAS)

* Sistema válido somente a partir de **janeiro/2026**
* Cobrança apenas se:

  * casa ativa
  * mês >= dataInicioCobranca
  * mês >= 01/2026
* Casas isentas não geram cobrança nem inadimplência
* Pagamento controlado apenas por flag pago/não pago

---

## 8. Interface (UX)

### 8.1 Tela de Cobrança Mensal

Filtro: mês/ano

Tabela:

```
Casa | Água | Luz
Casa 01 | ✅ | ❌
Casa 02 | — | ✅
```

* `—` = isento
* Toque rápido para marcar pago

---

## 9. Relatórios

* Casas inadimplentes por mês
* Total esperado vs total pago
* Entradas e saídas mensais
* Relatório anual
* Quantidade de crianças e adultos

---

## 10. Segurança

* Apenas Admin pode excluir registros
* Logs de criação e pagamento devem registrar usuário
* Firestore Rules baseadas em perfil

---

## 11. Fora de Escopo (por enquanto)

* Cobrança automática
* Integração bancária
* App nativo iOS/Android separado
* Notificações push

---

## 12. Diretriz Final

Priorizar:

* simplicidade
* clareza
* uso no celular
* regras explícitas
* histórico confiável
