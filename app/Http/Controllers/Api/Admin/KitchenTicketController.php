<?php

namespace App\Http\Controllers\Api\Admin;

use App\Models\KitchenTicket;
use Illuminate\Http\Request;

class KitchenTicketController extends BaseAdminController
{
    public function index(Request $request)
    {
        $businessId = $this->currentBusinessId($request);

        $kitchenTickets = KitchenTicket::with(['order', 'printer'])
            ->where('business_id', $businessId)
            ->get();

        return $this->successResponse($kitchenTickets, 'Kitchen tickets retrieved successfully');
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'order_id' => 'required|exists:orders,id',
            'ticket_type' => 'nullable|string|max:50',
            'printer_id' => 'nullable|exists:printers,id',
            'generated_at' => 'nullable|date',
        ]);

        $businessId = $this->currentBusinessId($request);
        $this->ensureOrderBelongsToBusiness($validated['order_id'], $businessId);

        if (!empty($validated['printer_id'])) {
            $this->ensurePrinterBelongsToBusiness($validated['printer_id'], $businessId);
        }

        $kitchenTicket = KitchenTicket::create([
            ...$validated,
            'business_id' => $businessId,
        ]);
        return $this->createdResponse($kitchenTicket, 'Kitchen ticket created successfully');
    }

    public function show(Request $request, $id)
    {
        $businessId = $this->currentBusinessId($request);
        $kitchenTicket = $this->ensureKitchenTicketBelongsToBusiness($id, $businessId);

        $kitchenTicket->load(['order', 'printer']);

        return $this->successResponse($kitchenTicket, 'Kitchen ticket retrieved successfully');
    }

    public function update(Request $request, $id)
    {
        $businessId = $this->currentBusinessId($request);
        $kitchenTicket = $this->ensureKitchenTicketBelongsToBusiness($id, $businessId);

        $validated = $request->validate([
            'order_id' => 'sometimes|required|exists:orders,id',
            'ticket_type' => 'nullable|string|max:50',
            'printer_id' => 'nullable|exists:printers,id',
            'generated_at' => 'nullable|date',
        ]);

        if (isset($validated['order_id'])) {
            $this->ensureOrderBelongsToBusiness($validated['order_id'], $businessId);
        }

        if (isset($validated['printer_id'])) {
            $this->ensurePrinterBelongsToBusiness($validated['printer_id'], $businessId);
        }

        $kitchenTicket->update([
            ...$validated,
            'business_id' => $businessId,
        ]);
        return $this->updatedResponse($kitchenTicket, 'Kitchen ticket updated successfully');
    }

    public function destroy(Request $request, $id)
    {
        $businessId = $this->currentBusinessId($request);
        $kitchenTicket = $this->ensureKitchenTicketBelongsToBusiness($id, $businessId);

        $kitchenTicket->delete();
        return $this->deletedResponse('Kitchen ticket deleted successfully');
    }
}
