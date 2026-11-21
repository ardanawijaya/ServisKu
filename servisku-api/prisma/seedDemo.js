/**
 * Data demo untuk pengujian & video presentasi.
 * Jalankan dari folder servisku-api:   node prisma/seedDemo.js
 * Aman dijalankan berulang kali (tidak membuat data ganda).
 *
 * Akun yang dibuat (kata sandi semuanya: Demo12345!)
 *   Pengguna : budi@demo.com
 *   Bengkel  : makmur@demo.com, autocare@demo.com, sahabat@demo.com
 */
require('dotenv').config();
const bcrypt = require('bcrypt');
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

const PASSWORD = 'Demo12345!';

const LAYANAN_MOTOR = [
  { kategori: 'Oli & Pelumas', nama: 'Ganti Oli Mesin & Filter', deskripsi: 'Termasuk cek 10 titik standar', durasiMenit: 30, hargaMin: 65000, hargaMax: 150000 },
  { kategori: 'Oli & Pelumas', nama: 'Ganti Oli Gardan', deskripsi: 'Untuk skuter matic', durasiMenit: 20, hargaMin: 25000, hargaMax: 45000 },
  { kategori: 'Transmisi', nama: 'Servis CVT & Pembersihan', deskripsi: 'Pembersihan pulley, roller & v-belt', durasiMenit: 45, hargaMin: 85000, hargaMax: 120000 },
  { kategori: 'Pengereman', nama: 'Ganti Kampas Rem Depan / Belakang', deskripsi: 'Pembersihan kaliper & minyak rem', durasiMenit: 30, hargaMin: 45000, hargaMax: 95000 },
  { kategori: 'Perawatan Berkala', nama: 'Tune Up & Gurah Mesin Injeksi', deskripsi: 'Reset ECU, pembersihan injector & busi', durasiMenit: 60, hargaMin: 150000, hargaMax: 250000 },
  { kategori: 'Mesin', nama: 'Ganti Busi', deskripsi: 'Busi standar atau iridium', durasiMenit: 15, hargaMin: 20000, hargaMax: 120000 },
];

const LAYANAN_MOBIL = [
  { kategori: 'Oli & Pelumas', nama: 'Ganti Oli Mesin & Filter Oli', deskripsi: 'Oli sintetik atau semi sintetik', durasiMenit: 45, hargaMin: 350000, hargaMax: 750000 },
  { kategori: 'Pengereman', nama: 'Ganti Kampas Rem Depan', deskripsi: 'Termasuk cek cakram', durasiMenit: 60, hargaMin: 250000, hargaMax: 500000 },
  { kategori: 'Ban & Spooring', nama: 'Spooring & Balancing', deskripsi: 'Komputerisasi 4 roda', durasiMenit: 90, hargaMin: 200000, hargaMax: 350000 },
  { kategori: 'Kelistrikan', nama: 'Ganti Aki', deskripsi: 'Termasuk cek sistem pengisian', durasiMenit: 30, hargaMin: 650000, hargaMax: 1500000 },
  { kategori: 'Perawatan Berkala', nama: 'Tune Up Mobil', deskripsi: 'Busi, filter udara, dan setel mesin', durasiMenit: 120, hargaMin: 400000, hargaMax: 900000 },
];

const BENGKEL = [
  {
    email: 'makmur@demo.com', noHp: '6281200000001', pemilik: 'Pak Makmur',
    nama: 'Bengkel Makmur Jaya', spesialis: 'Spesialis Mobil & Motor', kota: 'Surabaya',
    alamat: 'Jl. Ketintang No. 123, Gayungan', jamBuka: '08:00', jamTutup: '17:00',
    hari: 'Senin - Sabtu', kuota: 12, layanan: [...LAYANAN_MOTOR, ...LAYANAN_MOBIL.slice(0, 2)],
  },
  {
    email: 'autocare@demo.com', noHp: '6281200000002', pemilik: 'Bu Sari',
    nama: 'AutoCare Presisi Nusantara', spesialis: 'Spesialis Injeksi, Rem & Kaki-kaki', kota: 'Surabaya',
    alamat: 'Jl. Ahmad Yani No. 88, Wonokromo', jamBuka: '09:00', jamTutup: '18:00',
    hari: 'Senin - Sabtu', kuota: 10, layanan: LAYANAN_MOBIL,
  },
  {
    email: 'sahabat@demo.com', noHp: '6281200000003', pemilik: 'Pak Anto',
    nama: 'Garasi Motor Sahabat', spesialis: 'Motor Matic & Bebek', kota: 'Sidoarjo',
    alamat: 'Jl. Jemursari Raya No. 45', jamBuka: '08:00', jamTutup: '16:00',
    hari: 'Setiap Hari', kuota: 8, layanan: LAYANAN_MOTOR.slice(0, 4),
  },
];

async function main() {
  const passwordHash = await bcrypt.hash(PASSWORD, 10);

  // Pengguna demo
  await prisma.user.upsert({
    where: { email: 'budi@demo.com' },
    update: {},
    create: { role: 'pengguna', nama: 'Budi Santoso', email: 'budi@demo.com', noHp: '6281200000010', passwordHash },
  });
  console.log('Pengguna : budi@demo.com');

  for (const b of BENGKEL) {
    const user = await prisma.user.upsert({
      where: { email: b.email },
      update: {},
      create: { role: 'bengkel', nama: b.pemilik, email: b.email, noHp: b.noHp, passwordHash },
    });
    const workshop = await prisma.workshop.upsert({
      where: { userId: user.id },
      update: {},
      create: {
        userId: user.id, nama: b.nama, spesialis: b.spesialis, kota: b.kota, alamat: b.alamat,
        noWhatsapp: b.noHp, jamBuka: b.jamBuka, jamTutup: b.jamTutup, hariOperasional: b.hari, kuotaHarian: b.kuota,
      },
    });
    const jumlah = await prisma.workshopService.count({ where: { workshopId: workshop.id } });
    if (jumlah === 0) {
      await prisma.workshopService.createMany({
        data: b.layanan.map((l) => ({ ...l, workshopId: workshop.id, isActive: true })),
      });
    }
    console.log(`Bengkel  : ${b.email} (${b.nama})`);
  }

  console.log(`\nSelesai. Kata sandi semua akun demo: ${PASSWORD}`);
}

main()
  .catch((e) => {
    console.error('Gagal membuat data demo:', e.message);
    process.exitCode = 1;
  })
  .finally(() => prisma.$disconnect());
