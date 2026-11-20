const prisma = require('../config/db');
const { hariIni, hitungKendaraan } = require('./reminder');

/**
 * Hitung pengingat untuk banyak kendaraan sekaligus (2 query saja).
 * Mengembalikan objek { [vehicleId]: pengingat | null }.
 * Status tidak disimpan di database: dihitung setiap kali diminta,
 * sehingga selalu akurat setelah odometer atau catatan servis berubah.
 */
async function pengingatUntukKendaraan(vehicles) {
  const hasil = {};
  if (!vehicles.length) return hasil;

  const ids = vehicles.map((v) => v.id);
  const [vcs, logs] = await Promise.all([
    prisma.vehicleComponent.findMany({
      where: { vehicleId: { in: ids } },
      include: { component: true },
    }),
    prisma.odometerLog.findMany({
      where: { vehicleId: { in: ids } },
      orderBy: { dicatatPada: 'asc' },
    }),
  ]);

  const today = hariIni();
  for (const v of vehicles) {
    const items = vcs
      .filter((x) => x.vehicleId === v.id)
      .map((x) => ({ komponen: x.component, vc: x }));
    const vLogs = logs.filter((l) => l.vehicleId === v.id);
    hasil[v.id] = hitungKendaraan(v.odometerTerakhir, items, vLogs, today);
  }
  return hasil;
}

module.exports = { pengingatUntukKendaraan };
