import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/resident_model.dart';
import '../../models/house_model.dart';
import '../../services/resident_service.dart';
import '../../services/house_service.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_display.dart';
import 'resident_form_screen.dart';

class ResidentsListScreen extends StatelessWidget {
  const ResidentsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final residentService = ResidentService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Moradores'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToForm(context),
            tooltip: 'Adicionar morador',
          ),
        ],
      ),
      body: StreamBuilder<List<ResidentModel>>(
        stream: residentService.getResidentsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const ErrorDisplay(message: 'Erro ao carregar moradores');
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final residents = snapshot.data!;

          if (residents.isEmpty) {
            return EmptyState(
              icon: Icons.people_outline,
              message: 'Nenhum morador cadastrado',
              actionLabel: 'Adicionar morador',
              onAction: () => _navigateToForm(context),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: residents.length,
            itemBuilder: (context, index) {
              final resident = residents[index];
              return _ResidentCard(
                resident: resident,
                onTap: () => _navigateToForm(context, resident: resident),
              );
            },
          );
        },
      ),
    );
  }

  void _navigateToForm(BuildContext context, {ResidentModel? resident}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResidentFormScreen(resident: resident),
      ),
    );
  }
}

class _ResidentCard extends StatelessWidget {
  final ResidentModel resident;
  final VoidCallback onTap;

  const _ResidentCard({required this.resident, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: resident.isCrianca
              ? Colors.orange[100]
              : Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            resident.isCrianca ? Icons.child_care : Icons.person,
            color: resident.isCrianca
                ? Colors.orange[900]
                : Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                resident.nome,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (resident.tipo == ResidentType.responsavel)
              Chip(
                label: const Text('Responsável'),
                backgroundColor: Colors.blue[100],
                labelStyle: TextStyle(fontSize: 11, color: Colors.blue[900]),
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${resident.idade} anos'),
            if (resident.isCrianca)
              Text(
                'Criança',
                style: TextStyle(color: Colors.orange[700], fontSize: 12),
              ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
