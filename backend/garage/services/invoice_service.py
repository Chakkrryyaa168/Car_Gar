from decimal import Decimal
from django.db import transaction
from garage.models import Invoice, InvoiceStatus, ApprovalStatus


def recalculate_or_create_invoice(ticket, tax_rate=Decimal('0.07'), discount=Decimal('0.00')):
    """
    Dynamically calculates or updates the invoice based strictly on APPROVED ticket items.
    """
    with transaction.atomic():
        approved_items = ticket.items.filter(approval_status=ApprovalStatus.APPROVED)
        subtotal = sum((item.total_price for item in approved_items), Decimal('0.00'))

        tax_amount = (subtotal * tax_rate).quantize(Decimal('0.01'))
        total_amount = subtotal + tax_amount - discount
        if total_amount < Decimal('0.00'):
            total_amount = Decimal('0.00')

        invoice, created = Invoice.objects.get_or_create(
            ticket=ticket,
            defaults={
                'subtotal': subtotal,
                'tax_amount': tax_amount,
                'discount_amount': discount,
                'total_amount': total_amount,
                'amount_paid': Decimal('0.00'),
                'status': InvoiceStatus.DRAFT,
            }
        )

        if not created:
            invoice.subtotal = subtotal
            invoice.tax_amount = tax_amount
            invoice.discount_amount = discount
            invoice.total_amount = total_amount
            if invoice.amount_paid >= total_amount and total_amount > Decimal('0.00'):
                invoice.status = InvoiceStatus.PAID
            elif invoice.amount_paid > Decimal('0.00'):
                invoice.status = InvoiceStatus.PARTIALLY_PAID
            invoice.save()

        return invoice
