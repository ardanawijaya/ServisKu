import 'pengingat_model.dart';

class VehicleModel {
  final int id;
  final String jenis; // 'motor' | 'mobil'
  final String merekTipe;
  final String platNomor;
  final int tahun;
  final int odometerTerakhir;
  final bool isUtama;
  final DateTime? servisTerakhir;
  final PengingatModel? pengingat;

  const VehicleModel({
    required this.id,
    required this.jenis,
    required this.merekTipe,
    required this.platNomor,
    required this.tahun,
    required this.odometerTerakhir,
    required this.isUtama,
    this.servisTerakhir,
    this.pengingat,
  });

  bool get isMotor => jenis == 'motor';

  factory VehicleModel.fromJson(Map<String, dynamic> j) => VehicleModel(
        id: j['id'] as int,
        jenis: j['jenis'] as String,
        merekTipe: j['merekTipe'] as String,
        platNomor: j['platNomor'] as String,
        tahun: j['tahun'] as int,
        odometerTerakhir: j['odometerTerakhir'] as int,
        isUtama: j['isUtama'] as bool,
        servisTerakhir: j['servisTerakhir'] == null
            ? null
            : DateTime.parse(j['servisTerakhir'] as String),
        pengingat: j['pengingat'] == null
            ? null
            : PengingatModel.fromJson(j['pengingat'] as Map<String, dynamic>),
      );
}
