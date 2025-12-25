<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Check;
use App\Models\Employee;
use App\Models\Floor;
use App\Models\KitchenTicket;
use App\Models\MenuItem;
use App\Models\ModifierGroup;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Modifier;
use App\Models\Printer;
use App\Models\Payment;
use App\Models\RestaurantTable;
use App\Models\Shift;
use App\Traits\ApiResponse;
use Illuminate\Http\Exceptions\HttpResponseException;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class BaseAdminController extends Controller
{
    use ApiResponse;

    protected function currentBusinessId(Request $request): int
    {
        $user = $request->user() ?? Auth::user();

        if (!$user || !$user->business_id) {
            throw new HttpResponseException(
                $this->errorResponse('Authenticated user is not associated with a business.', 403)
            );
        }

        return (int) $user->business_id;
    }

    protected function assertModelBelongsToBusiness(?object $model, int $businessId, string $resourceName = 'Resource'): void
    {
        if (!$model) {
            throw new HttpResponseException($this->notFoundResponse("{$resourceName} not found"));
        }

        if (!array_key_exists('business_id', $model->getAttributes())) {
            return;
        }

        if ((int) $model->business_id !== $businessId) {
            throw new HttpResponseException(
                $this->forbiddenResponse("{$resourceName} does not belong to the authenticated business")
            );
        }
    }

    protected function ensureFloorBelongsToBusiness(int $floorId, int $businessId): Floor
    {
        $floor = Floor::find($floorId);

        if (!$floor || (int) $floor->business_id !== $businessId) {
            throw new HttpResponseException(
                $this->errorResponse('Floor does not belong to the authenticated business', 422)
            );
        }

        return $floor;
    }

    protected function ensureTableBelongsToBusiness(int $tableId, int $businessId): RestaurantTable
    {
        $table = RestaurantTable::with('floor')->find($tableId);

        if (
            !$table ||
            !$table->floor ||
            (int) $table->floor->business_id !== $businessId
        ) {
            throw new HttpResponseException(
                $this->errorResponse('Table does not belong to the authenticated business', 422)
            );
        }

        return $table;
    }

    protected function ensureEmployeeBelongsToBusiness(int $employeeId, int $businessId): Employee
    {
        $employee = Employee::find($employeeId);

        if (!$employee || (int) $employee->business_id !== $businessId) {
            throw new HttpResponseException(
                $this->errorResponse('Employee does not belong to the authenticated business', 422)
            );
        }

        return $employee;
    }

    protected function ensureMenuItemBelongsToBusiness(int $menuItemId, int $businessId): MenuItem
    {
        $menuItem = MenuItem::find($menuItemId);

        if (!$menuItem || (int) $menuItem->business_id !== $businessId) {
            throw new HttpResponseException(
                $this->errorResponse('Menu item does not belong to the authenticated business', 422)
            );
        }

        return $menuItem;
    }

    protected function ensurePrinterBelongsToBusiness(int $printerId, int $businessId): Printer
    {
        $printer = Printer::find($printerId);

        if (!$printer || (int) $printer->business_id !== $businessId) {
            throw new HttpResponseException(
                $this->errorResponse('Printer does not belong to the authenticated business', 422)
            );
        }

        return $printer;
    }

    protected function ensureModifierGroupBelongsToBusiness(int $modifierGroupId, int $businessId): ModifierGroup
    {
        $modifierGroup = ModifierGroup::find($modifierGroupId);

        if (!$modifierGroup || (int) $modifierGroup->business_id !== $businessId) {
            throw new HttpResponseException(
                $this->errorResponse('Modifier group does not belong to the authenticated business', 422)
            );
        }

        return $modifierGroup;
    }

    protected function ensureModifierBelongsToBusiness(int $modifierId, int $businessId): Modifier
    {
        $modifier = Modifier::find($modifierId);

        if (!$modifier || (int) $modifier->business_id !== $businessId) {
            throw new HttpResponseException(
                $this->errorResponse('Modifier does not belong to the authenticated business', 422)
            );
        }

        return $modifier;
    }

    protected function ensureOrderBelongsToBusiness(int $orderId, int $businessId): Order
    {
        $order = Order::find($orderId);

        if (!$order || (int) $order->business_id !== $businessId) {
            throw new HttpResponseException(
                $this->errorResponse('Order does not belong to the authenticated business', 422)
            );
        }

        return $order;
    }

    protected function ensureCheckBelongsToBusiness(int $checkId, int $businessId): Check
    {
        $check = Check::with('order.table.floor')->find($checkId);

        if (
            !$check ||
            !$check->order ||
            !$check->order->table ||
            !$check->order->table->floor ||
            (int) $check->order->table->floor->business_id !== $businessId
        ) {
            throw new HttpResponseException(
                $this->errorResponse('Check does not belong to the authenticated business', 422)
            );
        }

        return $check;
    }

    protected function ensureOrderItemBelongsToBusiness(int $orderItemId, int $businessId): OrderItem
    {
        $orderItem = OrderItem::with([
            'order',
            'check.order.table.floor',
            'menuItem',
        ])->find($orderItemId);

        if (!$orderItem) {
            throw new HttpResponseException(
                $this->errorResponse('Order item does not belong to the authenticated business', 422)
            );
        }

        if (
            !$orderItem->order ||
            (int) $orderItem->order->business_id !== $businessId
        ) {
            throw new HttpResponseException(
                $this->errorResponse('Order item does not belong to the authenticated business', 422)
            );
        }

        if (
            !$orderItem->check ||
            !$orderItem->check->order ||
            !$orderItem->check->order->table ||
            !$orderItem->check->order->table->floor ||
            (int) $orderItem->check->order->table->floor->business_id !== $businessId
        ) {
            throw new HttpResponseException(
                $this->errorResponse('Order item does not belong to the authenticated business', 422)
            );
        }

        if (
            !$orderItem->menuItem ||
            (int) $orderItem->menuItem->business_id !== $businessId
        ) {
            throw new HttpResponseException(
                $this->errorResponse('Order item does not belong to the authenticated business', 422)
            );
        }

        return $orderItem;
    }

    protected function ensurePaymentBelongsToBusiness(int $paymentId, int $businessId): Payment
    {
        $payment = Payment::with(['check.order.table.floor', 'employee'])->find($paymentId);

        if (
            !$payment ||
            !$payment->check ||
            !$payment->check->order ||
            !$payment->check->order->table ||
            !$payment->check->order->table->floor ||
            (int) $payment->check->order->table->floor->business_id !== $businessId ||
            !$payment->employee ||
            (int) $payment->employee->business_id !== $businessId
        ) {
            throw new HttpResponseException(
                $this->errorResponse('Payment does not belong to the authenticated business', 422)
            );
        }

        return $payment;
    }

    protected function ensureKitchenTicketBelongsToBusiness(int $kitchenTicketId, int $businessId): KitchenTicket
    {
        $kitchenTicket = KitchenTicket::with(['order', 'printer'])->find($kitchenTicketId);

        if (!$kitchenTicket || (int) $kitchenTicket->business_id !== $businessId) {
            throw new HttpResponseException(
                $this->errorResponse('Kitchen ticket does not belong to the authenticated business', 422)
            );
        }

        if (
            ($kitchenTicket->order && (int) $kitchenTicket->order->business_id !== $businessId) ||
            ($kitchenTicket->printer && (int) $kitchenTicket->printer->business_id !== $businessId)
        ) {
            throw new HttpResponseException(
                $this->errorResponse('Associated resources do not belong to the authenticated business', 422)
            );
        }

        return $kitchenTicket;
    }

    protected function ensureShiftBelongsToBusiness(int $shiftId, int $businessId): Shift
    {
        $shift = Shift::with('employee')->find($shiftId);

        if (!$shift || (int) $shift->business_id !== $businessId) {
            throw new HttpResponseException(
                $this->errorResponse('Shift does not belong to the authenticated business', 422)
            );
        }

        return $shift;
    }
}
