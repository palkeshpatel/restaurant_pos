import 'floor.dart';
import 'api_response.dart';

class FloorResponse {
  final List<Floor> floors;

  FloorResponse({required this.floors});

  factory FloorResponse.fromJson(List<dynamic> json) {
    return FloorResponse(
      floors: json.map((floor) => Floor.fromJson(floor)).toList(),
    );
  }
}

