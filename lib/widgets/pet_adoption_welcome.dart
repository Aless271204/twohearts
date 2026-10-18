import 'package:flutter/material.dart';
import '../services/shared_pet_service.dart';
import '../services/supabase_service.dart';
import '../core/pet_model_catalog.dart';
import '../presentation/profile_screen/profile_screen.dart';
import 'forest_runner_view.dart';

class PetAdoptionWelcome extends StatefulWidget {
  const PetAdoptionWelcome({super.key});
  @override
  State<PetAdoptionWelcome> createState() => _PetAdoptionWelcomeState();
}

class _PetAdoptionWelcomeState extends State<PetAdoptionWelcome> {
  final pet = SharedPetService.instance, name = TextEditingController();
  String species = 'penguin';
  bool busy = false;
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
      await pet.change('choose', species, name.text);
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
    if (!pet.ready) return const Center(child: CircularProgressIndicator());
    if (!pet.paired)
      return Center(
        child: Padding(
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
                'Su Nido empieza juntos',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Enlacen sus cuentas en Configuración. Después podrán adoptar una de las cuatro mascotas.',
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
                label: const Text('Configuración'),
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
          if (error != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: FilledButton(
                onPressed: arrived,
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
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: busy ? null : adopt,
                icon: const Icon(Icons.favorite_rounded),
                label: Text(busy ? 'Preparando su llegada…' : 'Adoptar juntos'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
