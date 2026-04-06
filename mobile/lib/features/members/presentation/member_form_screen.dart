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
  final _availabilityController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    _availabilityController.dispose();
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
      ),
    );
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
                  labelText: 'Funcao',
                  hintText: 'Ex.: Baixista',
                ),
                validator: (value) => _required(value, 'a funcao'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _availabilityController,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                decoration: const InputDecoration(
                  labelText: 'Disponibilidade',
                  hintText: 'Ex.: Sextas a noite',
                ),
                validator: (value) => _required(value, 'a disponibilidade'),
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
