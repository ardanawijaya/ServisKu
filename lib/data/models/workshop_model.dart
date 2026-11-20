int _int(dynamic v) => (v as num).toInt();

class WorkshopStats {
  final int menunggu;
  final int dikonfirmasi;
  final int dikerjakan;
  final int selesai;
  final int antrean;
  final int layananTotal;
  final int layananAktif;

  const WorkshopStats({
    required this.menunggu,
    required this.dikonfirmasi,
    required this.dikerjakan,
    required this.selesai,
    required this.antrean,
    required this.layananTotal,
    required this.layananAktif,
  });

  factory WorkshopStats.fromJson(Map<String, dynamic> j) => WorkshopStats(
        menunggu: _int(j['menunggu']),
        dikonfirmasi: _int(j['dikonfirmasi']),
        dikerjakan: _int(j['dikerjakan']),
        selesai: _int(j['selesai']),
        antrean: _int(j['antrean']),
        layananTotal: _int(j['layananTotal']),
        layananAktif: _int(j['layananAktif']),
      );
}

class WorkshopModel {
  final int id;
  final String nama;
  final String? spesialis;
  final String? kota;
  final String? alamat;
  final String? noWhatsapp;
  final String jamBuka;
  final String jamTutup;
  final String hariOperasional;
  final int kuotaHarian;
  final bool buka;
  final WorkshopStats stats;

  const WorkshopModel({
    required this.id,
    required this.nama,
    required this.spesialis,
    required this.kota,
    required this.alamat,
    required this.noWhatsapp,
    required this.jamBuka,
    required this.jamTutup,
    required this.hariOperasional,
    required this.kuotaHarian,
    required this.buka,
    required this.stats,
  });

  /// Profil dianggap lengkap jika alamat sudah diisi.
  bool get profilLengkap => (alamat ?? '').trim().isNotEmpty;

  factory WorkshopModel.fromJson(Map<String, dynamic> j) => WorkshopModel(
        id: _int(j['id']),
        nama: j['nama'] as String,
        spesialis: j['spesialis'] as String?,
        kota: j['kota'] as String?,
        alamat: j['alamat'] as String?,
        noWhatsapp: j['noWhatsapp'] as String?,
        jamBuka: j['jamBuka'] as String,
        jamTutup: j['jamTutup'] as String,
        hariOperasional: j['hariOperasional'] as String,
        kuotaHarian: _int(j['kuotaHarian']),
        buka: j['buka'] as bool,
        stats: WorkshopStats.fromJson(j['stats'] as Map<String, dynamic>),
      );
}

class WorkshopServiceModel {
  final int id;
  final String kategori;
  final String nama;
  final String? deskripsi;
  final int durasiMenit;
  final int hargaMin;
  final int hargaMax;
  final bool isActive;

  const WorkshopServiceModel({
    required this.id,
    required this.kategori,
    required this.nama,
    required this.deskripsi,
    required this.durasiMenit,
    required this.hargaMin,
    required this.hargaMax,
    required this.isActive,
  });

  factory WorkshopServiceModel.fromJson(Map<String, dynamic> j) => WorkshopServiceModel(
        id: _int(j['id']),
        kategori: j['kategori'] as String,
        nama: j['nama'] as String,
        deskripsi: j['deskripsi'] as String?,
        durasiMenit: _int(j['durasiMenit']),
        hargaMin: _int(j['hargaMin']),
        hargaMax: _int(j['hargaMax']),
        isActive: j['isActive'] as bool,
      );
}
