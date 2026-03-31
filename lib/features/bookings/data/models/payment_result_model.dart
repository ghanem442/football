class PaymentResultModel {
  final bool success;
  final PaymentDataModel? data;
  final PaymentErrorModel? error;
  final String? message;
  final String? status;
  final Map<String, dynamic>? raw;

  const PaymentResultModel({
    required this.success,
    required this.data,
    required this.error,
    this.message,
    this.status,
    this.raw,
  });

  bool get isSuccess {
    if (success != true) return false;

    final dataStatus = data?.status.trim().toUpperCase();
    if (dataStatus == null || dataStatus.isEmpty) {
      return true;
    }

    return dataStatus == 'SUCCESS' ||
        dataStatus == 'SUCCEEDED' ||
        dataStatus == 'COMPLETED' ||
        dataStatus == 'PAID' ||
        dataStatus == 'CONFIRMED' ||
        dataStatus == 'PENDING' ||
        dataStatus == 'INITIATED' ||
        dataStatus == 'CREATED';
  }

  String? get errorCode =>
      (error?.code.trim().isNotEmpty == true) ? error!.code.trim() : null;

  String get errorEn => error?.en ?? '';
  String get errorAr => error?.ar ?? '';

  String get rootMessage => (message ?? '').trim();
  String get rootStatus => (status ?? '').trim();

  String get userMessageAr {
    if (errorAr.trim().isNotEmpty) return errorAr.trim();
    if (errorEn.trim().isNotEmpty) return errorEn.trim();
    if (rootMessage.isNotEmpty) return rootMessage;
    if (errorCode?.isNotEmpty == true) return errorCode!;
    if (rootStatus.isNotEmpty) return rootStatus;
    return 'حدث خطأ أثناء الدفع';
  }

  String get userMessageEn {
    if (errorEn.trim().isNotEmpty) return errorEn.trim();
    if (errorAr.trim().isNotEmpty) return errorAr.trim();
    if (rootMessage.isNotEmpty) return rootMessage;
    if (errorCode?.isNotEmpty == true) return errorCode!;
    if (rootStatus.isNotEmpty) return rootStatus;
    return 'Payment failed';
  }

  String get redirectUrl {
    final dataRedirect = data?.redirectUrl?.trim() ?? '';
    if (dataRedirect.isNotEmpty) return dataRedirect;

    final rawRedirect = _pickFirstString(raw, const [
      'redirectUrl',
      'redirect_url',
      'paymentUrl',
      'payment_url',
      'url',
    ]);
    if (rawRedirect.isNotEmpty) return rawRedirect;

    return '';
  }

  String get paymentToken {
    final dataToken = data?.paymentToken?.trim() ?? '';
    if (dataToken.isNotEmpty) return dataToken;

    final rawToken = _pickFirstString(raw, const [
      'paymentToken',
      'payment_token',
      'token',
    ]);
    if (rawToken.isNotEmpty) return rawToken;

    return '';
  }

  String get iframeId {
    final dataIframeId = data?.iframeId?.trim() ?? '';
    if (dataIframeId.isNotEmpty) return dataIframeId;

    final rawIframeId = _pickFirstString(raw, const [
      'iframeId',
      'iframe_id',
    ]);
    if (rawIframeId.isNotEmpty) return rawIframeId;

    return '';
  }

  bool get hasRedirectUrl => redirectUrl.isNotEmpty;
  bool get hasPaymentToken => paymentToken.isNotEmpty;
  bool get hasIframeId => iframeId.isNotEmpty;

  factory PaymentResultModel.fromAny(dynamic raw) {
    if (raw is Map) {
      return PaymentResultModel.fromJson(Map<String, dynamic>.from(raw));
    }
    return const PaymentResultModel(
      success: false,
      data: null,
      error: null,
      message: null,
      status: null,
      raw: null,
    );
  }

  factory PaymentResultModel.fromJson(Map<String, dynamic> json) {
    final root = Map<String, dynamic>.from(json);

    final nestedData = root['data'];
    final dataMap = nestedData is Map<String, dynamic>
        ? nestedData
        : (nestedData is Map ? Map<String, dynamic>.from(nestedData) : null);

    final errJson = root['error'];

    final normalizedData = <String, dynamic>{
      if (dataMap != null) ...dataMap,
      if ((dataMap?['paymentId'] == null || '${dataMap?['paymentId']}'.isEmpty) &&
          root['paymentId'] != null)
        'paymentId': root['paymentId'],
      if ((dataMap?['transactionId'] == null ||
              '${dataMap?['transactionId']}'.isEmpty) &&
          root['transactionId'] != null)
        'transactionId': root['transactionId'],
      if ((dataMap?['status'] == null || '${dataMap?['status']}'.isEmpty) &&
          root['status'] != null)
        'status': root['status'],
      if ((dataMap?['redirectUrl'] == null ||
              '${dataMap?['redirectUrl']}'.isEmpty) &&
          root['redirectUrl'] != null)
        'redirectUrl': root['redirectUrl'],
      if ((dataMap?['paymentToken'] == null ||
              '${dataMap?['paymentToken']}'.isEmpty) &&
          root['paymentToken'] != null)
        'paymentToken': root['paymentToken'],
      if ((dataMap?['iframeId'] == null || '${dataMap?['iframeId']}'.isEmpty) &&
          root['iframeId'] != null)
        'iframeId': root['iframeId'],
      if ((dataMap?['amount'] == null || '${dataMap?['amount']}'.isEmpty) &&
          root['amount'] != null)
        'amount': root['amount'],
      if ((dataMap?['currency'] == null || '${dataMap?['currency']}'.isEmpty) &&
          root['currency'] != null)
        'currency': root['currency'],
    };

    final inferredSuccess = _inferSuccess(root, normalizedData);

    return PaymentResultModel(
      success: inferredSuccess,
      data: normalizedData.isNotEmpty
          ? PaymentDataModel.fromJson(normalizedData)
          : null,
      error: errJson is Map
          ? PaymentErrorModel.fromJson(Map<String, dynamic>.from(errJson))
          : null,
      message: root['message']?.toString(),
      status: root['status']?.toString(),
      raw: root,
    );
  }

  static bool _inferSuccess(
    Map<String, dynamic> root,
    Map<String, dynamic> normalizedData,
  ) {
    if (root['success'] == true) return true;
    if (root['success'] == false) return false;

    final error = root['error'];
    if (error != null) return false;

    final status = (normalizedData['status'] ?? root['status'] ?? '')
        .toString()
        .trim()
        .toUpperCase();

    if (status.isNotEmpty) {
      const positiveStatuses = {
        'SUCCESS',
        'SUCCEEDED',
        'COMPLETED',
        'PAID',
        'CONFIRMED',
        'PENDING',
        'INITIATED',
        'CREATED',
      };

      const negativeStatuses = {
        'FAILED',
        'FAIL',
        'ERROR',
        'REJECTED',
        'CANCELLED',
        'CANCELED',
      };

      if (positiveStatuses.contains(status)) return true;
      if (negativeStatuses.contains(status)) return false;
    }

    final hasUsefulPaymentPayload =
        _pickFirstString(root, const [
          'redirectUrl',
          'redirect_url',
          'paymentUrl',
          'payment_url',
          'paymentToken',
          'payment_token',
          'token',
          'iframeId',
          'iframe_id',
        ]).isNotEmpty ||
            _pickFirstString(normalizedData, const [
              'redirectUrl',
              'redirect_url',
              'paymentUrl',
              'payment_url',
              'paymentToken',
              'payment_token',
              'token',
              'iframeId',
              'iframe_id',
            ]).isNotEmpty;

    if (hasUsefulPaymentPayload) return true;

    return false;
  }

  static String _pickFirstString(
    Map<String, dynamic>? source,
    List<String> keys,
  ) {
    if (source == null) return '';

    for (final key in keys) {
      final value = source[key];
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }

    return '';
  }

  @override
  String toString() {
    return 'PaymentResultModel('
        'success: $success, '
        'status: $status, '
        'message: $message, '
        'errorCode: ${error?.code}, '
        'dataStatus: ${data?.status}, '
        'redirectUrl: ${data?.redirectUrl}, '
        'paymentToken: ${data?.paymentToken}, '
        'iframeId: ${data?.iframeId}, '
        'raw: $raw'
        ')';
  }
}

class PaymentDataModel {
  final String paymentId;
  final String transactionId;
  final String status;
  final String? redirectUrl;
  final String amount;
  final String currency;
  final String? paymentToken;
  final String? iframeId;

  const PaymentDataModel({
    required this.paymentId,
    required this.transactionId,
    required this.status,
    required this.redirectUrl,
    required this.amount,
    required this.currency,
    required this.paymentToken,
    required this.iframeId,
  });

  factory PaymentDataModel.fromJson(Map<String, dynamic> json) {
    return PaymentDataModel(
      paymentId: (json['paymentId'] ?? '').toString(),
      transactionId: (json['transactionId'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      redirectUrl: _firstNonEmpty(json, const [
        'redirectUrl',
        'redirect_url',
        'paymentUrl',
        'payment_url',
        'url',
      ]),
      amount: (json['amount'] ?? '0').toString(),
      currency: (json['currency'] ?? '').toString(),
      paymentToken: _firstNonEmpty(json, const [
        'paymentToken',
        'payment_token',
        'token',
      ]),
      iframeId: _firstNonEmpty(json, const [
        'iframeId',
        'iframe_id',
      ]),
    );
  }

  static String? _firstNonEmpty(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }
}

class PaymentErrorModel {
  final String code;
  final Map<String, dynamic> message;
  final String? plainMessage;

  const PaymentErrorModel({
    required this.code,
    required this.message,
    required this.plainMessage,
  });

  String get en {
    final mapValue = (message['en'] ?? '').toString().trim();
    if (mapValue.isNotEmpty) return mapValue;
    return (plainMessage ?? '').trim();
  }

  String get ar {
    final mapValue = (message['ar'] ?? '').toString().trim();
    if (mapValue.isNotEmpty) return mapValue;
    return (plainMessage ?? '').trim();
  }

  factory PaymentErrorModel.fromJson(Map<String, dynamic> json) {
    final rawMessage = json['message'];

    return PaymentErrorModel(
      code: (json['code'] ?? '').toString(),
      message: rawMessage is Map
          ? Map<String, dynamic>.from(rawMessage)
          : <String, dynamic>{},
      plainMessage: rawMessage is String ? rawMessage : null,
    );
  }
}