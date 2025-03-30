import os
import io
import re
import requests
import tempfile
import base64
import time
import threading
import queue
import speech_recognition as sr
from flask import Flask, render_template, request, jsonify, send_from_directory
from flask_socketio import SocketIO
from pdf2image import convert_from_bytes
import pytesseract
from PIL import Image
import fitz  # PyMuPDF
from langdetect import detect, LangDetectException
import google.generativeai as genai
from gtts import gTTS
# Import RAG-specific libraries
import numpy as np
from sentence_transformers import SentenceTransformer
from sklearn.metrics.pairwise import cosine_similarity

# -------------------- App & SocketIO Initialization --------------------
app = Flask(__name__)
socketio = SocketIO(app)
app.config['MAX_CONTENT_LENGTH'] = 10 * 1024 * 1024  # 10MB file upload limit

# -------------------- RAG SYSTEM IMPLEMENTATION --------------------
class DocumentRAG:
    def __init__(self, model_name="all-MiniLM-L6-v2"):
        """Initialize the RAG system with a sentence transformer model."""
        self.model = SentenceTransformer(model_name)
        self.documents = {}  # Store document chunks and embeddings
        self.document_text = {}  # Store original full document text
        
    def simple_split_sentences(self, text):
        """
        Simple sentence splitter that doesn't rely on nltk.
        """
        # Replace common abbreviations with placeholders to avoid splitting on their periods
        text = text.replace("Mr.", "Mr_DOT_")
        text = text.replace("Mrs.", "Mrs_DOT_")
        text = text.replace("Dr.", "Dr_DOT_")
        text = text.replace("Ms.", "Ms_DOT_")
        text = text.replace("Prof.", "Prof_DOT_")
        text = text.replace("Inc.", "Inc_DOT_")
        text = text.replace("Ltd.", "Ltd_DOT_")
        text = text.replace("vs.", "vs_DOT_")
        text = text.replace("i.e.", "ie_DOT_")
        text = text.replace("e.g.", "eg_DOT_")
        text = text.replace("etc.", "etc_DOT_")
        
        # Split on sentence-ending punctuation followed by space or newline
        sentences = re.split(r'(?<=[.!?])\s+', text)
        
        # Clean up sentences and restore abbreviations
        cleaned_sentences = []
        for s in sentences:
            if not s.strip():
                continue
            s = s.replace("Mr_DOT_", "Mr.")
            s = s.replace("Mrs_DOT_", "Mrs.")
            s = s.replace("Dr_DOT_", "Dr.")
            s = s.replace("Ms_DOT_", "Ms.")
            s = s.replace("Prof_DOT_", "Prof.")
            s = s.replace("Inc_DOT_", "Inc.")
            s = s.replace("Ltd_DOT_", "Ltd.")
            s = s.replace("vs_DOT_", "vs.")
            s = s.replace("ie_DOT_", "i.e.")
            s = s.replace("eg_DOT_", "e.g.")
            s = s.replace("etc_DOT_", "etc.")
            cleaned_sentences.append(s)
            
        return cleaned_sentences
        
    def process_document(self, document_id, text, chunk_size=5):
        """
        Process a document by splitting it into chunks and computing embeddings.
        
        Args:
            document_id: Unique identifier for the document
            text: The document text
            chunk_size: Number of sentences per chunk
        """
        # Store the original document text
        self.document_text[document_id] = text
        
        # Split text into sentences using our simple approach instead of nltk
        try:
            sentences = self.simple_split_sentences(text)
            if not sentences:
                # If no sentences detected, treat the whole text as one sentence
                sentences = [text]
        except Exception as e:
            print(f"Error splitting sentences: {e}")
            # Fallback to simple paragraph splitting if sentence splitting fails
            sentences = [p.strip() for p in text.split('\n\n') if p.strip()]
            if not sentences:
                sentences = [text]
        
        # Create chunks of sentences
        chunks = []
        for i in range(0, len(sentences), chunk_size):
            chunk = " ".join(sentences[i:min(i+chunk_size, len(sentences))])
            chunks.append(chunk)
        
        # Compute embeddings for each chunk
        embeddings = self.model.encode(chunks)
        
        # Store chunks and embeddings
        self.documents[document_id] = {
            "chunks": chunks,
            "embeddings": embeddings
        }
        
        print(f"Processed document {document_id} into {len(chunks)} chunks")
        return len(chunks)
    
    def retrieve_relevant_chunks(self, document_id, query, top_k=3):
        """
        Retrieve the most relevant chunks from a document for a given query.
        
        Args:
            document_id: Unique identifier for the document
            query: The user query
            top_k: Number of top chunks to retrieve
        
        Returns:
            List of relevant chunks
        """
        if document_id not in self.documents:
            return []
        
        # Compute query embedding
        query_embedding = self.model.encode([query])[0]
        
        # Compute similarity with all chunks
        chunk_embeddings = self.documents[document_id]["embeddings"]
        similarities = cosine_similarity([query_embedding], chunk_embeddings)[0]
        
        # Get top-k chunks
        top_indices = np.argsort(similarities)[-top_k:]
        top_chunks = [self.documents[document_id]["chunks"][i] for i in top_indices]
        
        return top_chunks
    
    def generate_prompt_with_context(self, document_id, query, top_k=3):
        """
        Generate a prompt that includes relevant context from the document.
        
        Args:
            document_id: Unique identifier for the document
            query: The user query
            top_k: Number of top chunks to retrieve
        
        Returns:
            A prompt string with relevant context
        """
        relevant_chunks = self.retrieve_relevant_chunks(document_id, query, top_k)
        
        if not relevant_chunks:
            return None
        
        context_text = "\n\n".join(relevant_chunks)
        
        prompt = f"""You are a helpful assistant that provides accurate information based on the document context.

DOCUMENT CONTEXT:
{context_text}

USER QUERY:
{query}

Instructions:
1. Answer the user's query based ONLY on the document context provided above.
2. If the answer is not contained in the context, say "I don't have specific information about that in the document."
3. Do not make up or infer information that is not present in the context.
4. Cite specific sections or quotes from the document when relevant.
5. Keep your answer concise, clear, and directly relevant to the query.
"""
        return prompt

# Initialize the RAG system
rag_system = DocumentRAG()

# Store document session information for each user
legal_document_sessions = {}  # Format: {socket_id: {'document_id': 'doc_123', 'active': True}}

# -------------------- SOLUTION PROVIDER FUNCTIONS & ROUTES --------------------
# Mistral API Functions for solution provider
MISTRAL_API_KEY = "qCrx2JAOa9tDelNuVPhSusV5Fogl1NEL"  # Replace with your actual API key
MISTRAL_API_URL = "https://api.mistral.ai/v1/chat/completions"

def call_mistral_api(prompt, model="mistral-large-latest"):
    """Call the Mistral API with the provided prompt."""
    headers = {
        "Authorization": f"Bearer {MISTRAL_API_KEY}",
        "Content-Type": "application/json"
    }
    data = {
        "model": model,
        "messages": [{"role": "user", "content": prompt}],
        "temperature": 0.7,
        "max_tokens": 1024
    }
    response = requests.post(MISTRAL_API_URL, headers=headers, json=data)
    response.raise_for_status()
    result = response.json()
    return result['choices'][0]['message']['content']

def extract_text_from_pdf(pdf_bytes):
    """Extract text from a PDF using PyMuPDF."""
    text = ""
    try:
        doc = fitz.open(stream=pdf_bytes, filetype="pdf")
        for page_num in range(len(doc)):
            page = doc.load_page(page_num)
            text += page.get_text()
        doc.close()
        return text
    except Exception as e:
        return f"Error extracting text from PDF: {str(e)}"

def extract_text_from_image(image_bytes):
    """Extract text from an image using pytesseract OCR."""
    try:
        image = Image.open(io.BytesIO(image_bytes))
        return pytesseract.image_to_string(image)
    except Exception as e:
        return f"Error extracting text from image: {str(e)}"

def process_pdf_with_ocr(pdf_bytes):
    """If regular text extraction yields limited results, use OCR on PDF images."""
    text = extract_text_from_pdf(pdf_bytes)
    if len(text.strip()) < 100 and not text.startswith("Error"):
        try:
            images = convert_from_bytes(pdf_bytes)
            ocr_text = ""
            for image in images:
                ocr_text += pytesseract.image_to_string(image)
            return ocr_text if ocr_text.strip() else text
        except Exception as e:
            return f"Error processing PDF with OCR: {str(e)}"
    return text

@app.route('/solutionprovider')
def solutionprovider_index():
    """Serve the solution provider HTML page."""
    current_dir = os.path.abspath(os.path.dirname(__file__))
    return send_from_directory(current_dir, "solutionprovider.html")

@app.route('/solutionprovider/ask', methods=['POST'])
def solutionprovider_ask():
    """Endpoint for handling queries and document uploads for the solution provider."""
    try:
        query = request.form.get('query', '')
        # Optionally, 'type' can be used for customization
        query_type = request.form.get('type', 'general')
        document_text = None

        # Process file upload if provided
        if 'document' in request.files and request.files['document'].filename != '':
            file = request.files['document']
            if file.content_length and file.content_length > 10 * 1024 * 1024:
                return jsonify({"error": "File too large. Please upload files smaller than 10MB."})
            file_bytes = file.read()
            if not file_bytes:
                return jsonify({"error": "Empty file uploaded."})
            if file.filename.lower().endswith('.pdf'):
                document_text = process_pdf_with_ocr(file_bytes)
            elif file.filename.lower().endswith(('.jpg', '.jpeg', '.png')):
                document_text = extract_text_from_image(file_bytes)
            else:
                return jsonify({"error": "Unsupported file format. Please upload PDF or image files."})
        
        # Build prompt based on document or direct text query
        if document_text:
            summary_prompt = f"Please summarize the following document in clear, concise language:\n\n{document_text}"
            response_text = call_mistral_api(summary_prompt)
        else:
            response_text = call_mistral_api(query)
            
        return jsonify({
            "response": response_text,
            "document_text": document_text  # Useful for debugging or confirmation
        })
    except Exception as e:
        app.logger.error(f"Error processing request: {str(e)}")
        return jsonify({"error": f"An error occurred: {str(e)}"})

# -------------------- Dummy Dataset Function --------------------
def dummy_dataset_usage():
    dataset_file = "chatbot_dataset.csv"
    try:
        with open(dataset_file, "r", encoding="utf-8") as f:
            lines = f.readlines()
        count = len(lines) - 1
        print(f"Dataset loaded with {count} conversation pairs from {dataset_file}.")
    except Exception as e:
        print(f"Error loading dataset {dataset_file}: {e}")

# -------------------- LEGAL ASSISTANT SETUP --------------------
LEGAL_API_KEY = "qCrx2JAOa9tDelNuVPhSusV5Fogl1NEL"
LEGAL_MODEL = "mistral-medium"
LEGAL_ENDPOINT = "https://api.mistral.ai/v1/chat/completions"
legal_token = 0
legal_tts_queue = queue.Queue()

def get_legal_response(user_input, language="en"):
    """Get legal assistant response using Mistral API"""
    system_prompt = (
        """You are a helpful legal assistant speaking on a phone call. Your responses should be:
1. Direct, crisp, and straight to the point
2. Conversational and natural like a human on a phone call
3. Brief and concise (2-3 sentences when possible)
4. Based on established legal knowledge

Speak in a natural, conversational tone. Use everyday language. Avoid formal legal jargon unless necessary.
Provide general legal information and suggest seeking professional legal advice when needed.
Don't say "I'm not a lawyer" or "This is not legal advice" unless specifically asked about your limitations.

When asked legal questions, provide clear, actionable information without unnecessary explanations or caveats.

For non-legal questions, politely redirect: "I'm focused on helping with legal questions. What legal concern can I help with?"

If the situation sounds complex or high-stakes, briefly suggest consulting with a qualified attorney."""
    )
    
    headers = {
        "Authorization": f"Bearer {LEGAL_API_KEY}",
        "Content-Type": "application/json"
    }
    
    data = {
        "model": LEGAL_MODEL,
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_input}
        ],
        "max_tokens": 500,
        "temperature": 0.7
    }
    
    try:
        response = requests.post(LEGAL_ENDPOINT, json=data, headers=headers, timeout=30)
        response.raise_for_status()
        result = response.json()
        return result["choices"][0]["message"]["content"]
    except requests.exceptions.RequestException as e:
        error_message = f"Error: Unable to fetch legal response. {str(e)}"
        if hasattr(e, 'response') and e.response is not None:
            error_message += f"\nResponse details: {e.response.text}"
        print(error_message)
        return error_message

# -------------------- MEDICAL ASSISTANT SETUP --------------------
# Changed from Gemini to Mistral API
MISTRAL_API_KEY = "qCrx2JAOa9tDelNuVPhSusV5Fogl1NEL"  # Your Mistral API key
MISTRAL_MEDICAL_MODEL = "mistral-large-latest"  # You can use "mistral-medium" or other models as needed
MISTRAL_ENDPOINT = "https://api.mistral.ai/v1/chat/completions"
medical_token = 0
medical_tts_queue = queue.Queue()

def get_medical_response(user_input, language="en"):
    """Get medical assistant response using Mistral API instead of Gemini"""
    system_prompt = (
        """You are a helpful medical assistant speaking on a phone call. Your responses should be:
1. Direct, crisp, and straight to the point
2. Conversational and natural like a human on a phone call
3. Brief and concise (2-3 sentences when possible)
4. Based on established medical knowledge

Speak in a natural, conversational tone. Use everyday language. Avoid formal medical jargon unless necessary.
Do mention specific medicines to take along with doses. Provide general advice and suggest seeking professional medical help when needed.
Don't say "I'm not a replacement for a doctor" unless specifically asked about your limitations.

When asked medical questions, provide clear, actionable information without unnecessary explanations or caveats.

For non-medical questions, politely redirect: "I'm focused on helping with health questions. What medical concern can I help with?"

If the situation sounds urgent or serious, briefly suggest seeking immediate medical attention."""
    )
    
    headers = {
        "Authorization": f"Bearer {MISTRAL_API_KEY}",
        "Content-Type": "application/json"
    }
    
    data = {
        "model": MISTRAL_MEDICAL_MODEL,
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_input}
        ],
        "max_tokens": 500,
        "temperature": 0.7
    }
    
    try:
        response = requests.post(MISTRAL_ENDPOINT, json=data, headers=headers, timeout=30)
        response.raise_for_status()
        result = response.json()
        return result["choices"][0]["message"]["content"]
    except requests.exceptions.RequestException as e:
        error_message = f"Error: Unable to fetch medical response. {str(e)}"
        if hasattr(e, 'response') and e.response is not None:
            error_message += f"\nResponse details: {e.response.text}"
        print(error_message)
        return error_message
    
# -------------------- GOVERNMENT ASSISTANT SETUP --------------------
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "AIzaSyBoBzvZlz0Ir6ux9ETx89p9BAE7nAQBeyM")  # Replace with your actual Gemini API key
GEMINI_MODEL = "gemini-1.5-pro"
genai.configure(api_key=GEMINI_API_KEY)
government_token = 0
government_tts_queue = queue.Queue()

def get_grievance_response(user_input):
    system_prompt = '''You are an empathetic and professional Grievance Filing Assistant. Please guide the user through the grievance filing process based on the following details.
    write a general letter of grievance after i add details to it. 
mention where i have to apply the grievance and what are the steps to be followed.
    1. Direct, crisp, and straight to the point
2. Conversational and natural like a human on a phone call
3. Brief and concise (2-3 sentences when possible)
4. Based on established medical knowledge

Speak in a natural, conversational tone. Use everyday language. 
    Keep it short and concise. in 3 to 4 lines
    '''
    try:
        model = genai.GenerativeModel(GEMINI_MODEL)
        chat = model.start_chat(history=[])
        response = chat.send_message(f"{system_prompt}\n\nUser input: {user_input}")
        return response.text
    except Exception as e:
        print(f"Error with Government Assistant API: {str(e)}")
        return f"Error: Unable to fetch response. {str(e)}"

# -------------------- TTS PROCESSING FUNCTION --------------------
def text_to_speech(text, namespace):
    """Enhanced text to speech function that properly processes audio for streaming"""
    try:
        if not text or len(text.strip()) < 2:
            print(f"Empty text received for TTS, skipping ({namespace})")
            return
            
        print(f"[{namespace}] Converting to speech: '{text}'")
        
        # Create temp file in a way that ensures it's accessible
        with tempfile.NamedTemporaryFile(delete=False, suffix='.mp3') as temp_file:
            temp_filename = temp_file.name
            print(f"[{namespace}] Temp file created: {temp_filename}")
        
        # Generate and save audio
        tts = gTTS(text=text, lang='en', slow=False)
        tts.save(temp_filename)
        print(f"[{namespace}] Audio saved to temp file")
        
        # Add a small delay to ensure file is fully written
        time.sleep(0.2)
        
        # Read the audio file
        with open(temp_filename, 'rb') as audio_file:
            audio_data = base64.b64encode(audio_file.read()).decode('utf-8')
            print(f"[{namespace}] Audio file read, size: {len(audio_data)} chars")
        
        # Clean up
        try:
            os.unlink(temp_filename)
            print(f"[{namespace}] Temp file deleted")
        except Exception as e:
            print(f"[{namespace}] Warning: Could not delete temp file: {str(e)}")
        
        # Send the audio data to the client
        print(f"[{namespace}] Sending audio data to client")
        socketio.emit('tts_audio', {'audio': audio_data}, namespace=namespace)
        print(f"[{namespace}] Audio data sent")
    
    except Exception as e:
        print(f"[{namespace}] TTS Error: {str(e)}")
        socketio.emit('error_message', {'message': f'Error generating speech: {str(e)}'}, namespace=namespace)

def process_tts(namespace, tts_queue, get_current_token):
    """Worker function that processes the TTS queue for a specific namespace"""
    print(f"[{namespace}] TTS worker thread started")
    while True:
        try:
            print(f"[{namespace}] Waiting for sentence in TTS queue...")
            token, text = tts_queue.get()
            print(f"[{namespace}] Got sentence from queue (token {token}): '{text}'")
            
            current_token = get_current_token()
            if token != current_token:
                print(f"[{namespace}] Skipping TTS for outdated token {token} (current token is {current_token})")
                tts_queue.task_done()
                continue
                
            text_to_speech(text, namespace)
            tts_queue.task_done()
        except Exception as e:
            print(f"[{namespace}] Error in TTS worker: {str(e)}")
            try:
                tts_queue.task_done()
            except:
                pass

# -------------------- VOICE RECOGNITION FUNCTION --------------------
def recognize_speech(namespace, stream_func):
    r = sr.Recognizer()
    r.energy_threshold = 300  # Lower value = more sensitive
    r.dynamic_energy_threshold = True
    with sr.Microphone() as source:
        print("Speak now...")
        r.adjust_for_ambient_noise(source, duration=1)
        print(f"[{namespace}] Listening for speech...")
        audio = r.listen(source, timeout=5, phrase_time_limit=10)
        print(f"[{namespace}] Audio captured")
    try:
        text = r.recognize_google(audio)
        print(f"[{namespace}] Speech recognized: '{text}'")
        socketio.emit('user_message', {'text': text}, namespace=namespace)
        socketio.emit('speech_recognized', {'text': text}, namespace=namespace)
        try:
            detected_lang = detect(text)
        except LangDetectException:
            detected_lang = "en"
        if namespace == '/legal':
            global legal_token
            legal_token += 1
            with legal_tts_queue.mutex:
                legal_tts_queue.queue.clear()
            socketio.emit('stop_audio', namespace=namespace)
            stream_func(text, legal_token, detected_lang)
        elif namespace == '/medical':
            global medical_token
            medical_token += 1
            with medical_tts_queue.mutex:
                medical_tts_queue.queue.clear()
            socketio.emit('stop_audio', namespace=namespace)
            stream_func(text, medical_token, detected_lang)
        elif namespace == '/government':
            global government_token
            government_token += 1
            with government_tts_queue.mutex:
                government_tts_queue.queue.clear()
            socketio.emit('stop_audio', namespace=namespace)
            stream_func(text, government_token)
    except sr.UnknownValueError:
        print(f"[{namespace}] Could not understand the audio")
        socketio.emit('error_message', {'message': "Sorry, I couldn't understand. Please try again."}, namespace=namespace)
    except sr.RequestError as e:
        print(f"[{namespace}] Could not request results from the speech recognition service; {e}")
        socketio.emit('error_message', {'message': f"Error in speech recognition service: {str(e)}"}, namespace=namespace)
    except Exception as e:
        print(f"[{namespace}] Speech recognition error: {e}")
        import traceback
        traceback.print_exc()
        socketio.emit('error_message', {'message': f"An error occurred during speech recognition: {str(e)}"}, namespace=namespace)
    finally:
        socketio.emit('listening_status', {'status': False}, namespace=namespace)

# -------------------- STREAMING RESPONSE FUNCTIONS --------------------
def stream_response_legal(user_input, token, language="en"):
    global legal_token
    if token != legal_token:
        return
    socketio.emit('thinking_status', {'status': True}, namespace='/legal')
    try:
        full_response = get_legal_response(user_input, language)
        sentences = [s.strip() for s in re.split(r'(?<=[.!?]) +', full_response) if s.strip()]
        print(f"[LEGAL] Processing response with {len(sentences)} sentences")
        accumulated_text = ""
        
        # Stream the text response in a sentence-by-sentence fashion for UI display
        for sentence in sentences:
            if token != legal_token:
                print("[LEGAL] Token changed, stopping response streaming")
                break
                
            accumulated_text += (" " if accumulated_text else "") + sentence
            socketio.emit('response_stream', {'text': accumulated_text, 'is_final': False}, namespace='/legal')
            socketio.sleep(0.3)
            
        if token == legal_token:
            # Send final complete text response
            socketio.emit('response_stream', {'text': accumulated_text, 'is_final': True}, namespace='/legal')
            
            # First, explicitly stop any ongoing audio
            socketio.emit('stop_audio', namespace='/legal')
            socketio.sleep(0.5)  # Give time for the client to stop audio
            
            # Now send the complete response to TTS
            print(f"[LEGAL] Sending complete response to TTS: '{full_response}'")
            legal_tts_queue.put((token, full_response))
    except Exception as e:
        print(f"[LEGAL] Error in stream_response: {str(e)}")
        socketio.emit('error_message', {'message': f'Error generating legal response: {str(e)}'}, namespace='/legal')
    finally:
        if token == legal_token:
            socketio.emit('thinking_status', {'status': False}, namespace='/legal')
            
def stream_response_legal_with_document(user_input, document_id, token, language="en"):
    """Handle streaming responses that use the RAG system for document Q&A."""
    global legal_token
    if token != legal_token:
        return
    socketio.emit('thinking_status', {'status': True}, namespace='/legal')
    try:
        # Generate prompt with document context
        prompt = rag_system.generate_prompt_with_context(document_id, user_input)
        
        if not prompt:
            error_msg = "I couldn't find relevant information about that in the document."
            socketio.emit('response_stream', {'text': error_msg, 'is_final': True}, namespace='/legal')
            socketio.emit('thinking_status', {'status': False}, namespace='/legal')
            return
            
        # Get response from the LLM
        full_response = call_mistral_api(prompt)
        sentences = [s.strip() for s in re.split(r'(?<=[.!?]) +', full_response) if s.strip()]
        print(f"[LEGAL-RAG] Processing response with {len(sentences)} sentences")
        accumulated_text = ""
        
        for sentence in sentences:
            if token != legal_token:
                print("[LEGAL-RAG] Token changed, stopping response streaming")
                break
                
            accumulated_text += (" " if accumulated_text else "") + sentence
            socketio.emit('response_stream', {'text': accumulated_text, 'is_final': False}, namespace='/legal')
            
            # Add each sentence to the TTS queue
            print(f"[LEGAL-RAG] Adding sentence to TTS queue: '{sentence}'")
            legal_tts_queue.put((token, sentence))
            
            socketio.sleep(0.3)
            
        if token == legal_token:
            socketio.emit('response_stream', {'text': accumulated_text, 'is_final': True}, namespace='/legal')
    except Exception as e:
        print(f"[LEGAL-RAG] Error in stream_response_with_document: {str(e)}")
        socketio.emit('error_message', {'message': f'Error generating document-based response: {str(e)}'}, namespace='/legal')
    finally:
        if token == legal_token:
            socketio.emit('thinking_status', {'status': False}, namespace='/legal')

def stream_response_medical(user_input, token, language="en"):
    global medical_token
    if token != medical_token:
        return
    socketio.emit('thinking_status', {'status': True}, namespace='/medical')
    try:
        full_response = get_medical_response(user_input, language)
        sentences = [s.strip() for s in re.split(r'(?<=[.!?]) +', full_response) if s.strip()]
        print(f"[MEDICAL] Processing response with {len(sentences)} sentences")
        accumulated_text = ""
        
        for sentence in sentences:
            if token != medical_token:
                print("[MEDICAL] Token changed, stopping response streaming")
                break
                
            accumulated_text += (" " if accumulated_text else "") + sentence
            socketio.emit('response_stream', {'text': accumulated_text, 'is_final': False}, namespace='/medical')
            
            # Add each sentence to the TTS queue
            print(f"[MEDICAL] Adding sentence to TTS queue: '{sentence}'")
            medical_tts_queue.put((token, sentence))
            
            socketio.sleep(0.3)
            
        if token == medical_token:
            socketio.emit('response_stream', {'text': accumulated_text, 'is_final': True}, namespace='/medical')
    except Exception as e:
        print(f"[MEDICAL] Error in stream_response: {str(e)}")
        socketio.emit('error_message', {'message': f'Error generating medical response: {str(e)}'}, namespace='/medical')
    finally:
        if token == medical_token:
            socketio.emit('thinking_status', {'status': False}, namespace='/medical')

def stream_response_government(user_input, token):
    global government_token
    if token != government_token:
        return
    socketio.emit('thinking_status', {'status': True}, namespace='/government')
    try:
        full_response = get_grievance_response(user_input)
        sentences = [s.strip() for s in re.split(r'(?<=[.!?]) +', full_response) if s.strip()]
        print(f"[GOVERNMENT] Processing response with {len(sentences)} sentences")
        accumulated_text = ""
        
        for sentence in sentences:
            if token != government_token:
                print("[GOVERNMENT] Token changed, stopping response streaming")
                break
                
            accumulated_text += (" " if accumulated_text else "") + sentence
            socketio.emit('response_stream', {'text': accumulated_text, 'is_final': False}, namespace='/government')
            
            # Add each sentence to the TTS queue
            print(f"[GOVERNMENT] Adding sentence to TTS queue: '{sentence}'")
            government_tts_queue.put((token, sentence))
            
            socketio.sleep(0.3)
            
        if token == government_token:
            socketio.emit('response_stream', {'text': accumulated_text, 'is_final': True}, namespace='/government')
    except Exception as e:
        print(f"[GOVERNMENT] Error in stream_response: {str(e)}")
        socketio.emit('error_message', {'message': f'Error generating response: {str(e)}'}, namespace='/government')
    finally:
        if token == government_token:
            socketio.emit('thinking_status', {'status': False}, namespace='/government')

# -------------------- LEGAL RAG ROUTES AND HANDLERS --------------------
@app.route('/legal-rag')
def legal_rag():
    """Serve the legal RAG HTML page."""
    current_dir = os.path.abspath(os.path.dirname(__file__))
    return send_from_directory(current_dir, "legal_rag.html")

@app.route('/api/legal/upload-document', methods=['POST'])
def legal_upload_document():
    """API endpoint for uploading and processing a legal document for RAG."""
    try:
        if 'document' not in request.files:
            return jsonify({"error": "No document provided"})
            
        file = request.files['document']
        if file.filename == '':
            return jsonify({"error": "No file selected"})
            
        # Check file type
        if not file.filename.lower().endswith('.pdf'):
            return jsonify({"error": "Only PDF files are supported"})
            
        # Read the file
        file_bytes = file.read()
        
        # Extract text from the PDF
        document_text = process_pdf_with_ocr(file_bytes)
        
        if document_text.startswith("Error"):
            return jsonify({"error": document_text})
            
        # Generate a unique document ID
        document_id = f"doc_{int(time.time())}"
        
        # Process the document with the RAG system
        chunk_count = rag_system.process_document(document_id, document_text)
        
        # Generate a summary
        summary_prompt = f"""Please provide a brief summary of the following legal document in 3-4 sentences:

{document_text[:5000]}{"..." if len(document_text) > 5000 else ""}

Focus on:
1. Document type (contract, agreement, etc.)
2. Main parties involved
3. Key provisions or obligations
"""
        summary = call_mistral_api(summary_prompt)
        
        return jsonify({
            "success": True,
            "document_id": document_id,
            "chunk_count": chunk_count,
            "summary": summary,
            "char_count": len(document_text)
        })
        
    except Exception as e:
        print(f"Error in legal_upload_document: {str(e)}")
        return jsonify({"error": f"An error occurred: {str(e)}"})

# -------------------- SOCKET.IO LEGAL RAG NAMESPACE --------------------

@socketio.on('connect', namespace='/legal-rag')
def legal_rag_connect():
    print(f"[LEGAL-RAG] Client connected: {request.sid}")

@socketio.on('disconnect', namespace='/legal-rag')
def legal_rag_disconnect():
    print(f"[LEGAL-RAG] Client disconnected: {request.sid}")
    # Clean up session data when user disconnects
    if request.sid in legal_document_sessions:
        del legal_document_sessions[request.sid]

@socketio.on('set_active_document', namespace='/legal-rag')
def legal_rag_set_document(data):
    """Set the active document for the current user session."""
    document_id = data.get('document_id')
    if not document_id:
        socketio.emit('error', {"message": "Document ID is required"}, room=request.sid, namespace='/legal-rag')
        return
        
    if document_id not in rag_system.documents:
        socketio.emit('error', {"message": "Document not found. Please upload it first."}, room=request.sid, namespace='/legal-rag')
        return
        
    # Store the document session for this user
    legal_document_sessions[request.sid] = {
        "document_id": document_id,
        "active": True
    }
    
    socketio.emit('document_activated', {"document_id": document_id}, room=request.sid, namespace='/legal-rag')
    
    # Send initial greeting
    greeting = "I've analyzed your document. You can now ask me questions about its content."
    socketio.emit('rag_response', {
        "text": greeting,
        "is_final": True
    }, room=request.sid, namespace='/legal-rag')

@socketio.on('query_document', namespace='/legal-rag')
def legal_rag_query(data):
    """Handle document queries using the RAG system."""
    query = data.get('query', '').strip()
    if not query:
        socketio.emit('error', {"message": "Query cannot be empty"}, room=request.sid, namespace='/legal-rag')
        return
        
    # Check if this user has an active document
    if request.sid not in legal_document_sessions or not legal_document_sessions[request.sid].get("active"):
        socketio.emit('error', {"message": "No active document. Please upload a document first."}, room=request.sid, namespace='/legal-rag')
        return
        
    document_id = legal_document_sessions[request.sid]["document_id"]
    
    # Notify client that we're processing the query
    socketio.emit('thinking', {}, room=request.sid, namespace='/legal-rag')
    
    # Start a thread to process the query
    thread = threading.Thread(target=process_legal_rag_query, args=(request.sid, document_id, query))
    thread.daemon = True
    thread.start()

def process_legal_rag_query(socket_id, document_id, query):
    """Process a document query in a background thread."""
    try:
        # Generate prompt with document context
        prompt = rag_system.generate_prompt_with_context(document_id, query)
        
        if not prompt:
            socketio.emit('error', {
                "message": "Could not find relevant information for your query in the document."
            }, room=socket_id, namespace='/legal-rag')
            return
            
        # Get response from the LLM
        response = call_mistral_api(prompt)
        
        # Split the response into sentences for simulated streaming
        sentences = [s.strip() for s in re.split(r'(?<=[.!?]) +', response) if s.strip()]
        
        accumulated_text = ""
        for sentence in sentences:
            # Check if the client is still connected
            if socket_id not in legal_document_sessions:
                print(f"[LEGAL-RAG] Client disconnected during response generation: {socket_id}")
                return
                
            time.sleep(0.3)  # Simulate streaming delay
            accumulated_text += (" " if accumulated_text else "") + sentence
            socketio.emit('rag_response', {
                'text': accumulated_text,
                'is_final': False
            }, room=socket_id, namespace='/legal-rag')
        
        socketio.emit('rag_response', {
            'text': accumulated_text,
            'is_final': True
        }, room=socket_id, namespace='/legal-rag')
    
    except Exception as e:
        print(f"[LEGAL-RAG] Error processing query: {str(e)}")
        socketio.emit('error', {
            "message": f"An error occurred: {str(e)}"
        }, room=socket_id, namespace='/legal-rag')

# -------------------- ENHANCED LEGAL ASSISTANT WITH DOCUMENT CHAT --------------------

# Enhanced message handler for legal assistant with document support
@socketio.on('send_message', namespace='/legal')
def handle_legal_message(data):
    global legal_token
    user_input = data['message'].strip()
    if not user_input:
        return
    
    # Clear the TTS queue and stop any ongoing audio
    with legal_tts_queue.mutex:
        legal_tts_queue.queue.clear()
    socketio.emit('stop_audio', namespace='/legal')
    
    # Rest of your message handling code...
        
    # Check for active document
    document_id = data.get('document_id', None)
    use_document = data.get('use_document', False)
    
    try:
        detected_lang = detect(user_input)
    except LangDetectException:
        detected_lang = "en"
        
    print(f"[LEGAL] Received new message: '{user_input}'")
    legal_token += 1
    with legal_tts_queue.mutex:
        legal_tts_queue.queue.clear()
    socketio.emit('stop_audio', namespace='/legal')
    
    # If we have a document and the flag is set, use the RAG-based response
    if use_document and document_id and document_id in rag_system.documents:
        thread = threading.Thread(
            target=stream_response_legal_with_document, 
            args=(user_input, document_id, legal_token, detected_lang)
        )
    else:
        thread = threading.Thread(
            target=stream_response_legal, 
            args=(user_input, legal_token, detected_lang)
        )
        
    thread.daemon = True
    thread.start()

# Enhanced endpoint to handle document uploads directly to legal assistant
@app.route('/api/legal/process-document', methods=['POST'])
def legal_process_document():
    """Process a document upload directly from the legal chat interface"""
    try:
        if 'document' not in request.files:
            return jsonify({"error": "No document provided"})
            
        file = request.files['document']
        if file.filename == '':
            return jsonify({"error": "No file selected"})
            
        # Check file size
        if file.content_length and file.content_length > 10 * 1024 * 1024:
            return jsonify({"error": "File too large. Please upload files smaller than 10MB."})
            
        # Process file
        file_bytes = file.read()
        if not file_bytes:
            return jsonify({"error": "Empty file uploaded."})
            
        # Extract text based on file type
        if file.filename.lower().endswith('.pdf'):
            document_text = process_pdf_with_ocr(file_bytes)
        elif file.filename.lower().endswith(('.jpg', '.jpeg', '.png')):
            document_text = extract_text_from_image(file_bytes)
        else:
            return jsonify({"error": "Unsupported file format. Please upload PDF or image files."})
            
        if document_text.startswith("Error"):
            return jsonify({"error": document_text})
            
        # Generate a unique document ID
        document_id = f"doc_{int(time.time())}"
        
        # Process the document with the RAG system
        chunk_count = rag_system.process_document(document_id, document_text)
        
        # Generate a summary for preview
        summary_prompt = f"""Please summarize this legal document briefly:

{document_text[:5000]}{"..." if len(document_text) > 5000 else ""}"""
        
        summary = call_mistral_api(summary_prompt)
        
        return jsonify({
            "success": True,
            "document_id": document_id,
            "filename": file.filename,
            "summary": summary,
            "char_count": len(document_text),
            "chunk_count": chunk_count
        })
            
    except Exception as e:
        print(f"Error in legal_process_document: {str(e)}")
        return jsonify({"error": f"An error occurred: {str(e)}"})

# -------------------- COMBINED ASSISTANT ROUTES --------------------
@app.route('/services/legal.html')
def serve_legal():
    current_dir = os.path.abspath(os.path.dirname(__file__))
    return send_from_directory(current_dir, "legal.html")

@app.route('/services/medical.html')
def serve_medical():
    current_dir = os.path.abspath(os.path.dirname(__file__))
    return send_from_directory(current_dir, "medical.html")

@app.route('/services/government.html')
def serve_government():
    current_dir = os.path.abspath(os.path.dirname(__file__))
    return send_from_directory(current_dir, "government.html")

@app.route('/services/emergency.html')
def serve_emergency():
    current_dir = os.path.abspath(os.path.dirname(__file__))
    return send_from_directory(current_dir, "emergency.html")

@app.route('/')
def index():
    base_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
    return send_from_directory(base_dir, "index.html")

@app.route('/CitiVoice/services/solutionprovider.html')
def serve_solutionprovider():
    current_dir = os.path.abspath(os.path.dirname(__file__))
    return send_from_directory(current_dir, "solutionprovider.html")

@app.route('/test_tts')
def test_tts():
    print("Testing TTS functionality")
    text_to_speech("This is a test of the text to speech system.", "/test")
    return "Testing TTS functionality. Check console for logs."

@app.route('/test_mic')
def test_mic():
    print("Testing microphone setup")
    try:
        mic_list = sr.Microphone.list_microphone_names()
        return jsonify({
            'status': 'success',
            'microphones': mic_list,
            'count': len(mic_list)
        })
    except Exception as e:
        import traceback
        error_trace = traceback.format_exc()
        return jsonify({
            'status': 'error',
            'message': str(e),
            'traceback': error_trace
        })

@socketio.on('start_voice_input', namespace='/legal')
def handle_legal_voice_input():
    socketio.emit('listening_status', {'status': True}, namespace='/legal')
    thread = threading.Thread(target=recognize_speech, args=('/legal', stream_response_legal))
    thread.daemon = True
    thread.start()

# -------------------- SOCKET.IO MEDICAL NAMESPACE --------------------
@socketio.on('send_message', namespace='/medical')
def handle_medical_message(data):
    global medical_token
    user_input = data['message'].strip()
    if not user_input:
        return
    try:
        detected_lang = detect(user_input)
    except LangDetectException:
        detected_lang = "en"
    print(f"[MEDICAL] Received new message: '{user_input}'")
    medical_token += 1
    with medical_tts_queue.mutex:
        medical_tts_queue.queue.clear()
    socketio.emit('stop_audio', namespace='/medical')
    thread = threading.Thread(target=stream_response_medical, args=(user_input, medical_token, detected_lang))
    thread.daemon = True
    thread.start()

@socketio.on('start_voice_input', namespace='/medical')
def handle_medical_voice_input():
    socketio.emit('listening_status', {'status': True}, namespace='/medical')
    thread = threading.Thread(target=recognize_speech, args=('/medical', stream_response_medical))
    thread.daemon = True
    thread.start()

# -------------------- SOCKET.IO GOVERNMENT NAMESPACE --------------------
@socketio.on('send_message', namespace='/government')
def handle_government_message(data):
    global government_token
    user_input = data['message'].strip()
    if not user_input:
        return
    try:
        detected_lang = detect(user_input)
    except LangDetectException:
        detected_lang = "en"
    print(f"[GOVERNMENT] Received new message: '{user_input}'")
    government_token += 1
    with government_tts_queue.mutex:
        government_tts_queue.queue.clear()
    socketio.emit('stop_audio', namespace='/government')
    thread = threading.Thread(target=stream_response_government, args=(user_input, government_token))
    thread.daemon = True
    thread.start()

@socketio.on('start_voice_input', namespace='/government')
def handle_government_voice_input():
    socketio.emit('listening_status', {'status': True}, namespace='/government')
    thread = threading.Thread(target=recognize_speech, args=('/government', stream_response_government))
    thread.daemon = True
    thread.start()

@socketio.on('connect', namespace='/legal')
def handle_legal_connect():
    print("[LEGAL] Client connected")

@socketio.on('disconnect', namespace='/legal')
def handle_legal_disconnect():
    print("[LEGAL] Client disconnected")

@socketio.on('connect', namespace='/medical')
def handle_medical_connect():
    print("[MEDICAL] Client connected")

@socketio.on('disconnect', namespace='/medical')
def handle_medical_disconnect():
    print("[MEDICAL] Client disconnected")

@socketio.on('connect', namespace='/government')
def handle_government_connect():
    print("[GOVERNMENT] Client connected")

@socketio.on('disconnect', namespace='/government')
def handle_government_disconnect():
    print("[GOVERNMENT] Client disconnected")

# -------------------- MAIN ENTRY POINT --------------------
if __name__ == '__main__':
    # Start TTS worker threads for each assistant
    print("Starting TTS worker threads...")
    
    # Legal assistant TTS worker
    legal_tts_thread = threading.Thread(
        target=process_tts, 
        args=('/legal', legal_tts_queue, lambda: legal_token)
    )
    legal_tts_thread.daemon = True
    legal_tts_thread.start()
    
    # Medical assistant TTS worker
    medical_tts_thread = threading.Thread(
        target=process_tts, 
        args=('/medical', medical_tts_queue, lambda: medical_token)
    )
    medical_tts_thread.daemon = True
    medical_tts_thread.start()
    
    # Government assistant TTS worker
    government_tts_thread = threading.Thread(
        target=process_tts, 
        args=('/government', government_tts_queue, lambda: government_token)
    )
    government_tts_thread.daemon = True
    government_tts_thread.start()
    
    dummy_dataset_usage()
    print("Starting Combined Assistant Web App...")
    socketio.run(app, debug=True, port=5005)