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
    return ReserveTableResponse(
      order: json['order'] as Map<String, dynamic>?,
      orderTicketId: json['order_ticket_id']?.toString(),
      orderTicketTitle: json['order_ticket_title']?.toString(),
      message: json['message']?.toString(),
    );
  }
}

