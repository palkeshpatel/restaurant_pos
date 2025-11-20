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

  factory ReserveTableResponse.fromJson(Map<String, dynamic> json) {
    return ReserveTableResponse(
      order: json['order'] as Map<String, dynamic>?,
      orderTicketId: json['order_ticket_id']?.toString(),
      orderTicketTitle: json['order_ticket_title']?.toString(),
      message: json['message']?.toString(),
    );
  }
}

