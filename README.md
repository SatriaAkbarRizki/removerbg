# removerbg

A web application to remove image backgrounds automatically using AI local withoud lose quality image, i create this website because not like remove bg lose quality my image so i create this and libray [rembg](https://github.com/danielgatis/rembg)

## Quick Start (Docker)

The easiest way to run the entire stack (Frontend & Backend) is using Docker Compose.

1. **Build and start the containers:**

   ```bash
   docker-compose up --build -d
   ```

2. **Access the application:**
   - **Frontend:** [http://localhost:5173](http://localhost:5173)
   - **Backend API:** [http://localhost:5000](http://localhost:5000)

3. **Stop the services:**
   ```bash
   docker-compose down
   ```

---

## Project Structure

- `src/`: Vue 3 frontend application.
- `backend/`: FastAPI backend service for image processing.
- `docker-compose.yml`: Orchestrates both services.

---

## Tech Stack

- **Frontend:** Vue 3, Vite, TypeScript.
- **Backend:** FastAPI, Python.
- **AI Core:** [rembg](https://github.com/danielgatis/rembg) - A powerful library to remove image backgrounds using U2-Net.

---

## Local Development (Manual Setup)

If you prefer to run the services individually without Docker:

### Frontend (Vue 3 + Vite)

```bash
# Install dependencies
npm install

# Run development server
npm run dev
```

### Backend (Python + FastAPI)

```bash
cd backend

# Create and activate virtual environment
python -m venv .venv
source .venv/bin/activate  # Windows: .venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Run the server
python server.py
```

---

## API Documentation

### Remove Background

- **Endpoint**: `POST /api/remove`
- **Content-Type**: `multipart/form-data`
- **Payload**: `file` (Image)
- **Response**: PNG image with background removed.
