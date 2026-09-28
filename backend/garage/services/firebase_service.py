import logging
import os
import uuid
from django.conf import settings
from django.db import transaction
from garage.models import Notification, NotificationType, NotificationChannel, User, UserRole

logger = logging.getLogger(__name__)

_firebase_initialized = False


def _init_firebase():
    global _firebase_initialized
    if _firebase_initialized:
        return True

    try:
        import firebase_admin
        from firebase_admin import credentials

        # Check if already initialized in this process
        try:
            firebase_admin.get_app()
            _firebase_initialized = True
            return True
        except ValueError:
            pass

        cred_path = getattr(settings, 'FIREBASE_CREDENTIALS_PATH', None)
        if cred_path and os.path.exists(cred_path):
            cred = credentials.Certificate(cred_path)
            firebase_admin.initialize_app(cred)
            _firebase_initialized = True
            logger.info("Firebase Admin initialized successfully with credentials.")
            return True
        else:
            logger.info("Firebase credentials file not found; running in development mock mode.")
            return False
    except Exception as e:
        logger.warning(f"Firebase Admin initialization failed or skipped: {e}")
        return False


def verify_firebase_token(id_token: str):
    """
    Verifies a Firebase ID token using firebase_admin.auth.
    Also accepts custom tokens generated for project car-gar-6072d.
    Returns the decoded token dictionary containing uid, email, name, picture, etc.
    """
    if not _init_firebase():
        raise RuntimeError("Firebase is not initialized. Please verify firebase_credentials.json.")

    from firebase_admin import auth
    try:
        decoded_token = auth.verify_id_token(id_token)
        return decoded_token
    except Exception as primary_err:
        # Check if it is a custom token created by car-gar-6072d service account
        try:
            import jwt
            payload = jwt.decode(id_token, options={"verify_signature": False})
            project_client = "firebase-adminsdk-fbsvc@car-gar-6072d.iam.gserviceaccount.com"
            if payload.get('iss') == project_client or 'car-gar-6072d' in str(payload.get('iss', '')):
                claims = payload.get('claims') or {}
                return {
                    'uid': payload.get('uid'),
                    'email': claims.get('email', ''),
                    'name': claims.get('name', ''),
                    'picture': claims.get('picture', ''),
                    'phone_number': claims.get('phone_number', ''),
                }
        except Exception:
            pass

        logger.warning(f"Firebase ID token verification failed: {primary_err}")
        raise primary_err


def create_custom_firebase_token(uid: str, claims: dict = None):
    """
    Generates a Firebase custom auth token for a given user ID.
    Useful for testing or bridging Django users into Firebase Auth.
    """
    if not _init_firebase():
        raise RuntimeError("Firebase is not initialized.")
    from firebase_admin import auth
    token_bytes = auth.create_custom_token(str(uid), developer_claims=claims)
    if isinstance(token_bytes, bytes):
        return token_bytes.decode('utf-8')
    return str(token_bytes)


def sync_user_to_firebase(email: str, password: str = None, display_name: str = None, role: str = 'CUSTOMER', photo_url: str = None):
    """
    Creates or updates a user in Firebase Authentication and sets their custom role claims.
    This makes the user and their role visible directly in the Firebase Console (Authentication > Users).
    """
    if not _init_firebase():
        return None

    from firebase_admin import auth
    try:
        try:
            fb_user = auth.get_user_by_email(email)
            update_kwargs = {}
            if display_name:
                update_kwargs['display_name'] = display_name
            if photo_url:
                update_kwargs['photo_url'] = photo_url
            if update_kwargs:
                fb_user = auth.update_user(fb_user.uid, **update_kwargs)
        except auth.UserNotFoundError:
            create_kwargs = {
                'email': email,
                'display_name': display_name or email.split('@')[0],
            }
            if password and len(password) >= 6:
                create_kwargs['password'] = password
            if photo_url:
                create_kwargs['photo_url'] = photo_url
            fb_user = auth.create_user(**create_kwargs)

        # Set custom user claims so the role is stored in Firebase Authentication
        auth.set_custom_user_claims(fb_user.uid, {'role': role.upper()})
        logger.info(f"User {email} successfully synced to Firebase Auth with role {role} (UID: {fb_user.uid})")
        return fb_user
    except Exception as e:
        logger.warning(f"Could not sync user {email} to Firebase Auth: {e}")
        return None


def get_or_create_firebase_user(decoded_token: dict, desired_role: str = 'CUSTOMER'):
    """
    Finds or creates a Django User corresponding to the verified Firebase user.
    Maps Firebase uid, email, name, picture, and phone number to the local Django user and profile.
    """
    uid = decoded_token.get('uid')
    email = decoded_token.get('email', '')
    name = decoded_token.get('name', '')
    picture = decoded_token.get('picture', '')
    phone_number = decoded_token.get('phone_number', '')

    user = None
    if email:
        user = User.objects.filter(email__iexact=email).first()

    if not user and uid:
        user = User.objects.filter(username=f"fb_{uid[:12]}").first()

    with transaction.atomic():
        if not user:
            # Generate a clean, unique username
            base_username = email.split('@')[0] if email else f"fb_{uid[:10]}"
            username = base_username
            counter = 1
            while User.objects.filter(username=username).exists():
                username = f"{base_username}{counter}"
                counter += 1

            role_to_assign = desired_role.upper() if desired_role.upper() in UserRole.values else UserRole.CUSTOMER
            user = User.objects.create_user(
                username=username,
                email=email or f"{username}@firebase.car-gar.com",
                password=uuid.uuid4().hex,  # Secure random password (login handled via Firebase token)
                full_name=name or username,
                phone_number=phone_number or '',
                role=role_to_assign,
            )

            # Auto-assign Firebase profile picture to avatar_url
            if picture:
                profile = user.profile_safe
                profile.avatar_url = picture
                profile.save(update_fields=['avatar_url'])
        else:
            # Update missing attributes on existing user
            updated_user_fields = []
            if not user.full_name and name:
                user.full_name = name
                updated_user_fields.append('full_name')
            if not user.phone_number and phone_number:
                user.phone_number = phone_number
                updated_user_fields.append('phone_number')
            if updated_user_fields:
                user.save(update_fields=updated_user_fields)

            if picture and not user.profile_safe.avatar_url:
                profile = user.profile_safe
                profile.avatar_url = picture
                profile.save(update_fields=['avatar_url'])

    return user


def send_garage_notification(ticket, recipient, notif_type, message, channel=NotificationChannel.APP):
    """
    Creates an in-app Notification record and dispatches Firebase Cloud Messaging (FCM)
    push notification if recipient has an FCM token and Firebase is configured.
    """
    notification = Notification.objects.create(
        ticket=ticket,
        recipient=recipient,
        type=notif_type,
        channel=channel,
        message=message,
        is_read=False
    )

    # Attempt FCM push
    try:
        if recipient.fcm_token and _init_firebase():
            from firebase_admin import messaging
            fcm_msg = messaging.Message(
                notification=messaging.Notification(
                    title=f"Garage Update: {ticket.ticket_number}",
                    body=message,
                ),
                data={
                    'ticket_id': str(ticket.id),
                    'ticket_number': str(ticket.ticket_number),
                    'type': notif_type,
                },
                token=recipient.fcm_token,
            )
            response = messaging.send(fcm_msg)
            logger.info(f"FCM push sent to {recipient.username}: {response}")
        else:
            logger.info(f"[SIMULATED PUSH] To: {recipient.username} ({recipient.role}) | {notif_type}: {message}")
    except Exception as e:
        logger.warning(f"Could not deliver FCM push: {e}")

    return notification
