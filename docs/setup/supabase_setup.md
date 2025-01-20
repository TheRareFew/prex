# Supabase Repository Setup Guide

## Repository Setup

### 1. Create GitHub Repository
1. Go to GitHub and create a new repository named `prex-supabase`
2. Initialize with a README

### 2. Local Setup
```bash
# Clone the repository
git clone https://github.com/your-org/prex-supabase.git
cd prex-supabase

# Install Supabase CLI (using your preferred package manager)
# For Windows:
scoop bucket add supabase https://github.com/supabase/scoop-bucket.git
scoop install supabase

# Initialize Supabase project
supabase init
```

## Project Structure
Your repository will have this structure after initialization:
```
prex-supabase/
├── supabase/
│   ├── config.toml          # Project configuration
│   ├── seed.sql            # Seed data
│   └── migrations/         # Database migrations
│       └── 20240101000000_init.sql
└── README.md
```

## Supabase Project Setup

### 1. Create Supabase Project
1. Go to [supabase.com](https://supabase.com)
2. Click "New Project"
3. Fill in project details
4. Save the following from your project settings:
   - Project URL
   - Project API Keys (anon and service_role)
   - Project Reference ID

### 2. Link Project
```bash
supabase link --project-ref your-project-ref
```

### 3. Initialize Database

Create `supabase/migrations/20240101000000_init.sql`:
```sql
-- Enable necessary extensions
create extension if not exists "uuid-ossp";

-- Create test table
CREATE TABLE test_table (
  id uuid default uuid_generate_v4() primary key,
  value TEXT NOT NULL,
  created_at timestamptz default now()
);

-- Add sample data
INSERT INTO test_table (value) VALUES ('test value');

-- Set up row level security
ALTER TABLE test_table ENABLE ROW LEVEL SECURITY;

-- Create policies for public read access
CREATE POLICY "Public profiles are viewable by everyone"
ON test_table FOR SELECT
USING ( true );

-- Create policies for authenticated users
CREATE POLICY "Authenticated users can insert their own data"
ON test_table FOR INSERT
TO authenticated
WITH CHECK ( true );

CREATE POLICY "Authenticated users can update their own data"
ON test_table FOR UPDATE
TO authenticated
USING ( true );
```

## Environment Management

### 1. Local Development
Create `.env` file (do not commit):
```
SUPABASE_URL=your_project_url
SUPABASE_ANON_KEY=your_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
```

### 2. Production Setup
1. Add secrets in Supabase Dashboard:
   - Go to Project Settings > API
   - Note down the API keys for frontend use

### 3. GitHub Secrets
Add to repository secrets:
- `SUPABASE_ACCESS_TOKEN`
- `SUPABASE_PROJECT_ID`

## Deployment

### 1. GitHub Actions Configuration

Create `.github/workflows/deploy.yml`:
```yaml
name: Deploy Supabase

on:
  push:
    branches: [ main ]
    paths:
      - 'supabase/**'

jobs:
  deploy:
    runs-on: ubuntu-latest

    env:
      SUPABASE_ACCESS_TOKEN: ${{ secrets.SUPABASE_ACCESS_TOKEN }}
      PROJECT_ID: ${{ secrets.SUPABASE_PROJECT_ID }}

    steps:
      - uses: actions/checkout@v3
      
      - uses: supabase/setup-cli@v1
        with:
          version: latest
          
      - name: Deploy Migrations
        run: |
          supabase link --project-ref $PROJECT_ID
          supabase db push
```

## Development Workflow

### 1. Local Development
```bash
# Start Supabase locally
supabase start

# Create a new migration
supabase migration new my_migration_name

# Apply migrations
supabase db reset
```

### 2. Testing
```bash
# Test database connection
supabase db test

# Verify migrations
supabase db lint
```

### 3. Branching and Deployment
1. Create feature branch:
```bash
git checkout -b feature/new-feature
```

2. Test changes locally
3. Create PR and merge to main
4. GitHub Actions will automatically deploy

## Real-time Features

### 1. Enable Real-time
In the Supabase dashboard:
1. Go to Database > Replication
2. Enable real-time for specific tables
3. Configure publication to include the tables you want to track

### 2. Table Configuration
Example of enabling real-time for a table:
```sql
-- Enable real-time for test_table
alter publication supabase_realtime add table test_table;

-- Configure real-time for specific operations
comment on table test_table is '{"realtime": true, "realtime_opts": {"insert": true, "update": true, "delete": true}}';
```

## Monitoring

1. Database monitoring:
   - SQL Editor for queries
   - Database > Replication for real-time logs
   - API Statistics for usage metrics

2. Performance:
   - Database > Performance
   - Real-time latency metrics
   - Query performance analysis
