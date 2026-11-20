/// Parent model matching Supabase 'parents' table
class ParentModel {
  final int parId;
  final String partype; // P (Parent), G (Guardian)
  final String? paremail;
  final String? fathername;
  final String? mothername;
  final String? guardianname;
  final String? fathermobile;
  final String? mothermobile;
  final String? guardianmobile;
  final String? fatheroccupation;
  final String? motheroccupation;
  final String? guardianoccupation;
  final String? approvedby;
  final DateTime? approveddate;
  final DateTime? terminateddate;
  final String? terminatedby;
  final int activestatus;
  final String payincharge; // Person in charge of payments
  final String payinchargemob; // Mobile for login (10 chars)
  final String? parpassword;
  final int? parmobotp;
  final int parotpstatus; // 0 (pending), 1 (verified)

  ParentModel({
    required this.parId,
    required this.partype,
    this.paremail,
    this.fathername,
    this.mothername,
    this.guardianname,
    this.fathermobile,
    this.mothermobile,
    this.guardianmobile,
    this.fatheroccupation,
    this.motheroccupation,
    this.guardianoccupation,
    this.approvedby,
    this.approveddate,
    this.terminateddate,
    this.terminatedby,
    this.activestatus = 1,
    required this.payincharge,
    required this.payinchargemob,
    this.parpassword,
    this.parmobotp,
    this.parotpstatus = 0,
  });

  /// Create from Supabase JSON response
  factory ParentModel.fromJson(Map<String, dynamic> json) {
    return ParentModel(
      parId: json['par_id'] is int
          ? json['par_id']
          : int.parse(json['par_id'].toString()),
      partype: json['partype'] ?? 'P',
      paremail: json['paremail'],
      fathername: json['fathername'],
      mothername: json['mothername'],
      guardianname: json['guardianname'],
      fathermobile: json['fathermobile'],
      mothermobile: json['mothermobile'],
      guardianmobile: json['guardianmobile'],
      fatheroccupation: json['fatheroccupation'],
      motheroccupation: json['motheroccupation'],
      guardianoccupation: json['guardianoccupation'],
      approvedby: json['approvedby'],
      approveddate: json['approveddate'] != null
          ? DateTime.parse(json['approveddate'])
          : null,
      terminateddate: json['terminateddate'] != null
          ? DateTime.parse(json['terminateddate'])
          : null,
      terminatedby: json['terminatedby'],
      activestatus: json['activestatus'] ?? 1,
      payincharge: json['payincharge'] ?? '',
      payinchargemob: json['payinchargemob'] ?? '',
      parpassword: json['parpassword'],
      parmobotp: json['parmobotp'] != null
          ? int.tryParse(json['parmobotp'].toString())
          : null,
      parotpstatus: json['parotpstatus'] ?? 0,
    );
  }

  /// Convert to JSON for Supabase insert/update
  Map<String, dynamic> toJson() {
    return {
      'par_id': parId,
      'partype': partype,
      'paremail': paremail,
      'fathername': fathername,
      'mothername': mothername,
      'guardianname': guardianname,
      'fathermobile': fathermobile,
      'mothermobile': mothermobile,
      'guardianmobile': guardianmobile,
      'fatheroccupation': fatheroccupation,
      'motheroccupation': motheroccupation,
      'guardianoccupation': guardianoccupation,
      'approvedby': approvedby,
      'approveddate': approveddate?.toIso8601String(),
      'terminateddate': terminateddate?.toIso8601String(),
      'terminatedby': terminatedby,
      'activestatus': activestatus,
      'payincharge': payincharge,
      'payinchargemob': payinchargemob,
      'parpassword': parpassword,
      'parmobotp': parmobotp,
      'parotpstatus': parotpstatus,
    };
  }

  /// Helper getters for UI display
  String get displayName {
    // Return based on partype: P (Parent), G (Guardian)
    switch (partype) {
      case 'P':
        // For parent type, prefer father name, then mother name
        if (fathername != null && fathername!.isNotEmpty) return fathername!;
        if (mothername != null && mothername!.isNotEmpty) return mothername!;
        break;
      case 'G':
        if (guardianname != null && guardianname!.isNotEmpty) return guardianname!;
        break;
    }
    // Fallback to payincharge or any available name
    if (payincharge.isNotEmpty) return payincharge;
    if (fathername != null && fathername!.isNotEmpty) return fathername!;
    if (mothername != null && mothername!.isNotEmpty) return mothername!;
    if (guardianname != null && guardianname!.isNotEmpty) return guardianname!;
    return 'Parent';
  }

  /// Primary mobile is payinchargemob for authentication
  String get primaryMobile => payinchargemob;

  bool get isActive => activestatus == 1;
  bool get isSuspended => activestatus == 2;
  bool get isTerminated => activestatus == 9;

  /// Check if OTP is verified
  bool get isOtpVerified => parotpstatus == 1;

  ParentModel copyWith({
    int? parId,
    String? partype,
    String? paremail,
    String? fathername,
    String? mothername,
    String? guardianname,
    String? fathermobile,
    String? mothermobile,
    String? guardianmobile,
    String? fatheroccupation,
    String? motheroccupation,
    String? guardianoccupation,
    String? approvedby,
    DateTime? approveddate,
    DateTime? terminateddate,
    String? terminatedby,
    int? activestatus,
    String? payincharge,
    String? payinchargemob,
    String? parpassword,
    int? parmobotp,
    int? parotpstatus,
  }) {
    return ParentModel(
      parId: parId ?? this.parId,
      partype: partype ?? this.partype,
      paremail: paremail ?? this.paremail,
      fathername: fathername ?? this.fathername,
      mothername: mothername ?? this.mothername,
      guardianname: guardianname ?? this.guardianname,
      fathermobile: fathermobile ?? this.fathermobile,
      mothermobile: mothermobile ?? this.mothermobile,
      guardianmobile: guardianmobile ?? this.guardianmobile,
      fatheroccupation: fatheroccupation ?? this.fatheroccupation,
      motheroccupation: motheroccupation ?? this.motheroccupation,
      guardianoccupation: guardianoccupation ?? this.guardianoccupation,
      approvedby: approvedby ?? this.approvedby,
      approveddate: approveddate ?? this.approveddate,
      terminateddate: terminateddate ?? this.terminateddate,
      terminatedby: terminatedby ?? this.terminatedby,
      activestatus: activestatus ?? this.activestatus,
      payincharge: payincharge ?? this.payincharge,
      payinchargemob: payinchargemob ?? this.payinchargemob,
      parpassword: parpassword ?? this.parpassword,
      parmobotp: parmobotp ?? this.parmobotp,
      parotpstatus: parotpstatus ?? this.parotpstatus,
    );
  }
}
