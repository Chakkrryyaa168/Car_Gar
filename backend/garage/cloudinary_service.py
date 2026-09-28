import os
import uuid
import logging
from django.conf import settings
from django.core.files.storage import default_storage

logger = logging.getLogger(__name__)


def upload_image(file_or_bytes, folder='car_gar/ticket_photos', filename=None):
    """
    Upload an image file (e.g. Django UploadedFile, BytesIO, or file-like object)
    to Cloudinary under the specified folder.
    Falls back to Django default_storage if Cloudinary is unavailable.
    Returns the public URL (https://res.cloudinary.com/... or relative/absolute media URL).
    """
    # 1. Attempt Cloudinary upload
    try:
        import cloudinary
        import cloudinary.uploader

        c_name = getattr(settings, 'CLOUDINARY_STORAGE', {}).get('CLOUD_NAME')
        if c_name and c_name != 'demo':
            res = cloudinary.uploader.upload(
                file_or_bytes,
                folder=folder,
                resource_type='image',
            )
            url = res.get('secure_url') or res.get('url')
            if url:
                logger.info(f"Successfully uploaded image to Cloudinary: {url}")
                return url
    except Exception as e:
        logger.warning(f"Cloudinary upload failed, falling back to local storage: {e}")

    # 2. Local fallback via Django storage
    ext = '.jpg'
    if filename:
        ext = os.path.splitext(filename)[1] or '.jpg'
    elif hasattr(file_or_bytes, 'name') and file_or_bytes.name:
        ext = os.path.splitext(file_or_bytes.name)[1] or '.jpg'

    storage_path = f"{folder.strip('/')}/{uuid.uuid4().hex}{ext}"
    if hasattr(file_or_bytes, 'seek'):
        file_or_bytes.seek(0)
    saved_path = default_storage.save(storage_path, file_or_bytes)
    return f"{settings.MEDIA_URL.rstrip('/')}/{saved_path}"


def upload_base64_image(base64_str, folder='car_gar/ticket_photos'):
    """
    Upload a base64 encoded image string to Cloudinary.
    Falls back to Django default_storage if Cloudinary fails.
    """
    raw_b64 = base64_str
    if ',' in base64_str:
        raw_b64 = base64_str.split(',', 1)[1]

    # 1. Attempt Cloudinary upload with data URI
    try:
        import cloudinary
        import cloudinary.uploader

        c_name = getattr(settings, 'CLOUDINARY_STORAGE', {}).get('CLOUD_NAME')
        if c_name and c_name != 'demo':
            data_uri = f"data:image/jpeg;base64,{raw_b64}"
            res = cloudinary.uploader.upload(
                data_uri,
                folder=folder,
                resource_type='image',
            )
            url = res.get('secure_url') or res.get('url')
            if url:
                logger.info(f"Successfully uploaded base64 image to Cloudinary: {url}")
                return url
    except Exception as e:
        logger.warning(f"Cloudinary base64 upload failed, falling back to local: {e}")

    # 2. Local fallback
    import base64
    from django.core.files.base import ContentFile
    decoded = ContentFile(base64.b64decode(raw_b64))
    return upload_image(decoded, folder=folder, filename='image.jpg')
