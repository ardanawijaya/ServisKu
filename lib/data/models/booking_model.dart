import 'workshop_model.dart';

int _i(dynamic v) => (v as num).toInt();

/// Bengkel di daftar pencarian (sisi pengguna).
class BengkelModel {
  final int id;
  final String nama;
  final String? spesialis;
  final String? kota;
  final String? alamat;
  final String? noWhatsapp;
  final String jamBuka;
  final String jamTutup;
  final String hariOperasional;
  final bool buka;
  final List<String> kategori;
  final int hargaMulai;
  final int layananAktif;
  final String? slotHariIni;

  const BengkelModel({
    required this.id,
    required this.nama,
    required this.spesialis,
    required this.kota,
    required this.alamat,
    required this.noWhatsapp,
    required this.jamBuka,
    required this.jamTutup,
    required this.hariOperasional,
    required this.buka,
    required this.kategori,
    required this.hargaMulai,
    required this.layananAktif,
    required this.slotHariIni,
  });

  factory BengkelModel.fromJson(Map<String, dynamic> j) => BengkelModel(
        id: _i(j['id']),
        nama: j['nama'] as String,
        spesialis: j['spesialis'] as String?,
        kota: j['kota'] as String?,
        alamat: j['alamat'] as String?,
        noWhatsapp: j['noWhatsapp'] as String?,
        jamBuka: j['jamBuka'] as String,
        jamTutup: j['jamTutup'] as String,
        hariOperasional: j['hariOperasional'] as String,
        buka: j['buka'] as bool,
        kategori: ((j['kategori'] as List?) ?? []).map((e) => e.toString()).toList(),
        hargaMulai: j['hargaMulai'] == null ? 0 : _i(j['hargaMulai']),
        layananAktif: j['layananAktif'] == null ? 0 : _i(j['layananAktif']),
        slotHariIni: j['slotHariIni'] as String?,
      );
}

class BengkelDetail {
  final BengkelModel bengkel;
  final List<WorkshopServiceModel> layanan;
  const BengkelDetail(this.bengkel, this.layanan);
}

class SlotModel {
  final String jam;
  final bool tersedia;
  final int sisa;
  const SlotModel(this.jam, this.tersedia, this.sisa);
}

class AvailabilityModel {
  final bool tutup;
  final String? alasan;
  final bool penuh;
  final int kuotaSisa;
  final List<SlotModel> slots;

  const AvailabilityModel({
    required this.tutup,
    required this.alasan,
    required this.penuh,
    required this.kuotaSisa,
    required this.slots,
  });

  factory AvailabilityModel.fromJson(Map<String, dynamic> j) => AvailabilityModel(
        tutup: j['tutup'] as bool,
        alasan: j['alasan'] as String?,
        penuh: j['penuh'] as bool,
        kuotaSisa: _i((j['kuota'] as Map<String, dynamic>)['sisa']),
        slots: (j['slots'] as List)
            .map((e) => e as Map<String, dynamic>)
            .map((e) => SlotModel(e['jam'] as String, e['tersedia'] as bool, _i(e['sisa'])))
            .toList(),
      );
}

class BookingLayananModel {
  final int id;
  final String nama;
  final String kategori;
  final int harga;
  const BookingLayananModel(this.id, this.nama, this.kategori, this.harga);
}

class BookingModel {
  final int id;
  final String status; // menunggu | dikonfirmasi | ditolak | dikerjakan | selesai | dibatalkan
  final DateTime tanggal;
  final String jam;
  final String? keluhan;
  final String? alasanPenolakan;
  final int? biayaAkhir;
  final String? catatanBengkel;
  final String? mekanik;
  final DateTime createdAt;
  final int estimasiBiaya;
  final bool bolehBatal;
  final int bengkelId;
  final String bengkelNama;
  final String? bengkelAlamat;
  final String? bengkelKota;
  final String? bengkelWa;
  final String merekTipe;
  final String platNomor;
  final String jenisKendaraan;
  final String pelangganNama;
  final String pelangganHp;
  final List<BookingLayananModel> layanan;

  const BookingModel({
    required this.id,
    required this.status,
    required this.tanggal,
    required this.jam,
    required this.keluhan,
    required this.alasanPenolakan,
    required this.biayaAkhir,
    required this.catatanBengkel,
    required this.mekanik,
    required this.createdAt,
    required this.estimasiBiaya,
    required this.bolehBatal,
    required this.bengkelId,
    required this.bengkelNama,
    required this.bengkelAlamat,
    required this.bengkelKota,
    required this.bengkelWa,
    required this.merekTipe,
    required this.platNomor,
    required this.jenisKendaraan,
    required this.pelangganNama,
    required this.pelangganHp,
    required this.layanan,
  });

  String get namaLayanan => layanan.map((l) => l.nama).join(', ');

  factory BookingModel.fromJson(Map<String, dynamic> j) {
    final b = j['bengkel'] as Map<String, dynamic>;
    final k = j['kendaraan'] as Map<String, dynamic>;
    final p = j['pelanggan'] as Map<String, dynamic>;
    return BookingModel(
      id: _i(j['id']),
      status: j['status'] as String,
      tanggal: DateTime.parse(j['tanggal'] as String),
      jam: j['jam'] as String,
      keluhan: j['keluhan'] as String?,
      alasanPenolakan: j['alasanPenolakan'] as String?,
      biayaAkhir: j['biayaAkhir'] == null ? null : _i(j['biayaAkhir']),
      catatanBengkel: j['catatanBengkel'] as String?,
      mekanik: j['mekanik'] as String?,
      createdAt: DateTime.parse(j['createdAt'] as String),
      estimasiBiaya: _i(j['estimasiBiaya']),
      bolehBatal: j['bolehBatal'] as bool,
      bengkelId: _i(b['id']),
      bengkelNama: b['nama'] as String,
      bengkelAlamat: b['alamat'] as String?,
      bengkelKota: b['kota'] as String?,
      bengkelWa: b['noWhatsapp'] as String?,
      merekTipe: k['merekTipe'] as String,
      platNomor: k['platNomor'] as String,
      jenisKendaraan: k['jenis'] as String,
      pelangganNama: p['nama'] as String,
      pelangganHp: p['noHp'] as String,
      layanan: (j['layanan'] as List)
          .map((e) => e as Map<String, dynamic>)
          .map((e) => BookingLayananModel(
              _i(e['id']), e['nama'] as String, e['kategori'] as String, _i(e['harga'])))
          .toList(),
    );
  }
}
