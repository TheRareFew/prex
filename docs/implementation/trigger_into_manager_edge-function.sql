-- 0. Drop existing trigger and function if they exist
DROP TRIGGER IF EXISTS handle_manager_prompt_webhook ON manager_prompts;
DROP FUNCTION IF EXISTS handle_manager_prompt();

-- 1. Enable required extensions
CREATE EXTENSION IF NOT EXISTS "pg_net" WITH SCHEMA "extensions";

-- 2. Create webhook function
CREATE OR REPLACE FUNCTION handle_manager_prompt()
RETURNS TRIGGER AS $$
BEGIN
  -- Call webhook using net.http_post
  PERFORM net.http_post(
    -- URL (use host.docker.internal for local dev)
    url := 'http://host.docker.internal:54321/functions/v1/handle-manager-prompt',
    -- Headers must be jsonb
    headers := '{"Content-Type": "application/json"}'::jsonb,
    -- Body must be jsonb
    body := jsonb_build_object(
      'prompt_id', NEW.id,
      'conversation_id', NEW.conversation_id,
      'prompt', NEW.prompt,
      'created_at', NEW.created_at
    )
  );

  -- Log for debugging
  RAISE LOG 'Manager webhook sent for prompt_id: %', NEW.id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;  -- SECURITY DEFINER important!

-- 3. Create trigger
CREATE TRIGGER handle_manager_prompt_webhook
  AFTER INSERT ON manager_prompts  -- When to run
  FOR EACH ROW             -- Run for each row
  EXECUTE FUNCTION handle_manager_prompt(); 