import logging
from asgiref.sync import async_to_sync
from channels.layers import get_channel_layer

logger = logging.getLogger(__name__)


def broadcast_ticket_update(ticket_id, event_type, payload):
    """
    Broadcasts real-time events to both:
    1. The specific ticket channel: 'ticket_<ticket_id>'
    2. The garage global dashboard channel: 'garage_dashboard'
    """
    try:
        channel_layer = get_channel_layer()
        if not channel_layer:
            return

        message = {
            'type': 'ticket_event',
            'event': event_type,
            'ticket_id': str(ticket_id),
            'payload': payload,
        }

        # Send to specific ticket group
        async_to_sync(channel_layer.group_send)(
            f"ticket_{ticket_id}",
            message
        )

        # Send to garage dashboard group
        async_to_sync(channel_layer.group_send)(
            "garage_dashboard",
            message
        )
        logger.info(f"WebSocket broadcast sent for ticket {ticket_id}: {event_type}")
    except Exception as e:
        logger.warning(f"Failed to broadcast WebSocket message: {e}")
