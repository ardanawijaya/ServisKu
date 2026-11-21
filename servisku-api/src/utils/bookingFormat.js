// Relasi yang dimuat untuk setiap booking + bentuk JSON-nya
const includeBooking = {
  workshop: { select: { id: true, nama: true, alamat: true, kota: true, noWhatsapp: true } },
  vehicle: { select: { merekTipe: true, platNomor: true, jenis: true } },
  user: { select: { nama: true, noHp: true } },
  services: { include: { workshopService: { select: { nama: true, kategori: true } } } },
};

function formatBooking(b) {
  const layanan = b.services.map((s) => ({
    id: s.workshopServiceId,
    nama: s.workshopService.nama,
    kategori: s.workshopService.kategori,
    harga: s.harga,
  }));
  return {
    id: b.id,
    status: b.status,
    tanggal: b.tanggal,
    jam: b.jam,
    keluhan: b.keluhan,
    alasanPenolakan: b.alasanPenolakan,
    biayaAkhir: b.biayaAkhir,
    catatanBengkel: b.catatanBengkel,
    mekanik: b.mekanik,
    createdAt: b.createdAt,
    estimasiBiaya: layanan.reduce((s, l) => s + l.harga, 0),
    bolehBatal: b.status === 'menunggu' || b.status === 'dikonfirmasi',
    bengkel: {
      id: b.workshop.id,
      nama: b.workshop.nama,
      alamat: b.workshop.alamat,
      kota: b.workshop.kota,
      noWhatsapp: b.workshop.noWhatsapp,
    },
    kendaraan: { merekTipe: b.vehicle.merekTipe, platNomor: b.vehicle.platNomor, jenis: b.vehicle.jenis },
    pelanggan: { nama: b.user.nama, noHp: b.user.noHp },
    layanan,
  };
}

module.exports = { includeBooking, formatBooking };
