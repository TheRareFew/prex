# Frontend Repository Setup and Development Guide

## Project Structure
Your repository should follow this structure:
```
frontend/
├── src/
│   ├── components/
│   │   └── auth/
│   │       └── AuthWrapper.tsx
│   │   └── App.tsx
│   │   └── types/
│   │       └── supabase.ts
│   └── index.tsx
├── public/
├── amplify/
├── .env
├── package.json
└── README.md
```

## AWS Amplify Console Build Settings

When setting up your app in the Amplify Console, use these build settings:

```yaml
version: 1
frontend:
  phases:
    preBuild:
      commands:
        - npm ci
    build:
      commands:
        - npm run build
  artifacts:
    baseDirectory: build
    files:
      - '**/*'
  cache:
    paths:
      - node_modules/**/*
```

Build settings explanation:
- Frontend build command: `npm run build`
- Build output directory: `build`
- Node.js version: 18.x (or your preferred version)

These settings match the default Create React App configuration and will:
1. Install dependencies using `npm ci` (more reliable than `npm install`)
2. Build the project using the standard CRA build command
3. Serve files from the `build` directory
4. Cache `node_modules` for faster subsequent builds

## Git Setup
Since the frontend is set up as a submodule in the main repository, first ensure it's properly initialized:

```bash
# From the main repo root, initialize and update submodules if not done
git submodule update --init --recursive

# Navigate to frontend directory
cd frontend

# Ensure you're on the main branch
git checkout main

# Pull latest changes
git pull origin main

# For new feature development
git checkout -b feature/your-feature  # Create feature branch
git add .                            # Stage changes
git commit -m "feat: your changes"   # Commit changes
git push -u origin feature/your-feature  # Push feature branch

# After feature is complete and merged to main
git checkout main
git pull origin main

# Return to parent repo and update submodule reference
cd ..
git add frontend
git commit -m "chore: update frontend submodule"
git push origin main
```

## Local Setup
```bash
# Navigate to frontend directory
cd frontend

# Create React app with TypeScript template
npx create-react-app . --template typescript

# Install required dependencies
npm install @aws-amplify/cli @aws-amplify/ui-react aws-amplify
npm install @supabase/supabase-js

# Install Amplify CLI globally if not installed
npm install -g @aws-amplify/cli

# Configure Amplify CLI with your AWS credentials
amplify configure

# Initialize Amplify in the project
amplify init

# Add authentication
amplify add auth

# Push Amplify changes to cloud
amplify push

# Copy environment file template
cp .env.example .env

# Update .env with your values:
# REACT_APP_SUPABASE_URL=your-project-url
# REACT_APP_SUPABASE_ANON_KEY=your-anon-key

# Start development server
npm start
```

## Setup

### 1. Amplify Configuration
```bash
# Configure Amplify CLI (if not already configured)
amplify configure

# Pull existing Amplify environment
amplify pull
```

The following sections describe the existing setup for reference:

### 2. Supabase Client Setup
The Supabase client is configured in `src/lib/supabase.ts`:
```typescript
import { createClient } from '@supabase/supabase-js'

const supabaseUrl = process.env.REACT_APP_SUPABASE_URL!
const supabaseAnonKey = process.env.REACT_APP_SUPABASE_ANON_KEY!

export const supabase = createClient(supabaseUrl, supabaseAnonKey)
```

### 3. Authentication Setup
Create `src/components/auth/AuthWrapper.tsx`:
```typescript
import { Amplify } from 'aws-amplify'
import { withAuthenticator } from '@aws-amplify/ui-react'
import '@aws-amplify/ui-react/styles.css'
import awsconfig from '../../aws-exports'

Amplify.configure(awsconfig)

interface AuthWrapperProps {
  children: React.ReactNode
}

function AuthWrapper({ children }: AuthWrapperProps) {
  return <>{children}</>
}

export default withAuthenticator(AuthWrapper)
```

Update `src/App.tsx`:
```typescript
import { useEffect, useState } from 'react'
import AuthWrapper from './components/auth/AuthWrapper'
import { supabase } from './lib/supabase'

function App() {
  const [data, setData] = useState<any[]>([])

  useEffect(() => {
    fetchData()
  }, [])

  async function fetchData() {
    try {
      const { data, error } = await supabase
        .from('test_table')
        .select('*')
      
      if (error) throw error
      setData(data || [])
    } catch (error) {
      console.error('Error:', error)
    }
  }

  return (
    <AuthWrapper>
      <div>
        {/* Your app content */}
        <pre>{JSON.stringify(data, null, 2)}</pre>
      </div>
    </AuthWrapper>
  )
}

export default App
```

## Real-time Subscriptions

Example of using Supabase real-time:

```typescript
import { useEffect } from 'react'
import { supabase } from './lib/supabase'

function RealTimeComponent() {
  useEffect(() => {
    const channel = supabase
      .channel('table_changes')
      .on('postgres_changes', {
        event: '*',
        schema: 'public',
        table: 'test_table'
      }, (payload) => {
        console.log('Change received!', payload)
      })
      .subscribe()

    return () => {
      supabase.removeChannel(channel)
    }
  }, [])

  return <div>Listening for changes...</div>
}
```

## Deployment Setup

### AWS Amplify Console Setup
1. Go to AWS Management Console
2. Navigate to Amplify
3. Click "New App" > "Host web app"
4. Connect to the frontend submodule repository
5. Add environment variables:
   - `REACT_APP_SUPABASE_URL`
   - `REACT_APP_SUPABASE_ANON_KEY`

### GitHub Actions (Optional)

Create `.github/workflows/ci.yml`:
```yaml
name: CI

on:
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest

    env:
      REACT_APP_SUPABASE_URL: ${{ secrets.REACT_APP_SUPABASE_URL }}
      REACT_APP_SUPABASE_ANON_KEY: ${{ secrets.REACT_APP_SUPABASE_ANON_KEY }}

    steps:
    - uses: actions/checkout@v3
    - uses: actions/setup-node@v3
      with:
        node-version: '16'
        cache: 'npm'
    - run: npm ci
    - run: npm run build
    - run: npm test
```

## Development Workflow

### Local Development
```bash
# Start development server
npm start

# Run tests
npm test

# Build for production
npm run build
```

### Database Types

1. Install Supabase CLI locally
2. Generate types:
```bash
supabase gen types typescript --project-id your-project-id > src/types/supabase.ts
```

## Best Practices

1. Authentication
- Use Amplify for authentication
- Keep Supabase for data and real-time features

2. Data Fetching
```typescript
// Basic query
const { data, error } = await supabase
  .from('table')
  .select('*')

// With filters
const { data, error } = await supabase
  .from('table')
  .select('*')
  .eq('column', 'value')
```

3. Error Handling
```typescript
try {
  const { data, error } = await supabase.from('table').select()
  if (error) throw error
  // Handle data
} catch (error) {
  console.error('Error:', error.message)
}
```