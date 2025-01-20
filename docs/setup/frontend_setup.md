# Frontend Repository Setup and Deployment Guide

## Repository Setup

### 1. Create GitHub Repository
1. Go to GitHub and create a new repository named `prex-frontend`
2. Initialize with a README and .gitignore (Node)

### 2. Local Setup
```bash
# Clone the repository
git clone https://github.com/your-org/prex-frontend.git
cd prex-frontend

# Create React app
npx create-react-app . --template typescript

# Install required dependencies
npm install @aws-amplify/cli @aws-amplify/ui-react aws-amplify
npm install @supabase/supabase-js
```

## Project Structure
Your repository should follow this structure:
```
prex-frontend/
├── src/
│   ├── components/
│   │   └── auth/
│   │       └── AuthWrapper.tsx
│   ├── lib/
│   │   └── supabase.ts
│   ├── App.tsx
│   └── index.tsx
├── public/
├── amplify/
├── .env
├── package.json
└── README.md
```

## Setup

### 1. Environment Configuration
Create `.env`:
```
REACT_APP_SUPABASE_URL=your-project-url
REACT_APP_SUPABASE_ANON_KEY=your-anon-key
```

### 2. Initialize Amplify
```bash
# Configure Amplify CLI
amplify configure

# Initialize Amplify in the project
amplify init

# Add authentication
amplify add auth
amplify push
```

### 3. Supabase Client Setup
Create `src/lib/supabase.ts`:
```typescript
import { createClient } from '@supabase/supabase-js'

const supabaseUrl = process.env.REACT_APP_SUPABASE_URL!
const supabaseAnonKey = process.env.REACT_APP_SUPABASE_ANON_KEY!

export const supabase = createClient(supabaseUrl, supabaseAnonKey)
```

### 4. Authentication Setup
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

### 1. AWS Amplify Console Setup
1. Go to AWS Management Console
2. Navigate to Amplify
3. Click "New App" > "Host web app"
4. Connect to your GitHub repository
5. Add environment variables:
   - `REACT_APP_SUPABASE_URL`
   - `REACT_APP_SUPABASE_ANON_KEY`

### 2. GitHub Actions (Optional)

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

### 1. Local Development
```bash
# Start development server
npm start

# Run tests
npm test

# Build for production
npm run build
```

### 2. Database Types

1. Install Supabase CLI locally
2. Generate types:
```bash
supabase gen types typescript --project-id your-project-id > src/types/supabase.ts
```

### 3. Making Changes
1. Create feature branch
2. Make changes
3. Test locally
4. Create PR
5. After merge, Amplify will auto-deploy

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
```