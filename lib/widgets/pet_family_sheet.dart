import 'package:flutter/material.dart';
import '../core/pet_model_catalog.dart';
import '../services/shared_pet_service.dart';
import '../services/inventory_service.dart';

class PetFamilySheet extends StatefulWidget {
  const PetFamilySheet({super.key});
  @override
  State<PetFamilySheet> createState() => _PetFamilySheetState();
}

class _PetFamilySheetState extends State<PetFamilySheet> {
  final _pet = SharedPetService.instance;
  final _name = TextEditingController();
  late String _species;
  String? _petId;
  bool _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _species = _pet.species;
    _petId = _pet.activePetId;
    _name.text = _pet.name;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save(String action) async {
    if (action == 'adopt_gold') {
      final agreed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Una nueva compañía'),
          content: Text(
            'Desbloquear ${PetModelCatalog.labels[_species]} por 4.000 de oro. Se unirá a sus mascotas.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Volver'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Desbloquear'),
            ),
          ],
        ),
      );
      if (agreed != true || !mounted) return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _pet.change(
        action,
        _species,
        _name.text,
        petId: ['select', 'rename'].contains(action) ? _petId : null,
      );
      InventoryService.instance.refresh().catchError((Object _) {});
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted)
        setState(
          () => _error =
              'No se guardó el cambio. Revisa la conexión y los requisitos de adopción.',
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final owned = _pet.pets.any((p) => p['species'] == _species);
    final count = _pet.pets.map((p) => p['species']).toSet().length;
    final requiredLevel = count <= 1
        ? 8
        : count == 2
        ? 16
        : 24;
    final requiredDays = count <= 1
        ? 3
        : count == 2
        ? 7
        : 14;
    final canAdopt =
        count < 4 &&
        _pet.familyLevel >= requiredLevel &&
        _pet.careDays >= requiredDays;
    return Material(
      color: const Color(0xFFFFF9FA),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            20 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _pet.selectionConfirmed
                    ? 'Vuestras mascotas'
                    : 'Elijan su primera mascota',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Nivel compartido ${_pet.familyLevel} · ${_pet.careDays} días de cuidado',
              ),
              const SizedBox(height: 12),
              if (_pet.selectionConfirmed) ...[
                const Text(
                  'Tus mascotas',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final animal in _pet.pets)
                      ChoiceChip(
                        label: Text(
                          '${animal['name']?.toString().trim().isNotEmpty == true ? animal['name'] : PetModelCatalog.labels[animal['species']]} · ${PetModelCatalog.labels[animal['species']]}',
                        ),
                        selected: _petId != null && animal['id'] == _petId,
                        onSelected: _busy
                            ? null
                            : (_) => setState(() {
                                _petId = animal['id'] as String?;
                                _species = animal['species'] as String;
                                _name.text = animal['name'] as String? ?? '';
                              }),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: PetModelCatalog.models.keys.map((s) {
                  final adopted = _pet.pets.any((p) => p['species'] == s);
                  return SizedBox(
                    width: 145,
                    child: InkWell(
                      onTap: _busy
                          ? null
                          : () {
                              setState(() {
                                _species = s;
                                final matching = _pet.pets.where(
                                  (p) => p['species'] == s,
                                );
                                _petId = matching.isEmpty
                                    ? null
                                    : matching.first['id'] as String?;
                                _name.text = matching.isEmpty
                                    ? ''
                                    : matching.first['name'] as String? ?? '';
                              });
                            },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: s == _species
                                ? Colors.green
                                : Colors.black12,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Image.asset(
                              'assets/images/pets/$s.png',
                              height: 110,
                              fit: BoxFit.contain,
                            ),
                            Text(PetModelCatalog.labels[s]!),
                            Text(
                              adopted
                                  ? 'Adoptada'
                                  : _pet.selectionConfirmed
                                  ? 'Por adoptar'
                                  : 'Disponible',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _name,
                maxLength: 24,
                enabled: !_busy,
                decoration: const InputDecoration(
                  labelText: 'El nombre lo eligen ustedes',
                  hintText: 'Sin nombre todavía',
                ),
              ),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.red)),
              if (!_pet.selectionConfirmed)
                FilledButton(
                  onPressed: _busy ? null : () => _save('choose'),
                  child: const Text('Elegir nuestra mascota'),
                )
              else if (owned) ...[
                FilledButton(
                  onPressed: _busy ? null : () => _save('select'),
                  child: const Text('Llevar a la habitación'),
                ),
                TextButton(
                  onPressed: _busy ? null : () => _save('rename'),
                  child: const Text('Guardar solamente el nombre'),
                ),
                Text(
                  'Etapa: ${PetModelCatalog.stageFor((_pet.pets.firstWhere((p) => _petId == null ? p['species'] == _species : p['id'] == _petId)['level'] as int?) ?? 1)}',
                  textAlign: TextAlign.center,
                ),
              ] else ...[
                Text(
                  'Necesitan nivel compartido $requiredLevel y $requiredDays días distintos de cuidado, o pueden desbloquearla con oro.',
                ),
                FilledButton(
                  onPressed: _busy || !canAdopt ? null : () => _save('adopt'),
                  child: const Text('Adoptar'),
                ),
                OutlinedButton(
                  onPressed: _busy || InventoryService.instance.coins < 4000
                      ? null
                      : () => _save('adopt_gold'),
                  child: const Text('Desbloquear · 4.000 oro'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
