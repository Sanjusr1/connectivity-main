class SensorInfo {
  final String id;
  final String name;
  final String icon;
  final String purpose;
  final String samplingRate;
  final List<String> features;
  final String role;
  final String unit;
  final String range;

  SensorInfo({
    required this.id,
    required this.name,
    required this.icon,
    required this.purpose,
    required this.samplingRate,
    required this.features,
    required this.role,
    required this.unit,
    required this.range,
  });

  factory SensorInfo.fromJson(Map<String, dynamic> json) {
    return SensorInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String,
      purpose: json['purpose'] as String,
      samplingRate: json['samplingRate'] as String,
      features: List<String>.from(json['features'] as List),
      role: json['role'] as String,
      unit: json['unit'] as String,
      range: json['range'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'purpose': purpose,
      'samplingRate': samplingRate,
      'features': features,
      'role': role,
      'unit': unit,
      'range': range,
    };
  }
}
