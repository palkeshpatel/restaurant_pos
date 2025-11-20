class TableModel {
  final int id;
  final String name;
  final String size;
  final int capacity;
  final String status;
  final String? orderTicketId;
  final String? orderTicketTitle;
  final int? occupiedByEmployeeId;
  final String? occupiedByEmployeeName;
  final String? occupiedByEmployeeAvatar;

  TableModel({
    required this.id,
    required this.name,
    required this.size,
    required this.capacity,
    required this.status,
    this.orderTicketId,
    this.orderTicketTitle,
    this.occupiedByEmployeeId,
    this.occupiedByEmployeeName,
    this.occupiedByEmployeeAvatar,
  });

  bool get isAvailable => status == 'available';
  bool get isOccupied => status == 'occupied';
  bool get isReserved => status == 'reserved';
  bool get isInUse => isOccupied || isReserved;

  TableModel copyWith({
    int? id,
    String? name,
    String? size,
    int? capacity,
    String? status,
    String? orderTicketId,
    String? orderTicketTitle,
    int? occupiedByEmployeeId,
    String? occupiedByEmployeeName,
    String? occupiedByEmployeeAvatar,
  }) {
    return TableModel(
      id: id ?? this.id,
      name: name ?? this.name,
      size: size ?? this.size,
      capacity: capacity ?? this.capacity,
      status: status ?? this.status,
      orderTicketId: orderTicketId ?? this.orderTicketId,
      orderTicketTitle: orderTicketTitle ?? this.orderTicketTitle,
      occupiedByEmployeeId: occupiedByEmployeeId ?? this.occupiedByEmployeeId,
      occupiedByEmployeeName: occupiedByEmployeeName ?? this.occupiedByEmployeeName,
      occupiedByEmployeeAvatar: occupiedByEmployeeAvatar ?? this.occupiedByEmployeeAvatar,
    );
  }

  factory TableModel.fromJson(Map<String, dynamic> json) {
    return TableModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      size: json['size'] ?? 'medium',
      capacity: json['capacity'] ?? 4,
      status: json['status'] ?? 'available',
      orderTicketId: json['order_ticket_id']?.toString(),
      orderTicketTitle: json['order_ticket_title']?.toString(),
      occupiedByEmployeeId: json['occupied_by_employee_id'],
      occupiedByEmployeeName: json['occupied_by_employee_name'],
      occupiedByEmployeeAvatar: json['occupied_by_employee_avatar'],
    );
  }
}