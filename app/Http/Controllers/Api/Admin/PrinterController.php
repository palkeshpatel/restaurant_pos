<?php

namespace App\Http\Controllers\Api\Admin;

use App\Models\Printer;
use Illuminate\Http\Request;

class PrinterController extends BaseAdminController
{
    public function index(Request $request)
    {
        $businessId = $this->currentBusinessId($request);

        $perPage = $request->input('per_page', 10);
        $page = $request->input('page', 1);

        $printers = Printer::with(['business', 'printerRoutes', 'kitchenTickets'])
            ->where('business_id', $businessId)
            ->paginate($perPage, ['*'], 'page', $page);

        return $this->successResponse([
            'data' => $printers->items(),
            'total' => $printers->total(),
            'per_page' => $printers->perPage(),
            'current_page' => $printers->currentPage(),
            'last_page' => $printers->lastPage(),
        ], 'Printers retrieved successfully');
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'ip_address' => 'required|ip',
            'is_kitchen' => 'boolean',
            'is_receipt' => 'boolean',
        ]);

        $validated['business_id'] = $this->currentBusinessId($request);

        $printer = Printer::create($validated);
        return $this->createdResponse($printer, 'Printer created successfully');
    }

    public function show(Request $request, $id)
    {
        $businessId = $this->currentBusinessId($request);
        $printer = Printer::with(['business', 'printerRoutes', 'kitchenTickets'])->find($id);

        $this->assertModelBelongsToBusiness($printer, $businessId, 'Printer');

        return $this->successResponse($printer, 'Printer retrieved successfully');
    }

    public function update(Request $request, $id)
    {
        $businessId = $this->currentBusinessId($request);
        $printer = Printer::find($id);

        $this->assertModelBelongsToBusiness($printer, $businessId, 'Printer');

        $validated = $request->validate([
            'name' => 'sometimes|required|string|max:255',
            'ip_address' => 'sometimes|required|ip',
            'is_kitchen' => 'boolean',
            'is_receipt' => 'boolean',
        ]);

        $printer->update($validated);
        return $this->updatedResponse($printer, 'Printer updated successfully');
    }

    public function destroy(Request $request, $id)
    {
        $businessId = $this->currentBusinessId($request);
        $printer = Printer::find($id);

        $this->assertModelBelongsToBusiness($printer, $businessId, 'Printer');

        $printer->delete();
        return $this->deletedResponse('Printer deleted successfully');
    }
}
