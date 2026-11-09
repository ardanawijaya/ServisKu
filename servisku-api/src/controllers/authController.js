const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { z } = require('zod');
const prisma = require('../config/db');
const { normalizePhone, formatUser } = require('../utils/helpers');

const registerSchema = z.object({
  role: z.enum(['pengguna', 'bengkel']),
  nama: z.string().trim().min(2, 'Nama minimal 2 karakter').max(100),
  email: z.string().trim().toLowerCase().email('Format email tidak valid'),
  noHp: z.string().min(9, 'Nomor HP tidak valid').max(20),
  password: z.string().min(8, 'Kata sandi minimal 8 karakter'),
  konfirmasiPassword: z.string(),
  // khusus bengkel (opsional, dilengkapi nanti di profil bengkel)
  namaBengkel: z.string().trim().min(2).max(150).optional(),
  kota: z.string().trim().max(100).optional(),
}).refine((d) => d.password === d.konfirmasiPassword, {
  message: 'Konfirmasi kata sandi tidak sama',
  path: ['konfirmasiPassword'],
});

const loginSchema = z.object({
  identifier: z.string().trim().min(1, 'Email atau nomor ponsel wajib diisi'),
  password: z.string().min(1, 'Kata sandi wajib diisi'),
});

const profileSchema = z.object({
  nama: z.string().trim().min(2).max(100).optional(),
  email: z.string().trim().toLowerCase().email().optional(),
  noHp: z.string().min(9).max(20).optional(),
});

const passwordSchema = z.object({
  passwordLama: z.string().min(1),
  passwordBaru: z.string().min(8, 'Kata sandi baru minimal 8 karakter'),
});

function signToken(user) {
  return jwt.sign({ id: user.id, role: user.role }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || '7d',
  });
}

exports.register = async (req, res, next) => {
  try {
    const data = registerSchema.parse(req.body);
    const noHp = normalizePhone(data.noHp);

    const exists = await prisma.user.findFirst({
      where: { OR: [{ email: data.email }, { noHp }] },
    });
    if (exists) {
      const field = exists.email === data.email ? 'Email' : 'Nomor HP';
      return res.status(409).json({ success: false, message: `${field} sudah terdaftar` });
    }

    const passwordHash = await bcrypt.hash(data.password, 10);

    const user = await prisma.$transaction(async (tx) => {
      const created = await tx.user.create({
        data: { role: data.role, nama: data.nama, email: data.email, noHp, passwordHash },
      });
      // Akun bengkel otomatis dibuatkan profil bengkel awal
      if (data.role === 'bengkel') {
        await tx.workshop.create({
          data: {
            userId: created.id,
            nama: data.namaBengkel || data.nama,
            kota: data.kota || null,
            noWhatsapp: noHp,
          },
        });
      }
      return created;
    });

    res.status(201).json({
      success: true,
      message: 'Registrasi berhasil',
      data: { token: signToken(user), user: formatUser(user) },
    });
  } catch (err) {
    next(err);
  }
};

exports.login = async (req, res, next) => {
  try {
    const { identifier, password } = loginSchema.parse(req.body);
    const isEmail = identifier.includes('@');

    const user = await prisma.user.findFirst({
      where: isEmail
        ? { email: identifier.toLowerCase() }
        : { noHp: normalizePhone(identifier) },
    });

    // Pesan sengaja sama agar tidak membocorkan akun mana yang terdaftar
    const invalid = { success: false, message: 'Email/nomor ponsel atau kata sandi salah' };
    if (!user) return res.status(401).json(invalid);
    const ok = await bcrypt.compare(password, user.passwordHash);
    if (!ok) return res.status(401).json(invalid);

    res.json({
      success: true,
      message: 'Login berhasil',
      data: { token: signToken(user), user: formatUser(user) },
    });
  } catch (err) {
    next(err);
  }
};

exports.me = async (req, res) => {
  res.json({ success: true, data: { user: formatUser(req.user) } });
};

exports.updateProfile = async (req, res, next) => {
  try {
    const body = profileSchema.parse(req.body);
    const data = {};
    if (body.nama) data.nama = body.nama;
    if (body.email) data.email = body.email;
    if (body.noHp) data.noHp = normalizePhone(body.noHp);

    const conditions = [
      ...(data.email ? [{ email: data.email }] : []),
      ...(data.noHp ? [{ noHp: data.noHp }] : []),
    ];
    if (conditions.length) {
      const dup = await prisma.user.findFirst({
        where: { id: { not: req.user.id }, OR: conditions },
      });
      if (dup) {
        return res.status(409).json({ success: false, message: 'Email atau nomor HP sudah dipakai akun lain' });
      }
    }

    const user = await prisma.user.update({ where: { id: req.user.id }, data });
    res.json({ success: true, message: 'Profil diperbarui', data: { user: formatUser(user) } });
  } catch (err) {
    next(err);
  }
};

exports.changePassword = async (req, res, next) => {
  try {
    const { passwordLama, passwordBaru } = passwordSchema.parse(req.body);
    const ok = await bcrypt.compare(passwordLama, req.user.passwordHash);
    if (!ok) return res.status(400).json({ success: false, message: 'Kata sandi lama salah' });

    const passwordHash = await bcrypt.hash(passwordBaru, 10);
    await prisma.user.update({ where: { id: req.user.id }, data: { passwordHash } });
    res.json({ success: true, message: 'Kata sandi berhasil diubah' });
  } catch (err) {
    next(err);
  }
};
