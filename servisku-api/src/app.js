require('dotenv').config();
const express = require('express');
const cors = require('cors');
const errorHandler = require('./middleware/error');

const app = express();
app.use(cors());
app.use(express.json());

app.get('/', (req, res) => res.json({ success: true, message: 'ServisKu API berjalan' }));
app.use('/api', require('./routes'));

app.use((req, res) => res.status(404).json({ success: false, message: 'Endpoint tidak ditemukan' }));
app.use(errorHandler);

module.exports = app;
