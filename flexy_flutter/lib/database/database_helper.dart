import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

import '../core/authorization/app_permissions.dart';
import '../models/user_model.dart';
import '../models/role_model.dart';
import '../models/audit_log_model.dart';
import '../models/client_model.dart';
import '../models/historique_model.dart';
import '../models/settings_model.dart';
import '../models/paiement_dette_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('flexy_app.db');
    return _database!;
  }

  static String hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  Future<Database> _initDB(String filePath) async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getApplicationSupportDirectory();
    final path = join(dbPath.path, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgradeDB,
      onOpen: (db) async {
        await _ensureTablesAndColumns(db);
      },
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Roles table
    await db.execute('''
      CREATE TABLE Roles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        displayName TEXT NOT NULL,
        description TEXT,
        isSystem INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL
      )
    ''');

    // 2. Permissions table
    await db.execute('''
      CREATE TABLE Permissions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        module TEXT NOT NULL,
        description TEXT
      )
    ''');

    // 3. RolePermissions link table
    await db.execute('''
      CREATE TABLE RolePermissions (
        roleId INTEGER NOT NULL,
        permissionCode TEXT NOT NULL,
        PRIMARY KEY (roleId, permissionCode),
        FOREIGN KEY (roleId) REFERENCES Roles (id) ON DELETE CASCADE
      )
    ''');

    // 4. Users table
    await db.execute('''
      CREATE TABLE Users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT NOT NULL UNIQUE,
        fullName TEXT NOT NULL,
        password TEXT NOT NULL,
        roleId INTEGER,
        isActive INTEGER NOT NULL DEFAULT 1,
        createdAt TEXT NOT NULL,
        updatedAt TEXT,
        lastLoginAt TEXT,
        FOREIGN KEY (roleId) REFERENCES Roles (id) ON DELETE SET NULL
      )
    ''');

    // 5. AuditLogs table
    await db.execute('''
      CREATE TABLE AuditLogs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER,
        userFullName TEXT,
        action TEXT NOT NULL,
        resource TEXT NOT NULL,
        resourceId TEXT,
        status TEXT NOT NULL,
        reason TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    // 6. Clients table
    await db.execute('''
      CREATE TABLE Clients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom_prenom TEXT NOT NULL,
        fidel INTEGER NOT NULL DEFAULT 0,
        type INTEGER NOT NULL DEFAULT 0,
        numeroPhoneList TEXT,
        credit REAL NOT NULL DEFAULT 0.0
      )
    ''');

    // 7. Historiques table
    await db.execute('''
      CREATE TABLE Historiques (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        operateur INTEGER NOT NULL,
        Numero TEXT NOT NULL,
        somme REAL NOT NULL,
        rest_somme REAL DEFAULT 0.0,
        somme_payee REAL DEFAULT 0.0,
        Reponse TEXT,
        marge INTEGER DEFAULT 0,
        type INTEGER NOT NULL DEFAULT 1,
        status INTEGER NOT NULL DEFAULT 1,
        credit INTEGER NOT NULL DEFAULT 0,
        id_client INTEGER,
        id_user INTEGER,
        createdAt TEXT NOT NULL
      )
    ''');

    // 8. Settings table
    await db.execute('''
      CREATE TABLE Settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        typeOperator INTEGER NOT NULL UNIQUE,
        codeTrensfert INTEGER NOT NULL,
        codeSolde INTEGER NOT NULL,
        codeInternational INTEGER DEFAULT 0,
        codePin TEXT NOT NULL DEFAULT '0000',
        codeFacteur INTEGER DEFAULT 761,
        confYes INTEGER DEFAULT 1,
        confNo INTEGER DEFAULT 0,
        autoConfirmation INTEGER DEFAULT 1,
        comPort TEXT DEFAULT 'COM1',
        autoDetectUSB INTEGER DEFAULT 1,
        audioEnabled INTEGER DEFAULT 1,
        audioSpeed INTEGER DEFAULT 1,
        audioPerson TEXT DEFAULT 'default'
      )
    ''');

    // 9. Tresorerers table
    await db.execute('''
      CREATE TABLE Tresorerers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        somme REAL NOT NULL,
        rest_somme REAL DEFAULT 0.0,
        id_hist INTEGER,
        type INTEGER DEFAULT 1,
        id_client INTEGER,
        id_user INTEGER,
        createdAt TEXT NOT NULL
      )
    ''');

    // 10. PaiementsDette table
    await db.execute('''
      CREATE TABLE PaiementsDette (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        id_client INTEGER NOT NULL,
        id_user INTEGER NOT NULL,
        user_fullname TEXT NOT NULL,
        nom_client TEXT NOT NULL,
        montant REAL NOT NULL,
        ancien_credit REAL NOT NULL,
        nouveau_credit REAL NOT NULL,
        note TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    // Run Seeders
    await _seedRBAC(db);
    await _seedDefaultSettings(db);
  }

  Future<void> _onUpgradeDB(Database db, int oldVersion, int newVersion) async {
    await _ensureTablesAndColumns(db);
  }

  Future<void> _ensureTablesAndColumns(Database db) async {
    // Check and create Roles table if not exists
    await db.execute('''
      CREATE TABLE IF NOT EXISTS Roles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        displayName TEXT NOT NULL,
        description TEXT,
        isSystem INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL
      )
    ''');

    // Check and create Permissions table if not exists
    await db.execute('''
      CREATE TABLE IF NOT EXISTS Permissions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        module TEXT NOT NULL,
        description TEXT
      )
    ''');

    // Check and create RolePermissions table if not exists
    await db.execute('''
      CREATE TABLE IF NOT EXISTS RolePermissions (
        roleId INTEGER NOT NULL,
        permissionCode TEXT NOT NULL,
        PRIMARY KEY (roleId, permissionCode),
        FOREIGN KEY (roleId) REFERENCES Roles (id) ON DELETE CASCADE
      )
    ''');

    // Check and create AuditLogs table if not exists
    await db.execute('''
      CREATE TABLE IF NOT EXISTS AuditLogs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER,
        userFullName TEXT,
        action TEXT NOT NULL,
        resource TEXT NOT NULL,
        resourceId TEXT,
        status TEXT NOT NULL,
        reason TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    // Check and create PaiementsDette if not exists
    await db.execute('''
      CREATE TABLE IF NOT EXISTS PaiementsDette (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        id_client INTEGER NOT NULL,
        id_user INTEGER NOT NULL,
        user_fullname TEXT NOT NULL,
        nom_client TEXT NOT NULL,
        montant REAL NOT NULL,
        ancien_credit REAL NOT NULL,
        nouveau_credit REAL NOT NULL,
        note TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    // Add missing columns to Users table if upgraded from v1
    final userCols = await db.rawQuery('PRAGMA table_info(Users)');
    final colNames = userCols.map((c) => c['name'] as String).toSet();

    if (!colNames.contains('roleId')) {
      await db.execute('ALTER TABLE Users ADD COLUMN roleId INTEGER REFERENCES Roles(id)');
    }
    if (!colNames.contains('isActive')) {
      await db.execute('ALTER TABLE Users ADD COLUMN isActive INTEGER NOT NULL DEFAULT 1');
    }
    if (!colNames.contains('createdAt')) {
      await db.execute('ALTER TABLE Users ADD COLUMN createdAt TEXT NOT NULL DEFAULT "${DateTime.now().toIso8601String()}"');
    }
    if (!colNames.contains('updatedAt')) {
      await db.execute('ALTER TABLE Users ADD COLUMN updatedAt TEXT');
    }
    if (!colNames.contains('lastLoginAt')) {
      await db.execute('ALTER TABLE Users ADD COLUMN lastLoginAt TEXT');
    }

    // Seed RBAC data if missing
    await _seedRBAC(db);
  }

  Future<void> _seedRBAC(Database db) async {
    // 1. Seed Permissions
    for (final perm in AppPermissions.allPermissions) {
      await db.insert(
        'Permissions',
        perm.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    // 2. Define Default Roles
    final defaultRoles = [
      {
        'name': 'super_admin',
        'displayName': 'Super Admin',
        'description': 'Accès total sans restrictions à toutes les fonctionnalités et paramètres.',
        'isSystem': 1,
        'permissions': AppPermissions.allPermissions.map((p) => p.code).toList(),
      },
      {
        'name': 'admin',
        'displayName': 'Administrateur',
        'description': 'Gestion complète de l\'application, des utilisateurs et des paramètres.',
        'isSystem': 1,
        'permissions': AppPermissions.allPermissions
            .where((p) => p.code != AppPermissions.rolesDelete)
            .map((p) => p.code)
            .toList(),
      },
      {
        'name': 'manager',
        'displayName': 'Gestionnaire (Manager)',
        'description': 'Gestion des clients, des transactions, des dettes et consultation des rapports.',
        'isSystem': 1,
        'permissions': [
          AppPermissions.dashboardView,
          AppPermissions.transactionsView,
          AppPermissions.transactionsCreate,
          AppPermissions.transactionsDelete,
          AppPermissions.transactionsExport,
          AppPermissions.customersView,
          AppPermissions.customersCreate,
          AppPermissions.customersUpdate,
          AppPermissions.customersDelete,
          AppPermissions.debtsView,
          AppPermissions.debtsPay,
          AppPermissions.simActivationView,
          AppPermissions.simActivationManage,
          AppPermissions.settingsView,
          AppPermissions.auditLogsView,
        ],
      },
      {
        'name': 'seller',
        'displayName': 'Vendeur / Agent',
        'description': 'Effectuer des transferts, enregistrer des clients et encaisser les dettes.',
        'isSystem': 1,
        'permissions': [
          AppPermissions.dashboardView,
          AppPermissions.transactionsView,
          AppPermissions.transactionsCreate,
          AppPermissions.customersView,
          AppPermissions.customersCreate,
          AppPermissions.customersUpdate,
          AppPermissions.debtsView,
          AppPermissions.debtsPay,
        ],
      },
      {
        'name': 'cashier',
        'displayName': 'Caissier',
        'description': 'Opérations de caisse, encaissements de dettes et recharges Flexy.',
        'isSystem': 1,
        'permissions': [
          AppPermissions.transactionsView,
          AppPermissions.transactionsCreate,
          AppPermissions.debtsView,
          AppPermissions.debtsPay,
        ],
      },
      {
        'name': 'accountant',
        'displayName': 'Comptable',
        'description': 'Consultation financière, suivi des dettes et export des rapports.',
        'isSystem': 1,
        'permissions': [
          AppPermissions.dashboardView,
          AppPermissions.transactionsView,
          AppPermissions.transactionsExport,
          AppPermissions.debtsView,
          AppPermissions.auditLogsView,
        ],
      },
      {
        'name': 'viewer',
        'displayName': 'Lecteur (Consultation)',
        'description': 'Accès en lecture seule aux tableaux et statistiques sans modification.',
        'isSystem': 1,
        'permissions': [
          AppPermissions.dashboardView,
          AppPermissions.transactionsView,
          AppPermissions.customersView,
          AppPermissions.debtsView,
        ],
      },
    ];

    // Insert Default Roles and RolePermissions
    for (final roleData in defaultRoles) {
      final roleName = roleData['name'] as String;
      final existingRole = await db.query('Roles', where: 'name = ?', whereArgs: [roleName]);

      int roleId;
      if (existingRole.isEmpty) {
        roleId = await db.insert('Roles', {
          'name': roleName,
          'displayName': roleData['displayName'],
          'description': roleData['description'],
          'isSystem': roleData['isSystem'],
          'createdAt': DateTime.now().toIso8601String(),
        });
      } else {
        roleId = existingRole.first['id'] as int;
      }

      final perms = roleData['permissions'] as List<String>;
      for (final permCode in perms) {
        await db.insert(
          'RolePermissions',
          {'roleId': roleId, 'permissionCode': permCode},
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    }

    // 3. Ensure Default Super Admin User
    final superAdminRole = await db.query('Roles', where: 'name = ?', whereArgs: ['super_admin']);
    final superAdminRoleId = superAdminRole.isNotEmpty ? superAdminRole.first['id'] as int : 1;

    final existingAdmin = await db.query('Users', where: 'email = ?', whereArgs: ['admin@flexy.com']);
    final hashedPassword = hashPassword('admin');

    if (existingAdmin.isEmpty) {
      await db.insert('Users', {
        'email': 'admin@flexy.com',
        'fullName': 'Administrator',
        'password': hashedPassword,
        'roleId': superAdminRoleId,
        'isActive': 1,
        'createdAt': DateTime.now().toIso8601String(),
      });
    } else {
      await db.update(
        'Users',
        {
          'roleId': superAdminRoleId,
          'isActive': 1,
        },
        where: 'email = ?',
        whereArgs: ['admin@flexy.com'],
      );
    }
  }

  Future<void> _seedDefaultSettings(Database db) async {
    await db.insert('Settings', {
      'typeOperator': 1, // Djezzy
      'codeTrensfert': 710,
      'codeSolde': 710,
      'codeInternational': 0,
      'codePin': '0000',
      'codeFacteur': 761,
      'confYes': 1,
      'confNo': 0,
      'autoConfirmation': 1,
      'comPort': 'COM3',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    await db.insert('Settings', {
      'typeOperator': 2, // Mobilis
      'codeTrensfert': 610,
      'codeSolde': 222,
      'codeInternational': 0,
      'codePin': '0000',
      'codeFacteur': 761,
      'confYes': 1,
      'confNo': 0,
      'autoConfirmation': 1,
      'comPort': 'COM4',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    await db.insert('Settings', {
      'typeOperator': 3, // Ooredoo
      'codeTrensfert': 115,
      'codeSolde': 200,
      'codeInternational': 0,
      'codePin': '0000',
      'codeFacteur': 761,
      'confYes': 1,
      'confNo': 0,
      'autoConfirmation': 1,
      'comPort': 'COM5',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  // ==========================================
  // AUTH & USER DAO METHODS
  // ==========================================

  Future<UserModel?> login(String email, String password) async {
    final db = await instance.database;
    final hashedPassword = hashPassword(password);
    final maps = await db.rawQuery('''
      SELECT U.*, R.name as roleName, R.displayName as roleDisplayName 
      FROM Users U 
      LEFT JOIN Roles R ON U.roleId = R.id 
      WHERE U.email = ? AND U.password = ?
    ''', [email, hashedPassword]);

    if (maps.isNotEmpty) {
      final userMap = maps.first;
      final userId = userMap['id'] as int;
      final isActive = (userMap['isActive'] as int? ?? 1) == 1;

      if (!isActive) {
        await logAudit(
          userId: userId,
          userFullName: userMap['fullName'] as String?,
          action: 'auth.login',
          resource: 'Users',
          resourceId: userId.toString(),
          status: 'DENIED',
          reason: 'Compte désactivé',
        );
        return null;
      }

      // Fetch user permissions via role
      final roleId = userMap['roleId'] as int?;
      List<String> permissions = [];
      if (roleId != null) {
        permissions = await getPermissionsForRole(roleId);
      }

      // Update last login
      final now = DateTime.now().toIso8601String();
      await db.update(
        'Users',
        {'lastLoginAt': now},
        where: 'id = ?',
        whereArgs: [userId],
      );

      final user = UserModel.fromMap(userMap, permissions: permissions);

      await logAudit(
        userId: userId,
        userFullName: user.fullName,
        action: 'auth.login',
        resource: 'Users',
        resourceId: userId.toString(),
        status: 'SUCCESS',
        reason: 'Connexion réussie',
      );

      return user;
    }

    await logAudit(
      userId: null,
      userFullName: email,
      action: 'auth.login',
      resource: 'Users',
      status: 'DENIED',
      reason: 'Identifiants invalides ($email)',
    );

    return null;
  }

  Future<UserModel?> getUserById(int id) async {
    final db = await instance.database;
    final maps = await db.rawQuery('''
      SELECT U.*, R.name as roleName, R.displayName as roleDisplayName 
      FROM Users U 
      LEFT JOIN Roles R ON U.roleId = R.id 
      WHERE U.id = ?
    ''', [id]);

    if (maps.isNotEmpty) {
      final userMap = maps.first;
      final roleId = userMap['roleId'] as int?;
      List<String> permissions = [];
      if (roleId != null) {
        permissions = await getPermissionsForRole(roleId);
      }
      return UserModel.fromMap(userMap, permissions: permissions);
    }
    return null;
  }

  Future<List<UserModel>> getAllUsers() async {
    final db = await instance.database;
    final maps = await db.rawQuery('''
      SELECT U.*, R.name as roleName, R.displayName as roleDisplayName 
      FROM Users U 
      LEFT JOIN Roles R ON U.roleId = R.id 
      ORDER BY U.id ASC
    ''');

    final List<UserModel> users = [];
    for (final map in maps) {
      final roleId = map['roleId'] as int?;
      List<String> permissions = [];
      if (roleId != null) {
        permissions = await getPermissionsForRole(roleId);
      }
      users.add(UserModel.fromMap(map, permissions: permissions));
    }
    return users;
  }

  Future<int> insertUser(UserModel user, {int? actorId, String? actorName}) async {
    final db = await instance.database;
    final hashedPassword = hashPassword(user.password);
    final id = await db.insert('Users', {
      'email': user.email.trim().toLowerCase(),
      'fullName': user.fullName.trim(),
      'password': hashedPassword,
      'roleId': user.roleId,
      'isActive': user.isActive ? 1 : 0,
      'createdAt': DateTime.now().toIso8601String(),
    });

    await logAudit(
      userId: actorId,
      userFullName: actorName,
      action: 'users.create',
      resource: 'Users',
      resourceId: id.toString(),
      status: 'SUCCESS',
      reason: 'Création de l\'utilisateur ${user.email}',
    );

    return id;
  }

  Future<int> updateUser(UserModel user, {int? actorId, String? actorName}) async {
    final db = await instance.database;
    final Map<String, dynamic> updateData = {
      'email': user.email.trim().toLowerCase(),
      'fullName': user.fullName.trim(),
      'roleId': user.roleId,
      'isActive': user.isActive ? 1 : 0,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    if (user.password.isNotEmpty) {
      updateData['password'] = hashPassword(user.password);
    }

    final rows = await db.update(
      'Users',
      updateData,
      where: 'id = ?',
      whereArgs: [user.id],
    );

    await logAudit(
      userId: actorId,
      userFullName: actorName,
      action: 'users.update',
      resource: 'Users',
      resourceId: user.id.toString(),
      status: 'SUCCESS',
      reason: 'Mise à jour de l\'utilisateur ${user.email}',
    );

    return rows;
  }

  Future<int> resetUserPassword(int userId, String newPassword, {int? actorId, String? actorName}) async {
    final db = await instance.database;
    final hashedPassword = hashPassword(newPassword);
    final rows = await db.update(
      'Users',
      {
        'password': hashedPassword,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [userId],
    );

    await logAudit(
      userId: actorId,
      userFullName: actorName,
      action: 'users.reset_password',
      resource: 'Users',
      resourceId: userId.toString(),
      status: 'SUCCESS',
      reason: 'Réinitialisation du mot de passe pour l\'utilisateur #$userId',
    );

    return rows;
  }

  Future<int> toggleUserStatus(int userId, bool isActive, {int? actorId, String? actorName}) async {
    final db = await instance.database;
    final rows = await db.update(
      'Users',
      {
        'isActive': isActive ? 1 : 0,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [userId],
    );

    await logAudit(
      userId: actorId,
      userFullName: actorName,
      action: 'users.update_status',
      resource: 'Users',
      resourceId: userId.toString(),
      status: 'SUCCESS',
      reason: 'Statut utilisateur changé à: ${isActive ? 'Actif' : 'Inactif'}',
    );

    return rows;
  }

  Future<int> deleteUser(int userId, {int? actorId, String? actorName}) async {
    final db = await instance.database;
    final user = await getUserById(userId);
    if (user != null && user.isSuperAdmin) {
      await logAudit(
        userId: actorId,
        userFullName: actorName,
        action: 'users.delete',
        resource: 'Users',
        resourceId: userId.toString(),
        status: 'DENIED',
        reason: 'Tentative interdite de suppression du compte Super Admin',
      );
      throw Exception('Impossible de supprimer le compte Super Admin.');
    }

    final rows = await db.delete('Users', where: 'id = ?', whereArgs: [userId]);

    await logAudit(
      userId: actorId,
      userFullName: actorName,
      action: 'users.delete',
      resource: 'Users',
      resourceId: userId.toString(),
      status: 'SUCCESS',
      reason: 'Suppression du compte utilisateur #$userId',
    );

    return rows;
  }

  // ==========================================
  // ROLES & PERMISSIONS DAO METHODS
  // ==========================================

  Future<List<RoleModel>> getAllRoles() async {
    final db = await instance.database;
    final maps = await db.query('Roles', orderBy: 'id ASC');
    final List<RoleModel> roles = [];

    for (final map in maps) {
      final roleId = map['id'] as int;
      final permissions = await getPermissionsForRole(roleId);
      roles.add(RoleModel.fromMap(map, permissions: permissions));
    }
    return roles;
  }

  Future<RoleModel?> getRoleById(int id) async {
    final db = await instance.database;
    final maps = await db.query('Roles', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      final permissions = await getPermissionsForRole(id);
      return RoleModel.fromMap(maps.first, permissions: permissions);
    }
    return null;
  }

  Future<List<String>> getPermissionsForRole(int roleId) async {
    final db = await instance.database;
    final maps = await db.query(
      'RolePermissions',
      columns: ['permissionCode'],
      where: 'roleId = ?',
      whereArgs: [roleId],
    );
    return maps.map((m) => m['permissionCode'] as String).toList();
  }

  Future<List<PermissionDefinition>> getAllPermissions() async {
    final db = await instance.database;
    final maps = await db.query('Permissions', orderBy: 'module ASC, code ASC');
    return maps.map((m) => PermissionDefinition.fromMap(m)).toList();
  }

  Future<int> insertRole(RoleModel role, List<String> permissions, {int? actorId, String? actorName}) async {
    final db = await instance.database;
    final roleId = await db.transaction((txn) async {
      final id = await txn.insert('Roles', {
        'name': role.name.trim().toLowerCase().replaceAll(' ', '_'),
        'displayName': role.displayName.trim(),
        'description': role.description?.trim(),
        'isSystem': 0,
        'createdAt': DateTime.now().toIso8601String(),
      });

      for (final perm in permissions) {
        await txn.insert(
          'RolePermissions',
          {'roleId': id, 'permissionCode': perm},
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }

      return id;
    });

    await logAudit(
      userId: actorId,
      userFullName: actorName,
      action: 'roles.create',
      resource: 'Roles',
      resourceId: roleId.toString(),
      status: 'SUCCESS',
      reason: 'Création du rôle personnalisé "${role.displayName}"',
    );

    return roleId;
  }

  Future<void> updateRole(RoleModel role, List<String> permissions, {int? actorId, String? actorName}) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.update(
        'Roles',
        {
          'displayName': role.displayName.trim(),
          'description': role.description?.trim(),
        },
        where: 'id = ?',
        whereArgs: [role.id],
      );

      // Refresh permissions for this role
      await txn.delete('RolePermissions', where: 'roleId = ?', whereArgs: [role.id]);

      for (final perm in permissions) {
        await txn.insert(
          'RolePermissions',
          {'roleId': role.id, 'permissionCode': perm},
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    });

    await logAudit(
      userId: actorId,
      userFullName: actorName,
      action: 'roles.update',
      resource: 'Roles',
      resourceId: role.id.toString(),
      status: 'SUCCESS',
      reason: 'Mise à jour des permissions du rôle "${role.displayName}"',
    );
  }

  Future<int> deleteRole(int roleId, {int? actorId, String? actorName}) async {
    final db = await instance.database;
    final role = await getRoleById(roleId);

    if (role != null && role.isSystem) {
      await logAudit(
        userId: actorId,
        userFullName: actorName,
        action: 'roles.delete',
        resource: 'Roles',
        resourceId: roleId.toString(),
        status: 'DENIED',
        reason: 'Tentative interdite de suppression d\'un rôle système (${role.name})',
      );
      throw Exception('Impossible de supprimer un rôle système.');
    }

    final rows = await db.delete('Roles', where: 'id = ?', whereArgs: [roleId]);

    await logAudit(
      userId: actorId,
      userFullName: actorName,
      action: 'roles.delete',
      resource: 'Roles',
      resourceId: roleId.toString(),
      status: 'SUCCESS',
      reason: 'Suppression du rôle #$roleId',
    );

    return rows;
  }

  // ==========================================
  // AUDIT LOGS DAO METHODS
  // ==========================================

  Future<int> logAudit({
    int? userId,
    String? userFullName,
    required String action,
    required String resource,
    String? resourceId,
    required String status,
    String? reason,
  }) async {
    try {
      final db = await instance.database;
      return await db.insert('AuditLogs', {
        'userId': userId,
        'userFullName': userFullName,
        'action': action,
        'resource': resource,
        'resourceId': resourceId,
        'status': status,
        'reason': reason,
        'createdAt': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      return 0;
    }
  }

  Future<List<AuditLogModel>> getAllAuditLogs({
    int limit = 200,
    int offset = 0,
    String? search,
    String? status,
  }) async {
    final db = await instance.database;
    String whereClause = '';
    final List<dynamic> whereArgs = [];

    if (search != null && search.isNotEmpty) {
      whereClause += '(action LIKE ? OR resource LIKE ? OR userFullName LIKE ? OR reason LIKE ?)';
      final s = '%$search%';
      whereArgs.addAll([s, s, s, s]);
    }

    if (status != null && status.isNotEmpty) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'status = ?';
      whereArgs.add(status);
    }

    final maps = await db.query(
      'AuditLogs',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'id DESC',
      limit: limit,
      offset: offset,
    );

    return maps.map((m) => AuditLogModel.fromMap(m)).toList();
  }

  // ==========================================
  // CLIENT DAO METHODS
  // ==========================================

  Future<List<ClientModel>> getAllClients() async {
    final db = await instance.database;
    final maps = await db.query('Clients', orderBy: 'nom_prenom ASC');
    return maps.map((m) => ClientModel.fromMap(m)).toList();
  }

  Future<int> insertClient(ClientModel client, {int? actorId, String? actorName}) async {
    final db = await instance.database;
    final id = await db.insert('Clients', client.toMap());

    await logAudit(
      userId: actorId,
      userFullName: actorName,
      action: 'customers.create',
      resource: 'Clients',
      resourceId: id.toString(),
      status: 'SUCCESS',
      reason: 'Ajout du client ${client.nomPrenom}',
    );

    return id;
  }

  Future<int> updateClient(ClientModel client, {int? actorId, String? actorName}) async {
    final db = await instance.database;
    final rows = await db.update(
      'Clients',
      client.toMap(),
      where: 'id = ?',
      whereArgs: [client.id],
    );

    await logAudit(
      userId: actorId,
      userFullName: actorName,
      action: 'customers.update',
      resource: 'Clients',
      resourceId: client.id.toString(),
      status: 'SUCCESS',
      reason: 'Mise à jour du client ${client.nomPrenom}',
    );

    return rows;
  }

  Future<int> deleteClient(int id, {int? actorId, String? actorName}) async {
    final db = await instance.database;
    final rows = await db.delete('Clients', where: 'id = ?', whereArgs: [id]);

    await logAudit(
      userId: actorId,
      userFullName: actorName,
      action: 'customers.delete',
      resource: 'Clients',
      resourceId: id.toString(),
      status: 'SUCCESS',
      reason: 'Suppression du client #$id',
    );

    return rows;
  }

  // ==========================================
  // HISTORIQUE / TRANSACTIONS DAO METHODS
  // ==========================================

  Future<List<HistoriqueModel>> getAllHistoriques() async {
    final db = await instance.database;
    final maps = await db.rawQuery('''
      SELECT H.*, C.nom_prenom as clientName 
      FROM Historiques H 
      LEFT JOIN Clients C ON H.id_client = C.id 
      ORDER BY H.id DESC
    ''');
    return maps.map((m) => HistoriqueModel.fromMap(m)).toList();
  }

  Future<int> insertHistorique(HistoriqueModel hist, {int? actorId, String? actorName}) async {
    final db = await instance.database;
    final id = await db.insert('Historiques', hist.toMap());

    await logAudit(
      userId: actorId,
      userFullName: actorName,
      action: 'transactions.create',
      resource: 'Historiques',
      resourceId: id.toString(),
      status: 'SUCCESS',
      reason: 'Transfert Flexy de ${hist.somme} DZD vers le numéro ${hist.numero}',
    );

    return id;
  }

  Future<int> deleteHistorique(int id, {int? actorId, String? actorName}) async {
    final db = await instance.database;
    final rows = await db.delete('Historiques', where: 'id = ?', whereArgs: [id]);

    await logAudit(
      userId: actorId,
      userFullName: actorName,
      action: 'transactions.delete',
      resource: 'Historiques',
      resourceId: id.toString(),
      status: 'SUCCESS',
      reason: 'Suppression de la transaction Flexy #$id',
    );

    return rows;
  }

  Future<int> updateHistorique(HistoriqueModel hist) async {
    final db = await instance.database;
    return await db.update(
      'Historiques',
      hist.toMap(),
      where: 'id = ?',
      whereArgs: [hist.id],
    );
  }

  // ==========================================
  // SETTINGS DAO METHODS
  // ==========================================

  Future<List<SettingsModel>> getAllSettings() async {
    final db = await instance.database;
    final maps = await db.query('Settings');
    return maps.map((m) => SettingsModel.fromMap(m)).toList();
  }

  Future<SettingsModel?> getSettingsByOperator(int operateur) async {
    final db = await instance.database;
    final maps = await db.query(
      'Settings',
      where: 'typeOperator = ?',
      whereArgs: [operateur],
    );
    if (maps.isNotEmpty) {
      return SettingsModel.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateSettings(SettingsModel settings, {int? actorId, String? actorName}) async {
    final db = await instance.database;
    final rows = await db.update(
      'Settings',
      settings.toMap(),
      where: 'typeOperator = ?',
      whereArgs: [settings.typeOperator],
    );

    await logAudit(
      userId: actorId,
      userFullName: actorName,
      action: 'settings.update',
      resource: 'Settings',
      resourceId: settings.typeOperator.toString(),
      status: 'SUCCESS',
      reason: 'Mise à jour des paramètres pour l\'opérateur #${settings.typeOperator}',
    );

    return rows;
  }

  // ==========================================
  // PAIEMENTS DETTE DAO METHODS
  // ==========================================

  Future<int> insertPaiementDette(PaiementDetteModel p, {int? actorId, String? actorName}) async {
    final db = await instance.database;
    final id = await db.insert('PaiementsDette', p.toMap());

    await logAudit(
      userId: actorId ?? p.idUser,
      userFullName: actorName ?? p.userFullname,
      action: 'debts.pay',
      resource: 'PaiementsDette',
      resourceId: id.toString(),
      status: 'SUCCESS',
      reason: 'Règlement de dette de ${p.montant} DZD pour le client ${p.nomClient}',
    );

    return id;
  }

  Future<List<PaiementDetteModel>> getAllPaiementsDette() async {
    final db = await instance.database;
    final maps = await db.query('PaiementsDette', orderBy: 'createdAt DESC');
    return maps.map((m) => PaiementDetteModel.fromMap(m)).toList();
  }

  Future<List<PaiementDetteModel>> getPaiementsDetteByClient(int clientId) async {
    final db = await instance.database;
    final maps = await db.query(
      'PaiementsDette',
      where: 'id_client = ?',
      whereArgs: [clientId],
      orderBy: 'createdAt DESC',
    );
    return maps.map((m) => PaiementDetteModel.fromMap(m)).toList();
  }

  Future<int> insertTresorerie({
    required double somme,
    required int idUser,
    int? idClient,
    String? note,
  }) async {
    final db = await instance.database;
    return await db.insert('Tresorerers', {
      'somme': somme,
      'rest_somme': 0.0,
      'type': 1, // Income / Payment received
      'id_client': idClient,
      'id_user': idUser,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }
}
