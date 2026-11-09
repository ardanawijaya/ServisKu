require('dotenv').config();
const app = require('./src/app');

if (!process.env.JWT_SECRET) {
  console.error('JWT_SECRET belum diisi di file .env');
  process.exit(1);
}

const PORT = process.env.PORT || 3000;
// 0.0.0.0 agar bisa diakses dari HP asli lewat IP laptop
app.listen(PORT, '0.0.0.0', () => console.log(`ServisKu API jalan di http://localhost:${PORT}`));
