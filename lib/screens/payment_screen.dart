import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:flutter/services.dart';
import '../services/api_service.dart';

class PaymentScreen extends StatefulWidget {
  final double totalAmount;
  final String orderTicketId;
  final String? tableName;
  final String? orderTicketTitle;
  final DateTime? orderStartTime;
  final List<Map<String, dynamic>> orderItems; // List of items with details

  const PaymentScreen({
    Key? key,
    required this.totalAmount,
    required this.orderTicketId,
    this.tableName,
    this.orderTicketTitle,
    this.orderStartTime,
    required this.orderItems,
  }) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String? _selectedPaymentMethod;
  bool _isProcessing = false;
  final double _taxRate = 0.10; // 10% tax
  final double _gratuityRate = 0.0; // Can be configured

  double get _subtotal => widget.totalAmount / 1.1; // Remove tax to get subtotal
  double get _tax => _subtotal * _taxRate;
  double get _gratuity => _subtotal * _gratuityRate;
  double get _total => _subtotal + _tax + _gratuity;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Summary Header
            _buildOrderHeader(isMobile),
            SizedBox(height: 24),
            
            // Bill Details
            _buildBillDetails(isMobile),
            SizedBox(height: 24),
            
            // Payment Method Selection
            _buildPaymentMethodSection(isMobile),
            SizedBox(height: 24),
            
            // Payment Button
            _buildPaymentButton(isMobile),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderHeader(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.receipt_long,
                color: Theme.of(context).colorScheme.primary,
                size: isMobile ? 24 : 28,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.tableName ?? 'Table',
                      style: TextStyle(
                        fontSize: isMobile ? 18 : 22,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    if (widget.orderTicketTitle != null)
                      Text(
                        widget.orderTicketTitle!,
                        style: TextStyle(
                          fontSize: isMobile ? 12 : 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (widget.orderStartTime != null) ...[
            SizedBox(height: 8),
            Text(
              'Order Date: ${_formatDateTime(widget.orderStartTime!)}',
              style: TextStyle(
                fontSize: isMobile ? 11 : 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBillDetails(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bill Details',
            style: TextStyle(
              fontSize: isMobile ? 18 : 20,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16),
          
          // Items List
          ...widget.orderItems.map((item) => Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name'] ?? 'Item',
                        style: TextStyle(
                          fontSize: isMobile ? 14 : 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      if (item['quantity'] != null && item['quantity'] > 1)
                        Text(
                          'Qty: ${item['quantity']}',
                          style: TextStyle(
                            fontSize: isMobile ? 12 : 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  '\$${(item['price'] ?? 0.0) * (item['quantity'] ?? 1)}',
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          )),
          
          Divider(height: 24),
          
          // Summary
          _buildSummaryRow('Subtotal:', _subtotal, isMobile),
          SizedBox(height: 8),
          _buildSummaryRow('Tax (10%):', _tax, isMobile),
          if (_gratuity > 0) ...[
            SizedBox(height: 8),
            _buildSummaryRow('Gratuity:', _gratuity, isMobile),
          ],
          SizedBox(height: 12),
          Divider(height: 1, thickness: 2),
          SizedBox(height: 12),
          _buildSummaryRow(
            'Total:',
            _total,
            isMobile,
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, bool isMobile, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? (isMobile ? 16 : 18) : (isMobile ? 14 : 16),
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
            color: isTotal ? Theme.of(context).colorScheme.primary : Colors.black87,
          ),
        ),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: isTotal ? (isMobile ? 20 : 24) : (isMobile ? 14 : 16),
            fontWeight: FontWeight.w700,
            color: isTotal ? Theme.of(context).colorScheme.primary : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodSection(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Payment Method',
          style: TextStyle(
            fontSize: isMobile ? 18 : 20,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 16),
        
        // Cash Payment Option
        _buildPaymentOption(
          icon: Icons.money,
          title: 'Cash',
          subtitle: 'Pay with cash',
          value: 'cash',
          isMobile: isMobile,
        ),
        SizedBox(height: 12),
        
        // Online Payment Option
        _buildPaymentOption(
          icon: Icons.credit_card,
          title: 'Online Payment',
          subtitle: 'Stripe (Coming Soon)',
          value: 'online',
          isMobile: isMobile,
          isComingSoon: true,
        ),
      ],
    );
  }

  Widget _buildPaymentOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required bool isMobile,
    bool isComingSoon = false,
  }) {
    final isSelected = _selectedPaymentMethod == value;
    
    return InkWell(
      onTap: isComingSoon
          ? () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Online payment with Stripe will be available soon'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          : () {
              setState(() {
                _selectedPaymentMethod = value;
              });
            },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey.shade700,
                size: isMobile ? 24 : 28,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: isMobile ? 16 : 18,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.black87,
                        ),
                      ),
                      if (isComingSoon) ...[
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Soon',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: isMobile ? 12 : 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
                size: isMobile ? 24 : 28,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentButton(bool isMobile) {
    return Column(
      children: [
        // Print Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _printBill,
            icon: Icon(Icons.print),
            label: Text('Print Bill'),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: isMobile ? 14 : 16),
              side: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        SizedBox(height: 12),
        
        // Process Payment Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (_selectedPaymentMethod == null || _isProcessing)
                ? null
                : _processPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: isMobile ? 16 : 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
            ),
            child: _isProcessing
                ? SizedBox(
                    height: isMobile ? 20 : 24,
                    width: isMobile ? 20 : 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Process Payment',
                    style: TextStyle(
                      fontSize: isMobile ? 16 : 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  void _printBill() {
    // TODO: Implement print functionality
    // This will use a print package like printing or esc_pos_utils
    // For now, just show a message
    
    HapticFeedback.mediumImpact();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Print functionality will be implemented soon'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 2),
      ),
    );
    
    // Future implementation:
    // - Use printing package to generate PDF
    // - Or use esc_pos_utils for thermal printer
    // - Format bill with all details
    // - Send to printer
  }

  Future<void> _processPayment() async {
    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a payment method'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Call payment API
      final response = await ApiService.processPayment(
        orderTicketId: widget.orderTicketId,
        type: _selectedPaymentMethod!, // 'cash' or 'online'
        amount: _total,
        tipAmount: _gratuity,
      );

      if (mounted) {
        if (response.success) {
          // Payment successful
          Navigator.pop(context, {
            'success': true,
            'payment_method': _selectedPaymentMethod,
            'type': _selectedPaymentMethod,
            'amount': _total,
            'order_ticket_id': widget.orderTicketId,
            'paid': true,
          });
        } else {
          // Payment failed
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'Payment processing failed'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

