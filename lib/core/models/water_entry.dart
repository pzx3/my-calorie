class WaterEntry {
  final String   id;
  final int      amountMl;
  final DateTime dateTime;

  const WaterEntry({required this.id, required this.amountMl, required this.dateTime});

  Map<String, dynamic> toJson() => {
    'id': id, 'amountMl': amountMl, 'dateTime': dateTime.toIso8601String(),
  };

  factory WaterEntry.fromJson(Map<String, dynamic> j) => WaterEntry(
    id: j['id']?.toString() ?? '', 
    amountMl: (j['amountMl'] as num?)?.toInt() ?? 0, 
    dateTime: j['dateTime'] != null ? DateTime.tryParse(j['dateTime'].toString()) ?? DateTime.now() : DateTime.now(),
  );
}
