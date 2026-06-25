import 'package:medisync/features/vital_signs/domain/entities/nivel_signo_vital.dart';
import 'package:medisync/features/vital_signs/domain/entities/tipo_signo_vital.dart';

class SignoVital {
  final int id;
  final TipoSignoVital tipo;
  final double valor;
  final DateTime fechaMedicion;

  const SignoVital({
    required this.id,
    required this.tipo,
    required this.valor,
    required this.fechaMedicion,
  });

  NivelSignoVital get nivel {
    final (normalMin, normalMax) = tipo.rangoNormal;
    if (valor >= normalMin && valor <= normalMax) return NivelSignoVital.normal;
    final (warnMin, warnMax) = tipo.rangoWarning;
    if (valor >= warnMin && valor <= warnMax) return NivelSignoVital.warning;
    return NivelSignoVital.critical;
  }
}
