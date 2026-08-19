enum HitStatus { idle, checking, ok, timeout, fail }

class Hit {
  const Hit({this.status = HitStatus.idle, this.ms, this.detail, this.at});

  final HitStatus status;
  final int? ms;
  final String? detail;
  final DateTime? at;

  static const idle = Hit();
  static const checking = Hit(status: HitStatus.checking);

  Hit copyWith({HitStatus? status, int? ms, String? detail, DateTime? at}) {
    return Hit(
      status: status ?? this.status,
      ms: ms ?? this.ms,
      detail: detail ?? this.detail,
      at: at ?? this.at,
    );
  }

  String get readout {
    switch (status) {
      case HitStatus.idle:
        return '·';
      case HitStatus.checking:
        return '…';
      case HitStatus.ok:
        return ms == null ? 'ok' : '${ms}ms';
      case HitStatus.timeout:
        return 'to';
      case HitStatus.fail:
        return detail == null || detail!.isEmpty ? 'fail' : detail!;
    }
  }

  bool get isLive => status == HitStatus.checking;
}

class NicChoice {
  const NicChoice({required this.id, required this.label, this.address});

  final String id;
  final String label;
  final String? address;

  static const any = NicChoice(id: 'any', label: 'any NIC');
}
