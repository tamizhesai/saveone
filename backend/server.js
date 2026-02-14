const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

let latestFingerprintScan = {
  fingerprintId: null,
  timestamp: null,
  type: null
};

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
      'SELECT id, name, email, phone_number, nominee_number, profile_picture_url FROM users WHERE phone_number = $1 AND password = $2',
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
      'SELECT id, user_id, file_name, firebase_url, firebase_path, file_size, file_type, uploaded_at FROM documents WHERE user_id = $1 ORDER BY uploaded_at DESC',
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
  const { user_id, file_name, firebase_url, firebase_path, file_size, file_type } = req.body;

  try {
    const result = await pool.query(
      'INSERT INTO documents (user_id, file_name, firebase_url, firebase_path, file_size, file_type) VALUES ($1, $2, $3, $4, $5, $6) RETURNING id',
      [user_id, file_name, firebase_url, firebase_path, file_size, file_type]
    );

    res.status(201).json({ id: result.rows[0].id });
  } catch (error) {
    console.error('Upload document error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.delete('/api/documents/:id', async (req, res) => {
  const { id } = req.params;

  try {
    const result = await pool.query(
      'DELETE FROM documents WHERE id = $1 RETURNING id',
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Document not found' });
    }

    res.status(200).json({ message: 'Document deleted' });
  } catch (error) {
    console.error('Delete document error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.put('/api/users/:id/profile-picture', async (req, res) => {
  const { id } = req.params;
  const { profile_picture_url } = req.body;

  try {
    const result = await pool.query(
      'UPDATE users SET profile_picture_url = $1 WHERE id = $2 RETURNING id',
      [profile_picture_url, id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.status(200).json({ message: 'Profile picture updated' });
  } catch (error) {
    console.error('Update profile picture error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.post('/api/fingerprint/check', async (req, res) => {
  const { fingerprint_id } = req.body;

  try {
    const result = await pool.query(
      'SELECT id, name, email, phone_number, nominee_number, profile_picture_url FROM users WHERE fingerprint_id = $1',
      [fingerprint_id]
    );

    if (result.rows.length > 0) {
      res.status(200).json({ exists: true, user: result.rows[0] });
    } else {
      res.status(200).json({ exists: false });
    }
  } catch (error) {
    console.error('Fingerprint check error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.post('/api/fingerprint/register', async (req, res) => {
  const { fingerprint_id, name, email, phone_number, password, nominee_number } = req.body;

  try {
    const existingUser = await pool.query(
      'SELECT * FROM users WHERE email = $1 OR phone_number = $2 OR fingerprint_id = $3',
      [email, phone_number, fingerprint_id]
    );

    if (existingUser.rows.length > 0) {
      return res.status(400).json({ error: 'User already exists' });
    }

    const result = await pool.query(
      'INSERT INTO users (name, email, phone_number, password, nominee_number, fingerprint_id) VALUES ($1, $2, $3, $4, $5, $6) RETURNING id',
      [name, email, phone_number, password, nominee_number, fingerprint_id]
    );

    res.status(201).json({ id: result.rows[0].id, message: 'User registered with fingerprint' });
  } catch (error) {
    console.error('Fingerprint register error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.post('/api/fingerprint/scan', async (req, res) => {
  const { fingerprint_id, type } = req.body;

  latestFingerprintScan = {
    fingerprintId: fingerprint_id,
    timestamp: Date.now(),
    type: type || 'unknown'
  };

  console.log(`Fingerprint scan received: ID=${fingerprint_id}, Type=${type}`);
  res.status(200).json({ message: 'Scan received', fingerprintId: fingerprint_id });
});

app.get('/api/fingerprint/latest', async (req, res) => {
  if (latestFingerprintScan.fingerprintId === null) {
    return res.status(404).json({ message: 'No fingerprint scan available' });
  }

  const age = Date.now() - latestFingerprintScan.timestamp;
  if (age > 60000) {
    return res.status(404).json({ message: 'Scan expired (older than 60 seconds)' });
  }

  res.status(200).json(latestFingerprintScan);
});

app.delete('/api/fingerprint/latest', async (req, res) => {
  latestFingerprintScan = {
    fingerprintId: null,
    timestamp: null,
    type: null
  };
  res.status(200).json({ message: 'Scan cleared' });
});

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'OK' });
});

app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
