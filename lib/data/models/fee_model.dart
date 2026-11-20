import '../../core/utils/server_time.dart';

/// Fee status based on paidstatus field ('P' = Paid, 'U' = Unpaid)
enum FeeStatus { pending, partial, paid, overdue }

/// Fee Group model matching Supabase 'feegroup' table
class FeeGroupModel {
  final int fgId;
  final String fgdesc;
  final int? banId;
  final int insId;
  final int yrId;
  final String yrlabel;
  final int activestatus;

  FeeGroupModel({
    required this.fgId,
    required this.fgdesc,
    this.banId,
    required this.insId,
    required this.yrId,
    required this.yrlabel,
    this.activestatus = 1,
  });

  factory FeeGroupModel.fromJson(Map<String, dynamic> json) {
    return FeeGroupModel(
      fgId: int.tryParse('${json['fg_id'] ?? ''}') ?? 0,
      fgdesc: json['fgdesc'] ?? '',
      banId: json['ban_id'] != null
          ? (json['ban_id'] is int ? json['ban_id'] : int.parse(json['ban_id'].toString()))
          : null,
      insId: json['ins_id'] is int ? json['ins_id'] : int.parse(json['ins_id'].toString()),
      // School fee types / groups are shared by every year (no yr_id).
      yrId: int.tryParse('${json['yr_id'] ?? ''}') ?? 0,
      yrlabel: json['yrlabel'] ?? '',
      activestatus: json['activestatus'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'fg_id': fgId,
    'fgdesc': fgdesc,
    'ban_id': banId,
    'ins_id': insId,
    'yr_id': yrId,
    'yrlabel': yrlabel,
    'activestatus': activestatus,
  };
}

/// Fee Type model matching Supabase 'feetype' table
class FeeTypeModel {
  final int feeId;
  final String feedesc;
  final String feeshort;
  final int? feeoptional;
  final int? feecategory;
  final int fgId;
  final int yrId;
  final String yrlabel;
  final int activestatus;

  // Joined data from feegroup
  final FeeGroupModel? feeGroup;

  FeeTypeModel({
    required this.feeId,
    required this.feedesc,
    required this.feeshort,
    this.feeoptional,
    this.feecategory,
    required this.fgId,
    required this.yrId,
    required this.yrlabel,
    this.activestatus = 1,
    this.feeGroup,
  });

  factory FeeTypeModel.fromJson(Map<String, dynamic> json) {
    return FeeTypeModel(
      feeId: json['fee_id'] is int ? json['fee_id'] : int.parse(json['fee_id'].toString()),
      feedesc: json['feedesc'] ?? '',
      feeshort: json['feeshort'] ?? '',
      feeoptional: json['feeoptional'],
      feecategory: json['feecategory'],
      fgId: int.tryParse('${json['fg_id'] ?? ''}') ?? 0,
      // School fee types / groups are shared by every year (no yr_id).
      yrId: int.tryParse('${json['yr_id'] ?? ''}') ?? 0,
      yrlabel: json['yrlabel'] ?? '',
      activestatus: json['activestatus'] ?? 1,
      feeGroup: json['feegroup'] != null ? FeeGroupModel.fromJson(json['feegroup']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'fee_id': feeId,
    'feedesc': feedesc,
    'feeshort': feeshort,
    'feeoptional': feeoptional,
    'feecategory': feecategory,
    'fg_id': fgId,
    'yr_id': yrId,
    'yrlabel': yrlabel,
    'activestatus': activestatus,
  };

  /// Get fee group name (from joined data or empty)
  String get feeGroupName => feeGroup?.fgdesc ?? '';
}

/// Fee demand model matching Supabase 'feedemand' table
class FeeModel {
  final int demId;
  final String demno;
  final int insId;
  final String inscode;
  final int yrId;
  final String demseqtype; // Sequence type for fee demand ('ARREAR' vs regular)
  final String? arrearclass; // Original class an arrear demand is carried from
  final int stuId;
  final String stuadmno;
  final String stuclass;
  final String demfeeyear;
  final String demfeeterm;
  final int? feeId; // NEW: Links to feetype table
  final String demfeetype;
  final String? demfeecategory;
  final double feeamount;
  final int? conId;
  final double conamount;
  final double paidamount;
  final double balancedue;
  final double fineamount;
  final int? payId;
  final String paidstatus;
  final String createdby;
  final DateTime createdat;
  final int activestatus;
  final DateTime? inactivedate;
  final DateTime? duedate;

  // Joined data from feetype/feegroup
  final FeeTypeModel? feeType;

  FeeModel({
    required this.demId,
    required this.demno,
    required this.insId,
    required this.inscode,
    required this.yrId,
    required this.demseqtype,
    this.arrearclass,
    required this.stuId,
    required this.stuadmno,
    required this.stuclass,
    required this.demfeeyear,
    required this.demfeeterm,
    this.feeId,
    required this.demfeetype,
    this.demfeecategory,
    required this.feeamount,
    this.conId,
    this.conamount = 0,
    this.paidamount = 0,
    required this.balancedue,
    this.fineamount = 0,
    this.payId,
    required this.paidstatus,
    required this.createdby,
    required this.createdat,
    this.activestatus = 1,
    this.inactivedate,
    this.duedate,
    this.feeType,
  });

  /// Create from Supabase JSON response
  factory FeeModel.fromJson(Map<String, dynamic> json) {
    return FeeModel(
      demId: json['dem_id'] is int ? json['dem_id'] : int.parse(json['dem_id'].toString()),
      demno: json['demno'] ?? '',
      insId: json['ins_id'] is int ? json['ins_id'] : int.parse(json['ins_id'].toString()),
      inscode: json['inscode'] ?? '',
      // yr_id is nullable — arrear demands carry NULL (their year isn't in the
      // year master). Parse null-safely so one arrear row can't crash the list.
      yrId: json['yr_id'] is int ? json['yr_id'] : (int.tryParse(json['yr_id']?.toString() ?? '') ?? 0),
      demseqtype: json['demseqtype'] ?? '',
      arrearclass: json['arrearclass'],
      stuId: json['stu_id'] is int ? json['stu_id'] : (int.tryParse(json['stu_id']?.toString() ?? '') ?? 0),
      stuadmno: json['stuadmno'] ?? '',
      stuclass: json['stuclass'] ?? '',
      demfeeyear: json['demfeeyear'] ?? '',
      demfeeterm: json['demfeeterm'] ?? '',
      feeId: json['fee_id'] != null
          ? (json['fee_id'] is int ? json['fee_id'] : int.parse(json['fee_id'].toString()))
          : null,
      demfeetype: json['demfeetype'] ?? '',
      demfeecategory: json['demfeecategory'],
      feeamount: (json['feeamount'] as num?)?.toDouble() ?? 0,
      conId: json['con_id'] != null
          ? (json['con_id'] is int ? json['con_id'] : int.parse(json['con_id'].toString()))
          : null,
      conamount: (json['conamount'] as num?)?.toDouble() ?? 0,
      paidamount: (json['paidamount'] as num?)?.toDouble() ?? 0,
      balancedue: (json['balancedue'] as num?)?.toDouble() ?? 0,
      fineamount: (json['fineamount'] as num?)?.toDouble() ?? 0,
      payId: json['pay_id'] != null
          ? (json['pay_id'] is int ? json['pay_id'] : int.parse(json['pay_id'].toString()))
          : null,
      paidstatus: json['paidstatus'] ?? 'U',
      createdby: json['createdby'] ?? '',
      createdat: json['createdat'] != null
          ? parseServerTimeOr(json['createdat'], DateTime.now())
          : DateTime.now(),
      activestatus: json['activestatus'] ?? 1,
      inactivedate: json['inactivedate'] != null
          ? DateTime.parse(json['inactivedate'])
          : null,
      duedate: json['duedate'] != null
          ? DateTime.parse(json['duedate'])
          : null,
      feeType: json['feetype'] != null ? FeeTypeModel.fromJson(json['feetype']) : null,
    );
  }

  /// Convert to JSON for Supabase insert/update
  Map<String, dynamic> toJson() {
    return {
      'dem_id': demId,
      'demno': demno,
      'ins_id': insId,
      'inscode': inscode,
      'yr_id': yrId,
      'demseqtype': demseqtype,
      'arrearclass': arrearclass,
      'stu_id': stuId,
      'stuadmno': stuadmno,
      'stuclass': stuclass,
      'demfeeyear': demfeeyear,
      'demfeeterm': demfeeterm,
      'fee_id': feeId,
      'demfeetype': demfeetype,
      'demfeecategory': demfeecategory,
      'feeamount': feeamount,
      'con_id': conId,
      'conamount': conamount,
      'paidamount': paidamount,
      'balancedue': balancedue,
      'fineamount': fineamount,
      'pay_id': payId,
      'paidstatus': paidstatus,
      'createdby': createdby,
      'activestatus': activestatus,
    };
  }

  /// Helper getters for UI display (backward compatible with old model)
  String get id => demId.toString();
  String get feeTypeName => demfeetype;
  String get term => '$demfeeterm ($demfeeyear)';
  double get amount => feeamount;
  double get discountAmount => conamount;
  double get totalAmount => feeamount - conamount;
  double get balanceAmount => balancedue;
  double get paidAmount => paidamount;

  /// True when this demand is an arrear (carried-forward) fee.
  bool get isArrear => demseqtype.trim().toUpperCase() == 'ARREAR';

  /// Label for the arrear's original class, or empty when not an arrear / unknown.
  String get arrearClassLabel => (arrearclass ?? '').trim();

  /// Late fee - not in feedemand table, returns 0
  double get lateFee => 0;

  /// Due date - from duedate column, falls back to createdat if null
  DateTime get dueDate => duedate ?? createdat;

  FeeStatus get status {
    if (paidstatus == 'P') return FeeStatus.paid;
    if (paidamount > 0 && balancedue > 0) return FeeStatus.partial;
    return FeeStatus.pending;
  }

  bool get isPaid => paidstatus == 'P';
  bool get isActive => activestatus == 1;

  FeeModel copyWith({
    int? demId,
    String? demno,
    int? insId,
    String? inscode,
    int? yrId,
    String? demseqtype,
    String? arrearclass,
    int? stuId,
    String? stuadmno,
    String? stuclass,
    String? demfeeyear,
    String? demfeeterm,
    int? feeId,
    String? demfeetype,
    String? demfeecategory,
    double? feeamount,
    int? conId,
    double? conamount,
    double? paidamount,
    double? balancedue,
    double? fineamount,
    int? payId,
    String? paidstatus,
    String? createdby,
    DateTime? createdat,
    int? activestatus,
    DateTime? inactivedate,
    DateTime? duedate,
    FeeTypeModel? feeType,
  }) {
    return FeeModel(
      demId: demId ?? this.demId,
      demno: demno ?? this.demno,
      insId: insId ?? this.insId,
      inscode: inscode ?? this.inscode,
      yrId: yrId ?? this.yrId,
      demseqtype: demseqtype ?? this.demseqtype,
      arrearclass: arrearclass ?? this.arrearclass,
      stuId: stuId ?? this.stuId,
      stuadmno: stuadmno ?? this.stuadmno,
      stuclass: stuclass ?? this.stuclass,
      demfeeyear: demfeeyear ?? this.demfeeyear,
      demfeeterm: demfeeterm ?? this.demfeeterm,
      feeId: feeId ?? this.feeId,
      demfeetype: demfeetype ?? this.demfeetype,
      demfeecategory: demfeecategory ?? this.demfeecategory,
      feeamount: feeamount ?? this.feeamount,
      conId: conId ?? this.conId,
      conamount: conamount ?? this.conamount,
      paidamount: paidamount ?? this.paidamount,
      balancedue: balancedue ?? this.balancedue,
      fineamount: fineamount ?? this.fineamount,
      payId: payId ?? this.payId,
      paidstatus: paidstatus ?? this.paidstatus,
      createdby: createdby ?? this.createdby,
      createdat: createdat ?? this.createdat,
      activestatus: activestatus ?? this.activestatus,
      inactivedate: inactivedate ?? this.inactivedate,
      duedate: duedate ?? this.duedate,
      feeType: feeType ?? this.feeType,
    );
  }

  /// Helper getters for fee type/group info from joined data
  String get feeGroupName => feeType?.feeGroupName ?? '';
  String get feeCategory => feeType?.feecategory?.toString() ?? '';
  bool get isTransportFee => feeType?.feeGroup?.fgdesc.toLowerCase().contains('transport') ??
                              demfeetype.toLowerCase().contains('transport') ||
                              demfeetype.toLowerCase().contains('bus') ||
                              demfeetype.toLowerCase().contains('van');
}

/// Fee summary for dashboard display
class FeeSummary {
  final double totalDue;
  final double totalPaid;
  final double totalPending;
  final int pendingCount;
  final int overdueCount;
  final DateTime? nextDueDate;

  FeeSummary({
    required this.totalDue,
    required this.totalPaid,
    required this.totalPending,
    required this.pendingCount,
    required this.overdueCount,
    this.nextDueDate,
  });
}
