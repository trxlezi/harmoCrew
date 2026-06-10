import 'package:flutter/material.dart';

import '../domain/member.dart';

class MemberFormScreen extends StatefulWidget {
  const MemberFormScreen({super.key});

  static const routeName = '/members/new';

  @override
  State<MemberFormScreen> createState() => _MemberFormScreenState();
}

class _MemberFormScreenState extends State<MemberFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _roleController = TextEditingController();
  final _instrumentsController = TextEditingController();
  final _specialtiesController = TextEditingController();
  final _stylesController = TextEditingController();
  final _availabilityController = TextEditingController();
  final _cityController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    _instrumentsController.dispose();
    _specialtiesController.dispose();
    _stylesController.dispose();
    _availabilityController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return 'Informe $label';
    }

    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.pop(
      context,
      Member(
        name: _nameController.text.trim(),
        role: _roleController.text.trim(),
        availability: _availabilityController.text.trim(),
        instruments: _splitList(_instrumentsController.text),
        specialties: _splitList(_specialtiesController.text),
        styles: _splitList(_stylesController.text),
        city: _cityController.text.trim(),
      ),
    );
  }

  List<String> _splitList(String value) {
    return value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastrar integrante')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Preencha os dados do integrante',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  hintText: 'Ex.: Carlos Silva',
                ),
                validator: (value) => _required(value, 'o nome'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _roleController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Especialidade principal',
                  hintText: 'Ex.: Baixista',
                ),
                validator: (value) =>
                    _required(value, 'a especialidade principal'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _instrumentsController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Instrumentos',
                  hintText: 'Ex.: Baixo, violao, voz',
                ),
                validator: (value) => _required(value, 'os instrumentos'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _specialtiesController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Especialidades',
                  hintText: 'Ex.: Arranjo, composicao',
                ),
                validator: (value) => _required(value, 'as especialidades'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _stylesController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Estilos musicais',
                  hintText: 'Ex.: Pop Rock, Neo Soul',
                ),
                validator: (value) => _required(value, 'os estilos musicais'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _availabilityController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Disponibilidade',
                  hintText: 'Ex.: Sextas a noite',
                ),
                validator: (value) => _required(value, 'a disponibilidade'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cityController,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                decoration: const InputDecoration(
                  labelText: 'Cidade/localidade',
                  hintText: 'Opcional',
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Salvar integrante'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
