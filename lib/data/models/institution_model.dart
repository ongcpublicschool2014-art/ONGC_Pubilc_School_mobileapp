/// Institution/School model matching Supabase 'institution' table
class InstitutionModel {
  final int insId;
  final String inscode;
  final String insname;
  final String? insaddress1;
  final String? insaddress2;
  final String? insaddress3;
  final String? cityName; // From joined city table
  final String? inspincode;
  final String? insmobno;
  final String? insmail;
  final String? inshortname;
  final String? inslogo;
  final String? insmotto;
  final int activestatus;

  InstitutionModel({
    required this.insId,
    required this.inscode,
    required this.insname,
    this.insaddress1,
    this.insaddress2,
    this.insaddress3,
    this.cityName,
    this.inspincode,
    this.insmobno,
    this.insmail,
    this.inshortname,
    this.inslogo,
    this.insmotto,
    this.activestatus = 1,
  });

  /// Create from Supabase JSON response (with joined city data)
  factory InstitutionModel.fromJson(Map<String, dynamic> json) {
    // Handle nested city data from join
    String? cityName;
    if (json['city'] != null && json['city'] is Map) {
      cityName = json['city']['citname'];
    } else if ((json['inscity']?.toString() ?? '').trim().isNotEmpty) {
      // School: the city is a plain column (no city table).
      cityName = json['inscity'].toString().trim();
    }

    return InstitutionModel(
      insId: json['ins_id'] is int ? json['ins_id'] : int.parse(json['ins_id'].toString()),
      inscode: json['inscode'] ?? '',
      insname: json['insname'] ?? '',
      insaddress1: json['insaddress1'],
      insaddress2: json['insaddress2'],
      insaddress3: json['insaddress3'],
      cityName: cityName,
      inspincode: json['inspincode'],
      insmobno: json['insmobno'],
      insmail: json['insmail'],
      inshortname: json['inshortname'],
      inslogo: json['inslogo'],
      insmotto: json['insmotto'],
      activestatus: json['activestatus'] ?? 1,
    );
  }

  /// Helper getters for UI display
  String get name => insname;
  String get code => inscode;
  String? get phone => insmobno;
  String? get email => insmail;
  String? get logoUrl => inslogo;
  String? get motto => insmotto;
  bool get isActive => activestatus == 1;

  /// Get formatted address
  String get fullAddress {
    final parts = [insaddress1, insaddress2, insaddress3, cityName, inspincode]
        .where((p) => p != null && p.isNotEmpty)
        .toList();
    return parts.isNotEmpty ? parts.join(', ') : 'Address not available';
  }

  /// Get short address (address1 + city or pincode)
  String get shortAddress {
    // Use city name if available, otherwise use pincode
    final locationPart = cityName ?? inspincode;
    final parts = [insaddress1, locationPart]
        .where((p) => p != null && p.isNotEmpty)
        .toList();
    return parts.isNotEmpty ? parts.join(', ') : 'Address not available';
  }
}
