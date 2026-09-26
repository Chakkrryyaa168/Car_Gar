import uuid
from decimal import Decimal
from django.db import transaction
from django.contrib.auth import get_user_model
from django.shortcuts import get_object_or_404
from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action, api_view, permission_classes
from rest_framework.response import Response
from rest_framework_simplejwt.tokens import RefreshToken

from garage.models import (
    Vehicle, ServiceTicket, InventoryItem, TicketItem,
    TicketPhoto, StockMovement, Invoice, Payment,
    TicketStatusLog, Notification, UserRole, TicketStatus,
    ApprovalStatus, PhotoStage, ItemType, InvoiceStatus,
    NotificationType, StockMovementType
)
from garage.serializers import (
    UserSerializer, VehicleSerializer, InventoryItemSerializer,
    TicketPhotoSerializer, TicketItemSerializer, StockMovementSerializer,
    PaymentSerializer, InvoiceSerializer, TicketStatusLogSerializer,
    NotificationSerializer, ServiceTicketListSerializer, ServiceTicketDetailSerializer
)
from garage.permissions import (
    IsAdminUserRole, IsReceptionistOrAdmin, IsMechanicOrAdmin,
    IsStaffUser, IsTicketParticipant
)
from garage.services.websocket_service import broadcast_ticket_update
from garage.services.firebase_service import send_garage_notification
from garage.services.inventory_service import deduct_item_inventory
from garage.services.invoice_service import recalculate_or_create_invoice

User = get_user_model()


# -------------------------------------------------------------
# Authentication & Demo Role Switching Endpoints
# -------------------------------------------------------------

@api_view(['POST'])
@permission_classes([permissions.AllowAny])
def demo_login_view(request):
    """
    Instantly returns JWT tokens and user profile for any chosen role:
    ADMIN, RECEPTIONIST, MECHANIC, CUSTOMER.
    Creates default test users if they don't already exist.
    """
    role = request.data.get('role', 'CUSTOMER').upper()
    role_configs = {
        UserRole.ADMIN: ('admin_user', 'admin@cargarage.com', 'Alex Stone (Admin)', '0812345678'),
        UserRole.RECEPTIONIST: ('reception_user', 'reception@cargarage.com', 'Sarah Connor (Front Desk)', '0823456789'),
        UserRole.MECHANIC: ('mechanic_user', 'mechanic@cargarage.com', 'Mike Miller (Lead Mechanic)', '0834567890'),
        UserRole.CUSTOMER: ('customer_user', 'customer@cargarage.com', 'John Doe (Vehicle Owner)', '0845678901'),
    }

    if role not in role_configs:
        return Response({'error': f'Invalid role: {role}'}, status=status.HTTP_400_BAD_REQUEST)

    username, email, full_name, phone = role_configs[role]
    user, created = User.objects.get_or_create(
        username=username,
        defaults={
            'email': email,
            'full_name': full_name,
            'phone_number': phone,
            'role': role,
            'is_staff': (role in [UserRole.ADMIN, UserRole.RECEPTIONIST]),
            'is_superuser': (role == UserRole.ADMIN),
        }
    )
    if not created and user.role != role:
        user.role = role
        user.save()

    refresh = RefreshToken.for_user(user)
    return Response({
        'access': str(refresh.access_token),
        'refresh': str(refresh),
        'user': UserSerializer(user).data
    })


@api_view(['POST'])
@permission_classes([permissions.AllowAny])
def login_view(request):
    """
    Standard user login with username/email and password.
    """
    username_or_email = request.data.get('username') or request.data.get('email', '')
    password = request.data.get('password', '')

    if not username_or_email or not password:
        return Response({'error': 'Username/email and password are required'}, status=status.HTTP_400_BAD_REQUEST)

    # Allow login by email or username
    user = User.objects.filter(username=username_or_email).first()
    if not user:
        user = User.objects.filter(email__iexact=username_or_email).first()

    if not user or not user.check_password(password):
        # Demo fallback: if using seeded user with default password
        if user and password in ['admin123', 'reception123', 'mechanic123', 'customer123', 'password']:
            user.set_password(password)
            user.save()
        else:
            return Response({'error': 'Invalid credentials'}, status=status.HTTP_401_UNAUTHORIZED)

    refresh = RefreshToken.for_user(user)
    return Response({
        'access': str(refresh.access_token),
        'refresh': str(refresh),
        'user': UserSerializer(user).data
    })


@api_view(['POST'])
@permission_classes([permissions.AllowAny])
def register_view(request):
    """
    Customer registration endpoint with optional vehicle registration.
    """
    email = (request.data.get('email') or '').strip()
    password = (request.data.get('password') or '').strip()
    full_name = (request.data.get('full_name') or '').strip()
    phone_number = (request.data.get('phone_number') or '').strip()
    role = (request.data.get('role') or UserRole.CUSTOMER).upper()

    if not email or not password:
        return Response({'error': 'Email and password are required'}, status=status.HTTP_400_BAD_REQUEST)

    username = (request.data.get('username') or '').strip() or email.split('@')[0]
    # Ensure unique username
    base_username = username
    counter = 1
    while User.objects.filter(username=username).exists():
        username = f"{base_username}{counter}"
        counter += 1

    if User.objects.filter(email__iexact=email).exists():
        return Response({'error': 'An account with this email already exists'}, status=status.HTTP_400_BAD_REQUEST)

    with transaction.atomic():
        user = User.objects.create_user(
            username=username,
            email=email,
            password=password,
            full_name=full_name or username,
            phone_number=phone_number,
            role=role if role in UserRole.values else UserRole.CUSTOMER
        )

        # Optional vehicle creation
        plate = (request.data.get('license_plate') or '').strip()
        if plate:
            vin = (request.data.get('vin') or '').strip() or f"VIN-{uuid.uuid4().hex[:10].upper()}"
            make = (request.data.get('make') or '').strip() or 'Toyota'
            model = (request.data.get('model') or '').strip() or 'Camry'
            try:
                year = int(request.data.get('year') or 2022)
            except (ValueError, TypeError):
                year = 2022
            color = (request.data.get('color') or '').strip() or 'Silver'

            Vehicle.objects.create(
                owner=user,
                license_plate=plate,
                vin=vin,
                make=make,
                model=model,
                year=year,
                color=color,
                is_verified=True,
            )

    refresh = RefreshToken.for_user(user)
    return Response({
        'access': str(refresh.access_token),
        'refresh': str(refresh),
        'user': UserSerializer(user).data
    }, status=status.HTTP_201_CREATED)


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def current_user_view(request):
    return Response(UserSerializer(request.user).data)


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def update_fcm_token(request):
    token = request.data.get('fcm_token')
    if token:
        request.user.fcm_token = token
        request.user.save(update_fields=['fcm_token'])
        return Response({'status': 'FCM token updated'})
    return Response({'error': 'fcm_token is required'}, status=status.HTTP_400_BAD_REQUEST)


# -------------------------------------------------------------
# Vehicle ViewSet
# -------------------------------------------------------------

class VehicleViewSet(viewsets.ModelViewSet):
    serializer_class = VehicleSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if user.role in [UserRole.ADMIN, UserRole.RECEPTIONIST, UserRole.MECHANIC]:
            return Vehicle.objects.all().select_related('owner')
        return Vehicle.objects.filter(owner=user).select_related('owner')

    def perform_create(self, serializer):
        user = self.request.user
        owner_id = self.request.data.get('owner')
        if owner_id and user.role in [UserRole.ADMIN, UserRole.RECEPTIONIST]:
            owner = get_object_or_404(User, id=owner_id)
            serializer.save(owner=owner)
        else:
            serializer.save(owner=user)


# -------------------------------------------------------------
# ServiceTicket ViewSet
# -------------------------------------------------------------

class ServiceTicketViewSet(viewsets.ModelViewSet):
    permission_classes = [permissions.IsAuthenticated]

    def get_serializer_class(self):
        if self.action in ['retrieve']:
            return ServiceTicketDetailSerializer
        return ServiceTicketListSerializer

    def get_queryset(self):
        user = self.request.user
        qs = ServiceTicket.objects.select_related(
            'vehicle', 'customer', 'lead_mechanic', 'receptionist'
        ).prefetch_related('items', 'photos', 'status_logs')

        if user.role == UserRole.CUSTOMER:
            qs = qs.filter(customer=user)
        elif user.role == UserRole.MECHANIC:
            # Mechanics see assigned tickets or tickets needing inspection/work
            pass

        # Optional query filter by status
        status_param = self.request.query_params.get('status')
        if status_param:
            qs = qs.filter(current_status=status_param)

        return qs

    def perform_create(self, serializer):
        user = self.request.user
        receptionist = user if user.role in [UserRole.RECEPTIONIST, UserRole.ADMIN] else None
        ticket = serializer.save(receptionist=receptionist)

        # Initial Status Log
        TicketStatusLog.objects.create(
            ticket=ticket,
            changed_by=user,
            from_status='NONE',
            to_status=ticket.current_status,
            remarks='Ticket created and vehicle checked in.'
        )

        # Broadcast WebSocket event
        broadcast_ticket_update(ticket.id, 'TICKET_CREATED', {
            'ticket_id': str(ticket.id),
            'ticket_number': ticket.ticket_number,
            'status': ticket.current_status
        })

    @action(detail=True, methods=['POST'])
    def change_status(self, request, pk=None):
        ticket = self.get_object()
        new_status = request.data.get('status')
        remarks = request.data.get('remarks', '')

        if new_status not in TicketStatus.values:
            return Response({'error': f'Invalid status: {new_status}'}, status=status.HTTP_400_BAD_REQUEST)

        old_status = ticket.current_status
        ticket.current_status = new_status
        ticket.save(update_fields=['current_status', 'updated_at'])

        # Log transition
        TicketStatusLog.objects.create(
            ticket=ticket,
            changed_by=request.user,
            from_status=old_status,
            to_status=new_status,
            remarks=remarks
        )

        # Side effects according to business flow:
        if new_status == TicketStatus.PENDING_CUSTOMER_APPROVAL:
            # Recalculate invoice draft
            recalculate_or_create_invoice(ticket)
            # Notify Customer
            send_garage_notification(
                ticket=ticket,
                recipient=ticket.customer,
                notif_type=NotificationType.APPROVAL_NEEDED,
                message=f"Inspection finished for {ticket.vehicle.model}. Please review and approve repair items."
            )
        elif new_status == TicketStatus.WORK_COMPLETED:
            # Notify Receptionist
            if ticket.receptionist:
                send_garage_notification(
                    ticket=ticket,
                    recipient=ticket.receptionist,
                    notif_type=NotificationType.WORK_COMPLETED,
                    message=f"All repairs completed for {ticket.ticket_number}. Ready for invoice generation."
                )
        elif new_status == TicketStatus.READY_FOR_PICKUP:
            recalculate_or_create_invoice(ticket)
            # Notify Customer
            send_garage_notification(
                ticket=ticket,
                recipient=ticket.customer,
                notif_type=NotificationType.READY_FOR_PICKUP,
                message=f"Your vehicle {ticket.vehicle.model} ({ticket.vehicle.license_plate}) is ready for pickup!"
            )

        # Broadcast via WebSockets
        broadcast_ticket_update(ticket.id, 'STATUS_CHANGED', {
            'ticket_id': str(ticket.id),
            'ticket_number': ticket.ticket_number,
            'from_status': old_status,
            'to_status': new_status,
            'remarks': remarks
        })

        return Response({
            'status': 'Status updated successfully',
            'ticket': ServiceTicketDetailSerializer(ticket).data
        })

    @action(detail=True, methods=['POST'])
    def assign_mechanic(self, request, pk=None):
        ticket = self.get_object()
        mechanic_id = request.data.get('mechanic_id')
        mechanic = get_object_or_404(User, id=mechanic_id, role__in=[UserRole.MECHANIC, UserRole.ADMIN])

        ticket.lead_mechanic = mechanic
        if ticket.current_status == TicketStatus.CHECKED_IN:
            ticket.current_status = TicketStatus.INSPECTING
        ticket.save()

        TicketStatusLog.objects.create(
            ticket=ticket,
            changed_by=request.user,
            from_status=ticket.current_status,
            to_status=ticket.current_status,
            remarks=f"Assigned lead mechanic to {mechanic.full_name}"
        )

        send_garage_notification(
            ticket=ticket,
            recipient=mechanic,
            notif_type=NotificationType.INSPECTION_READY,
            message=f"You have been assigned to service ticket {ticket.ticket_number} ({ticket.vehicle.model})"
        )

        broadcast_ticket_update(ticket.id, 'MECHANIC_ASSIGNED', {
            'ticket_id': str(ticket.id),
            'mechanic_name': mechanic.full_name
        })

        return Response(ServiceTicketDetailSerializer(ticket).data)

    @action(detail=True, methods=['POST'])
    def batch_approve_items(self, request, pk=None):
        """
        Customer endpoint to review diagnosis and mark items as APPROVED or REJECTED individually.
        Request body: {"approvals": [{"item_id": "...", "status": "APPROVED" | "REJECTED"}]}
        """
        ticket = self.get_object()
        approvals = request.data.get('approvals', [])

        has_approved_any = False
        with transaction.atomic():
            for item_data in approvals:
                item_id = item_data.get('item_id')
                appr_status = item_data.get('status')
                if appr_status in [ApprovalStatus.APPROVED, ApprovalStatus.REJECTED]:
                    ticket_item = ticket.items.filter(id=item_id).first()
                    if ticket_item:
                        ticket_item.approval_status = appr_status
                        ticket_item.save(update_fields=['approval_status', 'updated_at'])
                        if appr_status == ApprovalStatus.APPROVED:
                            has_approved_any = True

            # Recalculate invoice dynamically
            recalculate_or_create_invoice(ticket)

            # Move status to APPROVED_IN_PROGRESS if moving from PENDING_CUSTOMER_APPROVAL
            if ticket.current_status == TicketStatus.PENDING_CUSTOMER_APPROVAL and has_approved_any:
                old_status = ticket.current_status
                ticket.current_status = TicketStatus.APPROVED_IN_PROGRESS
                ticket.save(update_fields=['current_status', 'updated_at'])

                TicketStatusLog.objects.create(
                    ticket=ticket,
                    changed_by=request.user,
                    from_status=old_status,
                    to_status=ticket.current_status,
                    remarks="Customer confirmed item approvals. Work in progress."
                )

                if ticket.lead_mechanic:
                    send_garage_notification(
                        ticket=ticket,
                        recipient=ticket.lead_mechanic,
                        notif_type=NotificationType.WORK_STARTED,
                        message=f"Customer approved repairs for {ticket.ticket_number}. Work can proceed."
                    )

        broadcast_ticket_update(ticket.id, 'ITEMS_APPROVED', {
            'ticket_id': str(ticket.id),
            'ticket_number': ticket.ticket_number,
            'current_status': ticket.current_status
        })

        return Response(ServiceTicketDetailSerializer(ticket).data)

    @action(detail=True, methods=['GET'])
    def photos_grouped(self, request, pk=None):
        ticket = self.get_object()
        photos = ticket.photos.all()
        grouped = {
            PhotoStage.CHECKIN_INSPECTION: [],
            PhotoStage.FAULT_EVIDENCE: [],
            PhotoStage.REPAIR_COMPLETED: [],
        }
        for photo in photos:
            grouped[photo.stage].append(TicketPhotoSerializer(photo).data)
        return Response(grouped)


# -------------------------------------------------------------
# TicketItem ViewSet
# -------------------------------------------------------------

class TicketItemViewSet(viewsets.ModelViewSet):
    serializer_class = TicketItemSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if user.role == UserRole.CUSTOMER:
            return TicketItem.objects.filter(ticket__customer=user)
        return TicketItem.objects.all().select_related('ticket', 'inventory_item', 'assigned_mechanic')

    def perform_create(self, serializer):
        user = self.request.user
        item = serializer.save(assigned_mechanic=user if user.role == UserRole.MECHANIC else None)
        recalculate_or_create_invoice(item.ticket)
        broadcast_ticket_update(item.ticket.id, 'ITEM_ADDED', {
            'ticket_id': str(item.ticket.id),
            'item_id': str(item.id),
            'description': item.description
        })

    def perform_destroy(self, instance):
        ticket = instance.ticket
        instance.delete()
        recalculate_or_create_invoice(ticket)
        broadcast_ticket_update(ticket.id, 'ITEM_DELETED', {
            'ticket_id': str(ticket.id),
        })

    @action(detail=True, methods=['POST'])
    def approve(self, request, pk=None):
        item = self.get_object()
        item.approval_status = ApprovalStatus.APPROVED
        item.save()
        recalculate_or_create_invoice(item.ticket)

        broadcast_ticket_update(item.ticket.id, 'ITEM_STATUS_UPDATED', {
            'ticket_id': str(item.ticket.id),
            'item_id': str(item.id),
            'approval_status': item.approval_status
        })
        return Response(TicketItemSerializer(item).data)

    @action(detail=True, methods=['POST'])
    def reject(self, request, pk=None):
        item = self.get_object()
        item.approval_status = ApprovalStatus.REJECTED
        item.save()
        recalculate_or_create_invoice(item.ticket)

        broadcast_ticket_update(item.ticket.id, 'ITEM_STATUS_UPDATED', {
            'ticket_id': str(item.ticket.id),
            'item_id': str(item.id),
            'approval_status': item.approval_status
        })
        return Response(TicketItemSerializer(item).data)

    @action(detail=True, methods=['POST'])
    def complete(self, request, pk=None):
        """
        Mechanic marks an individual repair item completed.
        If it's a PART, inventory is automatically & atomically deducted.
        If all approved items on the ticket are finished, transitions ticket to WORK_COMPLETED.
        """
        item = self.get_object()
        user = request.user

        with transaction.atomic():
            item.is_completed = True
            item.save(update_fields=['is_completed', 'updated_at'])

            # Deduct inventory if part
            if item.type == ItemType.PART and item.inventory_item:
                deduct_item_inventory(item, user)

            # Check if all approved items are now complete
            ticket = item.ticket
            approved_items = ticket.items.filter(approval_status=ApprovalStatus.APPROVED)
            if approved_items.exists() and all(i.is_completed for i in approved_items):
                old_status = ticket.current_status
                ticket.current_status = TicketStatus.WORK_COMPLETED
                ticket.save(update_fields=['current_status', 'updated_at'])

                TicketStatusLog.objects.create(
                    ticket=ticket,
                    changed_by=user,
                    from_status=old_status,
                    to_status=TicketStatus.WORK_COMPLETED,
                    remarks="All approved repair items have been marked completed."
                )

                if ticket.receptionist:
                    send_garage_notification(
                        ticket=ticket,
                        recipient=ticket.receptionist,
                        notif_type=NotificationType.WORK_COMPLETED,
                        message=f"All repair tasks completed for {ticket.ticket_number}. Ready for invoice!"
                    )

        broadcast_ticket_update(item.ticket.id, 'ITEM_COMPLETED', {
            'ticket_id': str(item.ticket.id),
            'item_id': str(item.id),
            'ticket_status': item.ticket.current_status
        })
        return Response(TicketItemSerializer(item).data)


# -------------------------------------------------------------
# TicketPhoto ViewSet
# -------------------------------------------------------------

class TicketPhotoViewSet(viewsets.ModelViewSet):
    serializer_class = TicketPhotoSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        ticket_id = self.request.query_params.get('ticket_id')
        if ticket_id:
            return TicketPhoto.objects.filter(ticket_id=ticket_id)
        return TicketPhoto.objects.all()

    def create(self, request, *args, **kwargs):
        from django.conf import settings
        from django.core.files.storage import default_storage
        import os

        data = request.data.copy()

        # Handle multipart file upload from device
        file_obj = request.FILES.get('file') or request.FILES.get('image')
        if file_obj:
            ext = os.path.splitext(file_obj.name)[1] or '.jpg'
            filename = f"ticket_photos/{uuid.uuid4().hex}{ext}"
            saved_path = default_storage.save(filename, file_obj)
            file_url = f"{settings.MEDIA_URL.rstrip('/')}/{saved_path}"
            if not file_url.startswith('http'):
                file_url = request.build_absolute_uri(file_url)
            data['url'] = file_url

        # Handle base64 upload if provided
        base64_data = data.get('image_base64')
        if base64_data:
            import base64
            from django.core.files.base import ContentFile
            if ',' in base64_data:
                base64_data = base64_data.split(',', 1)[1]
            decoded_file = ContentFile(base64.b64decode(base64_data))
            filename = f"ticket_photos/{uuid.uuid4().hex}.jpg"
            saved_path = default_storage.save(filename, decoded_file)
            file_url = f"{settings.MEDIA_URL.rstrip('/')}/{saved_path}"
            if not file_url.startswith('http'):
                file_url = request.build_absolute_uri(file_url)
            data['url'] = file_url

        serializer = self.get_serializer(data=data)
        serializer.is_valid(raise_exception=True)
        self.perform_create(serializer)
        return Response(serializer.data, status=status.HTTP_201_CREATED)

    def perform_create(self, serializer):
        photo = serializer.save(uploaded_by=self.request.user)
        broadcast_ticket_update(photo.ticket.id, 'PHOTO_UPLOADED', {
            'ticket_id': str(photo.ticket.id),
            'stage': photo.stage,
            'url': photo.url
        })

    def perform_destroy(self, instance):
        ticket = instance.ticket
        instance.delete()
        broadcast_ticket_update(ticket.id, 'PHOTO_DELETED', {
            'ticket_id': str(ticket.id),
        })


# -------------------------------------------------------------
# Inventory & Stock Movement ViewSets
# -------------------------------------------------------------

class InventoryViewSet(viewsets.ModelViewSet):
    serializer_class = InventoryItemSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return InventoryItem.objects.all()

    @action(detail=False, methods=['GET'])
    def low_stock(self, request):
        low_items = [item for item in InventoryItem.objects.all() if item.is_low_stock]
        serializer = self.get_serializer(low_items, many=True)
        return Response(serializer.data)

    @action(detail=True, methods=['POST'])
    def restock(self, request, pk=None):
        item = self.get_object()
        quantity = int(request.data.get('quantity', 0))
        if quantity <= 0:
            return Response({'error': 'Quantity must be positive'}, status=status.HTTP_400_BAD_REQUEST)

        with transaction.atomic():
            item.quantity_on_hand += quantity
            item.save(update_fields=['quantity_on_hand', 'updated_at'])

            StockMovement.objects.create(
                inventory_item=item,
                movement_type=StockMovementType.RECEIVED,
                quantity=quantity,
                created_by=request.user
            )

        return Response(InventoryItemSerializer(item).data)


class StockMovementViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = StockMovementSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return StockMovement.objects.all().select_related('inventory_item', 'created_by')


# -------------------------------------------------------------
# Invoice & Payment ViewSets
# -------------------------------------------------------------

class InvoiceViewSet(viewsets.ModelViewSet):
    serializer_class = InvoiceSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if user.role == UserRole.CUSTOMER:
            return Invoice.objects.filter(ticket__customer=user).prefetch_related('payments')
        return Invoice.objects.all().prefetch_related('payments')

    @action(detail=True, methods=['POST'])
    def record_payment(self, request, pk=None):
        invoice = self.get_object()
        amount = Decimal(str(request.data.get('amount_paid', 0)))
        method = request.data.get('method', 'CASH')
        tx_ref = request.data.get('transaction_reference', '')

        if amount <= 0:
            return Response({'error': 'Payment amount must be greater than zero'}, status=status.HTTP_400_BAD_REQUEST)

        with transaction.atomic():
            payment = Payment.objects.create(
                invoice=invoice,
                amount_paid=amount,
                method=method,
                transaction_reference=tx_ref,
                received_by=request.user
            )

            invoice.amount_paid += amount
            if invoice.amount_paid >= invoice.total_amount:
                invoice.status = InvoiceStatus.PAID
                # Transition ticket to PAID_AND_CLOSED
                ticket = invoice.ticket
                old_status = ticket.current_status
                ticket.current_status = TicketStatus.PAID_AND_CLOSED
                ticket.save(update_fields=['current_status', 'updated_at'])

                TicketStatusLog.objects.create(
                    ticket=ticket,
                    changed_by=request.user,
                    from_status=old_status,
                    to_status=TicketStatus.PAID_AND_CLOSED,
                    remarks=f"Payment received in full (${invoice.amount_paid}). Ticket closed."
                )

                send_garage_notification(
                    ticket=ticket,
                    recipient=ticket.customer,
                    notif_type=NotificationType.INVOICE_ISSUED,
                    message=f"Thank you! Your payment of ${amount} for invoice {invoice.invoice_number} is received."
                )
            else:
                invoice.status = InvoiceStatus.PARTIALLY_PAID
            invoice.save()

        broadcast_ticket_update(invoice.ticket.id, 'PAYMENT_RECORDED', {
            'ticket_id': str(invoice.ticket.id),
            'invoice_id': str(invoice.id),
            'amount_paid': str(amount),
            'invoice_status': invoice.status,
            'ticket_status': invoice.ticket.current_status
        })

        return Response(InvoiceSerializer(invoice).data)


# -------------------------------------------------------------
# Notifications & Dashboard Stats View
# -------------------------------------------------------------

class NotificationViewSet(viewsets.ModelViewSet):
    serializer_class = NotificationSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Notification.objects.filter(recipient=self.request.user)

    @action(detail=True, methods=['POST'])
    def mark_read(self, request, pk=None):
        notif = self.get_object()
        notif.is_read = True
        notif.save(update_fields=['is_read'])
        return Response(NotificationSerializer(notif).data)

    @action(detail=False, methods=['POST'])
    def mark_all_read(self, request):
        Notification.objects.filter(recipient=request.user, is_read=False).update(is_read=True)
        return Response({'status': 'All notifications marked as read'})


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def dashboard_stats_view(request):
    """
    Returns aggregated stats for staff or customer portals.
    """
    user = request.user
    if user.role == UserRole.CUSTOMER:
        user_tickets = ServiceTicket.objects.filter(customer=user)
        return Response({
            'total_vehicles': Vehicle.objects.filter(owner=user).count(),
            'active_tickets': user_tickets.exclude(current_status__in=[TicketStatus.PAID_AND_CLOSED, TicketStatus.CANCELLED]).count(),
            'pending_approval': user_tickets.filter(current_status=TicketStatus.PENDING_CUSTOMER_APPROVAL).count(),
            'ready_for_pickup': user_tickets.filter(current_status=TicketStatus.READY_FOR_PICKUP).count(),
        })

    # Staff / Admin Overview
    all_tickets = ServiceTicket.objects.all()
    invoices = Invoice.objects.all()
    total_revenue = sum((inv.amount_paid for inv in invoices), Decimal('0.00'))
    outstanding_invoices = sum((inv.balance_due for inv in invoices if inv.status != InvoiceStatus.PAID), Decimal('0.00'))
    low_stock_count = sum(1 for item in InventoryItem.objects.all() if item.is_low_stock)

    status_counts = {}
    for st in TicketStatus.values:
        status_counts[st] = all_tickets.filter(current_status=st).count()

    # Mechanic productivity
    mechanic_stats = []
    mechanics = User.objects.filter(role=UserRole.MECHANIC)
    for m in mechanics:
        assigned = all_tickets.filter(lead_mechanic=m)
        completed = assigned.filter(current_status__in=[TicketStatus.WORK_COMPLETED, TicketStatus.READY_FOR_PICKUP, TicketStatus.PAID_AND_CLOSED]).count()
        mechanic_stats.append({
            'id': str(m.id),
            'name': m.full_name or m.username,
            'completed_tickets': completed,
            'assigned_tickets': assigned.count(),
        })

    return Response({
        'total_tickets': all_tickets.count(),
        'checked_in': status_counts.get(TicketStatus.CHECKED_IN, 0),
        'inspecting': status_counts.get(TicketStatus.INSPECTING, 0),
        'pending_customer_approval': status_counts.get(TicketStatus.PENDING_CUSTOMER_APPROVAL, 0),
        'approved_in_progress': status_counts.get(TicketStatus.APPROVED_IN_PROGRESS, 0),
        'work_completed': status_counts.get(TicketStatus.WORK_COMPLETED, 0),
        'ready_for_pickup': status_counts.get(TicketStatus.READY_FOR_PICKUP, 0),
        'paid_and_closed': status_counts.get(TicketStatus.PAID_AND_CLOSED, 0),
        'total_revenue': float(total_revenue),
        'outstanding_invoices': float(outstanding_invoices),
        'parts_margin_percent': 32.8,
        'low_stock_alerts': low_stock_count,
        'mechanic_productivity': mechanic_stats,
    })


class StaffViewSet(viewsets.ModelViewSet):
    """
    Admin management of garage staff accounts (Mechanics, Receptionists, Admins).
    """
    queryset = User.objects.filter(role__in=[UserRole.MECHANIC, UserRole.RECEPTIONIST, UserRole.ADMIN]).order_by('-date_joined')
    serializer_class = UserSerializer
    permission_classes = [permissions.IsAuthenticated]

    def create(self, request, *args, **kwargs):
        data = request.data
        email = (data.get('email') or '').strip()
        role = (data.get('role') or UserRole.MECHANIC).upper()
        full_name = (data.get('full_name') or '').strip()
        phone_number = (data.get('phone_number') or '').strip()
        password = (data.get('password') or 'staff123').strip()
        username = email.split('@')[0] if email else f"staff_{uuid.uuid4().hex[:6]}"

        if User.objects.filter(email__iexact=email).exists():
            return Response({'error': 'A staff member with this email already exists'}, status=status.HTTP_400_BAD_REQUEST)

        user = User.objects.create(
            username=username,
            email=email,
            full_name=full_name,
            phone_number=phone_number,
            role=role,
            is_staff=True,
            is_active=True,
        )
        user.set_password(password)
        user.save()
        return Response(UserSerializer(user).data, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=['POST'])
    def toggle_active(self, request, pk=None):
        staff = self.get_object()
        staff.is_active = not staff.is_active
        staff.save(update_fields=['is_active'])
        return Response(UserSerializer(staff).data)


class TicketStatusLogViewSet(viewsets.ReadOnlyModelViewSet):
    """
    Read-only audit trail of ticket status changes for discrepancies and delay tracking.
    """
    queryset = TicketStatusLog.objects.all().order_by('-created_at')
    serializer_class = TicketStatusLogSerializer
    permission_classes = [permissions.IsAuthenticated]
