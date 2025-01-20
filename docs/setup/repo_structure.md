# Repository Structure

This document describes the deployment repository structure. For local development structure, see `project_structure.md`.

## 1. Frontend Repository (`prex-frontend`)
- Contains React/Node.js application
- Deployed via AWS Amplify
- Structure:
```
prex-frontend/
├── src/
├── public/
├── amplify/
├── .gitignore
├── package.json
└── README.md
```

## 2. Supabase Repository (`prex-supabase`)
- Contains Supabase migrations, functions, and configurations
- Structure:
```
prex-supabase/
├── supabase/
│   ├── functions/
│   └── migrations/
├── .github/workflows/
└── README.md
```

## 3. Backend Repository (`prex-backend`)
- Contains FastAPI application
- Deployed to ECS/Fargate
- Structure:
```
prex-backend/
├── app/
├── tests/
├── Dockerfile
├── requirements.txt
├── .github/workflows/
└── README.md
```

## Benefits of Separate Repositories

1. **Independent Deployment Cycles**
   - Each component can be deployed independently
   - Reduces risk of unintended deployments
   - Easier to roll back specific components

2. **Clearer Permissions Management**
   - Different teams can have different access levels to each repository
   - Easier to manage GitHub secrets per component

3. **Simplified CI/CD**
   - Each repository has its own specific deployment workflow
   - Prevents unnecessary builds when unrelated components change

4. **Better Organization**
   - Clearer separation of concerns
   - Easier to maintain and debug
   - More focused documentation per component

## Repository Linking

Create a new repository (`prex-docs`) to maintain:
- Overall architecture documentation
- Environment setup guides
- Links to all component repositories
- Deployment procedures
- Environment variables list