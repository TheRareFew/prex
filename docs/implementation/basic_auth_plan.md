# Supabase Authentication Implementation Plan

## Overview
This document outlines the step-by-step plan to implement Supabase authentication in our application, ensuring it works both locally and in production.

## Prerequisites
- [ ] Supabase project created and configured
- [ ] Local development environment set up
- [ ] Frontend React application running
- [ ] Required environment variables configured
- [ ] Email service provider configured for auth emails

## Implementation Steps

### 1. Supabase Project Setup
- [ ] Configure Supabase Auth Settings in Dashboard
  - [ ] Set Site URL (`http://localhost:3000` for local, production URL for prod)
  - [ ] Add additional redirect URLs if needed
  - [ ] Configure email templates for auth emails
  - [ ] Set up email provider for auth emails
  - [ ] Set up custom domain for improved email deliverability (optional)
- [ ] Configure Auth Providers
  - [ ] Enable Email/Password authentication
  - [ ] Configure password requirements
  - [ ] Set up email confirmation settings
  - [ ] Configure invite email functionality
  - [ ] Set up appropriate authentication rules for invite system

### 2. Local Development Configuration
- [ ] Update Local Supabase Config
  ```toml
  [auth]
  site_url = "http://localhost:3000"
  additional_redirect_urls = ["http://localhost:3000/*"]
  [auth.email]
  enable_confirmations = false # for faster local development
  enable_invites = true
  ```
- [ ] Set Environment Variables
  - [ ] `REACT_APP_SUPABASE_URL`
  - [ ] `REACT_APP_SUPABASE_ANON_KEY`

### 3. Frontend Implementation

#### Auth Context and Hooks
- [ ] Create Auth Context
  - [ ] Implement user state management
  - [ ] Add loading states
  - [ ] Handle auth errors
  - [ ] Add invite management state
- [ ] Implement Auth Hook
  - [ ] Sign in functionality
  - [ ] Sign up functionality
  - [ ] Sign out functionality
  - [ ] Password reset
  - [ ] Session management
  - [ ] Invite user functionality

#### Components
- [ ] Create Auth Components
  - [ ] Sign In form
  - [ ] Sign Up form
  - [ ] Password Reset form
  - [ ] Email Confirmation page
  - [ ] Protected Route wrapper
  - [ ] Invite User component
    ```typescript
    // Example Invite Component Structure
    const InviteUser = () => {
      const [email, setEmail] = useState('');
      const handleInvite = async () => {
        const { data, error } = await supabase.auth.admin.inviteUserByEmail(email);
        // Handle response
      };
      return (
        <div>
          <input
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="Enter email"
          />
          <button onClick={handleInvite}>Invite</button>
        </div>
      );
    };
    ```

#### Integration
- [ ] Update App Component
  - [ ] Wrap with Auth Provider
  - [ ] Add protected routes
  - [ ] Handle auth state changes
  - [ ] Add invite system integration
- [ ] Add Auth to API Calls
  - [ ] Add auth headers to requests
  - [ ] Handle auth errors
  - [ ] Implement token refresh
  - [ ] Add invite-specific API endpoints

### 4. Database Configuration
- [ ] Set Up RLS Policies
  ```sql
  -- Enable RLS
  ALTER TABLE your_table ENABLE ROW LEVEL SECURITY;

  -- Create policies
  CREATE POLICY "Users can read own data" ON your_table
    FOR SELECT
    USING (auth.uid() = user_id);

  CREATE POLICY "Users can insert own data" ON your_table
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

  -- Add invite-specific policies
  CREATE POLICY "Only admins can invite users" ON auth.users
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.role() = 'admin');
  ```
- [ ] Test RLS Policies
  - [ ] Verify authenticated access
  - [ ] Verify unauthenticated access is blocked
  - [ ] Test different user roles
  - [ ] Test invite system permissions

### 5. Production Configuration
- [ ] Update Production Supabase Settings
  - [ ] Configure production URLs
  - [ ] Enable email confirmations
  - [ ] Set proper rate limits
  - [ ] Configure production email settings
  - [ ] Set up custom domain for emails
- [ ] Set Up CI/CD
  - [ ] Add required secrets to GitHub
  - [ ] Configure deployment workflow
  - [ ] Set up environment variables

### 6. Testing
- [ ] Unit Tests
  - [ ] Test auth hooks
  - [ ] Test protected components
  - [ ] Test API integration
  - [ ] Test invite functionality
- [ ] Integration Tests
  - [ ] Test auth flow
  - [ ] Test protected routes
  - [ ] Test error handling
  - [ ] Test invite flow
- [ ] E2E Tests
  - [ ] Test complete sign up flow
  - [ ] Test sign in flow
  - [ ] Test password reset flow
  - [ ] Test invite user flow
  - [ ] Test invited user registration

### 7. Documentation
- [ ] Update README
  - [ ] Add auth setup instructions
  - [ ] Document environment variables
  - [ ] Add usage examples
  - [ ] Document invite system
- [ ] Create User Guide
  - [ ] Document sign up process
  - [ ] Document password requirements
  - [ ] Document error messages
  - [ ] Document invite process
  - [ ] Add invite email templates

## Testing Checklist
- [ ] Local Development
  - [ ] Sign up works
  - [ ] Sign in works
  - [ ] Protected routes work
  - [ ] API calls work with auth
  - [ ] Invite system works
- [ ] Production
  - [ ] Email confirmation works
  - [ ] Password reset works
  - [ ] Session persistence works
  - [ ] Auth state properly synced
  - [ ] Invite emails delivered properly
  - [ ] Custom domain emails working

## Security Checklist
- [ ] Proper CORS configuration
- [ ] Secure session handling
- [ ] Environment variables properly set
- [ ] RLS policies in place
- [ ] No sensitive data exposure
- [ ] Rate limiting configured
- [ ] Password requirements enforced
- [ ] Invite system properly secured
- [ ] Email domain properly configured

## Notes
- Local development uses relaxed settings for faster iteration
- Production environment requires stricter security measures
- Always test auth flows in both environments before deploying
- Monitor auth-related errors and user feedback
- Consider using dedicated email service for complex workflows
- Ensure proper permissions for invite functionality
- Test email deliverability in production environment 