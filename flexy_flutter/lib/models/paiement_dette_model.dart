class PaiementDetteModel {
  final int? id;
  final int idClient;
  final int idUser;
  final String userFullname;
  final String nomClient;
  final double montant;
  final double ancienCredit;
  final double nouveauCredit;
  final String? note;
  final DateTime createdAt;

  PaiementDetteModel({
    this.id,
    required this.idClient,
    required this.idUser,
    required this.userFullname,
    required this.nomClient,
    required this.montant,
    required this.ancienCredit,
    required this.nouveauCredit,
    this.note,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'id_client': idClient,
      'id_user': idUser,
      'user_fullname': userFullname,
      'nom_client': nomClient,
      'montant': montant,
      'ancien_credit': ancienCredit,
      'nouveau_credit': nouveauCredit,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PaiementDetteModel.fromMap(Map<String, dynamic> map) {
    return PaiementDetteModel(
      id: map['id'] as int?,
      idClient: (map['id_client'] as num).toInt(),
      idUser: (map['id_user'] as num).toInt(),
      userFullname: map['user_fullname'] as String? ?? 'Admin',
      nomClient: map['nom_client'] as String? ?? '',
      montant: (map['montant'] as num).toDouble(),
      ancienCredit: (map['ancien_credit'] as num).toDouble(),
      nouveauCredit: (map['nouveau_credit'] as num).toDouble(),
      note: map['note'] as String?,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
