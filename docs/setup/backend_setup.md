# Backend Repository Setup and Deployment Guide (FastAPI on ECS)

## Repository Setup

### 1. Create GitHub Repository
1. Go to GitHub and create a new repository named `prex-backend`
2. Initialize with a README and Python .gitignore

### 2. Local Setup
```bash
# Clone the repository
git clone https://github.com/your-org/prex-backend.git
cd prex-backend

# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: .\venv\Scripts\activate

# Create initial project structure
mkdir -p app/api app/core app/models tests
```

## Project Structure
```
prex-backend/
├── app/
│   ├── api/
│   │   ├── __init__.py
│   │   └── endpoints.py
│   ├── core/
│   │   ├── __init__.py
│   │   └── config.py
│   ├── models/
│   │   ├── __init__.py
│   │   └── schemas.py
│   └── main.py
├── tests/
│   ├── __init__.py
│   └── test_api.py
├── Dockerfile
├── docker-compose.yml
├── requirements.txt
├── .gitignore
└── README.md
```

### 3. Create Core Files

1. Create `requirements.txt`:
```text
fastapi==0.100.0
uvicorn==0.22.0
pydantic==2.0.2
python-dotenv==1.0.0
pytest==7.4.0
httpx==0.24.1
```

2. Create `app/main.py`:
```python
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api.endpoints import router

app = FastAPI(title="PREX POC API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure this appropriately in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(router)

@app.get("/health")
async def health_check():
    return {"status": "healthy"}
```

3. Create `app/api/endpoints.py`:
```python
from fastapi import APIRouter, HTTPException
from app.models.schemas import Query, Response

router = APIRouter()

@router.post("/predict", response_model=Response)
async def predict(query: Query):
    try:
        # Add your AI logic here
        return Response(response="Test response")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
```

4. Create `app/models/schemas.py`:
```python
from pydantic import BaseModel

class Query(BaseModel):
    query: str

class Response(BaseModel):
    response: str
```

5. Create `app/core/config.py`:
```python
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    APP_NAME: str = "PREX POC API"
    DEBUG: bool = False
    
    class Config:
        env_file = ".env"

settings = Settings()
```

### 4. Docker Setup

1. Create `Dockerfile`:
```dockerfile
FROM python:3.9-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app app/
COPY tests tests/

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

2. Create `docker-compose.yml` for local development:
```yaml
version: '3.8'
services:
  api:
    build: .
    ports:
      - "8000:8000"
    volumes:
      - .:/app
    environment:
      - DEBUG=1
```

## AWS Infrastructure Setup

### 1. Create ECR Repository
```bash
aws ecr create-repository \
    --repository-name prex-backend \
    --image-scanning-configuration scanOnPush=true
```

### 2. Create ECS Task Definition

Create `task-definition.json`:
```json
{
  "family": "prex-backend",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "containerDefinitions": [
    {
      "name": "prex-backend",
      "image": "${ECR_REPOSITORY_URI}:latest",
      "portMappings": [
        {
          "containerPort": 8000,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {
          "name": "DEBUG",
          "value": "0"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/prex-backend",
          "awslogs-region": "${AWS_REGION}",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ]
}
```

## GitHub Actions Setup

Create `.github/workflows/deploy.yml`:
```yaml
name: Deploy to ECS

on:
  push:
    branches: [ main ]

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
        aws-region: ${{ secrets.AWS_REGION }}
    
    - name: Login to Amazon ECR
      id: login-ecr
      uses: aws-actions/amazon-ecr-login@v1
    
    - name: Build and push image
      env:
        ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
        ECR_REPOSITORY: prex-backend
        IMAGE_TAG: ${{ github.sha }}
      run: |
        docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG .
        docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
        echo "::set-output name=image::$ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG"
    
    - name: Update ECS service
      run: |
        aws ecs update-service \
          --cluster prex \
          --service prex-backend \
          --force-new-deployment
```

## Local Development

1. Install dependencies:
```bash
pip install -r requirements.txt
```

2. Run the application:
```bash
# Direct Python
uvicorn app.main:app --reload

# Or using Docker
docker-compose up --build
```

3. Run tests:
```bash
pytest
```

## Development Workflow

1. Create new branch:
```bash
git checkout -b feature/new-endpoint
```

2. Make changes and test locally:
```bash
# Run tests
pytest

# Start local server
uvicorn app.main:app --reload
```

3. Test the API:
```bash
curl -X POST http://localhost:8000/predict \
  -H "Content-Type: application/json" \
  -d '{"query":"test"}'
```

4. Commit and push:
```bash
git add .
git commit -m "Add new endpoint"
git push origin feature/new-endpoint
```

5. Create Pull Request on GitHub

## Environment Variables

Add these secrets to GitHub:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION`
- `ECR_REPOSITORY_URI`

## Monitoring

1. View logs in CloudWatch:
   - Navigate to CloudWatch Logs
   - Find the log group `/ecs/prex-backend`

2. Monitor ECS service:
   - Check ECS cluster metrics
   - View service events and task status