import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../users/users_list_screen.dart';
import '../houses/houses_list_screen.dart';
import '../residents/residents_list_screen.dart';
import '../fixed_values/fixed_values_list_screen.dart';
import '../financial/monthly_charges_screen.dart';
import '../entries/entries_list_screen.dart';
import '../expenses/expenses_list_screen.dart';
import '../reports/reports_screen.dart';
import '../map/mapa_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Recarrega os dados do usuário quando a tela é carregada
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      authProvider.reloadUserData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ilha Europinha'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(context),
            tooltip: 'Sair',
          ),
        ],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card de boas-vindas
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            child: Text(
                              user.nome[0].toUpperCase(),
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimaryContainer,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Olá, ${user.nome}!',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _getPerfilLabel(user.perfil),
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Menu de opções
                  Text(
                    'Menu Principal',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Grid de opções
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      if (user.canManageUsers)
                        _MenuCard(
                          icon: Icons.people,
                          title: 'Usuários',
                          subtitle: 'Gerenciar usuários',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const UsersListScreen(),
                            ),
                          ),
                        ),
                      if (user.canManageHouses)
                        _MenuCard(
                          icon: Icons.home,
                          title: 'Casas',
                          subtitle: 'Gerenciar casas',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HousesListScreen(),
                            ),
                          ),
                        ),
                      if (user.canManageHouses)
                        _MenuCard(
                          icon: Icons.group,
                          title: 'Moradores',
                          subtitle: 'Gerenciar moradores',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ResidentsListScreen(),
                            ),
                          ),
                        ),
                      if (user.canManageFinances)
                        _MenuCard(
                          icon: Icons.payment,
                          title: 'Cobranças',
                          subtitle: 'Mensalidades',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const MonthlyChargesScreen(),
                            ),
                          ),
                        ),
                      if (user.canManageFinances)
                        _MenuCard(
                          icon: Icons.trending_up,
                          title: 'Entradas',
                          subtitle: 'Receitas',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EntriesListScreen(),
                            ),
                          ),
                        ),
                      if (user.canManageFinances)
                        _MenuCard(
                          icon: Icons.trending_down,
                          title: 'Despesas',
                          subtitle: 'Gastos',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ExpensesListScreen(),
                            ),
                          ),
                        ),
                      if (user.canManageFinances)
                        _MenuCard(
                          icon: Icons.attach_money,
                          title: 'Valores Fixos',
                          subtitle: 'Mensalidades por casa',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const FixedValuesListScreen(),
                            ),
                          ),
                        ),
                      if (user.canViewReports)
                        _MenuCard(
                          icon: Icons.assessment,
                          title: 'Relatórios',
                          subtitle: 'Visualizar relatórios',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ReportsScreen(),
                            ),
                          ),
                        ),
                      if (user.perfil == UserProfile.admin)
                        _MenuCard(
                          icon: Icons.security,
                          title: 'Controle de Acesso',
                          subtitle: 'Permissões por perfil',
                          onTap: () =>
                              Navigator.pushNamed(context, '/access-control'),
                        ),
                      _MenuCard(
                        icon: Icons.map,
                        title: 'Mapa',
                        subtitle: 'Mapa da ilha',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MapaScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  String _getPerfilLabel(UserProfile perfil) {
    switch (perfil) {
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

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair'),
        content: const Text('Deseja realmente sair do sistema?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<AuthProvider>().signOut();
    }
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
