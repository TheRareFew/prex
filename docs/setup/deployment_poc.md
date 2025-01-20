# Tech Stack Proof of Concept Deployment Guide

## 1. Frontend (Node/React on Amplify)

### Initial Setup
1. Create a new React project:
```bash
git clone https://github.com/your-org/prex-frontend.git
cd prex-frontend
npx create-react-app .
```

2. Initialize Amplify:
```bash
npm install -g @aws-amplify/cli
amplify configure
amplify init
```

### Authentication Setup
1. Add authentication:
```bash
amplify add auth
amplify push
```

2. Configure auth in your React app:
```javascript
import { Amplify } from 'aws-amplify';
import { withAuthenticator } from '@aws-amplify/ui-react';
import '@aws-amplify/ui-react/styles.css';
import awsconfig from './aws-exports';
Amplify.configure(awsconfig);
```

### Test Components
Create two test buttons in `App.js`:
```javascript
import { useState } from 'react';
import { API } from 'aws-amplify';

function App() {
  const [value, setValue] = useState(null);

  const fetchValue = async () => {
    const response = await fetch('YOUR_SUPABASE_ENDPOINT/rest/v1/test_table?select=value', {
      headers: {
        'apikey': 'YOUR_SUPABASE_API_KEY'
      }
    });
    const data = await response.json();
    setValue(data[0].value);
  };

  const callAIEndpoint = async () => {
    const response = await fetch('YOUR_SUPABASE_FUNCTION_ENDPOINT', {
      headers: {
        'apikey': 'YOUR_SUPABASE_API_KEY'
      }
    });
    const data = await response.json();
    console.log(data);
  };

  return (
    <div>
      <button onClick={fetchValue}>Get Value</button>
      <button onClick={callAIEndpoint}>Call AI</button>
      {value && <p>Value: {value}</p>}
    </div>
  );
}

export default withAuthenticator(App);
```

## 2. Supabase Setup

### Database Setup
1. Create new project at [supabase.com](https://supabase.com)
2. Create test table:
```sql
CREATE TABLE test_table (
  id SERIAL PRIMARY KEY,
  value TEXT NOT NULL
);

INSERT INTO test_table (value) VALUES ('test value');
```

### Edge Function Setup
1. Install Supabase CLI:
```bash
npm install -g supabase
```

2. Create new edge function:
```bash
supabase functions new call-ai
```

3. Add function code to `supabase/functions/call-ai/index.ts`:
```typescript
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'

serve(async (req) => {
  const response = await fetch('YOUR_FASTAPI_ENDPOINT/predict', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ query: 'test' }),
  })
  
  const data = await response.json()
  
  return new Response(
    JSON.stringify(data),
    { headers: { 'Content-Type': 'application/json' } },
  )
})
```

### GitHub Actions Setup
Create `.github/workflows/supabase-deploy.yml`:
```yaml
name: Deploy Supabase Functions

on:
  push:
    branches: [ main ]
    paths:
      - 'supabase/functions/**'

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v2
      - uses: supabase/setup-cli@v1
      - run: |
          supabase link --project-ref ${{ secrets.SUPABASE_PROJECT_ID }}
          supabase functions deploy --project-ref ${{ secrets.SUPABASE_PROJECT_ID }}
        env:
          SUPABASE_ACCESS_TOKEN: ${{ secrets.SUPABASE_ACCESS_TOKEN }}
```

## 3. AI Backend (FastAPI on ECS/Fargate)

### FastAPI Setup
1. Create `Dockerfile`:
```dockerfile
FROM python:3.9-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

2. Create `main.py`:
```python
from fastapi import FastAPI
from pydantic import BaseModel

app = FastAPI()

class Query(BaseModel):
    query: str

@app.post("/predict")
async def predict(query: Query):
    return {"response": "Test response"}
```

3. Create `requirements.txt`:
```text
fastapi
uvicorn
pydantic
```

### ECS/Fargate Deployment
1. Create ECR repository:
```bash
aws ecr create-repository --repository-name prex-ai
```

2. Create `task-definition.json`:
```json
{
  "family": "prex-ai",
  "networkMode": "awsvpc",
  "containerDefinitions": [{
    "name": "prex-ai",
    "image": "YOUR_ECR_REPO_URI:latest",
    "portMappings": [{
      "containerPort": 8000,
      "protocol": "tcp"
    }],
    "essential": true
  }],
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512"
}
```

3. Create GitHub Actions workflow `.github/workflows/deploy-ai.yml`:
```yaml
name: Deploy AI Backend

on:
  push:
    branches: [ main ]
    paths:
      - 'ai/**'

jobs:
  deploy:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v2
    
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v1
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: us-east-1
    
    - name: Login to Amazon ECR
      id: login-ecr
      uses: aws-actions/amazon-ecr-login@v1
    
    - name: Build and push
      env:
        ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
        ECR_REPOSITORY: prex-ai
        IMAGE_TAG: latest
      run: |
        docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG .
        docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
    
    - name: Update ECS service
      run: |
        aws ecs update-service --cluster prex --service prex-ai --force-new-deployment
```

## 4. Testing the Stack

1. Deploy the AI backend first:
```bash
git push origin main
```
(This will trigger the ECS/Fargate deployment)

2. Deploy Supabase functions:
```bash
git push origin main
```
(This will trigger the Supabase functions deployment)

3. Deploy the frontend to Amplify:
```bash
amplify push
git push origin main
```

4. Test the flow:
- Log in to the React app
- Click the "Get Value" button to test Supabase database connection
- Click the "Call AI" button to test the complete stack (React → Supabase Function → FastAPI → Response)

## 5. Environment Variables Needed

- Supabase:
  - `SUPABASE_PROJECT_ID`
  - `SUPABASE_ACCESS_TOKEN`
  - `FASTAPI_ENDPOINT`

- AWS:
  - `AWS_ACCESS_KEY_ID`
  - `AWS_SECRET_ACCESS_KEY`
  - `AWS_REGION`

- React App:
  - `REACT_APP_SUPABASE_URL`
  - `REACT_APP_SUPABASE_ANON_KEY` 


