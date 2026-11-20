const prisma = require('../config/db');
const { pengingatUntukKendaraan } = require('./pengingatService');

/**
 * NOTIFIKASI DALAM APLIKASI
 * -------------------------
 * Tipe notifikasi:
 *   mendekati    : komponen mendekati jadwal servis      (kategori "perawatan")
 *   terlambat    : komponen melewati jadwal servis       (kategori "perawatan")
 *   servis       : catatan servis berhasil disimpan      (kategori "perawatan")
 *   pengingat_km : pengingat memperbarui odometer        (kategori "pengingat")
 *
 * Notifikasi dibuat secara "lazy" dan idempotent: setiap kali daftar notifikasi diminta,
 * sistem membandingkan status pengingat saat ini dengan notifikasi yang sudah ada dan hanya
 * membuat yang belum ada. Memanggilnya berulang kali tidak menimbulkan duplikat.
 */

const MS_HARI = 24 * 60 * 60 * 1000;
const JEDA_PENGINGAT_KM_HARI = 7;

const angka = (n) => Number(n).toLocaleString('id-ID');

function teksPerawatan(v, k) {
  const kendaraan = `${v.merekTipe} (${v.platNomor})`;
  if (k.status === 'terlambat') {
    const lewat =
      k.pemicu === 'waktu' && k.sisaHari !== null
        ? `terlewat ${angka(Math.abs(k.sisaHari))} hari`
        : `terlewat ${angka(Math.abs(k.sisaKm))} km`;
    return `${kendaraan}: ${k.komponen} sudah melewati jadwal servis (${lewat}). Segera lakukan servis.`;
  }
  const hari = k.sisaHari !== null ? ` atau ${angka(k.sisaHari)} hari` : '';
  return `${kendaraan}: ${k.komponen} mendekati jadwal servis. Tersisa ${angka(k.sisaKm)} km${hari}.`;
}

async function sinkron(userId) {
  const vehicles = await prisma.vehicle.findMany({ where: { userId } });
  if (!vehicles.length) return;
  const ids = vehicles.map((v) => v.id);

  const [peng, vcs, existing, lastLogs] = await Promise.all([
    pengingatUntukKendaraan(vehicles),
    prisma.vehicleComponent.findMany({
      where: { vehicleId: { in: ids } },
      include: { component: true },
    }),
    prisma.notification.findMany({
      where: { userId, vehicleId: { in: ids }, tipe: { in: ['mendekati', 'terlambat', 'pengingat_km'] } },
      select: { vehicleId: true, tipe: true, judul: true, createdAt: true },
    }),
    prisma.odometerLog.groupBy({
      by: ['vehicleId'],
      where: { vehicleId: { in: ids } },
      _max: { dicatatPada: true },
    }),
  ]);

  const baru = [];
  const sekarang = new Date();

  for (const v of vehicles) {
    // 1) Notifikasi perawatan: komponen mendekati / terlambat
    const p = peng[v.id];
    if (p) {
      for (const k of p.komponen) {
        if (k.status === 'aman') continue;
        const vc = vcs.find((x) => x.vehicleId === v.id && x.component.nama === k.komponen);
        // Notifikasi lama sebelum servis terakhir tidak dihitung (siklus baru boleh diberi notifikasi lagi)
        const batas = vc && vc.lastServiceDate ? new Date(vc.lastServiceDate) : new Date(0);
        const judul =
          k.status === 'terlambat' ? `${k.komponen} Terlambat Diservis` : `${k.komponen} Mendekati Jadwal`;
        const sudah = existing.some(
          (n) => n.vehicleId === v.id && n.tipe === k.status && n.judul === judul && n.createdAt >= batas,
        );
        if (!sudah) {
          baru.push({ userId, vehicleId: v.id, tipe: k.status, judul, isi: teksPerawatan(v, k) });
        }
      }
    }

    // 2) Pengingat memperbarui odometer jika sudah >= 7 hari tanpa pembaruan
    const last = lastLogs.find((l) => l.vehicleId === v.id);
    const lastAt = last && last._max ? last._max.dicatatPada : null;
    if (lastAt) {
      const hari = Math.floor((sekarang.getTime() - new Date(lastAt).getTime()) / MS_HARI);
      if (hari >= JEDA_PENGINGAT_KM_HARI) {
        const sudah = existing.some(
          (n) =>
            n.vehicleId === v.id &&
            n.tipe === 'pengingat_km' &&
            sekarang.getTime() - new Date(n.createdAt).getTime() < JEDA_PENGINGAT_KM_HARI * MS_HARI,
        );
        if (!sudah) {
          baru.push({
            userId,
            vehicleId: v.id,
            tipe: 'pengingat_km',
            judul: 'Catat Odometer Mingguan',
            isi: `Sudah ${hari} hari sejak pembaruan KM terakhir untuk ${v.merekTipe}. Perbarui angka KM agar estimasi servis tetap akurat.`,
          });
        }
      }
    }
  }

  if (baru.length > 0) await prisma.notification.createMany({ data: baru });
}

// Mencegah sinkronisasi ganda bersamaan untuk pengguna yang sama (agar tidak ada duplikat)
const sedangBerjalan = new Map();
function sinkronkanNotifikasi(userId) {
  if (sedangBerjalan.has(userId)) return sedangBerjalan.get(userId);
  const p = sinkron(userId).finally(() => sedangBerjalan.delete(userId));
  sedangBerjalan.set(userId, p);
  return p;
}

// Dipanggil setelah catatan servis berhasil dibuat
async function notifikasiServisTersimpan(userId, vehicle, record) {
  await prisma.notification.create({
    data: {
      userId,
      vehicleId: vehicle.id,
      tipe: 'servis',
      judul: 'Catatan Servis Berhasil Disimpan',
      isi: `${vehicle.merekTipe}: ${record.jenisServis} pada ${angka(record.odometer)} km di ${record.namaBengkel} (Rp ${angka(record.biaya)}) telah dicatat.`,
    },
  });
}

module.exports = { sinkronkanNotifikasi, notifikasiServisTersimpan };
