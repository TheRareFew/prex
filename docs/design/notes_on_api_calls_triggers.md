You're absolutely correct! If the `employees` table has a foreign key constraint referencing `auth.users`, you can't insert a bot employee directly into the `employees` table without also creating a corresponding user in the `auth.users` table. Instead, creating a separate table for bots is a cleaner and more scalable solution.

Here's how you can redesign the system to accommodate bots:

---

## **Redesign with a Separate `bots` Table**

### **1. Schema Updates**
Create a new `bots` table to store bot-specific information. This table will not have a foreign key constraint to `auth.users`.

```sql
-- Create the bots table
create table bots (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  created_at timestamptz default now()
);

-- Insert a default bot
insert into bots (id, name)
values ('00000000-0000-0000-0000-000000000000', 'AI Bot');
```

Update the `messages` table to reference either `auth.users` (for employees/customers) or `bots` (for system messages):

```sql
alter table messages
add column bot_id uuid references bots(id);

-- Drop the existing foreign key constraint (if necessary)
alter table messages
drop constraint messages_created_by_fkey;

-- Add a new constraint to allow either created_by or bot_id
alter table messages
add constraint messages_created_by_check
check (
  (created_by is not null and bot_id is null) or
  (created_by is null and bot_id is not null)
);
```

---

### **2. Updated `messages` Table Schema**
The `messages` table will now look like this:
```sql
messages
    - id (uuid, primary key)
    - ticket_id (uuid, references tickets.id)
    - created_by (uuid, references auth.users.id, nullable)
    - bot_id (uuid, references bots.id, nullable)
    - sender_type (message_sender_type, auto-set by trigger)
    - created_at (timestamptz, default now)
    - message (text)
    - is_system_message (boolean, default false)
```

---

### **3. Trigger Updates**
Modify the trigger to handle the new `bot_id` field when inserting system messages:

```sql
create or replace function call_edge_function_on_message_insert()
returns trigger as $$
begin
  -- Call the edge function only if the message is from a customer
  if NEW.sender_type = 'customer' then
    perform net.http_post(
      url := 'https://your-project.functions.supabase.co/handle-message',
      body := jsonb_build_object(
        'message_id', NEW.id,
        'ticket_id', NEW.ticket_id,
        'message', NEW.message
      )
    );
  end if;
  return NEW;
end;
$$ language plpgsql;
```

---

### **4. Edge Function Updates**
Update the edge function to insert system messages using the `bot_id` field:

```typescript
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const supabase = createClient(supabaseUrl, supabaseKey);

serve(async (req) => {
  try {
    const { message_id, ticket_id, message } = await req.json();

    // Call the AI API
    const aiResponse = await fetch('https://api.example.com/ai-endpoint', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ message }),
    });

    let systemMessage;
    if (aiResponse.ok) {
      const aiData = await aiResponse.json();
      systemMessage = aiData.response; // Assuming the AI returns a "response" field
    } else {
      systemMessage = 'Your ticket is being transferred to a human.';
    }

    // Insert the system message into the messages table
    const { error } = await supabase
      .from('messages')
      .insert([
        {
          ticket_id,
          message: systemMessage,
          bot_id: '00000000-0000-0000-0000-000000000000', // Bot ID
          is_system_message: true,
          sender_type: 'employee',
        },
      ]);

    if (error) throw error;

    return new Response(JSON.stringify({ success: true }), {
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { 'Content-Type': 'application/json' },
      status: 500,
    });
  }
});
```

---

### **5. Frontend Updates**
Update the `sendMessage` function to handle the new `bot_id` field when sending system messages:

```typescript
const sendSystemMessage = async (message: string) => {
  return sendMessage(message, true, null, '00000000-0000-0000-0000-000000000000');
};

const sendMessage = async (
  message: string,
  isSystemMessage: boolean = false,
  createdBy: string | null = user?.id,
  botId: string | null = null
) => {
  if (!ticketId || !message.trim()) return null;

  try {
    setError(null);

    // First check if the user is an employee
    const { data: employeeData, error: employeeError } = await supabase
      .from('employees')
      .select('id')
      .eq('id', user?.id)
      .single();

    if (employeeError && employeeError.code !== 'PGRST116') { // PGRST116 is "not found" error
      throw employeeError;
    }

    const senderType: message_sender_type = employeeData ? 'employee' : 'customer';

    console.log('Sending message:', message, 'for ticket:', ticketId);
    const { data, error: supabaseError } = await supabase
      .from('messages')
      .insert([
        {
          ticket_id: ticketId,
          message: message.trim(),
          created_by: createdBy,
          bot_id: botId,
          is_system_message: isSystemMessage,
          sender_type: senderType,
        },
      ])
      .select()
      .single();

    if (supabaseError) throw supabaseError;

    // Update ticket timestamp
    await updateTicketTimestamp(ticketId);

    console.log('Sent message:', data);
    // Update local state immediately for better UX
    setMessages(current => [...current, data]);
    return data;
  } catch (err) {
    const error = err as Error;
    console.error('Error sending message:', error);
    setError(error.message);
    return null;
  }
};
```

---

### **6. Benefits of This Design**
- **Separation of Concerns**: Bots and users are stored in separate tables, avoiding conflicts with foreign key constraints.
- **Scalability**: You can easily add more bots in the future without modifying the `employees` or `auth.users` tables.
- **Flexibility**: The `messages` table can now handle messages from both users and bots seamlessly.

---

This approach ensures a clean and maintainable design while addressing the foreign key constraint issue. Let me know if you need further clarification or additional features!

# Edge Function Implementation Notes

## Overview
The edge function handles incoming messages by:
1. Receiving the message via HTTP POST
2. Generating an automated response
3. Storing both messages in the database
4. Returning a success response with relevant IDs

## Implementation Details

### 1. Edge Function Setup
```bash
# Create function directory
mkdir -p supabase/functions/handle-message

# Required files
- index.ts      # Main function code
- config.toml   # Function configuration
```

### 2. Environment Configuration
```env
# .env file - Note: SUPABASE_ prefix not allowed in edge functions
EDGE_URL=http://127.0.0.1:54321
EDGE_SERVICE_ROLE_KEY=<your-service-role-key>
DATABASE_URL=postgresql://postgres:postgres@host.docker.internal:54322/postgres
```

### 3. Database Schema Updates
```sql
-- Create bots table for system messages
create table bots (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  created_at timestamptz default now()
);

-- Insert default bot
insert into bots (id, name)
values ('00000000-0000-0000-0000-000000000000', 'AI Bot');

-- Add bot_id to messages
alter table messages
add column bot_id uuid references bots(id);

-- Update messages constraint to require either user or bot
alter table messages
add constraint messages_created_by_check
check (
  (created_by is not null and bot_id is null) or
  (created_by is null and bot_id is not null)
);
```

### 4. Edge Function Code
The edge function:
- Uses direct PostgreSQL connection for better performance
- Handles CORS for browser requests
- Creates tickets automatically for testing
- Returns ticket ID for frontend reference

Key features:
- Connection pooling for database efficiency
- Proper error handling and status codes
- CORS headers for browser compatibility
- Transaction safety with connection release

### 5. Testing
Test the function using browser fetch:
```javascript
fetch('http://127.0.0.1:54321/functions/v1/handle-message', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    message_id: 'test123',
    ticket_id: 'test456',
    message: 'Hello bot!'
  })
})
.then(r => r.json())
.then(console.log)
```

Expected response:
```json
{
  "success": true,
  "ticket_id": "<uuid>"
}
```

### 6. Local Development
1. Start Supabase: `supabase start`
2. Start edge function: `supabase functions serve handle-message --env-file .env`
3. Test with browser fetch or Postman

### 7. Production Considerations
- Replace test responses with actual AI integration
- Add proper authentication checks
- Implement rate limiting
- Add more comprehensive error handling
- Consider adding message queueing for reliability

### 8. Next Steps
- Implement real AI integration
- Add user authentication
- Add rate limiting
- Implement message queueing
- Add monitoring and logging
- Set up production environment variables