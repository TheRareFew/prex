# Project Structure

## Development Structure (Monorepo)
This structure is recommended for local development in Cursor:

```
prex/
├── frontend/                 # React/Amplify frontend
│   ├── src/
│   ├── amplify/
│   └── package.json
│
├── backend/                  # FastAPI backend
│   ├── app/
│   ├── tests/
│   └── Dockerfile
│
├── supabase/                # Supabase functions and migrations
│   ├── functions/
│   └── migrations/
│
├── docs/                    # Shared documentation
│   ├── setup/
│   └── architecture/
│
├── .gitignore              # Root gitignore for common patterns
├── docker-compose.yml      # For local development of all services
└── README.md              
```

## Deployment Structure
For deployment, each component maintains its own repository:

- `prex-frontend` - React/Amplify frontend
- `prex-backend` - FastAPI backend
- `prex-supabase` - Supabase functions and migrations
- `prex-docs` - Documentation and architecture

This separation allows for:
- Independent deployment cycles
- Clearer permissions management
- Simplified CI/CD pipelines
- Better organization of component-specific concerns

You can work with both structures by:
1. Using the monorepo locally for development
2. Pushing changes to respective deployment repositories when ready
3. Letting each repository's CI/CD handle deployment

Each component can still maintain its own GitHub repository for deployment purposes, but during development, you can work with them together in Cursor. You can achieve this by:

1. Creating separate GitHub repositories for each component
2. Using git submodules or simply cloning each repo into the appropriate directory
3. Adding the following to your root `.gitignore`:
```
# Ignore the component directories as they're separate repos
/frontend/
/backend/
/supabase/

# But keep the docs and shared config
!/docs/
!docker-compose.yml
!README.md
```

This approach gives you the best of both worlds:
- Unified development environment in Cursor
- Separate deployment pipelines for each component
- Clear separation of concerns
- Easy local development and testing of interactions between components 