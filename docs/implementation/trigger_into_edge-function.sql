-- 0. Drop existing trigger and function if they exist
DROP TRIGGER IF EXISTS handle_customer_message_webhook ON messages;
DROP FUNCTION IF EXISTS handle_customer_message();

-- 1. Enable required extensions
CREATE EXTENSION IF NOT EXISTS "pg_net" WITH SCHEMA "extensions";

-- 2. Create webhook function
CREATE OR REPLACE FUNCTION handle_customer_message()
RETURNS TRIGGER AS $$
DECLARE
  is_bot_assigned BOOLEAN;
BEGIN
  -- Check if ticket is assigned to a bot
  SELECT EXISTS (
    SELECT 1 
    FROM tickets t
    JOIN bots b ON t.assigned_to = b.id
    WHERE t.id = NEW.ticket_id
  ) INTO is_bot_assigned;

  -- Only proceed if message is from customer, not system, and ticket assigned to bot
  IF NEW.sender_type = 'customer' 
     AND NOT NEW.is_system_message 
     AND is_bot_assigned THEN
    
    -- Call webhook using net.http_post
    PERFORM net.http_post(
      -- URL (use host.docker.internal for local dev)
      url := 'http://host.docker.internal:54321/functions/v1/handle-message',
      -- Headers must be jsonb
      headers := '{"Content-Type": "application/json"}'::jsonb,
      -- Body must be jsonb
      body := jsonb_build_object(
        'message_id', NEW.id,
        'ticket_id', NEW.ticket_id,
        'message', NEW.message,
        'user_id', NEW.created_by
      )
    );

    -- Log for debugging
    RAISE LOG 'Webhook sent for message_id: % (ticket assigned to bot)', NEW.id;
  ELSE
    -- Log why webhook not sent
    IF NOT (NEW.sender_type = 'customer' AND NOT NEW.is_system_message) THEN
      RAISE LOG 'Webhook not sent: not customer message or is system message';
    ELSIF NOT is_bot_assigned THEN
      RAISE LOG 'Webhook not sent: ticket not assigned to bot';
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;  -- SECURITY DEFINER important!

-- 3. Create trigger
CREATE TRIGGER handle_customer_message_webhook
  AFTER INSERT ON messages  -- When to run
  FOR EACH ROW             -- Run for each row
  EXECUTE FUNCTION handle_customer_message();