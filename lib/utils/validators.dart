class Validators {
  // Validação de email
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email é obrigatório';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Email inválido';
    }

    return null;
  }

  // Validação de senha
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Senha é obrigatória';
    }

    if (value.length < 6) {
      return 'Senha deve ter no mínimo 6 caracteres';
    }

    return null;
  }

  // Validação de nome
  static String? name(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nome é obrigatório';
    }

    if (value.length < 3) {
      return 'Nome deve ter no mínimo 3 caracteres';
    }

    return null;
  }

  // Validação genérica de campo obrigatório
  static String? Function(String?) required(String fieldName) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        return fieldName;
      }
      return null;
    };
  }

  // Validação de valor monetário
  static String? currency(String? value) {
    if (value == null || value.isEmpty) {
      return 'Valor é obrigatório';
    }

    final numValue = double.tryParse(value.replaceAll(',', '.'));
    if (numValue == null) {
      return 'Valor inválido';
    }

    if (numValue <= 0) {
      return 'Valor deve ser maior que zero';
    }

    return null;
  }

  // Validação de data
  static String? date(String? value) {
    if (value == null || value.isEmpty) {
      return 'Data é obrigatória';
    }

    // Tentar fazer parse da data
    try {
      DateTime.parse(value);
      return null;
    } catch (e) {
      return 'Data inválida';
    }
  }
}
