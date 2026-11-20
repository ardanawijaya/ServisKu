const prisma = require('../config/db');
const { sinkronkanNotifikasi } = require('../utils/notifikasi');

function format(n) {
  return {
    id: n.id,
    vehicleId: n.vehicleId,
    kendaraan: n.vehicle ? { merekTipe: n.vehicle.merekTipe, platNomor: n.vehicle.platNomor } : null,
    tipe: n.tipe,
    kategori: n.tipe === 'pengingat_km' ? 'pengingat' : 'perawatan',
    judul: n.judul,
    isi: n.isi,
    isRead: n.isRead,
    createdAt: n.createdAt,
  };
}

function httpError(status, message) {
  const e = new Error(message);
  e.status = status;
  return e;
}

exports.list = async (req, res, next) => {
  try {
    const userId = req.user.id;
    // Pastikan notifikasi terbaru (hasil pengingat) sudah dibuat sebelum daftar diambil
    await sinkronkanNotifikasi(userId);

    const [rows, unreadCount] = await Promise.all([
      prisma.notification.findMany({
        where: { userId },
        include: { vehicle: { select: { merekTipe: true, platNomor: true } } },
        orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
        take: 100,
      }),
      prisma.notification.count({ where: { userId, isRead: false } }),
    ]);

    res.json({ success: true, data: { notifications: rows.map(format), unreadCount } });
  } catch (err) {
    next(err);
  }
};

exports.markRead = async (req, res, next) => {
  try {
    const id = Number(req.params.id);
    if (!Number.isInteger(id) || id <= 0) throw httpError(400, 'ID notifikasi tidak valid');

    const n = await prisma.notification.findFirst({ where: { id, userId: req.user.id } });
    if (!n) throw httpError(404, 'Notifikasi tidak ditemukan');

    if (!n.isRead) await prisma.notification.update({ where: { id }, data: { isRead: true } });
    res.json({ success: true, message: 'Notifikasi ditandai sudah dibaca' });
  } catch (err) {
    next(err);
  }
};

exports.markAllRead = async (req, res, next) => {
  try {
    await prisma.notification.updateMany({
      where: { userId: req.user.id, isRead: false },
      data: { isRead: true },
    });
    res.json({ success: true, message: 'Semua notifikasi ditandai sudah dibaca' });
  } catch (err) {
    next(err);
  }
};
