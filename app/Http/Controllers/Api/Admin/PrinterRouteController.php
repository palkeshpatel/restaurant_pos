<?php

namespace App\Http\Controllers\Api\Admin;

use App\Models\PrinterRoute;
use App\Models\Printer;
use Illuminate\Http\Request;

class PrinterRouteController extends BaseAdminController
{
    public function index(Request $request)
    {
        $businessId = $this->currentBusinessId($request);

        $printerRoutes = PrinterRoute::with(['business', 'printer', 'menuItems'])
            ->where('business_id', $businessId)
            ->get();

        return $this->successResponse($printerRoutes, 'Printer routes retrieved successfully');
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'printer_id' => 'required|exists:printers,id',
        ]);

        $businessId = $this->currentBusinessId($request);

        $printer = Printer::where('id', $validated['printer_id'])
            ->where('business_id', $businessId)
            ->first();

        if (!$printer) {
            return $this->errorResponse('Printer does not belong to the authenticated business', 422);
        }

        $validated['business_id'] = $businessId;

        $printerRoute = PrinterRoute::create($validated);
        return $this->createdResponse($printerRoute, 'Printer route created successfully');
    }

    public function show(Request $request, $id)
    {
        $businessId = $this->currentBusinessId($request);
        $printerRoute = PrinterRoute::with(['business', 'printer', 'menuItems'])->find($id);

        $this->assertModelBelongsToBusiness($printerRoute, $businessId, 'Printer route');

        return $this->successResponse($printerRoute, 'Printer route retrieved successfully');
    }

    public function update(Request $request, $id)
    {
        $businessId = $this->currentBusinessId($request);
        $printerRoute = PrinterRoute::find($id);

        $this->assertModelBelongsToBusiness($printerRoute, $businessId, 'Printer route');

        $validated = $request->validate([
            'name' => 'sometimes|required|string|max:255',
            'printer_id' => 'sometimes|required|exists:printers,id',
        ]);

        if (isset($validated['printer_id'])) {
            $printer = Printer::where('id', $validated['printer_id'])
                ->where('business_id', $businessId)
                ->first();

            if (!$printer) {
                return $this->errorResponse('Printer does not belong to the authenticated business', 422);
            }
        }

        $printerRoute->update($validated);
        return $this->updatedResponse($printerRoute, 'Printer route updated successfully');
    }

    public function destroy(Request $request, $id)
    {
        $businessId = $this->currentBusinessId($request);
        $printerRoute = PrinterRoute::find($id);

        $this->assertModelBelongsToBusiness($printerRoute, $businessId, 'Printer route');

        $printerRoute->delete();
        return $this->deletedResponse('Printer route deleted successfully');
    }
}
