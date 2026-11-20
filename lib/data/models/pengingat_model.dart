int _int(dynamic v) => (v as num).toInt();

class KomponenModel {
  final String nama;
  final String status; // aman | mendekati | terlambat
  final String pemicu; // km | waktu
  final int sisaKm;
  final int? sisaHari;
  final int persenSisa;
  final DateTime? jatuhTempo;

  const KomponenModel({
    required this.nama,
    required this.status,
    required this.pemicu,
    required this.sisaKm,
    required this.sisaHari,
    required this.persenSisa,
    required this.jatuhTempo,
  });

  factory KomponenModel.fromJson(Map<String, dynamic> j) => KomponenModel(
        nama: j['komponen'] as String,
        status: j['status'] as String,
        pemicu: j['pemicu'] as String,
        sisaKm: _int(j['sisaKm']),
        sisaHari: j['sisaHari'] == null ? null : _int(j['sisaHari']),
        persenSisa: _int(j['persenSisa']),
        jatuhTempo:
            j['jatuhTempo'] == null ? null : DateTime.parse(j['jatuhTempo'] as String),
      );
}

class EstimasiModel {
  final String komponen;
  final String status;
  final int sisaKm;
  final int? sisaHari;
  final int persenTerpakai;
  final int? perkiraanHariDariKm;

  const EstimasiModel({
    required this.komponen,
    required this.status,
    required this.sisaKm,
    required this.sisaHari,
    required this.persenTerpakai,
    required this.perkiraanHariDariKm,
  });

  factory EstimasiModel.fromJson(Map<String, dynamic> j) => EstimasiModel(
        komponen: j['komponen'] as String,
        status: j['status'] as String,
        sisaKm: _int(j['sisaKm']),
        sisaHari: j['sisaHari'] == null ? null : _int(j['sisaHari']),
        persenTerpakai: _int(j['persenTerpakai']),
        perkiraanHariDariKm:
            j['perkiraanHariDariKm'] == null ? null : _int(j['perkiraanHariDariKm']),
      );
}

class PengingatModel {
  final int kondisiPersen;
  final String kondisiLabel;
  final String status; // status terburuk di antara semua komponen
  final double? rataRataKmPerHari;
  final EstimasiModel estimasi;
  final List<KomponenModel> komponen;

  const PengingatModel({
    required this.kondisiPersen,
    required this.kondisiLabel,
    required this.status,
    required this.rataRataKmPerHari,
    required this.estimasi,
    required this.komponen,
  });

  factory PengingatModel.fromJson(Map<String, dynamic> j) => PengingatModel(
        kondisiPersen: _int(j['kondisiPersen']),
        kondisiLabel: j['kondisiLabel'] as String,
        status: j['status'] as String,
        rataRataKmPerHari:
            j['rataRataKmPerHari'] == null ? null : (j['rataRataKmPerHari'] as num).toDouble(),
        estimasi: EstimasiModel.fromJson(j['estimasi'] as Map<String, dynamic>),
        komponen: (j['komponen'] as List)
            .map((e) => KomponenModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
