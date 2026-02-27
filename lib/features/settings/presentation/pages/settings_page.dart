import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worklog_pro/core/providers/theme_provider.dart';
import 'package:worklog_pro/features/settings/domain/entities/settings.dart';
import 'package:worklog_pro/features/settings/presentation/providers/settings_provider.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _formKey = GlobalKey<FormState>();

  // Artisan info controllers
  late TextEditingController _nameController;
  late TextEditingController _siretController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _tvaController;

  bool _initialized = false;

  void _initControllers(PdfHeader header) {
    if (_initialized) return;
    _nameController = TextEditingController(text: header.name);
    _siretController = TextEditingController(text: header.tvaNumber ?? '');
    _phoneController = TextEditingController(text: header.phone);
    _emailController = TextEditingController(text: header.email ?? '');
    _addressController = TextEditingController(text: header.address ?? '');
    _tvaController = TextEditingController(text: header.tvaNumber ?? '');
    _initialized = true;
  }

  @override
  void dispose() {
    if (_initialized) {
      _nameController.dispose();
      _siretController.dispose();
      _phoneController.dispose();
      _emailController.dispose();
      _addressController.dispose();
      _tvaController.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final header = PdfHeader(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      tvaNumber: _tvaController.text.trim().isEmpty ? null : _tvaController.text.trim(),
    );
    await ref.read(settingsProvider.notifier).updatePdfHeader(header);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Paramètres sauvegardés'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);

    // IMPORTANT: init controllers BEFORE building Scaffold so AppBar sees _initialized = true
    settingsAsync.whenData((settings) => _initControllers(settings.pdfHeader));

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Paramètres Artisan'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: _initialized ? _save : null,
            icon: const Icon(Icons.save, color: Colors.white),
            label: const Text('Sauvegarder', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (settings) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header info card
                  _buildInfoBanner(),
                  const SizedBox(height: 20),

                  // Identity section
                  _sectionCard(
                    icon: Icons.person,
                    title: 'Identité',
                    color: Colors.indigo,
                    children: [
                      _field(
                        controller: _nameController,
                        label: 'Nom / Raison sociale',
                        hint: 'Ex: Jean Dupont Électricité',
                        icon: Icons.business,
                        required: true,
                      ),
                      const SizedBox(height: 16),
                      _field(
                        controller: _siretController,
                        label: 'Numéro SIRET',
                        hint: 'Ex: 123 456 789 00012',
                        icon: Icons.fingerprint,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      _field(
                        controller: _tvaController,
                        label: 'N° TVA Intracommunautaire',
                        hint: 'Ex: BE 0123.456.789',
                        icon: Icons.receipt,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Contact section
                  _sectionCard(
                    icon: Icons.contact_phone,
                    title: 'Coordonnées',
                    color: Colors.teal,
                    children: [
                      _field(
                        controller: _phoneController,
                        label: 'Téléphone',
                        hint: 'Ex: +32 470 12 34 56',
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      _field(
                        controller: _emailController,
                        label: 'Email professionnel',
                        hint: 'Ex: contact@jean-electricite.be',
                        icon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      _field(
                        controller: _addressController,
                        label: 'Adresse',
                        hint: 'Ex: Rue de la Paix 1, 1000 Bruxelles',
                        icon: Icons.location_on,
                        maxLines: 2,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Theme section
                  _buildThemeCard(),
                  const SizedBox(height: 16),

                  // PDF preview card
                  _buildPdfPreviewCard(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.indigo.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.picture_as_pdf, color: Colors.indigo.shade400, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Ces informations apparaîtront automatiquement sur vos Factures et Devis PDF.',
              style: TextStyle(
                color: Colors.indigo.shade700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          // Fields
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool required = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label + (required ? ' *' : ''),
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.indigo, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      validator: required
          ? (value) => (value == null || value.trim().isEmpty)
              ? 'Ce champ est obligatoire'
              : null
          : null,
    );
  }

  Widget _buildThemeCard() {
    final themeMode = ref.watch(themeModeProvider);
    final options = [
      (ThemeMode.system, Icons.brightness_auto, 'Système'),
      (ThemeMode.light, Icons.wb_sunny, 'Clair'),
      (ThemeMode.dark, Icons.nightlight_round, 'Sombre'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withAlpha(20),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(Icons.dark_mode, color: Colors.deepPurple.shade400, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Apparence',
                  style: TextStyle(
                    color: Colors.deepPurple.shade400,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<ThemeMode>(
              segments: options.map((o) {
                return ButtonSegment<ThemeMode>(
                  value: o.$1,
                  icon: Icon(o.$2),
                  label: Text(o.$3),
                );
              }).toList(),
              selected: {themeMode},
              onSelectionChanged: (selection) {
                ref.read(themeModeProvider.notifier).setThemeMode(selection.first);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfPreviewCard() {
    return AnimatedBuilder(
      animation: Listenable.merge([
        if (_initialized) _nameController,
        if (_initialized) _phoneController,
        if (_initialized) _emailController,
        if (_initialized) _addressController,
        if (_initialized) _tvaController,
      ]),
      builder: (context, _) {
        final name = _initialized ? _nameController.text : '';
        final phone = _initialized ? _phoneController.text : '';
        final email = _initialized ? _emailController.text : '';
        final address = _initialized ? _addressController.text : '';
        final tva = _initialized ? _tvaController.text : '';
        final hasContent = name.isNotEmpty || phone.isNotEmpty;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.orange.withAlpha(20),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.preview, color: Colors.orange.shade700, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Aperçu sur les PDFs',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: hasContent
                    ? Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade900,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (name.isNotEmpty)
                              Text(
                                name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            if (tva.isNotEmpty)
                              Text(
                                'TVA: $tva',
                                style: TextStyle(
                                  color: Colors.white.withAlpha(180),
                                  fontSize: 11,
                                ),
                              ),
                            if (phone.isNotEmpty)
                              Text(
                                'Tél: $phone',
                                style: TextStyle(
                                  color: Colors.white.withAlpha(180),
                                  fontSize: 11,
                                ),
                              ),
                            if (email.isNotEmpty)
                              Text(
                                email,
                                style: TextStyle(
                                  color: Colors.white.withAlpha(180),
                                  fontSize: 11,
                                ),
                              ),
                            if (address.isNotEmpty)
                              Text(
                                address,
                                style: TextStyle(
                                  color: Colors.white.withAlpha(180),
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                      )
                    : Text(
                        'Remplissez les champs ci-dessus pour voir l\'aperçu',
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
