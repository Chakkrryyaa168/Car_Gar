import logging
import os
from django.conf import settings
from garage.models import Notification, NotificationType, NotificationChannel

logger = logging.getLogger(__name__)

_firebase_initialized = False


def _init_firebase():
    global _firebase_initialized
    if _firebase_initialized:
        return True

    try:
        import firebase_admin
        from firebase_admin import credentials

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
