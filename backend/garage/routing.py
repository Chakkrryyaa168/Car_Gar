from django.urls import re_path
from garage import consumers

websocket_urlpatterns = [
    re_path(r'^ws/tickets/(?P<ticket_id>[0-9a-fA-F-]+)/$', consumers.TicketConsumer.as_asgi()),
    re_path(r'^ws/dashboard/$', consumers.TicketConsumer.as_asgi()),
    re_path(r'^ws/tickets/$', consumers.TicketConsumer.as_asgi()),
]
