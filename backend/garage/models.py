import uuid
from decimal import Decimal
from django.db import models
from django.contrib.auth.models import AbstractUser
from django.utils import timezone


class UserRole(models.TextChoices):
    ADMIN = 'ADMIN', 'Admin'
    RECEPTIONIST = 'RECEPTIONIST', 'Receptionist'
    MECHANIC = 'MECHANIC', 'Mechanic'
    CUSTOMER = 'CUSTOMER', 'Customer'


class TicketStatus(models.TextChoices):
    CHECKED_IN = 'CHECKED_IN', 'Checked In'
    INSPECTION_PENDING = 'INSPECTION_PENDING', 'Inspection Pending'
    INSPECTING = 'INSPECTING', 'Inspecting'
    PENDING_CUSTOMER_APPROVAL = 'PENDING_CUSTOMER_APPROVAL', 'Pending Customer Approval'
    APPROVED_IN_PROGRESS = 'APPROVED_IN_PROGRESS', 'Approved - In Progress'
    WORK_COMPLETED = 'WORK_COMPLETED', 'Work Completed'
    READY_FOR_PICKUP = 'READY_FOR_PICKUP', 'Ready For Pickup'
    PAID_AND_CLOSED = 'PAID_AND_CLOSED', 'Paid & Closed'
    CANCELLED = 'CANCELLED', 'Cancelled'


class ItemType(models.TextChoices):
    LABOR = 'LABOR', 'Labor'
    PART = 'PART', 'Part'


class ApprovalStatus(models.TextChoices):
    PENDING = 'PENDING', 'Pending'
    APPROVED = 'APPROVED', 'Approved'
    REJECTED = 'REJECTED', 'Rejected'


class PhotoStage(models.TextChoices):
    CHECKIN_INSPECTION = 'CHECKIN_INSPECTION', 'Check-in Inspection'
    FAULT_EVIDENCE = 'FAULT_EVIDENCE', 'Fault Evidence'
    REPAIR_COMPLETED = 'REPAIR_COMPLETED', 'Repair Completed'


class StockMovementType(models.TextChoices):
    RECEIVED = 'RECEIVED', 'Received'
    USED_ON_TICKET = 'USED_ON_TICKET', 'Used On Ticket'
    ADJUSTED = 'ADJUSTED', 'Adjusted'
    RETURNED = 'RETURNED', 'Returned'


class InvoiceStatus(models.TextChoices):
    DRAFT = 'DRAFT', 'Draft'
    ISSUED = 'ISSUED', 'Issued'
    PARTIALLY_PAID = 'PARTIALLY_PAID', 'Partially Paid'
    PAID = 'PAID', 'Paid'
    CANCELLED = 'CANCELLED', 'Cancelled'


class PaymentMethod(models.TextChoices):
    CASH = 'CASH', 'Cash'
    CREDIT_CARD = 'CREDIT_CARD', 'Credit Card'
    BANK_TRANSFER = 'BANK_TRANSFER', 'Bank Transfer'
    ONLINE = 'ONLINE', 'Online'


class NotificationType(models.TextChoices):
    INSPECTION_READY = 'INSPECTION_READY', 'Inspection Ready'
    APPROVAL_NEEDED = 'APPROVAL_NEEDED', 'Approval Needed'
    WORK_STARTED = 'WORK_STARTED', 'Work Started'
    WORK_COMPLETED = 'WORK_COMPLETED', 'Work Completed'
    READY_FOR_PICKUP = 'READY_FOR_PICKUP', 'Ready For Pickup'
    INVOICE_ISSUED = 'INVOICE_ISSUED', 'Invoice Issued'


class NotificationChannel(models.TextChoices):
    APP = 'APP', 'App'
    SMS = 'SMS', 'SMS'
    EMAIL = 'EMAIL', 'Email'
    CALL = 'CALL', 'Phone Call'


class User(AbstractUser):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    role = models.CharField(
        max_length=20,
        choices=UserRole.choices,
        default=UserRole.CUSTOMER,
        db_index=True,
    )
    full_name = models.CharField(max_length=255, blank=True)
    phone_number = models.CharField(max_length=30, blank=True)
    fcm_token = models.CharField(max_length=255, blank=True, null=True)
    customer_code = models.CharField(
        max_length=20,
        unique=True,
        null=True,
        blank=True,
        db_index=True,
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def save(self, *args, **kwargs):
        if not self.full_name and (self.first_name or self.last_name):
            self.full_name = f"{self.first_name} {self.last_name}".strip()
        if not self.customer_code:
            import random
            for _ in range(1000):
                code = f"CG-{random.randint(1000, 9999)}"
                if not User.objects.filter(customer_code=code).exists():
                    self.customer_code = code
                    break
            if not self.customer_code:
                while True:
                    code = f"CG-{random.randint(10000, 99999)}"
                    if not User.objects.filter(customer_code=code).exists():
                        self.customer_code = code
                        break
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.full_name or self.username} ({self.role})"

    @property
    def profile_safe(self):
        profile, _ = UserProfile.objects.get_or_create(user=self)
        return profile


class Vehicle(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    owner = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='vehicles'
    )
    license_plate = models.CharField(max_length=20, unique=True, db_index=True)
    vin = models.CharField(max_length=50, unique=True, db_index=True)
    make = models.CharField(max_length=50)
    model = models.CharField(max_length=50)
    year = models.PositiveIntegerField()
    color = models.CharField(max_length=30)
    is_verified = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.year} {self.make} {self.model} [{self.license_plate}]"


class ServiceTicket(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    ticket_number = models.CharField(max_length=32, unique=True, db_index=True)
    vehicle = models.ForeignKey(
        Vehicle,
        on_delete=models.CASCADE,
        related_name='tickets'
    )
    customer = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='customer_tickets'
    )
    lead_mechanic = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='assigned_tickets'
    )
    receptionist = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='created_tickets'
    )
    current_status = models.CharField(
        max_length=35,
        choices=TicketStatus.choices,
        default=TicketStatus.CHECKED_IN,
        db_index=True,
    )
    mileage_in = models.PositiveIntegerField(default=0)
    fuel_level_percent = models.PositiveIntegerField(default=50)
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    def save(self, *args, **kwargs):
        if not self.ticket_number:
            timestamp = timezone.now().strftime('%y%m%d')
            rand_suffix = str(uuid.uuid4().hex[:4]).upper()
            self.ticket_number = f"TK-{timestamp}-{rand_suffix}"
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.ticket_number} - {self.vehicle.license_plate} ({self.current_status})"


class InventoryItem(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=150)
    sku = models.CharField(max_length=50, unique=True, db_index=True)
    cost_price = models.DecimalField(max_digits=10, decimal_places=2, default=Decimal('0.00'))
    selling_price = models.DecimalField(max_digits=10, decimal_places=2, default=Decimal('0.00'))
    quantity_on_hand = models.IntegerField(default=0)
    reorder_level = models.IntegerField(default=5)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    @property
    def is_low_stock(self):
        return self.quantity_on_hand <= self.reorder_level

    @property
    def is_out_of_stock(self):
        return self.quantity_on_hand <= 0

    class Meta:
        ordering = ['name']

    def __str__(self):
        return f"{self.name} (SKU: {self.sku}, Stock: {self.quantity_on_hand})"


class TicketItem(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    ticket = models.ForeignKey(
        ServiceTicket,
        on_delete=models.CASCADE,
        related_name='items'
    )
    assigned_mechanic = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='ticket_items'
    )
    inventory_item = models.ForeignKey(
        InventoryItem,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='ticket_usages'
    )
    type = models.CharField(
        max_length=10,
        choices=ItemType.choices,
        default=ItemType.PART
    )
    description = models.CharField(max_length=255)
    unit_price = models.DecimalField(max_digits=10, decimal_places=2, default=Decimal('0.00'))
    quantity = models.DecimalField(max_digits=8, decimal_places=2, default=Decimal('1.00'))
    total_price = models.DecimalField(max_digits=10, decimal_places=2, default=Decimal('0.00'))
    approval_status = models.CharField(
        max_length=15,
        choices=ApprovalStatus.choices,
        default=ApprovalStatus.PENDING,
        db_index=True
    )
    is_completed = models.BooleanField(default=False)
    mechanic_notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['created_at']

    def save(self, *args, **kwargs):
        self.total_price = Decimal(str(self.unit_price or 0)) * Decimal(str(self.quantity or 1))
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.ticket.ticket_number} - {self.description} (${self.total_price}) [{self.approval_status}]"


class TicketPhoto(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    ticket = models.ForeignKey(
        ServiceTicket,
        on_delete=models.CASCADE,
        related_name='photos'
    )
    ticket_item = models.ForeignKey(
        TicketItem,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='photos'
    )
    stage = models.CharField(
        max_length=30,
        choices=PhotoStage.choices,
        default=PhotoStage.CHECKIN_INSPECTION,
        db_index=True
    )
    url = models.URLField(max_length=1000)
    caption = models.CharField(max_length=255, blank=True)
    uploaded_by = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='uploaded_photos'
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['created_at']

    def __str__(self):
        return f"{self.ticket.ticket_number} - {self.stage} ({self.caption or 'Photo'})"


class StockMovement(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    inventory_item = models.ForeignKey(
        InventoryItem,
        on_delete=models.CASCADE,
        related_name='stock_movements'
    )
    ticket_item = models.ForeignKey(
        TicketItem,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='stock_movements'
    )
    movement_type = models.CharField(
        max_length=20,
        choices=StockMovementType.choices,
        default=StockMovementType.USED_ON_TICKET
    )
    quantity = models.IntegerField()
    created_by = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='recorded_movements'
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.inventory_item.name} - {self.movement_type}: {self.quantity}"


class Invoice(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    ticket = models.OneToOneField(
        ServiceTicket,
        on_delete=models.CASCADE,
        related_name='invoice'
    )
    invoice_number = models.CharField(max_length=32, unique=True, db_index=True)
    subtotal = models.DecimalField(max_digits=10, decimal_places=2, default=Decimal('0.00'))
    tax_amount = models.DecimalField(max_digits=10, decimal_places=2, default=Decimal('0.00'))
    discount_amount = models.DecimalField(max_digits=10, decimal_places=2, default=Decimal('0.00'))
    total_amount = models.DecimalField(max_digits=10, decimal_places=2, default=Decimal('0.00'))
    amount_paid = models.DecimalField(max_digits=10, decimal_places=2, default=Decimal('0.00'))
    status = models.CharField(
        max_length=20,
        choices=InvoiceStatus.choices,
        default=InvoiceStatus.DRAFT,
        db_index=True
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    def save(self, *args, **kwargs):
        if not self.invoice_number:
            timestamp = timezone.now().strftime('%y%m%d')
            rand_suffix = str(uuid.uuid4().hex[:4]).upper()
            self.invoice_number = f"INV-{timestamp}-{rand_suffix}"
        super().save(*args, **kwargs)

    @property
    def balance_due(self):
        return max(Decimal('0.00'), self.total_amount - self.amount_paid)

    def __str__(self):
        return f"{self.invoice_number} - Total: ${self.total_amount} ({self.status})"


class Payment(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    invoice = models.ForeignKey(
        Invoice,
        on_delete=models.CASCADE,
        related_name='payments'
    )
    amount_paid = models.DecimalField(max_digits=10, decimal_places=2)
    method = models.CharField(
        max_length=20,
        choices=PaymentMethod.choices,
        default=PaymentMethod.CASH
    )
    transaction_reference = models.CharField(max_length=100, blank=True)
    received_by = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='received_payments'
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"Payment of ${self.amount_paid} for {self.invoice.invoice_number} via {self.method}"


class TicketStatusLog(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    ticket = models.ForeignKey(
        ServiceTicket,
        on_delete=models.CASCADE,
        related_name='status_logs'
    )
    changed_by = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='status_changes'
    )
    from_status = models.CharField(max_length=35)
    to_status = models.CharField(max_length=35)
    remarks = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['created_at']

    def __str__(self):
        return f"{self.ticket.ticket_number}: {self.from_status} -> {self.to_status}"


class Notification(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    ticket = models.ForeignKey(
        ServiceTicket,
        on_delete=models.CASCADE,
        related_name='notifications'
    )
    recipient = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='notifications'
    )
    type = models.CharField(
        max_length=30,
        choices=NotificationType.choices
    )
    channel = models.CharField(
        max_length=10,
        choices=NotificationChannel.choices,
        default=NotificationChannel.APP
    )
    message = models.TextField()
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"Notification to {self.recipient.username}: {self.type} - Read={self.is_read}"


class UserProfile(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        related_name='profile',
        db_index=True
    )
    avatar_url = models.CharField(max_length=500, blank=True, default='')
    address = models.TextField(blank=True, default='')
    emergency_contact = models.CharField(max_length=50, blank=True, default='')

    # Customer-specific metadata
    secondary_phone = models.CharField(max_length=50, blank=True, default='')
    preferred_contact_channel = models.CharField(
        max_length=50,
        blank=True,
        default='App push'
    )  # 'App push', 'SMS', 'WhatsApp', 'Email'
    billing_address = models.TextField(blank=True, default='')
    saved_payment_method = models.CharField(
        max_length=50,
        blank=True,
        default='CREDIT_CARD'
    )  # 'CASH', 'CREDIT_CARD', 'BANK_TRANSFER', 'ONLINE'
    default_vehicle = models.ForeignKey(
        Vehicle,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='default_for_profiles'
    )
    communication_preferences = models.CharField(
        max_length=100,
        blank=True,
        default='ALL'
    )

    # Staff-specific metadata (Mechanic, Receptionist, Admin)
    employee_id = models.CharField(max_length=50, blank=True, default='')
    specialization = models.CharField(max_length=100, blank=True, default='')
    bio = models.TextField(blank=True, default='')

    # Admin / Staff employment records
    date_joined_company = models.DateField(null=True, blank=True)
    hourly_rate = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00'),
        null=True,
        blank=True
    )

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'user_profiles'
        ordering = ['-created_at']

    def __str__(self):
        return f"Profile of {self.user.username} ({self.user.role})"


from django.db.models.signals import post_save
from django.dispatch import receiver

@receiver(post_save, sender=User)
def create_or_save_user_profile(sender, instance, created, **kwargs):
    if created:
        UserProfile.objects.get_or_create(user=instance)

