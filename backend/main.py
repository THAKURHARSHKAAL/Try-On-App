import base64
import os
import tempfile
from typing import Optional
from urllib.parse import urlparse

import httpx
import replicate
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

load_dotenv()

app = FastAPI(title='FitMirror AI Try-On Backend')

app.add_middleware(
    CORSMiddleware,
    allow_origins=['*'],
    allow_credentials=True,
    allow_methods=['*'],
    allow_headers=['*'],
)


class TryOnRequest(BaseModel):
    person_image: str
    clothing_input: str


def is_url(value: str) -> bool:
    parsed = urlparse(value)
    return parsed.scheme in {'http', 'https'} and bool(parsed.netloc)


def decode_base64_to_temp_file(image_b64: str, suffix: str = '.png') -> str:
    try:
      image_bytes = base64.b64decode(image_b64, validate=True)
    except Exception as exc:
        raise HTTPException(status_code=400, detail=f'Invalid base64 image input: {exc}') from exc

    tmp = tempfile.NamedTemporaryFile(delete=False, suffix=suffix)
    tmp.write(image_bytes)
    tmp.flush()
    tmp.close()
    return tmp.name


async def download_image_to_temp_file(image_url: str, suffix: str = '.png') -> str:
    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.get(image_url)
            response.raise_for_status()
    except httpx.HTTPError as exc:
        raise HTTPException(status_code=400, detail=f'Failed to download clothing image URL: {exc}') from exc

    tmp = tempfile.NamedTemporaryFile(delete=False, suffix=suffix)
    tmp.write(response.content)
    tmp.flush()
    tmp.close()
    return tmp.name


@app.post('/api/tryon')
async def try_on(request: TryOnRequest):
    api_token = os.getenv('REPLICATE_API_TOKEN')
    if not api_token:
        raise HTTPException(
            status_code=500,
            detail='REPLICATE_API_TOKEN is not configured in environment variables.',
        )

    person_path: Optional[str] = None
    clothing_path: Optional[str] = None

    try:
        person_path = decode_base64_to_temp_file(request.person_image)

        if is_url(request.clothing_input):
            clothing_path = await download_image_to_temp_file(request.clothing_input)
        else:
            clothing_path = decode_base64_to_temp_file(request.clothing_input)

        with open(person_path, 'rb') as person_file, open(clothing_path, 'rb') as clothing_file:
            output = replicate.run(
                'cuuupid/idm-vton',
                input={
                    'human_img': person_file,
                    'garm_img': clothing_file,
                    'garment_des': 'clothing item',
                },
            )

        output_image_url = output[0] if isinstance(output, list) and output else output
        if not output_image_url:
            raise HTTPException(status_code=502, detail='Replicate returned empty output.')

        return {'result_url': str(output_image_url)}
    except HTTPException:
        raise
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f'Try-on generation failed: {exc}') from exc
    finally:
        for path in (person_path, clothing_path):
            if path and os.path.exists(path):
                os.remove(path)
