import '../../core/utils/server_time.dart';

/// Payment status based on paystatus field
/// 'I' = Initiated, 'C' = Complete, 'F' = Failed, 'R' = Refunded
enum PaymentStatus { pending, success, failed, refunded }

/// Payment model matching Supabase 'payment' table
class PaymentModel {
  final int payId;
  final int insId;
  final String? inscode;
  final int stuId;
  final int yrId;
  final String? yrlabel;
  final double transtotalamount;
  final String transcurrency;
  final DateTime? paydate;
  final String? paystatus;
  final String? paymethod;
  final String? payreference;
  final String? paynumber;
  final int? paygwresponse;
  final String? createdby;
  final DateTime createdat;
  final int activestatus;
  final String reconStatus; // 'P' = Pending reconciliation, 'R' = Reconciled/Approved

  PaymentModel({
    required this.payId,
    required this.insId,
    this.inscode,
    this.stuId = 0,
    this.yrId = 0,
    this.yrlabel,
    this.transtotalamount = 0,
    this.transcurrency = 'INR',
    this.paydate,
    this.paystatus,
    this.paymethod,
    this.payreference,
    this.paynumber,
    this.paygwresponse,
    this.createdby,
    required this.createdat,
    this.activestatus = 1,
    this.reconStatus = 'P',
  });

  /// Create from Supabase JSON response
  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      payId: json['pay_id'] is int ? json['pay_id'] : int.parse(json['pay_id'].toString()),
      insId: json['ins_id'] is int ? json['ins_id'] : int.parse(json['ins_id'].toString()),
      inscode: json['inscode'],
      stuId: json['stu_id'] != null
          ? (json['stu_id'] is int ? json['stu_id'] : int.parse(json['stu_id'].toString()))
          : 0,
      yrId: json['yr_id'] != null
          ? (json['yr_id'] is int ? json['yr_id'] : int.parse(json['yr_id'].toString()))
          : 0,
      yrlabel: json['yrlabel'],
      transtotalamount: (json['transtotalamount'] as num?)?.toDouble() ?? 0,
      transcurrency: json['transcurrency'] ?? 'INR',
      paydate: parseServerTime(json['paydate']),
      paystatus: json['paystatus'],
      paymethod: json['paymethod'],
      payreference: json['payreference'],
      paynumber: json['paynumber'],
      paygwresponse: json['paygwresponse'] != null
          ? (json['paygwresponse'] is int ? json['paygwresponse'] : int.parse(json['paygwresponse'].toString()))
          : null,
      createdby: json['createdby'],
      createdat: json['createdat'] != null
          ? parseServerTimeOr(json['createdat'], DateTime.now())
          : DateTime.now(),
      activestatus: json['activestatus'] ?? 1,
      reconStatus: json['recon_status']?.toString() ?? 'P',
    );
  }

  /// Convert to JSON for Supabase insert/update
  Map<String, dynamic> toJson() {
    return {
      'pay_id': payId,
      'ins_id': insId,
      'inscode': inscode,
      'stu_id': stuId,
      'yr_id': yrId,
      'yrlabel': yrlabel,
      'transtotalamount': transtotalamount,
      'transcurrency': transcurrency,
      'paydate': paydate?.toIso8601String(),
      'paystatus': paystatus,
      'paymethod': paymethod,
      'payreference': payreference,
      'paynumber': paynumber,
      'paygwresponse': paygwresponse,
      'createdby': createdby,
      'activestatus': activestatus,
    };
  }

  /// Helper getters for UI display (backward compatible with old model)
  String get id => payId.toString();
  String get paymentNumber => paynumber ?? 'PAY${payId.toString().padLeft(6, '0')}';
  DateTime get createdAt => createdat;

  /// Total payment amount
  double get amount => transtotalamount;

  /// Details - empty list as placeholder, would need to fetch from shoppingcartdetails
  List<dynamic> get details => [];

  PaymentStatus get status {
    switch (paystatus) {
      case 'C':
        return PaymentStatus.success;
      case 'F':
        return PaymentStatus.failed;
      case 'R':
        return PaymentStatus.refunded;
      default:
        return PaymentStatus.pending;
    }
  }

  String get statusText {
    switch (paystatus) {
      case 'C':
        return 'Paid';
      case 'F':
        return 'Failed';
      case 'R':
        return 'Refunded';
      case 'I':
        return 'Initiated';
      default:
        return 'Pending';
    }
  }

  String get paymentMethod => paymethod ?? 'Unknown';
  String get transactionId => payreference ?? '';
  DateTime? get paidAt => paydate;
  bool get isActive => activestatus == 1;
  bool get isSuccess => paystatus == 'C';
  bool get isReconciled => reconStatus == 'R';
  bool get isPendingApproval => paystatus == 'C' && reconStatus == 'P';

  PaymentModel copyWith({
    int? payId,
    int? insId,
    String? inscode,
    int? stuId,
    int? yrId,
    String? yrlabel,
    double? transtotalamount,
    String? transcurrency,
    DateTime? paydate,
    String? paystatus,
    String? paymethod,
    String? payreference,
    String? paynumber,
    int? paygwresponse,
    String? createdby,
    DateTime? createdat,
    int? activestatus,
    String? reconStatus,
  }) {
    return PaymentModel(
      payId: payId ?? this.payId,
      insId: insId ?? this.insId,
      inscode: inscode ?? this.inscode,
      stuId: stuId ?? this.stuId,
      yrId: yrId ?? this.yrId,
      yrlabel: yrlabel ?? this.yrlabel,
      transtotalamount: transtotalamount ?? this.transtotalamount,
      transcurrency: transcurrency ?? this.transcurrency,
      paydate: paydate ?? this.paydate,
      paystatus: paystatus ?? this.paystatus,
      paymethod: paymethod ?? this.paymethod,
      payreference: payreference ?? this.payreference,
      paynumber: paynumber ?? this.paynumber,
      paygwresponse: paygwresponse ?? this.paygwresponse,
      createdby: createdby ?? this.createdby,
      createdat: createdat ?? this.createdat,
      activestatus: activestatus ?? this.activestatus,
      reconStatus: reconStatus ?? this.reconStatus,
    );
  }
}

/// Shopping cart model matching Supabase 'shoppingcart' table
class ShoppingCartModel {
  final int carId;
  final int yrId;
  final String? yrlabel;
  final int insId;
  final int stuId;
  final String transtype;
  final DateTime transdate;
  final String transcurrency;
  final double transtotalamount;
  final String carinitiated;
  final String createdby;
  final DateTime createdon;
  final int activestatus;

  ShoppingCartModel({
    required this.carId,
    required this.yrId,
    this.yrlabel,
    required this.insId,
    required this.stuId,
    required this.transtype,
    required this.transdate,
    required this.transcurrency,
    required this.transtotalamount,
    required this.carinitiated,
    required this.createdby,
    required this.createdon,
    this.activestatus = 1,
  });

  factory ShoppingCartModel.fromJson(Map<String, dynamic> json) {
    return ShoppingCartModel(
      carId: json['car_id'] is int ? json['car_id'] : int.parse(json['car_id'].toString()),
      yrId: int.tryParse('${json['yr_id'] ?? ''}') ?? 0,
      yrlabel: json['yrlabel'],
      insId: json['ins_id'] is int ? json['ins_id'] : int.parse(json['ins_id'].toString()),
      stuId: json['stu_id'] is int ? json['stu_id'] : int.parse(json['stu_id'].toString()),
      transtype: json['transtype'] ?? '',
      transdate: json['transdate'] != null
          ? DateTime.parse(json['transdate'])
          : DateTime.now(),
      transcurrency: json['transcurrency'] ?? 'INR',
      transtotalamount: (json['transtotalamount'] as num?)?.toDouble() ?? 0,
      carinitiated: json['carinitiated'] ?? 'N',
      createdby: json['createdby'] ?? '',
      createdon: json['createdon'] != null
          ? parseServerTimeOr(json['createdon'], DateTime.now())
          : DateTime.now(),
      activestatus: json['activestatus'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'yr_id': yrId,
      'yrlabel': yrlabel,
      'ins_id': insId,
      'stu_id': stuId,
      'transtype': transtype,
      'transdate': transdate.toIso8601String().split('T')[0],
      'transcurrency': transcurrency,
      'transtotalamount': transtotalamount,
      'carinitiated': carinitiated,
      'createdby': createdby,
      'activestatus': activestatus,
    };
  }

  double get amount => transtotalamount;
  String get currency => transcurrency;
  bool get isActive => activestatus == 1;
}

/// Shopping cart details model matching Supabase 'shoppingcartdetails' table
class ShoppingCartDetailModel {
  final int cdId;
  final int carId;
  final int yrId;
  final String? yrlabel;
  final int insId;
  final int demId;
  final int? transdetailId;
  final String transcurrency;
  final double transtotalamount;
  final int activestatus;

  ShoppingCartDetailModel({
    required this.cdId,
    required this.carId,
    required this.yrId,
    this.yrlabel,
    required this.insId,
    required this.demId,
    this.transdetailId,
    required this.transcurrency,
    required this.transtotalamount,
    this.activestatus = 1,
  });

  factory ShoppingCartDetailModel.fromJson(Map<String, dynamic> json) {
    return ShoppingCartDetailModel(
      cdId: json['cd_id'] is int ? json['cd_id'] : int.parse(json['cd_id'].toString()),
      carId: json['car_id'] is int ? json['car_id'] : int.parse(json['car_id'].toString()),
      yrId: int.tryParse('${json['yr_id'] ?? ''}') ?? 0,
      yrlabel: json['yrlabel'],
      insId: json['ins_id'] is int ? json['ins_id'] : int.parse(json['ins_id'].toString()),
      demId: json['dem_id'] is int ? json['dem_id'] : int.parse(json['dem_id'].toString()),
      transdetailId: json['transdetail_id'] != null
          ? (json['transdetail_id'] is int ? json['transdetail_id'] : int.parse(json['transdetail_id'].toString()))
          : null,
      transcurrency: json['transcurrency'] ?? 'INR',
      transtotalamount: (json['transtotalamount'] as num?)?.toDouble() ?? 0,
      activestatus: json['activestatus'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'car_id': carId,
      'yr_id': yrId,
      'yrlabel': yrlabel,
      'ins_id': insId,
      'dem_id': demId,
      'transdetail_id': transdetailId,
      'transcurrency': transcurrency,
      'transtotalamount': transtotalamount,
      'activestatus': activestatus,
    };
  }

  double get amount => transtotalamount;
  bool get isActive => activestatus == 1;
}

/// Payment detail model matching Supabase 'paymentdetails' table
class PaymentDetailModel {
  final int pydId;
  final int payId;
  final int demId;
  final int yrId;
  final String? yrlabel;
  final int insId;
  final String transcurrency;
  final double transtotalamount;
  final int activestatus;

  PaymentDetailModel({
    required this.pydId,
    required this.payId,
    required this.demId,
    required this.yrId,
    this.yrlabel,
    required this.insId,
    this.transcurrency = 'INR',
    required this.transtotalamount,
    this.activestatus = 1,
  });

  factory PaymentDetailModel.fromJson(Map<String, dynamic> json) {
    return PaymentDetailModel(
      pydId: json['pyd_id'] is int ? json['pyd_id'] : int.parse(json['pyd_id'].toString()),
      payId: json['pay_id'] is int ? json['pay_id'] : int.parse(json['pay_id'].toString()),
      demId: json['dem_id'] is int ? json['dem_id'] : int.parse(json['dem_id'].toString()),
      yrId: int.tryParse('${json['yr_id'] ?? ''}') ?? 0,
      yrlabel: json['yrlabel'],
      insId: json['ins_id'] is int ? json['ins_id'] : int.parse(json['ins_id'].toString()),
      transcurrency: json['transcurrency'] ?? 'INR',
      transtotalamount: (json['transtotalamount'] as num?)?.toDouble() ?? 0,
      activestatus: json['activestatus'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pay_id': payId,
      'dem_id': demId,
      'yr_id': yrId,
      'yrlabel': yrlabel,
      'ins_id': insId,
      'transcurrency': transcurrency,
      'transtotalamount': transtotalamount,
      'activestatus': activestatus,
    };
  }

  double get amount => transtotalamount;
  bool get isActive => activestatus == 1;
}
