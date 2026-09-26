from rest_framework import permissions
from garage.models import UserRole


class IsAdminUserRole(permissions.BasePermission):
    def has_permission(self, request, view):
        return bool(
            request.user and
            request.user.is_authenticated and
            (request.user.role == UserRole.ADMIN or request.user.is_staff or request.user.is_superuser)
        )


class IsReceptionistOrAdmin(permissions.BasePermission):
    def has_permission(self, request, view):
        return bool(
            request.user and
            request.user.is_authenticated and
            (request.user.role in [UserRole.RECEPTIONIST, UserRole.ADMIN] or request.user.is_staff)
        )


class IsMechanicOrAdmin(permissions.BasePermission):
    def has_permission(self, request, view):
        return bool(
            request.user and
            request.user.is_authenticated and
            (request.user.role in [UserRole.MECHANIC, UserRole.ADMIN] or request.user.is_staff)
        )


class IsStaffUser(permissions.BasePermission):
    def has_permission(self, request, view):
        return bool(
            request.user and
            request.user.is_authenticated and
            (request.user.role in [UserRole.ADMIN, UserRole.RECEPTIONIST, UserRole.MECHANIC] or request.user.is_staff)
        )


class IsTicketParticipant(permissions.BasePermission):
    """
    Allows access if the user is staff OR is the customer who owns the ticket/vehicle.
    """
    def has_object_permission(self, request, view, obj):
        if not request.user or not request.user.is_authenticated:
            return False
        if request.user.role in [UserRole.ADMIN, UserRole.RECEPTIONIST, UserRole.MECHANIC] or request.user.is_staff:
            return True

        # Check if obj is a ServiceTicket or related model
        customer = getattr(obj, 'customer', None)
        if not customer and hasattr(obj, 'ticket'):
            customer = obj.ticket.customer
        if not customer and hasattr(obj, 'owner'):
            customer = obj.owner

        return customer == request.user
