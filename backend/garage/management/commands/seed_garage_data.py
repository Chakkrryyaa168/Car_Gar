from decimal import Decimal
import uuid
from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from garage.models import (
    Vehicle, ServiceTicket, InventoryItem, TicketItem,
    TicketPhoto, Invoice, Payment, TicketStatusLog,
    UserRole, TicketStatus, ItemType, ApprovalStatus,
    PhotoStage, InvoiceStatus, PaymentMethod, Notification,
    NotificationType, NotificationChannel
)
from garage.services.invoice_service import recalculate_or_create_invoice

User = get_user_model()


class Command(BaseCommand):
    help = 'Seeds realistic sample data for the Car Garage Management System'

    def handle(self, *args, **options):
        self.stdout.write("Seeding Car Garage Management System data...")

        # 1. Create Users
        admin, _ = User.objects.get_or_create(
            username='admin_user',
            defaults={
                'email': 'admin@cargarage.com',
                'full_name': 'Alex Stone (Admin)',
                'phone_number': '+1 555-0100',
                'role': UserRole.ADMIN,
                'is_staff': True,
                'is_superuser': True,
            }
        )
        admin.set_password('admin123')
        admin.save()

        receptionist, _ = User.objects.get_or_create(
            username='reception_user',
            defaults={
                'email': 'reception@cargarage.com',
                'full_name': 'Sarah Connor (Front Desk)',
                'phone_number': '+1 555-0101',
                'role': UserRole.RECEPTIONIST,
                'is_staff': True,
            }
        )
        receptionist.set_password('reception123')
        receptionist.save()

        mechanic, _ = User.objects.get_or_create(
            username='mechanic_user',
            defaults={
                'email': 'mechanic@cargarage.com',
                'full_name': 'Mike Miller (Lead Mechanic)',
                'phone_number': '+1 555-0102',
                'role': UserRole.MECHANIC,
            }
        )
        mechanic.set_password('mechanic123')
        mechanic.save()

        customer, _ = User.objects.get_or_create(
            username='customer_user',
            defaults={
                'email': 'customer@cargarage.com',
                'full_name': 'John Doe (Vehicle Owner)',
                'phone_number': '+1 555-0103',
                'role': UserRole.CUSTOMER,
            }
        )
        customer.set_password('customer123')
        customer.save()

        self.stdout.write(self.style.SUCCESS("Users seeded successfully."))

        # 2. Create Vehicles
        v1, _ = Vehicle.objects.get_or_create(
            license_plate='ABC-1234',
            defaults={
                'owner': customer,
                'vin': '1HGCR2F83HA001234',
                'make': 'Toyota',
                'model': 'Camry XSE',
                'year': 2022,
                'color': 'Pearl White',
                'is_verified': True,
            }
        )

        v2, _ = Vehicle.objects.get_or_create(
            license_plate='XYZ-9876',
            defaults={
                'owner': customer,
                'vin': '2T1BURHE8JC099876',
                'make': 'Honda',
                'model': 'Civic Touring',
                'year': 2021,
                'color': 'Aegean Blue',
                'is_verified': True,
            }
        )

        v3, _ = Vehicle.objects.get_or_create(
            license_plate='GAR-7788',
            defaults={
                'owner': customer,
                'vin': 'WBA3A5C59DF007788',
                'make': 'BMW',
                'model': '330i M Sport',
                'year': 2020,
                'color': 'Mineral Grey',
                'is_verified': True,
            }
        )

        self.stdout.write(self.style.SUCCESS("Vehicles seeded."))

        # 3. Create Inventory Items (including low stock and out-of-stock items)
        parts_data = [
            ('Full Synthetic Motor Oil 5W-30 (5QT)', 'OIL-5W30-SYN', Decimal('22.00'), Decimal('45.00'), 28, 10),
            ('OEM Engine Oil Filter', 'FLT-ENG-001', Decimal('5.50'), Decimal('14.99'), 18, 8),
            ('Ceramic Front Brake Pads Set', 'BRK-PAD-FR01', Decimal('32.00'), Decimal('79.99'), 3, 5),   # Low stock
            ('High Performance Brake Rotors (Pair)', 'BRK-ROT-002', Decimal('65.00'), Decimal('149.00'), 4, 4), # Low stock
            ('Cabin Hepa Air Filter', 'FLT-CAB-003', Decimal('8.00'), Decimal('24.99'), 0, 4),             # Out of stock
            ('Iridium Spark Plug (Pack of 4)', 'IGN-SPK-004', Decimal('18.00'), Decimal('42.00'), 15, 6),
            ('Heavy Duty Serpentine Belt', 'BLT-SERP-005', Decimal('14.00'), Decimal('35.00'), 2, 4),      # Low stock
            ('DOT 4 Synthetic Brake Fluid 1L', 'FLD-DOT4-006', Decimal('6.00'), Decimal('18.50'), 14, 5),
        ]

        part_objs = {}
        for name, sku, cost, sell, qty, reorder in parts_data:
            item, _ = InventoryItem.objects.get_or_create(
                sku=sku,
                defaults={
                    'name': name,
                    'cost_price': cost,
                    'selling_price': sell,
                    'quantity_on_hand': qty,
                    'reorder_level': reorder,
                }
            )
            part_objs[sku] = item

        self.stdout.write(self.style.SUCCESS("Inventory seeded."))

        # 4. Create Service Tickets across realistic states
        # Ticket A: PENDING_CUSTOMER_APPROVAL (Crucial for customer interactive approval demo)
        t_approval, _ = ServiceTicket.objects.get_or_create(
            ticket_number='TK-2026-0001',
            defaults={
                'vehicle': v1,
                'customer': customer,
                'lead_mechanic': mechanic,
                'receptionist': receptionist,
                'current_status': TicketStatus.PENDING_CUSTOMER_APPROVAL,
                'mileage_in': 42150,
                'fuel_level_percent': 70,
                'notes': 'Customer noticed squeaking sound during braking and check engine light flashed once.',
            }
        )

        TicketStatusLog.objects.get_or_create(
            ticket=t_approval,
            from_status=TicketStatus.INSPECTING,
            to_status=TicketStatus.PENDING_CUSTOMER_APPROVAL,
            defaults={
                'changed_by': mechanic,
                'remarks': 'Inspection complete. Discovered worn ceramic brake pads and clogged air filter.'
            }
        )

        # Ticket items awaiting customer approval
        item1, _ = TicketItem.objects.get_or_create(
            ticket=t_approval,
            description='Replace Front Ceramic Brake Pads',
            defaults={
                'assigned_mechanic': mechanic,
                'inventory_item': part_objs['BRK-PAD-FR01'],
                'type': ItemType.PART,
                'unit_price': Decimal('79.99'),
                'quantity': Decimal('1.00'),
                'approval_status': ApprovalStatus.PENDING,
                'is_completed': False,
                'mechanic_notes': 'Brake pads worn down to 2mm, immediate replacement advised.'
            }
        )

        item2, _ = TicketItem.objects.get_or_create(
            ticket=t_approval,
            description='Front Brake Caliper & Pad Labor (1.5 hrs)',
            defaults={
                'assigned_mechanic': mechanic,
                'type': ItemType.LABOR,
                'unit_price': Decimal('90.00'),
                'quantity': Decimal('1.50'),
                'approval_status': ApprovalStatus.PENDING,
                'is_completed': False,
                'mechanic_notes': 'Labor for caliper servicing and new pad installation.'
            }
        )

        item3, _ = TicketItem.objects.get_or_create(
            ticket=t_approval,
            description='Premium Full Synthetic Oil Change & Filter Replacement',
            defaults={
                'assigned_mechanic': mechanic,
                'inventory_item': part_objs['OIL-5W30-SYN'],
                'type': ItemType.PART,
                'unit_price': Decimal('45.00'),
                'quantity': Decimal('1.00'),
                'approval_status': ApprovalStatus.APPROVED,
                'is_completed': False,
                'mechanic_notes': 'Scheduled maintenance oil change.'
            }
        )

        item4, _ = TicketItem.objects.get_or_create(
            ticket=t_approval,
            description='Cabin Air Filter Replacement (Optional)',
            defaults={
                'assigned_mechanic': mechanic,
                'inventory_item': part_objs['FLT-CAB-003'],
                'type': ItemType.PART,
                'unit_price': Decimal('24.99'),
                'quantity': Decimal('1.00'),
                'approval_status': ApprovalStatus.PENDING,
                'is_completed': False,
                'mechanic_notes': 'Cabin filter has dust buildup.'
            }
        )

        # Photos for Ticket A
        TicketPhoto.objects.get_or_create(
            ticket=t_approval,
            caption='Vehicle Walkaround & Odometer Check-in',
            defaults={
                'stage': PhotoStage.CHECKIN_INSPECTION,
                'url': 'https://images.unsplash.com/photo-1617814076367-b759c7d7e738?auto=format&fit=crop&w=800&q=80',
                'uploaded_by': receptionist,
            }
        )

        TicketPhoto.objects.get_or_create(
            ticket=t_approval,
            caption='Worn Front Brake Pad Evidence (2mm remaining)',
            defaults={
                'stage': PhotoStage.FAULT_EVIDENCE,
                'ticket_item': item1,
                'url': 'https://images.unsplash.com/photo-1486006920555-c77dce18193b?auto=format&fit=crop&w=800&q=80',
                'uploaded_by': mechanic,
            }
        )

        # Ticket B: APPROVED_IN_PROGRESS (Mechanic active work)
        t_progress, _ = ServiceTicket.objects.get_or_create(
            ticket_number='TK-2026-0002',
            defaults={
                'vehicle': v2,
                'customer': customer,
                'lead_mechanic': mechanic,
                'receptionist': receptionist,
                'current_status': TicketStatus.APPROVED_IN_PROGRESS,
                'mileage_in': 31500,
                'fuel_level_percent': 50,
                'notes': 'Major 30,000-mile comprehensive service.',
            }
        )

        TicketItem.objects.get_or_create(
            ticket=t_progress,
            description='Engine Spark Plugs Replacement (Pack of 4)',
            defaults={
                'assigned_mechanic': mechanic,
                'inventory_item': part_objs['IGN-SPK-004'],
                'type': ItemType.PART,
                'unit_price': Decimal('42.00'),
                'quantity': Decimal('1.00'),
                'approval_status': ApprovalStatus.APPROVED,
                'is_completed': True,  # Done
                'mechanic_notes': 'Spark plugs installed and torqued to OEM spec.'
            }
        )

        TicketItem.objects.get_or_create(
            ticket=t_progress,
            description='Brake Fluid Flush & Bleed (DOT 4)',
            defaults={
                'assigned_mechanic': mechanic,
                'inventory_item': part_objs['FLD-DOT4-006'],
                'type': ItemType.PART,
                'unit_price': Decimal('18.50'),
                'quantity': Decimal('1.00'),
                'approval_status': ApprovalStatus.APPROVED,
                'is_completed': False, # In progress
                'mechanic_notes': 'System currently draining.'
            }
        )

        # Photos for Ticket B
        TicketPhoto.objects.get_or_create(
            ticket=t_progress,
            caption='New Iridium Spark Plugs Installed',
            defaults={
                'stage': PhotoStage.REPAIR_COMPLETED,
                'url': 'https://images.unsplash.com/photo-1503376780353-7e6692767b70?auto=format&fit=crop&w=800&q=80',
                'uploaded_by': mechanic,
            }
        )

        # Ticket C: READY_FOR_PICKUP (Completed, invoice issued)
        t_pickup, _ = ServiceTicket.objects.get_or_create(
            ticket_number='TK-2026-0003',
            defaults={
                'vehicle': v3,
                'customer': customer,
                'lead_mechanic': mechanic,
                'receptionist': receptionist,
                'current_status': TicketStatus.READY_FOR_PICKUP,
                'mileage_in': 58900,
                'fuel_level_percent': 90,
                'notes': 'Transmission fluid service and serpentine belt replacement.',
            }
        )

        i_c1, _ = TicketItem.objects.get_or_create(
            ticket=t_pickup,
            description='Serpentine Belt Replacement',
            defaults={
                'assigned_mechanic': mechanic,
                'inventory_item': part_objs['BLT-SERP-005'],
                'type': ItemType.PART,
                'unit_price': Decimal('35.00'),
                'quantity': Decimal('1.00'),
                'approval_status': ApprovalStatus.APPROVED,
                'is_completed': True,
            }
        )

        i_c2, _ = TicketItem.objects.get_or_create(
            ticket=t_pickup,
            description='Mechanic Diagnostic & Labor (1 hr)',
            defaults={
                'assigned_mechanic': mechanic,
                'type': ItemType.LABOR,
                'unit_price': Decimal('95.00'),
                'quantity': Decimal('1.00'),
                'approval_status': ApprovalStatus.APPROVED,
                'is_completed': True,
            }
        )

        inv_pickup = recalculate_or_create_invoice(t_pickup)
        inv_pickup.status = InvoiceStatus.ISSUED
        inv_pickup.save()

        # Ticket D: PAID_AND_CLOSED
        t_closed, _ = ServiceTicket.objects.get_or_create(
            ticket_number='TK-2026-0004',
            defaults={
                'vehicle': v1,
                'customer': customer,
                'lead_mechanic': mechanic,
                'receptionist': receptionist,
                'current_status': TicketStatus.PAID_AND_CLOSED,
                'mileage_in': 39000,
                'fuel_level_percent': 40,
                'notes': 'Standard oil change and tire rotation.',
            }
        )

        TicketItem.objects.get_or_create(
            ticket=t_closed,
            description='Oil and Filter Service',
            defaults={
                'assigned_mechanic': mechanic,
                'inventory_item': part_objs['OIL-5W30-SYN'],
                'type': ItemType.PART,
                'unit_price': Decimal('59.99'),
                'quantity': Decimal('1.00'),
                'approval_status': ApprovalStatus.APPROVED,
                'is_completed': True,
            }
        )

        inv_closed = recalculate_or_create_invoice(t_closed)
        inv_closed.amount_paid = inv_closed.total_amount
        inv_closed.status = InvoiceStatus.PAID
        inv_closed.save()

        Payment.objects.get_or_create(
            invoice=inv_closed,
            defaults={
                'amount_paid': inv_closed.total_amount,
                'method': PaymentMethod.CREDIT_CARD,
                'transaction_reference': 'TXN-99882211',
                'received_by': receptionist,
            }
        )

        # 5. Create Sample Notifications
        Notification.objects.get_or_create(
            ticket=t_approval,
            recipient=customer,
            type=NotificationType.APPROVAL_NEEDED,
            defaults={
                'channel': NotificationChannel.APP,
                'message': 'Inspection finished for your Toyota Camry XSE. Please review and approve repair items.',
                'is_read': False,
            }
        )

        Notification.objects.get_or_create(
            ticket=t_pickup,
            recipient=customer,
            type=NotificationType.READY_FOR_PICKUP,
            defaults={
                'channel': NotificationChannel.APP,
                'message': 'Your BMW 330i M Sport is ready for pickup! Total invoice: $139.10.',
                'is_read': False,
            }
        )

        self.stdout.write(self.style.SUCCESS("Service Tickets, Invoices, and Notifications seeded successfully!"))
