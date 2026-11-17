const { komponenDariJenis } = require('./serviceTypes');

// Jika odometer pada catatan servis lebih besar dari odometer kendaraan, perbarui odometer kendaraan.
async function syncOdometer(tx, vehicle, odometer) {
  if (odometer > vehicle.odometerTerakhir) {
    await tx.vehicle.update({ where: { id: vehicle.id }, data: { odometerTerakhir: odometer } });
    await tx.odometerLog.create({ data: { vehicleId: vehicle.id, km: odometer } });
  }
}

// Hitung ulang titik "servis terakhir" tiap komponen kendaraan dari seluruh catatan servis.
// Dipakai setelah tambah / ubah / hapus catatan, sehingga hasilnya selalu konsisten.
// Jika suatu komponen belum pernah diservis, kembali ke titik awal saat kendaraan didaftarkan.
async function recomputeComponents(tx, vehicleId) {
  const vehicle = await tx.vehicle.findUnique({ where: { id: vehicleId } });
  const firstLog = await tx.odometerLog.findFirst({
    where: { vehicleId },
    orderBy: { dicatatPada: 'asc' },
  });
  const baseKm = firstLog ? firstLog.km : 0;
  const baseDate = vehicle.createdAt;

  const records = await tx.serviceRecord.findMany({
    where: { vehicleId },
    orderBy: [{ tanggal: 'desc' }, { odometer: 'desc' }],
  });
  const comps = await tx.vehicleComponent.findMany({
    where: { vehicleId },
    include: { component: true },
  });

  for (const vc of comps) {
    const rec = records.find((r) => komponenDariJenis(r.jenisServis).includes(vc.component.nama));
    await tx.vehicleComponent.update({
      where: { id: vc.id },
      data: rec
        ? { lastServiceKm: rec.odometer, lastServiceDate: rec.tanggal }
        : { lastServiceKm: baseKm, lastServiceDate: baseDate },
    });
  }
}

module.exports = { syncOdometer, recomputeComponents };
