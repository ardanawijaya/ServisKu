class ServiceRecordModel {
  final int id;
  final int vehicleId;
  final String merekTipe;
  final String platNomor;
  final String jenisKendaraan;
  final DateTime tanggal;
  final int odometer;
  final List<String> jenisServis;
  final String namaBengkel;
  final int biaya;
  final String? catatan;
  final bool dariBooking;

  const ServiceRecordModel({
    required this.id,
    required this.vehicleId,
    required this.merekTipe,
    required this.platNomor,
    required this.jenisKendaraan,
    required this.tanggal,
    required this.odometer,
    required this.jenisServis,
    required this.namaBengkel,
    required this.biaya,
    required this.catatan,
    required this.dariBooking,
  });

  String get judul => jenisServis.join(' & ');
  bool get isMotor => jenisKendaraan == 'motor';

  factory ServiceRecordModel.fromJson(Map<String, dynamic> j) {
    final k = j['kendaraan'] as Map<String, dynamic>;
    return ServiceRecordModel(
      id: j['id'] as int,
      vehicleId: j['vehicleId'] as int,
      merekTipe: k['merekTipe'] as String,
      platNomor: k['platNomor'] as String,
      jenisKendaraan: k['jenis'] as String,
      tanggal: DateTime.parse(j['tanggal'] as String),
      odometer: j['odometer'] as int,
      jenisServis: (j['jenisServis'] as List).map((e) => e.toString()).toList(),
      namaBengkel: j['namaBengkel'] as String,
      biaya: j['biaya'] as int,
      catatan: j['catatan'] as String?,
      dariBooking: j['dariBooking'] as bool,
    );
  }
}
