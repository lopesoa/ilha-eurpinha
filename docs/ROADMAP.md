# 📋 Roadmap de Desenvolvimento

## ✅ Fase 1: Estrutura Base (CONCLUÍDO)

- [x] Configuração inicial do Flutter
- [x] Dependências do Firebase
- [x] Modelos de dados (7 models criados)
- [x] Serviço de autenticação
- [x] Security Rules do Firestore
- [x] Estrutura de pastas

## 🏗️ Fase 2: Autenticação e Usuários (PRÓXIMO)

### 2.1 Telas de Login/Auth
- [ ] Tela de login
- [ ] Validação de formulário
- [ ] Tratamento de erros
- [ ] Loading states

### 2.2 Gestão de Usuários
- [ ] Tela de listagem de usuários
- [ ] Tela de criação/edição de usuário
- [ ] Verificação de permissões
- [ ] Provider de usuário atual

### Arquivos a criar:
```
lib/screens/auth/
├── login_screen.dart
└── forgot_password_screen.dart

lib/screens/users/
├── users_list_screen.dart
├── user_form_screen.dart
└── user_details_screen.dart

lib/providers/
└── auth_provider.dart
```

## 🏠 Fase 3: Gestão de Casas e Moradores

### 3.1 Casas
- [ ] Service para CRUD de casas
- [ ] Tela de listagem de casas
- [ ] Tela de criação/edição de casa
- [ ] Widget de card de casa
- [ ] Filtros e busca

### 3.2 Moradores
- [ ] Service para CRUD de moradores
- [ ] Tela de listagem de moradores
- [ ] Tela de criação/edição de morador
- [ ] Cálculo automático de idade
- [ ] Identificação de crianças

### 3.3 Mapa da Ilha
- [ ] Widget de visualização do mapa
- [ ] Posicionamento de pins das casas
- [ ] Interação (tap para ver detalhes)
- [ ] Zoom e pan

### Arquivos a criar:
```
lib/services/
├── house_service.dart
└── resident_service.dart

lib/screens/houses/
├── houses_list_screen.dart
├── house_form_screen.dart
└── house_details_screen.dart

lib/screens/residents/
├── residents_list_screen.dart
└── resident_form_screen.dart

lib/screens/map/
└── island_map_screen.dart

lib/widgets/
├── house_card.dart
├── resident_card.dart
└── interactive_map.dart
```

## 💰 Fase 4: Sistema Financeiro

### 4.1 Valores Fixos
- [ ] Service para valores fixos
- [ ] Tela de configuração de valores
- [ ] Histórico de valores
- [ ] Validação (apenas 1 ativo por tipo)

### 4.2 Pagamentos Mensais
- [ ] Service de pagamentos
- [ ] Geração automática de cobranças
- [ ] Tela de cobrança mensal (tabela)
- [ ] Marcar como pago (toggle rápido)
- [ ] Validação das regras (jan/2026, isenções, etc)

### 4.3 Entradas e Despesas
- [ ] Service de entradas
- [ ] Service de despesas
- [ ] Telas de registro
- [ ] Listagem com filtros
- [ ] Cálculo de mês de referência

### Arquivos a criar:
```
lib/services/
├── fixed_value_service.dart
├── payment_service.dart
├── entry_service.dart
└── expense_service.dart

lib/screens/financial/
├── monthly_charges_screen.dart
├── fixed_values_screen.dart
├── entries_screen.dart
├── expenses_screen.dart
└── entry_form_screen.dart

lib/widgets/financial/
├── payment_table.dart
├── payment_row.dart
└── financial_summary_card.dart
```

## 📊 Fase 5: Relatórios

### 5.1 Relatórios Mensais
- [ ] Casas inadimplentes
- [ ] Total esperado vs pago
- [ ] Entradas do mês
- [ ] Despesas do mês
- [ ] Balanço mensal

### 5.2 Relatórios Anuais
- [ ] Resumo anual
- [ ] Gráficos de evolução
- [ ] Comparativo mensal

### 5.3 Relatórios Diversos
- [ ] Quantidade de moradores (adultos/crianças)
- [ ] Taxa de ocupação
- [ ] Histórico de pagamentos por casa

### Arquivos a criar:
```
lib/services/
└── report_service.dart

lib/screens/reports/
├── monthly_report_screen.dart
├── annual_report_screen.dart
└── residents_report_screen.dart

lib/widgets/reports/
├── chart_widget.dart
├── report_card.dart
└── defaulters_list.dart
```

## 🎨 Fase 6: UX/UI e Polimento

- [ ] Navegação completa
- [ ] Tema consistente
- [ ] Responsividade mobile
- [ ] Loading states em todas as telas
- [ ] Mensagens de erro amigáveis
- [ ] Confirmações de ações críticas
- [ ] Feedback visual (snackbars, dialogs)

## 🧪 Fase 7: Testes e Validação

- [ ] Testes unitários dos models
- [ ] Testes dos services
- [ ] Testes de integração
- [ ] Validação das regras de negócio
- [ ] Teste em dispositivos reais

## 🚀 Fase 8: Deploy

- [ ] Configuração de produção do Firebase
- [ ] Security Rules finais
- [ ] Build Android
- [ ] Build iOS (se aplicável)
- [ ] Publicação interna para testes

## 📝 Convenções do Projeto

### Nomenclatura
- **Telas:** `*_screen.dart`
- **Widgets:** `*_widget.dart` ou descrição clara
- **Services:** `*_service.dart`
- **Models:** `*_model.dart`
- **Providers:** `*_provider.dart`

### Organização
- Cada feature em sua pasta
- Widgets reutilizáveis em `lib/widgets/`
- Widgets específicos junto com a tela

### Boas Práticas
- Usar const sempre que possível
- Extrair widgets complexos
- Comentar lógica complexa
- Manter funções pequenas e focadas
- Validar inputs do usuário
- Tratar todos os erros

## 🎯 Prioridades

1. **Alta:** Autenticação, Casas, Pagamentos Mensais
2. **Média:** Moradores, Entradas/Despesas, Relatórios básicos
3. **Baixa:** Mapa interativo, Gráficos avançados, Relatórios detalhados

## 💡 Melhorias Futuras (Fora do Escopo Atual)

- [ ] Notificações push
- [ ] Exportação de relatórios (PDF/Excel)
- [ ] Dashboard com gráficos
- [ ] App nativo separado (iOS/Android)
- [ ] Integração bancária
- [ ] Cobrança automática
- [ ] Portal do morador (self-service)
- [ ] Histórico de ações (audit log)
- [ ] Backup automático
