# Supabase Deployment Process

This document outlines the process for deploying updates to the Supabase production environment.

## Prerequisites

- Supabase CLI installed
- Docker Desktop installed and running
- Access to the GitHub repository
- Required environment variables and secrets set up in GitHub:
  - `SUPABASE_ACCESS_TOKEN`
  - `SUPABASE_DB_PASSWORD`
  - `SUPABASE_PROJECT_ID`
  - `SUPABASE_PROD_CONFIG`

## Deployment Process

### 1. Local Development

1. Start the local Supabase environment:
   ```bash
   supabase start
   ```

2. Create a new migration:
   ```bash
   supabase migration new your_migration_name
   ```

3. Edit the migration file in `supabase/migrations/[timestamp]_your_migration_name.sql`

4. Test locally with Docker:
   ```bash
   # Apply migrations to local database
   supabase db reset
   
   # Test your changes in the local environment
   # The local API will be available at: http://localhost:54321
   # The local Studio will be available at: http://localhost:54323
   ```

5. Once tested locally, you can test against production:
   ```bash
   # Link to production project
   supabase link --project-ref "$PROJECT_ID"
   
   # Verify what will be pushed
   supabase db diff
   
   # Push if changes look correct
   supabase db push
   ```

### 2. Deployment to Production

There are two ways to deploy changes:

#### A. Automatic Deployment (Recommended)
1. Commit your changes to the `main` branch
2. Push to GitHub:
   ```bash
   git add .
   git commit -m "feat: your commit message"
   git push origin main
   ```
3. GitHub Actions will automatically:
   - Set up the Supabase CLI
   - Apply the production configuration
   - Deploy any new migrations
   - Clean up sensitive files

#### B. Manual Deployment
If needed, you can manually trigger the deployment:
1. Go to GitHub repository
2. Navigate to "Actions" tab
3. Select "Deploy Supabase" workflow
4. Click "Run workflow"
5. Select the branch (usually `main`)
6. Click "Run workflow"

### 3. Verification

After deployment:
1. Check the GitHub Actions logs for any errors
2. Verify that migrations were applied successfully
3. Test the affected functionality in the production environment

## Troubleshooting

### Common Issues

1. **Migration Conflicts**
   ```bash
   supabase migration repair --status reverted [migration_id]
   supabase db push
   ```

2. **Configuration Differences**
   - Ensure `SUPABASE_PROD_CONFIG` secret is up to date
   - Local config will be overwritten during deployment

3. **Authentication Issues**
   - Verify `SUPABASE_ACCESS_TOKEN` is valid
   - Check project reference ID is correct

### Getting Help

If you encounter issues:
1. Check the GitHub Actions logs
2. Run commands with `--debug` flag
3. Review Supabase project dashboard
4. Consult the team for assistance

## Security Notes

- Never commit sensitive credentials
- Always use GitHub secrets for sensitive data
- Production configuration is managed through `SUPABASE_PROD_CONFIG`
- Local `config.toml` is for development only 