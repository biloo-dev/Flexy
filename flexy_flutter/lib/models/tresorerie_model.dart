class TresorerieModel {
  final int? id;
  final double somme;
  final double restSomme;
  final int? idHist;
  final bool type;
  final int? idClient;
  final int? idUser;
  final DateTime createdAt;

  TresorerieModel({
    this.id,
    required this.somme,
    this.restSomme = 0.0,
    this.idHist,
    this.type = true,
    this.idClient,
    this.idUser,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'somme': somme,
      'rest_somme': restSomme,
      'id_hist': idHist,
      'type': type ? 1 : 0,
      'id_client': idClient,
      'id_user': idUser,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TresorerieModel.fromMap(Map<String, dynamic> map) {
    return TresorerieModel(
      id: map['id'] as int?,
      somme: (map['somme'] as num?)?.toDouble() ?? 0.0,
      restSomme: (map['rest_somme'] as num?)?.toDouble() ?? 0.0,
      idHist: map['id_hist'] as int?,
      type: (map['type'] == 1 || map['type'] == true),
      idClient: map['id_client'] as int?,
      idUser: map['id_user'] as int?,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
