class HistoriqueModel {
  final int? id;
  final int operateur; // 1: Djezzy, 2: Mobilis, 3: Ooredoo
  final String numero;
  final double somme;
  final double restSomme;
  final double sommePayee;
  final String reponse;
  final int marge;
  final bool type; // true / 1: Flexy envoyé, false / 0: Flexy reçu
  final bool status; // true: success, false: fail
  final bool credit; // true: on debt/credit, false: paid
  final int? idClient;
  final int? idUser;
  final String? clientName;
  final DateTime createdAt;

  HistoriqueModel({
    this.id,
    required this.operateur,
    required this.numero,
    required this.somme,
    this.restSomme = 0.0,
    this.sommePayee = 0.0,
    this.reponse = '',
    this.marge = 0,
    this.type = true,
    this.status = true,
    this.credit = false,
    this.idClient,
    this.idUser,
    this.clientName,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'operateur': operateur,
      'Numero': numero,
      'somme': somme,
      'rest_somme': restSomme,
      'somme_payee': sommePayee,
      'Reponse': reponse,
      'marge': marge,
      'type': type ? 1 : 0,
      'status': status ? 1 : 0,
      'credit': credit ? 1 : 0,
      'id_client': idClient,
      'id_user': idUser,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory HistoriqueModel.fromMap(Map<String, dynamic> map, {String? clientName}) {
    return HistoriqueModel(
      id: map['id'] as int?,
      operateur: (map['operateur'] as num?)?.toInt() ?? 1,
      numero: map['Numero'] as String? ?? '',
      somme: (map['somme'] as num?)?.toDouble() ?? 0.0,
      restSomme: (map['rest_somme'] as num?)?.toDouble() ?? 0.0,
      sommePayee: (map['somme_payee'] as num?)?.toDouble() ?? 0.0,
      reponse: map['Reponse'] as String? ?? '',
      marge: (map['marge'] as num?)?.toInt() ?? 0,
      type: (map['type'] == 1 || map['type'] == true),
      status: (map['status'] == 1 || map['status'] == true),
      credit: (map['credit'] == 1 || map['credit'] == true),
      idClient: map['id_client'] != null ? int.tryParse(map['id_client'].toString()) : null,
      idUser: map['id_user'] != null ? int.tryParse(map['id_user'].toString()) : null,
      clientName: clientName ?? map['clientName'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String get operatorName {
    switch (operateur) {
      case 1:
        return 'Djezzy';
      case 2:
        return 'Mobilis';
      case 3:
        return 'Ooredoo';
      default:
        return 'Mobilis';
    }
  }

  String get phone => numero;
  double get montant => somme;
  bool get isCredit => credit;
  String get dateFormatted =>
      '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year} ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}:${createdAt.second.toString().padLeft(2, '0')}';
}

