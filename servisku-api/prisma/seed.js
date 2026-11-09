// Data master interval servis (dipakai algoritma pengingat)
require('dotenv').config();
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

const data = [
  { nama: 'Oli Mesin', intervalKm: 2000, intervalBulan: 2, jenisKendaraan: 'motor' },
  { nama: 'Oli Gardan', intervalKm: 8000, intervalBulan: 6, jenisKendaraan: 'motor' },
  { nama: 'Kampas Rem', intervalKm: 10000, intervalBulan: 12, jenisKendaraan: 'motor' },
  { nama: 'Filter Udara', intervalKm: 8000, intervalBulan: 6, jenisKendaraan: 'motor' },
  { nama: 'Busi', intervalKm: 8000, intervalBulan: 12, jenisKendaraan: 'motor' },
  { nama: 'CVT / V-Belt', intervalKm: 24000, intervalBulan: 24, jenisKendaraan: 'motor' },
  { nama: 'Oli Mesin', intervalKm: 5000, intervalBulan: 6, jenisKendaraan: 'mobil' },
  { nama: 'Kampas Rem', intervalKm: 20000, intervalBulan: 12, jenisKendaraan: 'mobil' },
  { nama: 'Filter Udara', intervalKm: 20000, intervalBulan: 12, jenisKendaraan: 'mobil' },
  { nama: 'Busi', intervalKm: 20000, intervalBulan: 24, jenisKendaraan: 'mobil' },
  { nama: 'Ban', intervalKm: 40000, intervalBulan: 36, jenisKendaraan: 'mobil' },
  { nama: 'Aki', intervalKm: 40000, intervalBulan: 24, jenisKendaraan: 'mobil' },
];

async function main() {
  for (const d of data) {
    await prisma.serviceComponent.upsert({
      where: { nama_jenisKendaraan: { nama: d.nama, jenisKendaraan: d.jenisKendaraan } },
      update: d,
      create: d,
    });
  }
  console.log(`Seed selesai: ${data.length} komponen`);
}

main().catch(console.error).finally(() => prisma.$disconnect());
