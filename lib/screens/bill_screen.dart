import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';
import '../models/table_model.dart';
import '../providers/settings_provider.dart';

class BillScreen extends StatefulWidget {
  final List<OrderItem> items;
  
  const BillScreen({super.key, required this.items});

  @override
  State<BillScreen> createState() => _BillScreenState();
}

class _BillScreenState extends State<BillScreen> {
  final Set<int> _removedItems = {};
  bool _isMobile = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkScreenSize();
  }

  void _checkScreenSize() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    
    if (_isMobile != isMobile) {
      setState(() {
        _isMobile = isMobile;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final subtotal = _calculateSubtotal();
    final tax = subtotal * 0.1;
    final total = subtotal + tax;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Gourmet Restaurant Bill',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: SettingsProvider.restaurantGreen.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: SettingsProvider.restaurantGreen.withOpacity(0.5),
              ),
            ),
            child: IconButton(
              onPressed: () => _printBill(subtotal, tax, total),
              icon: const Icon(Icons.print),
              tooltip: 'Print Bill',
              color: SettingsProvider.restaurantGreen,
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: SettingsProvider.darkGradient,
        ),
        child: SafeArea(
              child: Column(
                children: [
                  // Restaurant Header
                  Container(
                    padding: EdgeInsets.all(_isMobile ? 16 : 20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface.withOpacity(0.2),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                      border: Border.all(
                        color: SettingsProvider.primaryColor.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    SettingsProvider.primaryColor,
                                    SettingsProvider.primaryColor.withOpacity(0.7),
                                  ],
                                ),
                              ),
                              child: const Icon(
                                Icons.restaurant,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'GOURMET',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 3,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Professional Restaurant Bill',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: SettingsProvider.primaryColor,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: SettingsProvider.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: SettingsProvider.primaryColor.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.calendar_today,
                                color: SettingsProvider.primaryColor,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Date: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Icon(
                                Icons.access_time,
                                color: SettingsProvider.primaryColor,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Time: ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bill Items (scrollable)
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: _isMobile ? 16 : 20),
                      itemCount: widget.items.length,
                      itemBuilder: (context, index) {
                        final item = widget.items[index];
                        final isRemoved = _removedItems.contains(item.id);

                        return _buildBillItem(item, isRemoved, () {
                          setState(() {
                            if (isRemoved) {
                              _removedItems.remove(item.id);
                            } else {
                              _removedItems.add(item.id);
                            }
                          });
                        });
                      },
                    ),
                  ),

                  // Bill Summary (fixed at bottom)
                  Container(
                padding: EdgeInsets.all(_isMobile ? 16 : 20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  border: const Border(
                    top: BorderSide(color: Colors.white, width: 0.1),
                  ),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow('Subtotal', subtotal),
                    const SizedBox(height: 8),
                    _buildSummaryRow('Tax (10%)', tax),
                    const SizedBox(height: 16),
                    _buildSummaryRow('Total', total, isTotal: true),
                    const SizedBox(height: 20),
                    _isMobile 
                        ? Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => _printBill(subtotal, tax, total),
                                  icon: const Icon(Icons.print),
                                  label: const Text('Print Bill'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    padding: const EdgeInsets.all(16),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => Navigator.of(context).pop(),
                                  icon: const Icon(Icons.close),
                                  label: const Text('Close'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    padding: const EdgeInsets.all(16),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => Navigator.of(context).pop(),
                                  icon: const Icon(Icons.close),
                                  label: const Text('Close'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    padding: const EdgeInsets.all(16),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _printBill(subtotal, tax, total),
                                  icon: const Icon(Icons.print),
                                  label: const Text('Print Bill'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    padding: const EdgeInsets.all(16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBillItem(OrderItem item, bool isRemoved, VoidCallback onToggleRemove) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isRemoved 
            ? Colors.red.withValues(alpha: 0.1) 
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRemoved ? Colors.red.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Item Icon
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                item.icon,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Item Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isRemoved ? Colors.red : Colors.white,
                    decoration: isRemoved ? TextDecoration.lineThrough : null,
                    decorationColor: Colors.red,
                    decorationThickness: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: isRemoved ? Colors.red.withValues(alpha: 0.7) : Colors.white70,
                    decoration: isRemoved ? TextDecoration.lineThrough : null,
                    decorationColor: Colors.red,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Qty: ${item.quantity}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isRemoved ? Colors.red.withValues(alpha: 0.7) : Colors.white70,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '₹${item.price.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isRemoved ? Colors.red : const Color(0xFF4caf50),
                        decoration: isRemoved ? TextDecoration.lineThrough : null,
                        decorationColor: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Remove/Undo Button
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isRemoved ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isRemoved ? Colors.green : Colors.red,
                width: 1,
              ),
            ),
            child: IconButton(
              onPressed: onToggleRemove,
              icon: Icon(
                isRemoved ? Icons.undo : Icons.remove_circle_outline,
                color: isRemoved ? Colors.green : Colors.red,
                size: 20,
              ),
              tooltip: isRemoved ? 'Undo Remove' : 'Remove Item',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isTotal = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: isTotal ? Colors.green.withValues(alpha: 0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isTotal ? Border.all(color: Colors.green, width: 1) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.green : Colors.white,
            ),
          ),
          Text(
            '₹${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: isTotal ? 20 : 16,
              fontWeight: FontWeight.bold,
              color: isTotal ? Colors.green : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  double _calculateSubtotal() {
    return widget.items
        .where((item) => !_removedItems.contains(item.id))
        .fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  Future<void> _printBill(double subtotal, double tax, double total) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Restaurant Header
              pw.Center(
                child: pw.Text(
                  '🍽️ RESTAURANT BILL',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              
              // Date and Time
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Date: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}'),
                  pw.Text('Time: ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}'),
                ],
              ),
              pw.SizedBox(height: 20),
              
              // Items
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Item', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Qty', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Price', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  ...widget.items
                      .where((item) => !_removedItems.contains(item.id))
                      .map((item) => pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(item.name),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(item.quantity.toString()),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('₹${item.price.toStringAsFixed(0)}'),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('₹${(item.price * item.quantity).toStringAsFixed(0)}'),
                          ),
                        ],
                      )),
                ],
              ),
              pw.SizedBox(height: 20),
              
              // Summary
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Subtotal: ₹${subtotal.toStringAsFixed(0)}'),
                    pw.Text('Tax (10%): ₹${tax.toStringAsFixed(0)}'),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      'Total: ₹${total.toStringAsFixed(0)}',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),
              
              // Footer
              pw.Center(
                child: pw.Text(
                  'Thank you for dining with us!',
                  style: pw.TextStyle(fontStyle: pw.FontStyle.italic),
                ),
              ),
            ],
          );
        },
      ),
    );
    
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}