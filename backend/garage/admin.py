from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from garage.models import (
    User, Vehicle, ServiceTicket, InventoryItem, TicketItem,
    TicketPhoto, StockMovement, Invoice, Payment,
    TicketStatusLog, Notification
)


@admin.register(User)
class CustomUserAdmin(BaseUserAdmin):
    list_display = ('username', 'email', 'full_name', 'role', 'phone_number', 'is_staff')
    list_filter = ('role', 'is_staff', 'is_superuser', 'is_active')
    fieldsets = BaseUserAdmin.fieldsets + (
        ('Garage Role & Profile', {'fields': ('role', 'full_name', 'phone_number', 'fcm_token')}),
    )


@admin.register(Vehicle)
class VehicleAdmin(admin.ModelAdmin):
    list_display = ('license_plate', 'make', 'model', 'year', 'color', 'owner', 'is_verified')
    search_fields = ('license_plate', 'vin', 'make', 'model')
    list_filter = ('is_verified', 'make', 'year')


class TicketItemInline(admin.TabularInline):
    model = TicketItem
    extra = 0


class TicketPhotoInline(admin.TabularInline):
    model = TicketPhoto
    extra = 0


@admin.register(ServiceTicket)
class ServiceTicketAdmin(admin.ModelAdmin):
    list_display = ('ticket_number', 'vehicle', 'customer', 'lead_mechanic', 'current_status', 'created_at')
    list_filter = ('current_status', 'created_at')
    search_fields = ('ticket_number', 'vehicle__license_plate', 'customer__full_name')
    inlines = [TicketItemInline, TicketPhotoInline]


@admin.register(InventoryItem)
class InventoryItemAdmin(admin.ModelAdmin):
    list_display = ('name', 'sku', 'selling_price', 'quantity_on_hand', 'reorder_level', 'is_low_stock')
    search_fields = ('name', 'sku')
    list_filter = ('reorder_level',)


@admin.register(TicketItem)
class TicketItemAdmin(admin.ModelAdmin):
    list_display = ('description', 'ticket', 'type', 'unit_price', 'quantity', 'total_price', 'approval_status', 'is_completed')
    list_filter = ('type', 'approval_status', 'is_completed')


@admin.register(TicketPhoto)
class TicketPhotoAdmin(admin.ModelAdmin):
    list_display = ('ticket', 'stage', 'caption', 'uploaded_by', 'created_at')
    list_filter = ('stage',)


@admin.register(StockMovement)
class StockMovementAdmin(admin.ModelAdmin):
    list_display = ('inventory_item', 'movement_type', 'quantity', 'created_by', 'created_at')
    list_filter = ('movement_type',)


class PaymentInline(admin.TabularInline):
    model = Payment
    extra = 0


@admin.register(Invoice)
class InvoiceAdmin(admin.ModelAdmin):
    list_display = ('invoice_number', 'ticket', 'total_amount', 'amount_paid', 'status', 'created_at')
    list_filter = ('status',)
    inlines = [PaymentInline]


@admin.register(Payment)
class PaymentAdmin(admin.ModelAdmin):
    list_display = ('invoice', 'amount_paid', 'method', 'received_by', 'created_at')
    list_filter = ('method',)


@admin.register(TicketStatusLog)
class TicketStatusLogAdmin(admin.ModelAdmin):
    list_display = ('ticket', 'changed_by', 'from_status', 'to_status', 'created_at')
    list_filter = ('from_status', 'to_status')


@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    list_display = ('ticket', 'recipient', 'type', 'channel', 'is_read', 'created_at')
    list_filter = ('type', 'channel', 'is_read')
