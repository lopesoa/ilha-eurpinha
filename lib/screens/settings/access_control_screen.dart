import 'package:flutter/material.dart';
import '../../models/user_model.dart';

class AccessControlScreen extends StatelessWidget {
  const AccessControlScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Controle de Acesso')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Permissões por Perfil',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildProfileCard(
            context,
            profile: UserProfile.admin,
            icon: Icons.admin_panel_settings,
            color: Colors.red,
          ),
          const SizedBox(height: 12),
          _buildProfileCard(
            context,
            profile: UserProfile.presidencia,
            icon: Icons.person,
            color: Colors.purple,
          ),
          const SizedBox(height: 12),
          _buildProfileCard(
            context,
            profile: UserProfile.diretoria,
            icon: Icons.business,
            color: Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildProfileCard(
            context,
            profile: UserProfile.tesouraria,
            icon: Icons.account_balance,
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          _buildProfileCard(
            context,
            profile: UserProfile.usuario,
            icon: Icons.person_outline,
            color: Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(
    BuildContext context, {
    required UserProfile profile,
    required IconData icon,
    required Color color,
  }) {
    final permissions = _getPermissions(profile);

    return Card(
      elevation: 4,
      child: ExpansionTile(
        leading: Icon(icon, color: color, size: 32),
        title: Text(
          _getProfileName(profile),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 18,
          ),
        ),
        subtitle: Text('${permissions.length} permissões'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...permissions.map(
                  (permission) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          permission.allowed
                              ? Icons.check_circle
                              : Icons.cancel,
                          color: permission.allowed ? Colors.green : Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                permission.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  decoration: permission.allowed
                                      ? null
                                      : TextDecoration.lineThrough,
                                ),
                              ),
                              if (permission.description != null)
                                Text(
                                  permission.description!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getProfileName(UserProfile profile) {
    switch (profile) {
      case UserProfile.admin:
        return 'Administrador';
      case UserProfile.presidencia:
        return 'Presidência';
      case UserProfile.diretoria:
        return 'Diretoria';
      case UserProfile.tesouraria:
        return 'Tesouraria';
      case UserProfile.usuario:
        return 'Usuário';
    }
  }

  List<Permission> _getPermissions(UserProfile profile) {
    final allPermissions = [
      // Gestão de Usuários
      Permission(
        'Criar/Editar Usuários',
        description: 'Criar novos usuários e editar existentes',
        allowed:
            profile == UserProfile.admin || profile == UserProfile.presidencia,
      ),
      Permission(
        'Excluir Usuários',
        description: 'Remover usuários do sistema',
        allowed: profile == UserProfile.admin,
      ),
      Permission(
        'Visualizar Usuários',
        description: 'Acessar lista de usuários',
        allowed:
            profile == UserProfile.admin || profile == UserProfile.presidencia,
      ),

      // Gestão de Casas
      Permission(
        'Criar/Editar Casas',
        description: 'Cadastrar e editar casas',
        allowed:
            profile == UserProfile.admin ||
            profile == UserProfile.presidencia ||
            profile == UserProfile.diretoria,
      ),
      Permission(
        'Excluir Casas',
        description: 'Remover casas do sistema',
        allowed: profile == UserProfile.admin,
      ),
      Permission(
        'Visualizar Casas',
        description: 'Acessar lista de casas',
        allowed: true, // Todos podem visualizar
      ),

      // Gestão de Residentes
      Permission(
        'Criar/Editar Residentes',
        description: 'Cadastrar e editar moradores',
        allowed:
            profile == UserProfile.admin ||
            profile == UserProfile.presidencia ||
            profile == UserProfile.diretoria,
      ),
      Permission(
        'Excluir Residentes',
        description: 'Remover residentes do sistema',
        allowed: profile == UserProfile.admin,
      ),
      Permission(
        'Visualizar Residentes',
        description: 'Acessar lista de moradores',
        allowed: true, // Todos podem visualizar
      ),

      // Gestão Financeira
      Permission(
        'Gerenciar Valores Fixos',
        description: 'Criar, editar e histórico de valores fixos',
        allowed:
            profile == UserProfile.admin || profile == UserProfile.tesouraria,
      ),
      Permission(
        'Gerenciar Cobranças Mensais',
        description: 'Marcar pagamentos de cobranças fixas',
        allowed:
            profile == UserProfile.admin || profile == UserProfile.tesouraria,
      ),
      Permission(
        'Gerenciar Receitas',
        description: 'Cadastrar e editar receitas extras',
        allowed:
            profile == UserProfile.admin || profile == UserProfile.tesouraria,
      ),
      Permission(
        'Gerenciar Despesas',
        description: 'Cadastrar e editar despesas',
        allowed:
            profile == UserProfile.admin || profile == UserProfile.tesouraria,
      ),
      Permission(
        'Excluir Registros Financeiros',
        description: 'Remover cobranças, receitas e despesas',
        allowed: profile == UserProfile.admin,
      ),

      // Relatórios
      Permission(
        'Visualizar Relatórios',
        description: 'Acessar relatórios financeiros e de residentes',
        allowed: profile != UserProfile.usuario,
      ),
      Permission(
        'Relatório Mensal',
        description: 'Ver detalhes financeiros mensais',
        allowed: profile != UserProfile.usuario,
      ),
      Permission(
        'Relatório Anual',
        description: 'Ver consolidado anual',
        allowed: profile != UserProfile.usuario,
      ),
      Permission(
        'Relatório de Saldo',
        description: 'Ver saldo em conta e fluxo de caixa',
        allowed: profile != UserProfile.usuario,
      ),
      Permission(
        'Relatório de Residentes',
        description: 'Ver estatísticas de moradores',
        allowed: profile != UserProfile.usuario,
      ),

      // Funcionalidades Gerais
      Permission(
        'Acesso ao Mapa da Ilha',
        description: 'Visualizar mapa com localização das casas',
        allowed: true, // Todos podem visualizar
      ),
    ];

    return allPermissions;
  }
}

class Permission {
  final String name;
  final String? description;
  final bool allowed;

  Permission(this.name, {this.description, required this.allowed});
}
