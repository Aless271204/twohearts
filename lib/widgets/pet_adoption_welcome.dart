import 'package:flutter/material.dart';

import '../services/shared_pet_service.dart';
import '../services/inventory_service.dart';
import '../services/supabase_service.dart';
import '../core/pet_model_catalog.dart';
import '../presentation/profile_screen/profile_screen.dart';
import 'forest_runner_view.dart';
import 'pet_load_status.dart';

class PetAdoptionWelcome extends StatefulWidget {
  const PetAdoptionWelcome({super.key});
  @override
  State<PetAdoptionWelcome> createState() => _PetAdoptionWelcomeState();
}

class _PetAdoptionWelcomeState extends State<PetAdoptionWelcome> {
  final pet = SharedPetService.instance, name = TextEditingController();
  String species = 'penguin';
  bool busy = false;
  bool choosingSolo = false;
  String? error;
  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  Future<void> adopt() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final paid = !pet.paired;
      if (paid) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('Una nueva compañía'),
            content: Text(
              'Adoptar ${PetModelCatalog.labels[species]} por 4.000 de oro. '
              'La mascota será parte de su Nido cuando enlaces tu cuenta.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: const Text('Volver'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(c, true),
                child: const Text('Confirmar · 4.000 oro'),
              ),
            ],
          ),
        );
        if (confirmed != true || !mounted) return;
      }
      await pet.change(paid ? 'adopt_gold' : 'choose', species, name.text);
      await InventoryService.instance.refresh();
    } catch (_) {
      if (mounted)
        setState(
          () => error = 'No se guardó la adopción. Vuelvan a intentarlo.',
        );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> arrived() async {
    if (busy) return;
    busy = true;
    try {
      await SupabaseService.instance.client.rpc('pet_arrival_ack');
      await pet.refresh();
    } catch (_) {
      if (mounted)
        setState(
          () => error =
              'La bienvenida está guardada. Toca continuar para entrar al Nido.',
        );
    } finally {
      busy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!pet.ready) {
      return PetLoadStatus(
        message: pet.loadError,
        onRetry: () => pet.refresh(),
      );
    }
    if (!pet.paired && !pet.selectionConfirmed && !choosingSolo)
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.favorite_rounded,
                size: 54,
                color: Color(0xFFF05280),
              ),
              const SizedBox(height: 16),
              const Text(
                'Una pequeña compañía para tu Nido',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Enlaza tu cuenta con esa persona especial para elegir juntos su primera mascota, o dale la bienvenida antes por 4.000 de oro.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ProfileScreen(),
                  ),
                ),
                icon: const Icon(Icons.settings_outlined),
                label: const Text('Enlazar nuestras cuentas'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => setState(() => choosingSolo = true),
                icon: const Icon(Icons.pets_rounded),
                label: const Text('Adoptar · 4.000 de oro'),
              ),
              const SizedBox(height: 12),
              const Text(
                'Al enlazarse después, conservarán la mascota sin volver a pagar. '
                'Si ambos ya tienen una, conservarán las dos.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    if (pet.data['arrival_pending'] == true)
      return Stack(
        children: [
          ForestRunnerView(
            key: ValueKey('arrival-${pet.data['pair_key']}-${pet.species}'),
            adoption: true,
            arrival: true,
            petSpecies: pet.species,
            onExit: arrived,
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: FilledButton(
              onPressed: busy ? null : arrived,
              child: const Text('Continuar al Nido'),
            ),
          ),
        ],
      );
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 2),
          child: Text(
            'Una pequeña compañía para ustedes',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
          ),
        ),
        const Expanded(child: ForestRunnerView(adoption: true)),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: Column(
            children: [
              Wrap(
                spacing: 6,
                children: [
                  for (final key in PetModelCatalog.models.keys)
                    ChoiceChip(
                      label: Text(PetModelCatalog.labels[key]!),
                      selected: species == key,
                      onSelected: busy
                          ? null
                          : (_) => setState(() => species = key),
                    ),
                ],
              ),
              TextField(
                controller: name,
                maxLength: 24,
                decoration: const InputDecoration(
                  labelText: '¿Cómo le van a llamar?',
                  counterText: '',
                ),
              ),
              if (error != null)
                Text(error!, style: const TextStyle(color: Colors.red)),
              if (!pet.paired) ...[
                Text(
                  'Tu oro: ${InventoryService.instance.coins} · Adopción: 4.000',
                ),
                if (InventoryService.instance.coins < 4000)
                  const Text('Todavía no tienes suficiente oro.'),
                TextButton(
                  onPressed: busy
                      ? null
                      : () => setState(() => choosingSolo = false),
                  child: const Text('Volver'),
                ),
              ],
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed:
                    busy ||
                        (!pet.paired && InventoryService.instance.coins < 4000)
                    ? null
                    : adopt,
                icon: const Icon(Icons.favorite_rounded),
                label: Text(
                  busy
                      ? 'Preparando su llegada…'
                      : pet.paired
                      ? 'Adoptar juntos'
                      : 'Adoptar · 4.000 de oro',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
