# FitMirror AI Try-On Integration (Flutter + FastAPI)

This project is structured specifically for a **Flutter-based app** with a lightweight Python backend.

## Project structure

- `lib/services/api_service.dart` → Flutter service used by your app UI.
- `backend/main.py` → FastAPI backend that calls Replicate AI model.
- `backend/requirements.txt` → Python dependencies.
- `backend/.env.example` → environment template.

---

## 1) Get a free Replicate API token

1. Sign up or log in at [replicate.com](https://replicate.com).
2. Open your API tokens page.
3. Create a token and copy it.
4. In `backend/`, copy `.env.example` to `.env` and set:

```env
REPLICATE_API_TOKEN=your_actual_token
```

---

## 2) Install backend dependencies

From `backend/`:

```bash
pip install -r requirements.txt
```

---

## 3) Run the backend

From `backend/`:

```bash
uvicorn main:app --reload
```

Endpoint:

- `POST /api/tryon`

---

## 4) Update backend URL in Flutter

In `lib/services/api_service.dart`, change:

- `https://your-backend.com`

to your running backend URL, e.g.:

- `http://127.0.0.1:8000`

For real-device testing, use your machine LAN IP, for example:

- `http://192.168.1.10:8000`

---

## 5) Flutter usage example

```dart
final apiService = ApiService(backendUrl: 'http://127.0.0.1:8000');

Future<void> generateTryOn(File personImage, String clothingInput) async {
  try {
    final resultUrl = await apiService.tryOnClothes(personImage, clothingInput);
    // Show in UI with Image.network(resultUrl)
  } catch (e) {
    // Show snackbar/dialog with error message
  }
}
```

`clothingInput` can be either:
- an image URL (`https://...jpg`)
- a base64 image string

---

## Practical Flutter development tricks

1. **Use a loading state** while `tryOnClothes` runs (button disabled + spinner).
2. **Cache results** (store returned URL with the selected clothing id).
3. **Resize big photos** before upload to reduce latency and mobile data usage.
4. **Show friendly errors** from `ApiServiceException` using snackbar messages.
5. **Keep backend URL in config** (e.g., `--dart-define`) per dev/staging/prod.
6. **Retry transient failures** once for timeout/network errors.
7. **Persist history** of generated looks for better user retention.

---

## Backend notes

- `clothing_input` URL is downloaded server-side.
- Base64 inputs are decoded to temporary files.
- Replicate model used: `cuuupid/idm-vton`.
- Server returns:

```json
{ "result_url": "https://..." }
```
