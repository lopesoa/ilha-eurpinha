import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/house_model.dart';
import '../../services/house_service.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_display.dart';
import 'house_form_screen.dart';

class HousesListScreen extends StatelessWidget {
  const HousesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final houseService = HouseService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Casas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToForm(context),
            tooltip: 'Adicionar casa',
          ),
        ],
      ),
      body: StreamBuilder<List<HouseModel>>(
        stream: houseService.getHousesStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const ErrorDisplay(message: 'Erro ao carregar casas');
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final houses = snapshot.data!;

          if (houses.isEmpty) {
            return EmptyState(
              icon: Icons.home_outlined,
              message: 'Nenhuma casa cadastrada',
              actionLabel: 'Adicionar casa',
              onAction: () => _navigateToForm(context),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: houses.length,
            itemBuilder: (context, index) {
              final house = houses[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  onTap: () => _navigateToForm(context, house: house),
                  leading: CircleAvatar(
                    backgroundColor: house.status == HouseStatus.ativa
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Colors.grey[300],
                    child: Icon(
                      Icons.home,
                      color: house.status == HouseStatus.ativa
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : Colors.grey[600],
                    ),
                  ),
                  title: Text(
                    house.identificador,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        house.status == HouseStatus.ativa ? 'Ativa' : 'Inativa',
                      ),
                      if (house.isentaAgua || house.isentaAssociacao)
                        Text(
                          'Isenções: ${house.isentaAgua ? "Água" : ""}${house.isentaAgua && house.isentaAssociacao ? ", " : ""}${house.isentaAssociacao ? "Associação" : ""}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[700],
                          ),
                        ),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _navigateToForm(BuildContext context, {HouseModel? house}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HouseFormScreen(house: house)),
    );
  }
}
