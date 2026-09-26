import logging
from decimal import Decimal
from django.db import transaction
from django.core.exceptions import ValidationError
from garage.models import StockMovement, StockMovementType, ItemType

logger = logging.getLogger(__name__)


def deduct_item_inventory(ticket_item, user):
    """
    Deducts stock when a PART ticket item is marked completed or used.
    Must run within an atomic transaction.
    """
    if ticket_item.type != ItemType.PART or not ticket_item.inventory_item:
        return None

    with transaction.atomic():
        # Select for update to prevent race conditions
        inventory_item = type(ticket_item.inventory_item).objects.select_for_update().get(
            id=ticket_item.inventory_item_id
        )

        qty_to_deduct = int(ticket_item.quantity)
        if qty_to_deduct <= 0:
            qty_to_deduct = 1

        # Check if already recorded to avoid duplicate deductions
        existing_movement = StockMovement.objects.filter(
            ticket_item=ticket_item,
            movement_type=StockMovementType.USED_ON_TICKET
        ).exists()

        if existing_movement:
            logger.info(f"Inventory deduction already recorded for ticket item {ticket_item.id}")
            return None

        inventory_item.quantity_on_hand -= qty_to_deduct
        inventory_item.save(update_fields=['quantity_on_hand', 'updated_at'])

        movement = StockMovement.objects.create(
            inventory_item=inventory_item,
            ticket_item=ticket_item,
            movement_type=StockMovementType.USED_ON_TICKET,
            quantity=-qty_to_deduct,
            created_by=user
        )

        logger.info(
            f"Deducted {qty_to_deduct} units of {inventory_item.name}. "
            f"New stock: {inventory_item.quantity_on_hand} (Reorder level: {inventory_item.reorder_level})"
        )
        return movement
