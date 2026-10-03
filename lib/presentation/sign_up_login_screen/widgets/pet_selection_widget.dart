import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class PetSelectionWidget extends StatelessWidget {
  final String? selectedPet;
  final ValueChanged<String> onPetSelected;
  final VoidCallback onConfirm;
  final bool isLoading;

  const PetSelectionWidget({
    super.key,
    required this.selectedPet,
    required this.onPetSelected,
    required this.onConfirm,
    required this.isLoading,
  });

  static const List<Map<String, String>> pets = [
    {'name': 'Pollito', 'emoji': '🐣', 'desc': 'Chick'},
    {'name': 'Pingüino', 'emoji': '🐧', 'desc': 'Penguin'},
    {'name': 'Oso', 'emoji': '🐻', 'desc': 'Bear'},
    {'name': 'Gato', 'emoji': '🐱', 'desc': 'Cat'},
    {'name': 'Perrito', 'emoji': '🐶', 'desc': 'Dog'},
    {'name': 'Loro', 'emoji': '🦜', 'desc': 'Parrot'},
    {'name': 'Mono', 'emoji': '🐵', 'desc': 'Monkey'},
    {'name': 'Sushi', 'emoji': '🍣', 'desc': 'Sushi'},
    {'name': 'Pasta', 'emoji': '🍝', 'desc': 'Pasta'},
    {'name': 'Bolón', 'emoji': '🫓', 'desc': 'Bolón'},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose your couple mascot',
          style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          'This little companion will grow with your relationship!',
          style: GoogleFonts.dmSans(
            fontSize: 12,
            color: const Color(0xFF6B6B6B),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.85,
            ),
            itemCount: pets.length,
            itemBuilder: (context, i) {
              final pet = pets[i];
              final isSelected = selectedPet == pet['name'];
              return GestureDetector(
                onTap: () => onPetSelected(pet['name']!),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryContainer
                        : AppTheme.surfaceVariantLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppTheme.primary : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(pet['emoji']!, style: const TextStyle(fontSize: 24)),
                      const SizedBox(height: 2),
                      Text(
                        pet['desc']!,
                        style: GoogleFonts.dmSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? AppTheme.primary
                              : const Color(0xFF6B6B6B),
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: selectedPet != null && !isLoading ? onConfirm : null,
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    selectedPet != null
                        ? 'Start with $selectedPet!'
                        : 'Select a mascot',
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
