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

# Start local development instance
supabase start
```

### 3. Development vs Production Setup

The project uses two environments:
1. Local Development (`localhost:54323`)
   - Used for development and testing
   - Configured through local `config.toml`
   - Can be reset and modified freely

2. Production (Supabase Cloud)
   - Hosted on Supabase platform
   - Configured through Supabase Dashboard
   - Changes should be carefully managed

#### Configuration Management
Store separate config files:
```
supabase/
├── config.toml           # Local development config (version controlled)
├── config.dev.toml      # Backup of development config (not version controlled)
└── config.prod.toml      # Production config (not version controlled)
```

Add these entries to your `.gitignore`:
```
# Supabase config files
config.prod.toml
config.dev.toml
```

> **Important Security Note**: 
> 1. Only commit `config.toml` with development settings
> 2. Never commit `config.prod.toml` or `config.dev.toml`
> 3. Store production configuration securely outside version control
> 4. Use environment variables for all sensitive values

#### Local Development Workflow
```bash
# Start local Supabase instance (uses config.toml)
supabase start

# Make changes to local config.toml as needed
# Example: Disable email confirmations for faster development
# in supabase/config.toml:
# [auth.email]
# enable_confirmations = false
# max_frequency = "1s"

# Test changes locally
supabase db reset
```

#### Production Workflow
```bash
# First time setup: Save current production config
supabase db remote commit --config-file=./supabase/config.prod.toml

# When deploying changes:
# 1. Backup your development config
cp ./supabase/config.toml ./supabase/config.dev.toml

# 2. Replace with production config (Supabase CLI only works with config.toml)
cp ./supabase/config.prod.toml ./supabase/config.toml

# 3. Deploy changes
supabase db push

# 4. Restore development config
cp ./supabase/config.dev.toml ./supabase/config.toml
```

> **Important Note**: The Supabase CLI only recognizes `config.toml` as the configuration file. While you can maintain separate configs (like `config.prod.toml` and `config.dev.toml`), you must temporarily rename the desired config to `config.toml` when deploying.

For automated deployments, update the GitHub Actions workflow to handle the config file swap:

```yaml
# In .github/workflows/deploy.yml
      - name: Deploy Migrations
        run: |
          supabase link --project-ref $PROJECT_ID
          supabase db push --config-file=./supabase/config.prod.toml
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

### 2. Login to Supabase CLI
```bash
# Login to Supabase CLI
supabase login

# Verify login status
supabase projects list
```

This will open your browser to complete the login process. After logging in, you'll be able to manage your Supabase projects through the CLI.

### 3. Link Project
```bash
supabase link --project-ref your-project-ref
```

When linking, you'll likely see configuration differences between your local and production environments. This is expected and can be managed as follows:

#### Development-specific Settings
Keep these different in local `config.toml`:
- `auth.site_url`: Use `http://localhost:3000` locally
- `auth.additional_redirect_urls`: Include local URLs
- `auth.email.enable_confirmations`: Can be `false` for faster development
- `auth.email.max_frequency`: Can be shorter for testing

#### Production Settings
These should be more restrictive in production:
- Email confirmations enabled
- Proper rate limiting
- Production URLs configured

To manage these differences:
1. Keep development-specific settings in your local `config.toml`
2. Use `supabase db diff` to review changes before deployment
3. Use `supabase db push` to deploy schema changes only
4. Manage production-specific settings through Supabase Dashboard

### 4. Initialize Database

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

First, ensure you have the required secrets:

#### Setting up GitHub Secrets
1. **Get SUPABASE_ACCESS_TOKEN**:
   - Go to [https://supabase.com/dashboard/account/tokens](https://supabase.com/dashboard/account/tokens)
   - Click "Generate New Token"
   - Name it (e.g., "GitHub Actions Deploy")
   - Copy the generated token immediately (it won't be shown again)

2. **Get SUPABASE_PROJECT_ID**:
   - Go to [https://supabase.com/dashboard/projects](https://supabase.com/dashboard/projects)
   - Select your project
   - Go to Project Settings (gear icon)
   - Copy the Reference ID from the top of the settings page
   - It looks like: "abcdefgh-ijkl-mnop-qrst-uvwxyz123456"

3. **Add Secrets to GitHub**:
   - Go to your `prex-supabase` repository on GitHub
   - Navigate to Settings → Secrets and variables → Actions
   - Click "New repository secret"
   - Add both secrets:
     - Name: `SUPABASE_ACCESS_TOKEN`, Value: (your generated token)
     - Name: `SUPABASE_PROJECT_ID`, Value: (your project's reference ID)

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
          # Backup development config if it exists
          [ -f config.toml ] && cp config.toml config.dev.toml || true
          
          # Use production config
          cp config.prod.toml config.toml
          
          # Deploy
          supabase link --project-ref $PROJECT_ID
          supabase db push
          
          # Restore development config if it existed
          [ -f config.dev.toml ] && cp config.dev.toml config.toml || true
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