import 'dart:convert';

class ClientModel {
  final int? id;
  final String nomPrenom;
  final bool fidel;
  final bool type; // false/0: Client, true/1: Fournisseur
  final List<String> numeroPhoneList;
  final double credit;

  ClientModel({
    this.id,
    required this.nomPrenom,
    this.fidel = false,
    this.type = false,
    required this.numeroPhoneList,
    this.credit = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nom_prenom': nomPrenom,
      'fidel': fidel ? 1 : 0,
      'type': type ? 1 : 0,
      'numeroPhoneList': jsonEncode(numeroPhoneList),
      'credit': credit,
    };
  }

  factory ClientModel.fromMap(Map<String, dynamic> map) {
    List<String> phones = [];
    if (map['numeroPhoneList'] != null) {
      final raw = map['numeroPhoneList'].toString().trim();
      if (raw.startsWith('[') && raw.endsWith(']')) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is List) {
            phones = decoded.map((e) => e.toString()).toList();
          } else if (decoded is String) {
            phones = [decoded];
          }
        } catch (_) {
          phones = [raw];
        }
      } else if (raw.isNotEmpty) {
        phones = [raw];
      }
    }

    return ClientModel(
      id: map['id'] as int?,
      nomPrenom: map['nom_prenom'] as String? ?? '',
      fidel: (map['fidel'] == 1 || map['fidel'] == true),
      type: (map['type'] == 1 || map['type'] == true),
      numeroPhoneList: phones,
      credit: (map['credit'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClientModel && (id != null ? other.id == id : other.nomPrenom == nomPrenom);
  }

  @override
  int get hashCode => id != null ? id.hashCode : nomPrenom.hashCode;
}
