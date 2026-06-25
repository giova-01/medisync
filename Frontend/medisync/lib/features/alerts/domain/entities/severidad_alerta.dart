enum SeveridadAlerta { info, warning, critical }

extension SeveridadAlertaX on SeveridadAlerta {
  String get apiValue => switch (this) {
        SeveridadAlerta.info => 'info',
        SeveridadAlerta.warning => 'warning',
        SeveridadAlerta.critical => 'critical',
      };

  static SeveridadAlerta fromApiValue(String v) => switch (v) {
        'warning' => SeveridadAlerta.warning,
        'critical' => SeveridadAlerta.critical,
        _ => SeveridadAlerta.info,
      };
}
