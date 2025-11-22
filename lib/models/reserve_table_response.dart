class ReserveTableResponse {
  final Map<String, dynamic>? order;
  final String? orderTicketId;
  final String? orderTicketTitle;
  final String? message;

  ReserveTableResponse({
    this.order,
    this.orderTicketId,
    this.orderTicketTitle,
    this.message,
  });

  // Get order_id from order object
  int? get orderId {
    if (order == null) return null;
    final id = order!['id'];
    if (id is int) return id;
    if (id is String) return int.tryParse(id);
    return null;
  }

  factory ReserveTableResponse.fromJson(Map<String, dynamic> json) {
    // Handle case where order might be an object that needs conversion
    dynamic orderData = json['order'];
    Map<String, dynamic>? orderMap;
    
    if (orderData is Map<String, dynamic>) {
      orderMap = orderData;
    } else if (orderData != null) {
      // Try to convert to map if it's not already
      try {
        orderMap = Map<String, dynamic>.from(orderData);
      } catch (e) {
        print('ReserveTableResponse: Error converting order to map: $e');
        orderMap = null;
      }
    }
    
    return ReserveTableResponse(
      order: orderMap,
      orderTicketId: json['order_ticket_id']?.toString(),
      orderTicketTitle: json['order_ticket_title']?.toString(),
      message: json['message']?.toString(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'order': order,
      'order_ticket_id': orderTicketId,
      'order_ticket_title': orderTicketTitle,
      'message': message,
    };
  }
}

