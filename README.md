# PREX Development Repository

This is the development monorepo for the PREX project. It contains all components for local development.

## Project Structure

```
prex/
├── frontend/                 # React/Amplify frontend
├── backend/                  # FastAPI backend
├── supabase/                # Supabase functions and migrations
├── docs/                    # Shared documentation
├── docker-compose.yml       # Local development setup
└── README.md
```

## Prerequisites

### For Local Setup (Minimal Resources)
- Node.js 16+ (Frontend)
- Python 3.9+ (Backend)
- PostgreSQL 14+ (Database)
- Supabase CLI (Optional, for functions)

### For Docker Setup (More Resources)
- Docker and Docker Compose (~2GB RAM minimum)

## Development Options

### Option 1: Fully Local Setup (Minimal Resources)

1. Start PostgreSQL database locally
2. Start backend:
```bash
cd backend
python -m venv venv
source venv/bin/activate  # On Windows: .\venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

3. Start frontend:
```bash
cd frontend
npm install
npm start
```

### Option 2: Docker Setup (More Resources)
Good for team development where environment consistency is important.

1. Start all services:
```bash
docker-compose up backend supabase
```

2. Start frontend locally:
```bash
cd frontend
npm install
npm start
```

## Getting Started

1. Clone this repository and its components:
```bash
# Clone main repo
git clone https://github.com/your-org/prex.git
cd prex

# Clone component repos
git clone https://github.com/your-org/prex-frontend.git frontend
git clone https://github.com/your-org/prex-backend.git backend
git clone https://github.com/your-org/prex-supabase.git supabase
```

2. Set up environment variables:
```bash
# Copy example env file
cp .env.example .env

# Edit .env with your values
nano .env
```

## Component Access

- Frontend: http://localhost:3000
- Backend API: http://localhost:8000
- Database: localhost:5432 (if running locally)
- Supabase Studio: http://localhost:54322 (if using Docker)

## Development Workflow

### Local Development (Minimal Resources)
1. Start backend:
```bash
cd backend
source venv/bin/activate  # On Windows: .\venv\Scripts\activate
uvicorn app.main:app --reload
```

2. Start frontend:
```bash
cd frontend
npm start
```

3. Run tests:
```bash
# Frontend tests
cd frontend
npm test

# Backend tests
cd backend
pytest
```

### Docker Development (More Resources)
Use this when you need the full Supabase setup or team consistency is important.

1. Start services:
```bash
docker-compose up backend supabase
```

2. Run frontend locally:
```bash
cd frontend
npm start
```

### Deployment

When ready to deploy:

1. Frontend (Amplify):
```bash
cd frontend
amplify push
git push origin main
```

2. Backend:
```bash
cd backend
git add .
git commit -m "Add new feature"
git push origin main
```

## Troubleshooting

1. If local backend fails:
```bash
# Check if Python environment is activated
source venv/bin/activate  # On Windows: .\venv\Scripts\activate

# Reinstall dependencies
pip install -r requirements.txt
```

2. If frontend development server isn't working:
```bash
# Clear node_modules and reinstall
cd frontend
rm -rf node_modules
npm install
```

3. If using Docker and containers fail:
```bash
# Remove all containers and volumes
docker-compose down -v

# Rebuild from scratch
docker-compose up --build
```

## Documentation

See the `docs/` directory for:
- Setup guides
- Architecture documentation
- Development guidelines
- Deployment procedures 