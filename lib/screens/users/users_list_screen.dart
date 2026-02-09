import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../services/user_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_display.dart';
import 'user_form_screen.dart';

class UsersListScreen extends StatelessWidget {
  const UsersListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userService = UserService();
    final currentUser = context.read<AuthProvider>().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuários'),
        actions: [
          if (currentUser?.canManageUsers == true)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _navigateToForm(context),
              tooltip: 'Adicionar usuário',
            ),
        ],
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: userService.getUsersStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorDisplay(
              message: 'Erro ao carregar usuários',
              onRetry: () {
                // Rebuild para tentar novamente
              },
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!;

          if (users.isEmpty) {
            return EmptyState(
              icon: Icons.people_outline,
              message: 'Nenhum usuário cadastrado',
              actionLabel: currentUser?.canManageUsers == true
                  ? 'Adicionar usuário'
                  : null,
              onAction: currentUser?.canManageUsers == true
                  ? () => _navigateToForm(context)
                  : null,
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return _UserCard(
                user: user,
                currentUser: currentUser,
                onTap: () => _navigateToForm(context, user: user),
              );
            },
          );
        },
      ),
    );
  }

  void _navigateToForm(BuildContext context, {UserModel? user}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UserFormScreen(user: user)),
    );
  }
}

class _UserCard extends StatelessWidget {
  final UserModel user;
  final UserModel? currentUser;
  final VoidCallback onTap;

  const _UserCard({
    required this.user,
    required this.currentUser,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: currentUser?.canManageUsers == true ? onTap : null,
        leading: CircleAvatar(
          backgroundColor: user.ativo
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.grey[300],
          child: Text(
            user.nome[0].toUpperCase(),
            style: TextStyle(
              color: user.ativo
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : Colors.grey[600],
            ),
          ),
        ),
        title: Text(
          user.nome,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: user.ativo ? null : TextDecoration.lineThrough,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email),
            const SizedBox(height: 4),
            Row(
              children: [
                _PerfilChip(perfil: user.perfil),
                const SizedBox(width: 8),
                if (!user.ativo)
                  Chip(
                    label: const Text('Inativo'),
                    backgroundColor: Colors.red[100],
                    labelStyle: TextStyle(fontSize: 12, color: Colors.red[900]),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
              ],
            ),
          ],
        ),
        trailing: currentUser?.canManageUsers == true
            ? const Icon(Icons.chevron_right)
            : null,
      ),
    );
  }
}

class _PerfilChip extends StatelessWidget {
  final UserProfile perfil;

  const _PerfilChip({required this.perfil});

  @override
  Widget build(BuildContext context) {
    final label = _getPerfilLabel();
    final color = _getPerfilColor();

    return Chip(
      label: Text(label),
      backgroundColor: color.withOpacity(0.2),
      labelStyle: TextStyle(
        fontSize: 12,
        color: color,
        fontWeight: FontWeight.bold,
      ),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  String _getPerfilLabel() {
    switch (perfil) {
      case UserProfile.admin:
        return 'Admin';
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

  Color _getPerfilColor() {
    switch (perfil) {
      case UserProfile.admin:
        return Colors.red;
      case UserProfile.presidencia:
        return Colors.purple;
      case UserProfile.diretoria:
        return Colors.blue;
      case UserProfile.tesouraria:
        return Colors.green;
      case UserProfile.usuario:
        return Colors.grey;
    }
  }
}
