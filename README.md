# SaveOne - Document Management App

A Flutter application with authentication and document management features, backed by PostgreSQL database.

## Features

### Authentication
- **Sign Up**: Create account with name, email, phone number, password, and nominee number
- **Sign In**: Login using phone number and password
- **Persistent Login**: Uses SharedPreferences to maintain login state
- **Logout**: Secure logout functionality

### Main Features
- **Home Page**: Dashboard showing total document count
- **Documents Page**: 
  - View all uploaded documents
  - Upload new documents using file picker
  - **Hybrid Storage**: Files stored in Firebase Storage, metadata in PostgreSQL
  - Display file information (name, size, upload date)
- **Profile Page**: 
  - View user details (name, email, phone, nominee number)
  - Logout button

### Hybrid Storage Architecture
- **Firebase Storage**: Stores actual document files with secure URLs
- **PostgreSQL**: Stores user data and document metadata (pointers to Firebase Storage)
- **Benefits**: Scalable file storage, fast metadata queries, secure access control

### UI/UX
- Clean and modern design
- Custom theme with colors:
  - Primary: #07A996
  - Background: #E7F2F1
  - Text Dark: #5B5B5B
  - Text Black: #040707
- Bottom navigation bar with 3 tabs (Home, Docs, Profile)

## Project Structure

```
lib/
├── config/
│   └── theme.dart              # App theme configuration
├── models/
│   ├── user_model.dart         # User data model
│   └── document_model.dart     # Document data model
├── services/
│   ├── auth_service.dart       # Authentication service
│   └── database_service.dart   # API communication service
├── screens/
│   ├── signup_page.dart        # Sign up screen
│   ├── signin_page.dart        # Sign in screen
│   ├── home_page.dart          # Home dashboard
│   ├── docs_page.dart          # Documents list and upload
│   ├── profile_page.dart       # User profile
│   └── main_navigation.dart    # Bottom navigation
└── main.dart                   # App entry point

backend/
├── server.js                   # Express server
├── database.sql                # Database schema
├── package.json                # Node dependencies
├── .env.example                # Environment variables template
└── README.md                   # Backend documentation
```

## Setup Instructions

### Prerequisites
- Flutter SDK (3.9.2 or higher)
- PostgreSQL database
- Node.js and npm

### 1. Firebase Setup

Configure Firebase for your project:
```bash
firebase login
dart pub global activate flutterfire_cli
flutterfire configure --project=your-project-id
```

Enable Firebase Storage in your Firebase Console:
- Go to Firebase Console > Storage
- Click "Get Started"
- Set up security rules (for testing, allow authenticated users)

### 2. Backend Setup

Navigate to the backend directory:
```bash
cd backend
```

Install dependencies:
```bash
npm install
```

Create `.env` file:
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

Create database and tables:
```bash
psql -U postgres -f database.sql
```

If migrating from old schema, run:
```bash
psql -U postgres -d saveone_db -f migrate_to_firebase.sql
```

Start the server:
```bash
npm start
```

Or for development with auto-reload:
```bash
npm run dev
```

### 3. Flutter App Setup

Install Flutter dependencies:
```bash
flutter pub get
```

Run the app:
```bash
flutter run
```

## Dependencies

### Flutter
- `http: ^1.1.0` - HTTP requests
- `shared_preferences: ^2.2.2` - Local storage
- `file_picker: ^8.1.4` - File selection
- `postgres: ^2.6.2` - PostgreSQL client
- `crypto: ^3.0.3` - Password hashing
- `firebase_core: ^3.8.1` - Firebase initialization
- `firebase_storage: ^12.3.8` - Firebase Storage for file uploads

### Backend
- `express: ^4.18.2` - Web framework
- `pg: ^8.11.3` - PostgreSQL client
- `cors: ^2.8.5` - CORS middleware
- `dotenv: ^16.3.1` - Environment variables

## API Endpoints

### Authentication
- `POST /api/users/signup` - Create new user
- `POST /api/users/signin` - Authenticate user

### Documents
- `GET /api/documents/:userId` - Get user documents
- `GET /api/documents/:userId/count` - Get document count
- `POST /api/documents/upload` - Upload document

### Health
- `GET /health` - Server health check

## Database Schema

### users
- id (SERIAL PRIMARY KEY)
- name (VARCHAR)
- email (VARCHAR UNIQUE)
- phone_number (VARCHAR UNIQUE)
- password (VARCHAR)
- nominee_number (VARCHAR)
- created_at (TIMESTAMP)

### documents
- id (SERIAL PRIMARY KEY)
- user_id (INTEGER FOREIGN KEY)
- file_name (VARCHAR)
- firebase_url (TEXT) - Download URL from Firebase Storage
- firebase_path (TEXT) - Storage path in Firebase
- file_size (INTEGER)
- file_type (VARCHAR) - MIME type
- uploaded_at (TIMESTAMP)

## Security Notes

- Passwords are hashed using SHA-256
- Phone numbers are unique identifiers
- Nominee number stored for emergency access
- CORS enabled for API access

## Future Enhancements

- Implement JWT authentication
- Add file download functionality
- Implement biometric authentication
- Add document categories/tags
- Enable document sharing
- Add search functionality
