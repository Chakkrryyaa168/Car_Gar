from django.urls import path, include
from rest_framework.routers import DefaultRouter
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView

from garage.views import (
    VehicleViewSet, ServiceTicketViewSet, TicketItemViewSet,
    TicketPhotoViewSet, InventoryViewSet, StockMovementViewSet,
    InvoiceViewSet, NotificationViewSet, demo_login_view,
    login_view, register_view, firebase_login_view, firebase_custom_token_view,
    current_user_view, user_profile_view, update_fcm_token, dashboard_stats_view,
    StaffViewSet, TicketStatusLogViewSet, upload_image_view, customer_lookup_view
)

router = DefaultRouter()
router.register(r'vehicles', VehicleViewSet, basename='vehicle')
router.register(r'tickets', ServiceTicketViewSet, basename='ticket')
router.register(r'ticket-items', TicketItemViewSet, basename='ticket-item')
router.register(r'photos', TicketPhotoViewSet, basename='photo')
router.register(r'inventory', InventoryViewSet, basename='inventory')
router.register(r'stock-movements', StockMovementViewSet, basename='stock-movement')
router.register(r'invoices', InvoiceViewSet, basename='invoice')
router.register(r'notifications', NotificationViewSet, basename='notification')
router.register(r'staff', StaffViewSet, basename='staff')
router.register(r'audit-logs', TicketStatusLogViewSet, basename='audit-log')

urlpatterns = [
    # Auth endpoints
    path('auth/demo-login/', demo_login_view, name='demo-login'),
    path('auth/login/', login_view, name='login'),
    path('auth/firebase-login/', firebase_login_view, name='firebase-login'),
    path('auth/firebase-token/', firebase_custom_token_view, name='firebase-token'),
    path('auth/register/', register_view, name='register'),
    path('auth/token/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('auth/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('auth/me/', current_user_view, name='current-user'),
    path('auth/profile/', user_profile_view, name='user-profile'),
    path('profile/', user_profile_view, name='profile-direct'),
    path('auth/fcm-token/', update_fcm_token, name='update-fcm-token'),

    # Direct Cloudinary Image Upload
    path('upload/', upload_image_view, name='upload-image'),

    # Customer lookup by unique ID / phone / plate
    path('customers/lookup/', customer_lookup_view, name='customer-lookup'),

    # Dashboard metrics
    path('dashboard/stats/', dashboard_stats_view, name='dashboard-stats'),

    # Router endpoints
    path('', include(router.urls)),
]
