# Implementation Plan for AI Endpoints

## Overview

This plan outlines the steps to implement the functions from `ai_endpoint_design.txt` within our current project infrastructure. We will leverage existing code, particularly referencing `file_handler.py` and `message_indexer.py` where appropriate. The implementation will involve creating new API endpoints in the backend, corresponding Supabase Edge Functions, and updating the frontend to interact with these endpoints.

---

## Functions to Implement

1. **`user_message`**
2. **`generate_article`**
3. **`update_article`**
4. **`process_ticket`**
5. **`upload_document`**

---

## General Steps

- [ ] Set up backend endpoints in FastAPI for each function.
- [ ] Create corresponding Supabase Edge Functions to act as an API gateway.
- [ ] Implement the logic for each function using LangChain and OpenAI APIs.
- [ ] Update the database schema if necessary, adhering to `schema.txt`.
- [ ] Update frontend hooks and components to interact with the new endpoints.
- [ ] Ensure proper authentication and error handling.

---

## Directory Structure References

- **Backend Directory:** `backend/`
  - API Endpoints: `backend/app/api/endpoints.py`
  - Models: `backend/app/models/`
- **Frontend Directory:** `frontend/`
  - Hooks: `frontend/src/hooks/`
  - Components: `frontend/src/components/`
- **Supabase Directory:** `supabase/`
  - Edge Functions: `supabase/functions/`

---

## Detailed Implementation

### 1. `user_message`

#### Description

Handle incoming user messages, determine if the AI can assist, or escalate the ticket.

#### Backend Implementation

- [ ] **Create the endpoint in `backend/app/api/endpoints.py`:**

[CODE START]
@router.post("/user_message")
async def user_message_endpoint(query: UserMessageQuery):
    """
    Handle incoming user message and provide AI response or escalate ticket.
    """
    try:
        # Determine if LLM can help
        can_help = await determine_ai_capability(query.messages)
        
        if can_help:
            response = await process_with_ai(query.messages)
            return UserMessageResponse(response=response, escalate=False)
        
        return UserMessageResponse(response=None, escalate=True)
    except Exception as e:
        logger.error(f"Error processing message: {str(e)}")
        return UserMessageResponse(response=None, escalate=True)
[CODE END]

- [ ] **Define schemas in `backend/app/models/schemas.py`:**

[CODE START]
class UserMessageQuery(BaseModel):
    messages: List[MessageSchema]  # Chat history

class UserMessageResponse(BaseModel):
    response: Optional[str]
    escalate: bool
[CODE END]

- [ ] **Create Supabase Edge Function in `supabase/functions/handle_user_message/index.ts`:**

[CODE START]
Deno.serve(async (req) => {
  try {
    const { messages } = await req.json()
    
    // Call backend API
    const response = await fetch(`${API_URL}/user_message`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ messages })
    })
    
    if (!response.ok) {
      throw new Error('Backend API error')
    }
    
    const data = await response.json()
    return new Response(JSON.stringify(data), {
      headers: { 'Content-Type': 'application/json' }
    })
  } catch (error) {
    // On error, escalate to human
    return new Response(JSON.stringify({
      response: null,
      escalate: true
    }), {
      headers: { 'Content-Type': 'application/json' }
    })
  }
})
[CODE END]

### 2. `generate_article`

#### Backend Implementation

- [ ] **Create the endpoint in `backend/app/api/endpoints.py`:**

[CODE START]
@router.post("/generate_article")
async def generate_article_endpoint(query: ArticleQuery):
    """
    Generate an article based on the provided query.
    """
    try:
        # Search knowledge base and info store
        relevant_info = await search_knowledge_base(query.query)
        
        # Generate article content
        article_content = await generate_content(query.query, relevant_info)
        
        return ArticleResponse(
            article=ArticleSchema(
                title=article_content.title,
                content=article_content.content,
                category=article_content.category,
                status="draft"
            )
        )
    except Exception as e:
        logger.error(f"Error generating article: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to generate article")
[CODE END]

- [ ] **Define schemas:**

[CODE START]
class ArticleQuery(BaseModel):
    query: str

class ArticleResponse(BaseModel):
    article: ArticleSchema
[CODE END]

### 3. `update_article`

#### Backend Implementation

- [ ] **Create the endpoint:**

[CODE START]
@router.post("/update_article")
async def update_article_endpoint(update_request: UpdateArticleRequest):
    """
    Update an article based on the query and existing content.
    """
    try:
        # Create new version
        new_version = await generate_article_update(
            update_request.query,
            update_request.article
        )
        
        return UpdateArticleResponse(updated_article=new_version)
    except Exception as e:
        logger.error(f"Error updating article: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to update article")
[CODE END]

- [ ] **Define schemas:**

[CODE START]
class UpdateArticleRequest(BaseModel):
    query: str
    article: ArticleSchema

class UpdateArticleResponse(BaseModel):
    updated_article: ArticleSchema
[CODE END]

### 4. `process_ticket`

#### Backend Implementation

- [ ] **Create the endpoint:**

[CODE START]
@router.post("/process_ticket")
async def process_ticket_endpoint(ticket_request: ProcessTicketRequest):
    """
    Process a ticket to assign category, priority, employee, and add a note.
    """
    try:
        # Analyze ticket
        analysis = await analyze_ticket(ticket_request.messages)
        
        # Update ticket
        updated_ticket = await update_ticket_details(
            ticket_request.ticket_id,
            analysis.category,
            analysis.priority,
            analysis.assigned_to
        )
        
        # Generate note
        note = await generate_ticket_note(analysis)
        
        return ProcessTicketResponse(
            ticket=updated_ticket,
            note=note
        )
    except Exception as e:
        logger.error(f"Error processing ticket: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to process ticket")
[CODE END]

### 5. `upload_document`

#### Backend Implementation

- [ ] **Create the endpoint:**

[CODE START]
@router.post("/upload_document")
async def upload_document_endpoint(file: UploadFile = File(...)):
    """
    Upload and process a document.
    """
    try:
        # Save file temporarily
        temp_path = await save_temp_file(file)
        
        # Process document
        content = await process_document(temp_path)
        
        # Generate embeddings and store
        doc_id = await store_document_embeddings(content)
        
        return UploadResponse(
            success=True,
            document_id=doc_id
        )
    except Exception as e:
        logger.error(f"Error uploading document: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to upload document")
    finally:
        # Cleanup
        if temp_path:
            os.remove(temp_path)
[CODE END]

