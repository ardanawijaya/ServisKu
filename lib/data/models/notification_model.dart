class NotificationModel {
  final int id;
  final int? vehicleId;
  final String? merekTipe;
  final String? platNomor;
  final String tipe; // mendekati | terlambat | servis | pengingat_km
  final String kategori; // perawatan | pengingat
  final String judul;
  final String isi;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.vehicleId,
    required this.merekTipe,
    required this.platNomor,
    required this.tipe,
    required this.kategori,
    required this.judul,
    required this.isi,
    required this.isRead,
    required this.createdAt,
  });

  NotificationModel copyWith({bool? isRead}) => NotificationModel(
        id: id,
        vehicleId: vehicleId,
        merekTipe: merekTipe,
        platNomor: platNomor,
        tipe: tipe,
        kategori: kategori,
        judul: judul,
        isi: isi,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
      );

  factory NotificationModel.fromJson(Map<String, dynamic> j) {
    final k = j['kendaraan'] as Map<String, dynamic>?;
    return NotificationModel(
      id: j['id'] as int,
      vehicleId: j['vehicleId'] as int?,
      merekTipe: k?['merekTipe'] as String?,
      platNomor: k?['platNomor'] as String?,
      tipe: j['tipe'] as String,
      kategori: j['kategori'] as String,
      judul: j['judul'] as String,
      isi: j['isi'] as String,
      isRead: j['isRead'] as bool,
      createdAt: DateTime.parse(j['createdAt'] as String),
    );
  }
}
