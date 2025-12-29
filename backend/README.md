# SaveOne Backend API

Backend server for SaveOne Flutter application with PostgreSQL database.

## Setup Instructions

### 1. Install PostgreSQL

Make sure PostgreSQL is installed on your system.

### 2. Create Database

Run the SQL commands in `database.sql` to create the database and tables:

```bash
psql -U postgres -f database.sql
```

Or manually:
```bash
psql -U postgres
```

Then copy and paste the contents of `database.sql`.

### 3. Configure Environment Variables

Create a `.env` file in the backend directory:

```bash
cp .env.example .env
```

Edit `.env` with your PostgreSQL credentials:

```
DB_HOST=localhost
DB_PORT=5432
DB_NAME=saveone_db
DB_USER=postgres
DB_PASSWORD=your_password
PORT=3000
```

### 4. Install Dependencies

```bash
npm install
```

### 5. Start the Server

Development mode (with auto-reload):
```bash
npm run dev
```

Production mode:
```bash
npm start
```

The server will run on `http://localhost:3000`

## API Endpoints

### Authentication

- **POST** `/api/users/signup` - Create new user account
  - Body: `{ name, email, phone_number, password, nominee_number }`
  
- **POST** `/api/users/signin` - Sign in user
  - Body: `{ phone_number, password }`

### Documents

- **GET** `/api/documents/:userId` - Get all documents for a user

- **GET** `/api/documents/:userId/count` - Get document count for a user

- **POST** `/api/documents/upload` - Upload a new document
  - Body: `{ user_id, file_name, file_content, file_size }`

### Health Check

- **GET** `/health` - Check server status

## Database Schema

### users table
- id (SERIAL PRIMARY KEY)
- name (VARCHAR)
- email (VARCHAR UNIQUE)
- phone_number (VARCHAR UNIQUE)
- password (VARCHAR)
- nominee_number (VARCHAR)
- created_at (TIMESTAMP)

### documents table
- id (SERIAL PRIMARY KEY)
- user_id (INTEGER FOREIGN KEY)
- file_name (VARCHAR)
- file_path (TEXT)
- file_size (INTEGER)
- uploaded_at (TIMESTAMP)
