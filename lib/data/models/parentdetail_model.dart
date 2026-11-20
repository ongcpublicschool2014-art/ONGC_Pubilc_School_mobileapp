/// Parent-Student relationship model matching Supabase 'parentdetail' table
/// This table links parents to students (many-to-many relationship)
class ParentDetailModel {
  final int pdId;
  final int parId;
  final int stuId;
  final int insId;
  final String inscode;
  final int activestatus;

  ParentDetailModel({
    required this.pdId,
    required this.parId,
    required this.stuId,
    required this.insId,
    required this.inscode,
    this.activestatus = 1,
  });

  /// Create from Supabase JSON response
  factory ParentDetailModel.fromJson(Map<String, dynamic> json) {
    return ParentDetailModel(
      pdId: json['pd_id'] is int
          ? json['pd_id']
          : int.parse(json['pd_id'].toString()),
      parId: json['par_id'] is int
          ? json['par_id']
          : int.parse(json['par_id'].toString()),
      stuId: json['stu_id'] is int
          ? json['stu_id']
          : int.parse(json['stu_id'].toString()),
      insId: json['ins_id'] is int
          ? json['ins_id']
          : int.parse(json['ins_id'].toString()),
      inscode: json['inscode'] ?? '',
      activestatus: json['activestatus'] ?? 1,
    );
  }

  /// Convert to JSON for Supabase insert/update
  Map<String, dynamic> toJson() {
    return {
      'pd_id': pdId,
      'par_id': parId,
      'stu_id': stuId,
      'ins_id': insId,
      'inscode': inscode,
      'activestatus': activestatus,
    };
  }

  bool get isActive => activestatus == 1;

  ParentDetailModel copyWith({
    int? pdId,
    int? parId,
    int? stuId,
    int? insId,
    String? inscode,
    int? activestatus,
  }) {
    return ParentDetailModel(
      pdId: pdId ?? this.pdId,
      parId: parId ?? this.parId,
      stuId: stuId ?? this.stuId,
      insId: insId ?? this.insId,
      inscode: inscode ?? this.inscode,
      activestatus: activestatus ?? this.activestatus,
    );
  }
}
