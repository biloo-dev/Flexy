/// Strongly-typed permission constants and metadata for the RBAC system.
class AppPermissions {
  // --- Dashboard Module ---
  static const String dashboardView = 'dashboard.view';

  // --- Transactions / Flexy Module ---
  static const String transactionsView = 'transactions.view';
  static const String transactionsCreate = 'transactions.create';
  static const String transactionsDelete = 'transactions.delete';
  static const String transactionsExport = 'transactions.export';

  // --- Customers / Clients Module ---
  static const String customersView = 'customers.view';
  static const String customersCreate = 'customers.create';
  static const String customersUpdate = 'customers.update';
  static const String customersDelete = 'customers.delete';

  // --- Debts Module ---
  static const String debtsView = 'debts.view';
  static const String debtsPay = 'debts.pay';

  // --- SIM Activation & Modem Module ---
  static const String simActivationView = 'sim_activation.view';
  static const String simActivationManage = 'sim_activation.manage';
  static const String terminalView = 'terminal.view';
  static const String terminalExecute = 'terminal.execute';

  // --- Settings Module ---
  static const String settingsView = 'settings.view';
  static const String settingsUpdate = 'settings.update';

  // --- Users Management Module ---
  static const String usersView = 'users.view';
  static const String usersCreate = 'users.create';
  static const String usersUpdate = 'users.update';
  static const String usersDelete = 'users.delete';

  // --- Roles & Permissions Module ---
  static const String rolesView = 'roles.view';
  static const String rolesCreate = 'roles.create';
  static const String rolesUpdate = 'roles.update';
  static const String rolesDelete = 'roles.delete';

  // --- Audit Logs Module ---
  static const String auditLogsView = 'audit_logs.view';
  static const String auditLogsExport = 'audit_logs.export';

  /// All system permissions list
  static const List<PermissionDefinition> allPermissions = [
    // Dashboard
    PermissionDefinition(
      code: dashboardView,
      name: 'Voir le tableau de bord',
      module: 'dashboard',
      description: 'Accéder aux statistiques et KPI globaux',
    ),

    // Transactions
    PermissionDefinition(
      code: transactionsView,
      name: 'Consulter les transactions',
      module: 'transactions',
      description: 'Voir l\'historique des transferts Flexy',
    ),
    PermissionDefinition(
      code: transactionsCreate,
      name: 'Effectuer des transferts',
      module: 'transactions',
      description: 'Lancer un transfert Flexy / Recharge USSD',
    ),
    PermissionDefinition(
      code: transactionsDelete,
      name: 'Supprimer des transactions',
      module: 'transactions',
      description: 'Supprimer une ligne de l\'historique des transferts',
    ),
    PermissionDefinition(
      code: transactionsExport,
      name: 'Exporter les transactions',
      module: 'transactions',
      description: 'Exporter les rapports de transferts',
    ),

    // Customers
    PermissionDefinition(
      code: customersView,
      name: 'Consulter les clients',
      module: 'customers',
      description: 'Voir la liste et les détails des clients',
    ),
    PermissionDefinition(
      code: customersCreate,
      name: 'Ajouter des clients',
      module: 'customers',
      description: 'Enregistrer un nouveau client',
    ),
    PermissionDefinition(
      code: customersUpdate,
      name: 'Modifier des clients',
      module: 'customers',
      description: 'Modifier les coordonnées d\'un client',
    ),
    PermissionDefinition(
      code: customersDelete,
      name: 'Supprimer des clients',
      module: 'customers',
      description: 'Supprimer définitivement un client',
    ),

    // Debts
    PermissionDefinition(
      code: debtsView,
      name: 'Consulter les dettes',
      module: 'debts',
      description: 'Voir les dettes clients et l\'historique des paiements',
    ),
    PermissionDefinition(
      code: debtsPay,
      name: 'Encaisser les paiements de dette',
      module: 'debts',
      description: 'Enregistrer un règlement de dette client',
    ),

    // SIM Activation & Terminal
    PermissionDefinition(
      code: simActivationView,
      name: 'Consulter l\'activation SIM',
      module: 'sim_activation',
      description: 'Accéder à l\'interface d\'activation SIM',
    ),
    PermissionDefinition(
      code: simActivationManage,
      name: 'Gérer l\'activation SIM',
      module: 'sim_activation',
      description: 'Activer et configurer des puces SIM',
    ),
    PermissionDefinition(
      code: terminalView,
      name: 'Consulter le terminal AT',
      module: 'terminal',
      description: 'Ouvrir la console Modem AT',
    ),
    PermissionDefinition(
      code: terminalExecute,
      name: 'Exécuter des commandes AT',
      module: 'terminal',
      description: 'Envoyer des commandes AT brutes aux modems',
    ),

    // Settings
    PermissionDefinition(
      code: settingsView,
      name: 'Consulter les paramètres',
      module: 'settings',
      description: 'Voir la configuration des modems et de l\'application',
    ),
    PermissionDefinition(
      code: settingsUpdate,
      name: 'Modifier les paramètres',
      module: 'settings',
      description: 'Mettre à jour les ports COM, codes USSD, et codes PIN',
    ),

    // Users
    PermissionDefinition(
      code: usersView,
      name: 'Consulter les utilisateurs',
      module: 'users',
      description: 'Voir la liste des comptes utilisateurs',
    ),
    PermissionDefinition(
      code: usersCreate,
      name: 'Créer des utilisateurs',
      module: 'users',
      description: 'Ajouter un nouveau compte utilisateur',
    ),
    PermissionDefinition(
      code: usersUpdate,
      name: 'Modifier des utilisateurs',
      module: 'users',
      description: 'Modifier les rôles, mots de passe et statuts des utilisateurs',
    ),
    PermissionDefinition(
      code: usersDelete,
      name: 'Supprimer des utilisateurs',
      module: 'users',
      description: 'Supprimer un compte utilisateur',
    ),

    // Roles
    PermissionDefinition(
      code: rolesView,
      name: 'Consulter les rôles',
      module: 'roles',
      description: 'Voir la liste des rôles et leurs permissions',
    ),
    PermissionDefinition(
      code: rolesCreate,
      name: 'Créer des rôles',
      module: 'roles',
      description: 'Créer de nouveaux rôles personnalisés',
    ),
    PermissionDefinition(
      code: rolesUpdate,
      name: 'Modifier les rôles',
      module: 'roles',
      description: 'Modifier les permissions attribuées à un rôle',
    ),
    PermissionDefinition(
      code: rolesDelete,
      name: 'Supprimer des rôles',
      module: 'roles',
      description: 'Supprimer un rôle personnalisé',
    ),

    // Audit Logs
    PermissionDefinition(
      code: auditLogsView,
      name: 'Consulter le journal d\'audit',
      module: 'audit_logs',
      description: 'Voir l\'historique des actions et des accès refusés',
    ),
    PermissionDefinition(
      code: auditLogsExport,
      name: 'Exporter le journal d\'audit',
      module: 'audit_logs',
      description: 'Exporter les logs de sécurité',
    ),
  ];

  /// Get permissions grouped by module
  static Map<String, List<PermissionDefinition>> get groupedPermissions {
    final Map<String, List<PermissionDefinition>> groups = {};
    for (final perm in allPermissions) {
      if (!groups.containsKey(perm.module)) {
        groups[perm.module] = [];
      }
      groups[perm.module]!.add(perm);
    }
    return groups;
  }
}

class PermissionDefinition {
  final String code;
  final String name;
  final String module;
  final String description;

  const PermissionDefinition({
    required this.code,
    required this.name,
    required this.module,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'name': name,
      'module': module,
      'description': description,
    };
  }

  factory PermissionDefinition.fromMap(Map<String, dynamic> map) {
    return PermissionDefinition(
      code: map['code'] as String,
      name: map['name'] as String? ?? '',
      module: map['module'] as String? ?? '',
      description: map['description'] as String? ?? '',
    );
  }
}
