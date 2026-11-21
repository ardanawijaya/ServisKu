const prisma = require('../config/db');

// Notifikasi untuk pengguna saat status booking berubah. Kegagalan di sini tidak boleh
// menggagalkan aksi bengkel, jadi error hanya dicatat.
async function kirimNotifikasiBooking(userId, vehicleId, judul, isi) {
  try {
    await prisma.notification.create({
      data: { userId, vehicleId, tipe: 'booking', judul, isi },
    });
  } catch (e) {
    console.error('Gagal membuat notifikasi booking:', e);
  }
}

module.exports = { kirimNotifikasiBooking };
