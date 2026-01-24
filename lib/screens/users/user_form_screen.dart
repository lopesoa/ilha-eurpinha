import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../utils/validators.dart';
import '../../providers/auth_provider.dart';

class UserFormScreen extends StatefulWidget {
  final UserModel? user;

  const UserFormScreen({super.key, this.user});

  @override
  State<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  UserProfile _selectedPerfil = UserProfile.usuario;
  bool _ativo = true;
  bool _isLoading = false;
  bool _obscurePassword = true;

  bool get isEditing => widget.user != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _nomeController.text = widget.user!.nome;
      _emailController.text = widget.user!.email;
      _selectedPerfil = widget.user!.perfil;
      _ativo = widget.user!.ativo;
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final currentUser = context.read<AuthProvider>().currentUser;
    if (currentUser == null || !currentUser.canManageUsers) {
      _showError('Você não tem permissão para esta ação');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (isEditing) {
        // Atualizar usuário existente
        final updatedUser = UserModel(
          id: widget.user!.id,
          nome: _nomeController.text.trim(),
          email: _emailController.text.trim(),
          perfil: _selectedPerfil,
          ativo: _ativo,
          createdAt: widget.user!.createdAt,
        );

        await UserService().updateUser(widget.user!.id, updatedUser);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Usuário atualizado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        // Criar novo usuário
        if (_passwordController.text.isEmpty) {
          _showError('Senha é obrigatória para novos usuários');
          setState(() => _isLoading = false);
          return;
        }

        await AuthService().createUser(
          nome: _nomeController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          perfil: _selectedPerfil,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Usuário criado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      _showError('Erro ao salvar usuário: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleDelete() async {
    final currentUser = context.read<AuthProvider>().currentUser;
    if (currentUser == null || !currentUser.canDeleteUsers) {
      _showError('Apenas Admin pode deletar usuários');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deletar usuário'),
        content: Text(
          'Tem certeza que deseja deletar o usuário ${widget.user!.nome}?\n\nEsta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Deletar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await UserService().deleteUser(widget.user!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuário deletado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _showError('Erro ao deletar usuário: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AuthProvider>().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Usuário' : 'Novo Usuário'),
        actions: [
          if (isEditing && currentUser?.canDeleteUsers == true)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _isLoading ? null : _handleDelete,
              tooltip: 'Deletar usuário',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Nome
            TextFormField(
              controller: _nomeController,
              decoration: const InputDecoration(
                labelText: 'Nome',
                hintText: 'Nome completo',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              validator: Validators.name,
              enabled: !_isLoading,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),

            // Email
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'email@exemplo.com',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: Validators.email,
              enabled: !_isLoading && !isEditing, // Email não pode ser editado
            ),
            if (isEditing)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 12),
                child: Text(
                  'O email não pode ser alterado',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ),
            const SizedBox(height: 16),

            // Senha (apenas para novos usuários)
            if (!isEditing)
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Senha',
                  hintText: 'Mínimo 6 caracteres',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: Validators.password,
                enabled: !_isLoading,
              ),
            if (!isEditing) const SizedBox(height: 16),

            // Perfil
            DropdownButtonFormField<UserProfile>(
              value: _selectedPerfil,
              decoration: const InputDecoration(
                labelText: 'Perfil',
                prefixIcon: Icon(Icons.admin_panel_settings_outlined),
                border: OutlineInputBorder(),
              ),
              items: UserProfile.values.map((perfil) {
                return DropdownMenuItem(
                  value: perfil,
                  child: Text(_getPerfilLabel(perfil)),
                );
              }).toList(),
              onChanged: _isLoading
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() => _selectedPerfil = value);
                      }
                    },
            ),
            const SizedBox(height: 16),

            // Status (apenas para edição)
            if (isEditing)
              SwitchListTile(
                title: const Text('Usuário ativo'),
                subtitle: Text(
                  _ativo
                      ? 'Usuário pode acessar o sistema'
                      : 'Usuário não pode acessar o sistema',
                ),
                value: _ativo,
                onChanged: _isLoading
                    ? null
                    : (value) {
                        setState(() => _ativo = value);
                      },
              ),
            const SizedBox(height: 32),

            // Botão de salvar
            FilledButton(
              onPressed: _isLoading ? null : _handleSave,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(isEditing ? 'Salvar alterações' : 'Criar usuário'),
            ),
          ],
        ),
      ),
    );
  }

  String _getPerfilLabel(UserProfile perfil) {
    switch (perfil) {
      case UserProfile.admin:
        return 'Administrador';
      case UserProfile.presidencia:
        return 'Presidência';
      case UserProfile.diretoria:
        return 'Diretoria';
      case UserProfile.tesouraria:
        return 'Tesouraria';
      case UserProfile.usuario:
        return 'Usuário';
    }
  }
}
