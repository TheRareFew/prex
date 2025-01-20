# Main Repository Setup Guide

## Overview
This guide explains how to set up the PREX project using a parent repository with three child repositories as submodules. This structure allows for unified development while maintaining separate deployment pipelines.

## 1. Parent Repository Setup

### Create Parent Repository
1. Create a new repository on GitHub named `prex` with these settings:
   - Repository name: `prex`
   - Description: "Main repository for the PREX project, containing all components"
   - Visibility: Private
   - Initialize with:
     - ✅ Add a README file
     - ✅ Add .gitignore (Python template)
     - ❌ No license file (can be added later)

2. Choose ONE of the following options:

#### Option A: Starting Fresh (New Directory)
```bash
git clone https://github.com/your-org/prex.git
cd prex
```

#### Option B: Existing Project Directory
If you already have a directory called "prex" with project files:
```bash
# Initialize git in current directory
git init

# Add the remote repository
git remote add origin https://github.com/your-org/prex.git

# Create and switch to main branch
git checkout -b main

# Add your files (if not already added and committed)
git add .
git commit -m "feat: initial project setup"

# If the remote has existing files (like README and .gitignore),
# pull them first and merge
git pull origin main --allow-unrelated-histories

# If you get merge conflicts, resolve them in the conflicting files
# (look for <<<<<<< HEAD markers), then:
git add .
git commit -m "chore: resolve merge conflicts"

# Push to main branch
git push -u origin main
```

### Configure Git
Create `.gitignore`:
```
# Dependencies
node_modules/
venv/
__pycache__/
*.pyc

# Environment files
.env
.env.*
!.env.example

# Build outputs
dist/
build/
.next/

# IDE and OS files
.vscode/
.idea/
.DS_Store

# Amplify
aws-exports.js
awsconfiguration.json
amplifyconfiguration.json
amplifyconfiguration.dart
amplify-build-config.json
amplify-gradle-config.json
amplifytools.xcconfig
.secret-*
```

### Initialize README.md
```markdown
# PREX Project

Main repository for the PREX project, containing all components as submodules.

## Components
- [Frontend](frontend/) - React/Amplify frontend application
- [Backend](backend/) - FastAPI backend service
- [Supabase](supabase/) - Database and serverless functions

## Setup
1. Clone this repository with submodules:
   ```bash
   git clone --recursive https://github.com/your-org/prex.git
   ```
2. Follow setup instructions in docs/setup for each component
3. Use docker-compose for local development

## Documentation
See the docs/ directory for detailed setup and architecture documentation.
```

## 2. Child Repositories Setup

### Create Child Repositories
1. Create three repositories on GitHub:
   - `prex-frontend`
   - `prex-backend`
   - `prex-supabase`

### Add Child Repositories as Submodules
```bash
# From the prex directory
git submodule add https://github.com/your-org/prex-frontend.git frontend
git submodule add https://github.com/your-org/prex-backend.git backend
git submodule add https://github.com/your-org/prex-supabase.git supabase

# Initialize and update submodules
git submodule update --init --recursive
```

### Create Documentation Directory
```bash
mkdir -p docs/setup docs/architecture
git add docs
git commit -m "feat: add documentation structure"
git push origin main
```

## 3. Development Workflow

### Initial Checkout
When cloning the repository for the first time:
```bash
# Clone with submodules
git clone --recursive https://github.com/your-org/prex.git

# Or if already cloned without submodules:
git submodule update --init --recursive
```

### Working with Submodules
1. Updating all submodules to their latest versions:
```bash
git submodule update --remote
```

2. Working on a specific component:
```bash
cd frontend  # or backend/supabase
git checkout develop
# Make changes
git add .
git commit -m "feat: description"
git push origin develop
```

3. Updating parent repo to track new submodule versions:
```bash
cd ..  # back to parent repo
git add frontend  # or backend/supabase
git commit -m "chore: update frontend submodule"
git push origin main
```

## 4. Docker Compose Setup

Create `docker-compose.yml` in the root directory:
```yaml
version: '3.8'

services:
  frontend:
    build: ./frontend
    ports:
      - "3000:3000"
    volumes:
      - ./frontend:/app
      - /app/node_modules
    environment:
      - NODE_ENV=development

  backend:
    build: ./backend
    ports:
      - "8000:8000"
    volumes:
      - ./backend:/app
    environment:
      - DEBUG=1

  supabase:
    image: supabase/supabase-local
    ports:
      - "54322:5432"  # Database
      - "54323:8000"  # API
    environment:
      - POSTGRES_PASSWORD=your-local-password

volumes:
  node_modules:
```

## 5. Branch Strategy

### Parent Repository
- `main` - Tracks stable versions of all submodules
- `develop` - Development integration
- `feature/*` - Feature branches that require cross-component changes

### Child Repositories
- `main` - Production
- `develop` - Development/Staging
- `feature/*` - Feature branches
- `release/*` - Release branches
- `hotfix/*` - Hot fix branches

## 6. Next Steps

1. Follow individual setup guides:
   - `frontend_setup.md`
   - `backend_setup.md`
   - `supabase_setup.md`

2. Set up CI/CD:
   - Configure GitHub Actions in each child repository
   - Set up necessary secrets and environment variables
   - Configure parent repository CI/CD for integration testing

3. Configure development environment:
   - Install required tools (Node.js, Python, Docker)
   - Set up local environment variables
   - Initialize development databases

## Common Tasks

### Adding a New Feature Across Components
1. Create feature branches in relevant submodules:
```bash
cd frontend
git checkout -b feature/new-feature
# Make frontend changes

cd ../backend
git checkout -b feature/new-feature
# Make backend changes
```

2. Create a feature branch in parent repo to track submodule changes:
```bash
git checkout -b feature/new-feature
git add frontend backend
git commit -m "feat: implement new feature"
```

### Updating All Components
```bash
# Pull latest changes for parent repo
git pull origin main

# Update all submodules to their latest versions
git submodule update --remote

# Commit submodule updates
git add .
git commit -m "chore: update all submodules"
git push origin main
``` 