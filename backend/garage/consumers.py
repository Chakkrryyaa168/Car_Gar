import json
import logging
from channels.generic.websocket import AsyncWebsocketConsumer

logger = logging.getLogger(__name__)


class TicketConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        self.ticket_id = self.scope['url_route']['kwargs'].get('ticket_id')
        if self.ticket_id:
            self.group_name = f"ticket_{self.ticket_id}"
            await self.channel_layer.group_add(self.group_name, self.channel_name)
        else:
            self.group_name = "garage_dashboard"
            await self.channel_layer.group_add(self.group_name, self.channel_name)

        await self.accept()
        logger.info(f"WebSocket client connected to {self.group_name}")
        await self.send(text_data=json.dumps({
            'type': 'connection_established',
            'channel': self.group_name,
            'message': 'Connected to Car Garage live tracking socket.'
        }))

    async def disconnect(self, close_code):
        if hasattr(self, 'group_name'):
            await self.channel_layer.group_discard(self.group_name, self.channel_name)
            logger.info(f"WebSocket client disconnected from {self.group_name}")

    async def receive(self, text_data=None, bytes_data=None):
        try:
            data = json.loads(text_data)
            action = data.get('action')
            if action == 'ping':
                await self.send(text_data=json.dumps({'type': 'pong'}))
        except Exception as e:
            logger.error(f"Error handling websocket client message: {e}")

    async def ticket_event(self, event):
        """
        Handler for messages broadcasted to the group.
        """
        await self.send(text_data=json.dumps({
            'type': event.get('event'),
            'ticket_id': event.get('ticket_id'),
            'payload': event.get('payload'),
        }))
