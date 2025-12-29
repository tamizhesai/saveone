const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'saveone_db',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD,
});

pool.on('connect', () => {
  console.log('Connected to PostgreSQL database');
});

pool.on('error', (err) => {
  console.error('Unexpected error on idle client', err);
  process.exit(-1);
});

app.post('/api/users/signup', async (req, res) => {
  const { name, email, phone_number, password, nominee_number } = req.body;

  try {
    const existingUser = await pool.query(
      'SELECT * FROM users WHERE email = $1 OR phone_number = $2',
      [email, phone_number]
    );

    if (existingUser.rows.length > 0) {
      return res.status(400).json({ error: 'User already exists' });
    }

    const result = await pool.query(
      'INSERT INTO users (name, email, phone_number, password, nominee_number) VALUES ($1, $2, $3, $4, $5) RETURNING id',
      [name, email, phone_number, password, nominee_number]
    );

    res.status(201).json({ id: result.rows[0].id });
  } catch (error) {
    console.error('Signup error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.post('/api/users/signin', async (req, res) => {
  const { phone_number, password } = req.body;

  try {
    const result = await pool.query(
      'SELECT id, name, email, phone_number, nominee_number FROM users WHERE phone_number = $1 AND password = $2',
      [phone_number, password]
    );

    if (result.rows.length === 0) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    res.status(200).json(result.rows[0]);
  } catch (error) {
    console.error('Signin error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.get('/api/documents/:userId', async (req, res) => {
  const { userId } = req.params;

  try {
    const result = await pool.query(
      'SELECT id, user_id, file_name, file_path, file_size, uploaded_at FROM documents WHERE user_id = $1 ORDER BY uploaded_at DESC',
      [userId]
    );

    res.status(200).json(result.rows);
  } catch (error) {
    console.error('Get documents error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.get('/api/documents/:userId/count', async (req, res) => {
  const { userId } = req.params;

  try {
    const result = await pool.query(
      'SELECT COUNT(*) as count FROM documents WHERE user_id = $1',
      [userId]
    );

    res.status(200).json({ count: parseInt(result.rows[0].count) });
  } catch (error) {
    console.error('Get document count error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.post('/api/documents/upload', async (req, res) => {
  const { user_id, file_name, file_content, file_size } = req.body;

  try {
    const result = await pool.query(
      'INSERT INTO documents (user_id, file_name, file_path, file_size) VALUES ($1, $2, $3, $4) RETURNING id',
      [user_id, file_name, file_content, file_size]
    );

    res.status(201).json({ id: result.rows[0].id });
  } catch (error) {
    console.error('Upload document error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'OK' });
});

app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
