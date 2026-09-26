from rest_framework import serializers
from django.contrib.auth import get_user_model
from garage.models import (
    Vehicle, ServiceTicket, InventoryItem, TicketItem,
    TicketPhoto, StockMovement, Invoice, Payment,
    TicketStatusLog, Notification, TicketStatus, ApprovalStatus
)

User = get_user_model()


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'full_name', 'phone_number', 'role', 'fcm_token']
        read_only_fields = ['id']


class VehicleSerializer(serializers.ModelSerializer):
    owner_name = serializers.ReadOnlyField(source='owner.full_name')
    owner_phone = serializers.ReadOnlyField(source='owner.phone_number')

    class Meta:
        model = Vehicle
        fields = [
            'id', 'owner', 'owner_name', 'owner_phone',
            'license_plate', 'vin', 'make', 'model', 'year', 'color',
            'is_verified', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class InventoryItemSerializer(serializers.ModelSerializer):
    is_low_stock = serializers.ReadOnlyField()
    is_out_of_stock = serializers.ReadOnlyField()

    class Meta:
        model = InventoryItem
        fields = [
            'id', 'name', 'sku', 'cost_price', 'selling_price',
            'quantity_on_hand', 'reorder_level', 'is_low_stock', 'is_out_of_stock',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class TicketPhotoSerializer(serializers.ModelSerializer):
    uploaded_by_name = serializers.ReadOnlyField(source='uploaded_by.full_name')

    class Meta:
        model = TicketPhoto
        fields = [
            'id', 'ticket', 'ticket_item', 'stage', 'url', 'caption',
            'uploaded_by', 'uploaded_by_name', 'created_at'
        ]
        read_only_fields = ['id', 'created_at']


class TicketItemSerializer(serializers.ModelSerializer):
    assigned_mechanic_name = serializers.ReadOnlyField(source='assigned_mechanic.full_name')
    inventory_item_name = serializers.ReadOnlyField(source='inventory_item.name')

    class Meta:
        model = TicketItem
        fields = [
            'id', 'ticket', 'assigned_mechanic', 'assigned_mechanic_name',
            'inventory_item', 'inventory_item_name', 'type', 'description',
            'unit_price', 'quantity', 'total_price', 'approval_status',
            'is_completed', 'mechanic_notes', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'total_price', 'created_at', 'updated_at']


class StockMovementSerializer(serializers.ModelSerializer):
    inventory_item_name = serializers.ReadOnlyField(source='inventory_item.name')
    created_by_name = serializers.ReadOnlyField(source='created_by.full_name')

    class Meta:
        model = StockMovement
        fields = [
            'id', 'inventory_item', 'inventory_item_name', 'ticket_item',
            'movement_type', 'quantity', 'created_by', 'created_by_name', 'created_at'
        ]
        read_only_fields = ['id', 'created_at']


class PaymentSerializer(serializers.ModelSerializer):
    received_by_name = serializers.ReadOnlyField(source='received_by.full_name')

    class Meta:
        model = Payment
        fields = [
            'id', 'invoice', 'amount_paid', 'method',
            'transaction_reference', 'received_by', 'received_by_name', 'created_at'
        ]
        read_only_fields = ['id', 'created_at']


class InvoiceSerializer(serializers.ModelSerializer):
    payments = PaymentSerializer(many=True, read_only=True)
    ticket_number = serializers.ReadOnlyField(source='ticket.ticket_number')
    balance_due = serializers.ReadOnlyField()

    class Meta:
        model = Invoice
        fields = [
            'id', 'ticket', 'ticket_number', 'invoice_number',
            'subtotal', 'tax_amount', 'discount_amount', 'total_amount',
            'amount_paid', 'balance_due', 'status', 'payments',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'invoice_number', 'created_at', 'updated_at']


class TicketStatusLogSerializer(serializers.ModelSerializer):
    changed_by_name = serializers.ReadOnlyField(source='changed_by.full_name')

    class Meta:
        model = TicketStatusLog
        fields = [
            'id', 'ticket', 'changed_by', 'changed_by_name',
            'from_status', 'to_status', 'remarks', 'created_at'
        ]
        read_only_fields = ['id', 'created_at']


class NotificationSerializer(serializers.ModelSerializer):
    ticket_number = serializers.ReadOnlyField(source='ticket.ticket_number')

    class Meta:
        model = Notification
        fields = [
            'id', 'ticket', 'ticket_number', 'recipient', 'type',
            'channel', 'message', 'is_read', 'created_at'
        ]
        read_only_fields = ['id', 'created_at']


class ServiceTicketListSerializer(serializers.ModelSerializer):
    vehicle_info = serializers.SerializerMethodField()
    customer_name = serializers.ReadOnlyField(source='customer.full_name')
    customer_phone = serializers.ReadOnlyField(source='customer.phone_number')
    lead_mechanic_name = serializers.ReadOnlyField(source='lead_mechanic.full_name')
    receptionist_name = serializers.ReadOnlyField(source='receptionist.full_name')
    total_items_count = serializers.SerializerMethodField()
    approved_items_count = serializers.SerializerMethodField()
    completed_items_count = serializers.SerializerMethodField()
    total_estimated_amount = serializers.SerializerMethodField()

    class Meta:
        model = ServiceTicket
        fields = [
            'id', 'ticket_number', 'vehicle', 'vehicle_info', 'customer',
            'customer_name', 'customer_phone', 'lead_mechanic', 'lead_mechanic_name',
            'receptionist', 'receptionist_name', 'current_status', 'mileage_in',
            'fuel_level_percent', 'notes', 'total_items_count', 'approved_items_count',
            'completed_items_count', 'total_estimated_amount', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'ticket_number', 'created_at', 'updated_at']

    def get_vehicle_info(self, obj):
        v = obj.vehicle
        return f"{v.year} {v.make} {v.model} ({v.license_plate})"

    def get_total_items_count(self, obj):
        return obj.items.count()

    def get_approved_items_count(self, obj):
        return obj.items.filter(approval_status=ApprovalStatus.APPROVED).count()

    def get_completed_items_count(self, obj):
        return obj.items.filter(is_completed=True).count()

    def get_total_estimated_amount(self, obj):
        approved = obj.items.filter(approval_status=ApprovalStatus.APPROVED)
        return float(sum((item.total_price for item in approved), 0))


class ServiceTicketDetailSerializer(serializers.ModelSerializer):
    vehicle = VehicleSerializer(read_only=True)
    customer = UserSerializer(read_only=True)
    lead_mechanic = UserSerializer(read_only=True)
    receptionist = UserSerializer(read_only=True)
    items = TicketItemSerializer(many=True, read_only=True)
    photos = TicketPhotoSerializer(many=True, read_only=True)
    status_logs = TicketStatusLogSerializer(many=True, read_only=True)
    invoice = InvoiceSerializer(read_only=True)

    class Meta:
        model = ServiceTicket
        fields = [
            'id', 'ticket_number', 'vehicle', 'customer', 'lead_mechanic',
            'receptionist', 'current_status', 'mileage_in', 'fuel_level_percent',
            'notes', 'items', 'photos', 'status_logs', 'invoice',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'ticket_number', 'created_at', 'updated_at']
