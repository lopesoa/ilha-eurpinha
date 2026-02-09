import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../models/house_model.dart';
import '../../models/house_map_position_model.dart';
import '../../models/resident_model.dart';
import '../../providers/auth_provider.dart';

enum MapaMode { viewing, positioning }

class MapaScreen extends StatefulWidget {
  const MapaScreen({super.key});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> with TickerProviderStateMixin {
  final _transformationController = TransformationController();

  bool _isLoading = true;
  bool _initialScaleSet = false;
  late Matrix4 _initialMatrix;

  MapaMode _mode = MapaMode.viewing;
  List<HouseModel> _houses = [];
  Map<String, HouseMapPosition> _positions = {};
  HouseModel? _selectedHouse;
  HouseModel? _draggedHouse;
  Offset? _dragStartOffset;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final housesSnapshot = await FirebaseFirestore.instance
        .collection('houses')
        .orderBy('identificador')
        .get();
    final houses = housesSnapshot.docs
        .map((doc) => HouseModel.fromFirestore(doc))
        .toList();

    final positionsSnap = await FirebaseFirestore.instance
        .collection('house_map_positions')
        .get();

    final positions = <String, HouseMapPosition>{};
    for (var doc in positionsSnap.docs) {
      final pos = HouseMapPosition.fromFirestore(doc);
      positions[pos.houseId] = pos;
    }

    setState(() {
      _houses = houses;
      _positions = positions;
      _isLoading = false;
    });
  }

  void _resetZoom() {
    final animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    final animation =
        Matrix4Tween(
          begin: _transformationController.value,
          end: _initialMatrix,
        ).animate(
          CurvedAnimation(parent: animationController, curve: Curves.easeInOut),
        );
    animation.addListener(
      () => _transformationController.value = animation.value,
    );
    animationController.forward().whenComplete(
      () => animationController.dispose(),
    );
  }

  void _zoom(double scaleFactor) {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    final newScale = (currentScale * scaleFactor).clamp(0.5, 4.0);
    _transformationController.value = Matrix4.identity()..scale(newScale);
  }

  void _handleTap(Offset position) {
    if (_mode == MapaMode.positioning && _selectedHouse != null) {
      _savePosition(_selectedHouse!, position);
    } else if (_mode == MapaMode.viewing) {
      _selectHouseAtPosition(position);
    }
  }

  void _selectHouseAtPosition(Offset position) {
    HouseModel? tappedHouse;

    for (final house in _houses) {
      final pos = _positions[house.id];
      if (pos != null) {
        final rect = Rect.fromCenter(
          center: Offset(pos.x, pos.y),
          width: 40,
          height: 40,
        );
        if (rect.contains(position)) {
          tappedHouse = house;
          break;
        }
      }
    }

    if (tappedHouse != null) {
      _showHouseDetails(tappedHouse);
    }
  }

  void _handlePanStart(Offset position) {
    if (_mode == MapaMode.positioning && _selectedHouse != null) {
      final pos = _positions[_selectedHouse!.id];
      if (pos != null) {
        final rect = Rect.fromCenter(
          center: Offset(pos.x, pos.y),
          width: 40,
          height: 40,
        );
        if (rect.contains(position)) {
          setState(() {
            _draggedHouse = _selectedHouse;
            _dragStartOffset = position;
          });
        }
      }
    }
  }

  void _handlePanUpdate(Offset newPosition) {
    if (_mode == MapaMode.positioning &&
        _draggedHouse != null &&
        _dragStartOffset != null) {
      setState(() {
        final currentPos = _positions[_draggedHouse!.id];
        if (currentPos != null) {
          final delta = newPosition - _dragStartOffset!;
          _positions[_draggedHouse!.id] = currentPos.copyWith(
            x: currentPos.x + delta.dx,
            y: currentPos.y + delta.dy,
          );
          _dragStartOffset = newPosition;
        }
      });
    }
  }

  Future<void> _handlePanEnd() async {
    if (_mode == MapaMode.positioning && _draggedHouse != null) {
      final pos = _positions[_draggedHouse!.id];
      if (pos != null) {
        await _savePositionToFirebase(pos);
      }
      setState(() {
        _draggedHouse = null;
        _dragStartOffset = null;
      });
    }
  }

  Future<void> _savePosition(HouseModel house, Offset position) async {
    final newPos = HouseMapPosition(
      houseId: house.id,
      x: position.dx,
      y: position.dy,
    );

    setState(() {
      _positions[house.id] = newPos;
    });

    await _savePositionToFirebase(newPos);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Casa ${house.numero} posicionada no mapa'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _savePositionToFirebase(HouseMapPosition position) async {
    final db = FirebaseFirestore.instance;

    if (position.id != null) {
      await db
          .collection('house_map_positions')
          .doc(position.id)
          .update(position.toFirestore());
    } else {
      final existingQuery = await db
          .collection('house_map_positions')
          .where('houseId', isEqualTo: position.houseId)
          .get();

      if (existingQuery.docs.isNotEmpty) {
        await db
            .collection('house_map_positions')
            .doc(existingQuery.docs.first.id)
            .update(position.toFirestore());
      } else {
        await db.collection('house_map_positions').add(position.toFirestore());
      }
    }

    await _loadData();
  }

  Future<void> _removePosition(HouseModel house) async {
    final db = FirebaseFirestore.instance;
    final query = await db
        .collection('house_map_positions')
        .where('houseId', isEqualTo: house.id)
        .get();

    for (var doc in query.docs) {
      await doc.reference.delete();
    }

    setState(() {
      _positions.remove(house.id);
      if (_selectedHouse?.id == house.id) {
        _selectedHouse = null;
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Casa ${house.numero} removida do mapa'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _showHouseDetails(HouseModel house) async {
    final residentsSnapshot = await FirebaseFirestore.instance
        .collection('residents')
        .where('houseId', isEqualTo: house.id)
        .orderBy('tipo', descending: true)
        .get();
    final residents = residentsSnapshot.docs
        .map((doc) => ResidentModel.fromFirestore(doc))
        .toList();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.home, size: 32, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Casa ${house.numero}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            house.status == HouseStatus.ativa
                                ? 'Ativa'
                                : 'Inativa',
                            style: TextStyle(
                              color: house.status == HouseStatus.ativa
                                  ? Colors.green[600]
                                  : Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Text(
                  'Residentes (${residents.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: residents.isEmpty
                      ? const Center(
                          child: Text(
                            'Nenhum residente cadastrado',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: residents.length,
                          itemBuilder: (context, index) {
                            final resident = residents[index];
                            final age =
                                DateTime.now().year -
                                resident.dataNascimento.year;
                            final isChild = age < 12;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      resident.tipo == ResidentType.responsavel
                                      ? Colors.blue
                                      : isChild
                                      ? Colors.orange
                                      : Colors.green,
                                  child: Icon(
                                    resident.tipo == ResidentType.responsavel
                                        ? Icons.star
                                        : isChild
                                        ? Icons.child_care
                                        : Icons.person,
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(
                                  resident.nome,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('$age anos'),
                                    Text(
                                      resident.tipo == ResidentType.responsavel
                                          ? 'Responsável'
                                          : 'Dependente',
                                      style: TextStyle(
                                        color:
                                            resident.tipo ==
                                                ResidentType.responsavel
                                            ? Colors.blue
                                            : Colors.grey[600],
                                        fontWeight:
                                            resident.tipo ==
                                                ResidentType.responsavel
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _selectHouseForPositioning() async {
    final house = await showDialog<HouseModel>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selecionar Casa'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _houses.length,
            itemBuilder: (context, index) {
              final house = _houses[index];
              final hasPosition = _positions.containsKey(house.id);

              return ListTile(
                leading: Icon(
                  hasPosition ? Icons.location_on : Icons.location_off,
                  color: hasPosition ? Colors.green : Colors.grey,
                ),
                title: Text('Casa ${house.numero}'),
                subtitle: hasPosition
                    ? const Text('Já posicionada - clique para mover')
                    : const Text('Não posicionada'),
                onTap: () => Navigator.pop(context, house),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );

    if (house != null) {
      setState(() {
        _selectedHouse = house;
        _mode = MapaMode.positioning;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _positions.containsKey(house.id)
                  ? 'Arraste a Casa ${house.numero} para nova posição'
                  : 'Toque no mapa para posicionar a Casa ${house.numero}',
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final canEdit = authProvider.currentUser?.canManageHouses ?? false;

    final bool shouldHandlePan =
        _mode == MapaMode.positioning && _draggedHouse != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _mode == MapaMode.positioning && _selectedHouse != null
              ? 'Posicionando Casa ${_selectedHouse!.numero}'
              : 'Mapa da Ilha',
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (_mode == MapaMode.positioning && _selectedHouse != null) ...[
            if (_positions.containsKey(_selectedHouse!.id))
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Remover do Mapa',
                onPressed: () => _removePosition(_selectedHouse!),
              ),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _mode = MapaMode.viewing;
                  _selectedHouse = null;
                });
              },
              icon: const Icon(Icons.check, color: Colors.white),
              label: const Text(
                'Concluir',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ] else ...[
            if (canEdit)
              IconButton(
                icon: const Icon(Icons.add_location_alt),
                tooltip: 'Posicionar Casa',
                onPressed: _selectHouseForPositioning,
              ),
          ],
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (!_initialScaleSet) {
                      const contentWidth = 1920.0;
                      const contentHeight = 1080.0;
                      final screenWidth = constraints.maxWidth;
                      final screenHeight = constraints.maxHeight;
                      final scaleX = screenWidth / contentWidth;
                      final scaleY = screenHeight / contentHeight;
                      final initialScale = min(scaleX, scaleY);
                      final dx =
                          (screenWidth - contentWidth * initialScale) / 2;
                      final dy =
                          (screenHeight - contentHeight * initialScale) / 2;
                      _initialMatrix = Matrix4.identity()
                        ..translate(dx, dy)
                        ..scale(initialScale);
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() {
                            _transformationController.value = _initialMatrix;
                            _initialScaleSet = true;
                          });
                        }
                      });
                    }

                    return Container(
                      color: Colors.grey[200],
                      child: InteractiveViewer(
                        constrained: false,
                        minScale: 0.5,
                        maxScale: 4.0,
                        boundaryMargin: const EdgeInsets.all(double.infinity),
                        transformationController: _transformationController,
                        panEnabled: !shouldHandlePan,
                        child: SizedBox(
                          width: 1920,
                          height: 1080,
                          child: GestureDetector(
                            onTapUp: (details) =>
                                _handleTap(details.localPosition),
                            onPanStart: shouldHandlePan
                                ? (details) =>
                                      _handlePanStart(details.localPosition)
                                : null,
                            onPanUpdate: shouldHandlePan
                                ? (details) =>
                                      _handlePanUpdate(details.localPosition)
                                : null,
                            onPanEnd: shouldHandlePan
                                ? (_) => _handlePanEnd()
                                : null,
                            child: Stack(
                              children: [
                                Image.asset(
                                  'assets/images/mapa_ilha.jpg',
                                  fit: BoxFit.cover,
                                  width: 1920,
                                  height: 1080,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey[300],
                                      child: const Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.image_not_supported,
                                              size: 64,
                                              color: Colors.grey,
                                            ),
                                            SizedBox(height: 16),
                                            Text(
                                              'Mapa não encontrado',
                                              style: TextStyle(
                                                color: Colors.grey,
                                              ),
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              'Adicione mapa_ilha.jpg em assets/images/',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                ..._houses.map((house) {
                                  final pos = _positions[house.id];
                                  if (pos == null) {
                                    return const SizedBox.shrink();
                                  }

                                  final isSelected =
                                      house.id == _selectedHouse?.id;

                                  return Positioned(
                                    left: pos.x - 20,
                                    top: pos.y - 20,
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: _mode == MapaMode.viewing
                                          ? () => _showHouseDetails(house)
                                          : null,
                                      child: Container(
                                        width: 40,
                                        height: 40,
                                        alignment: Alignment.center,
                                        child: Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? Colors.yellow[700]
                                                : Colors.blue,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.4,
                                                ),
                                                blurRadius: 4,
                                                offset: const Offset(0, 1),
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.home,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                Positioned(
                  top: 20,
                  right: 20,
                  child: Column(
                    children: [
                      FloatingActionButton.small(
                        onPressed: () => _zoom(1.2),
                        tooltip: 'Mais Zoom',
                        child: const Icon(Icons.add),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton.small(
                        onPressed: _resetZoom,
                        tooltip: 'Resetar Zoom',
                        child: const Icon(Icons.filter_center_focus),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton.small(
                        onPressed: () => _zoom(0.8),
                        tooltip: 'Menos Zoom',
                        child: const Icon(Icons.remove),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: _mode == MapaMode.viewing
          ? FloatingActionButton(
              onPressed: _loadData,
              tooltip: 'Atualizar',
              child: const Icon(Icons.refresh),
            )
          : null,
    );
  }
}
