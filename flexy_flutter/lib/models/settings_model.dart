class SettingsModel {
  final int? id;
  final int typeOperator; // 1: Djezzy, 2: Mobilis, 3: Ooredoo
  final int codeTransfert;
  final int codeSolde;
  final int codeInternational;
  final String codePin;
  final int codeFacteur;
  final int confYes;
  final int confNo;
  final bool autoConfirmation;
  final String comPort;
  final bool autoDetectUSB;
  final bool audioEnabled;
  final int audioSpeed;
  final String audioPerson;

  SettingsModel({
    this.id,
    required this.typeOperator,
    this.codeTransfert = 710,
    this.codeSolde = 710,
    this.codeInternational = 0,
    this.codePin = '0000',
    this.codeFacteur = 761,
    this.confYes = 1,
    this.confNo = 0,
    this.autoConfirmation = true,
    this.comPort = 'COM1',
    this.autoDetectUSB = true,
    this.audioEnabled = true,
    this.audioSpeed = 1,
    this.audioPerson = 'default',
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'typeOperator': typeOperator,
      'codeTrensfert': codeTransfert,
      'codeSolde': codeSolde,
      'codeInternational': codeInternational,
      'codePin': codePin,
      'codeFacteur': codeFacteur,
      'confYes': confYes,
      'confNo': confNo,
      'autoConfirmation': autoConfirmation ? 1 : 0,
      'comPort': comPort,
      'autoDetectUSB': autoDetectUSB ? 1 : 0,
      'audioEnabled': audioEnabled ? 1 : 0,
      'audioSpeed': audioSpeed,
      'audioPerson': audioPerson,
    };
  }

  factory SettingsModel.fromMap(Map<String, dynamic> map) {
    return SettingsModel(
      id: map['id'] as int?,
      typeOperator: (map['typeOperator'] as num?)?.toInt() ?? 1,
      codeTransfert: (map['codeTrensfert'] as num?)?.toInt() ?? 710,
      codeSolde: (map['codeSolde'] as num?)?.toInt() ?? 710,
      codeInternational: (map['codeInternational'] as num?)?.toInt() ?? 0,
      codePin: map['codePin'] as String? ?? '0000',
      codeFacteur: (map['codeFacteur'] as num?)?.toInt() ?? 761,
      confYes: (map['confYes'] as num?)?.toInt() ?? 1,
      confNo: (map['confNo'] as num?)?.toInt() ?? 0,
      autoConfirmation: (map['autoConfirmation'] == 1 || map['autoConfirmation'] == true),
      comPort: map['comPort'] as String? ?? 'COM1',
      autoDetectUSB: (map['autoDetectUSB'] == 1 || map['autoDetectUSB'] == true),
      audioEnabled: (map['audioEnabled'] == 1 || map['audioEnabled'] == true),
      audioSpeed: (map['audioSpeed'] as num?)?.toInt() ?? 1,
      audioPerson: map['audioPerson'] as String? ?? 'default',
    );
  }
}
