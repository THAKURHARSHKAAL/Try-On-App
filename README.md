# FitMirror AI Try-On Integration

This repository includes a Flutter API service and a FastAPI backend for AI try-on using Replicate.

## 1) Get a free Replicate API token

1. Sign up or log in at [replicate.com](https://replicate.com).
2. Open your account API tokens page.
3. Create a token and copy it.
4. In `backend/`, copy `.env.example` to `.env` and set:
   - `REPLICATE_API_TOKEN=your_actual_token`

## 2) Install backend dependencies

From the `backend/` folder, run:

```bash
pip install -r requirements.txt
```

## 3) Run the backend

From the `backend/` folder, run:

```bash
uvicorn main:app --reload
```

The try-on endpoint will be available at:

- `POST /api/tryon`

## 4) Update backend URL in Flutter

In `lib/services/api_service.dart`, update the default backend URL from:

- `https://your-backend.com`

to your running backend host (for example, `http://127.0.0.1:8000` for local testing).
