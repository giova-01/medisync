import 'package:medisync/features/vital_signs/domain/entities/signo_vital.dart';
import 'package:medisync/features/vital_signs/domain/entities/tipo_signo_vital.dart';

class SignoVitalDto {
  final int id;
  final String tipo;
  final double valor;
  final String fechaMedicion;

  const SignoVitalDto({
    required this.id,
    required this.tipo,
    required this.valor,
    required this.fechaMedicion,
  });

  factory SignoVitalDto.fromJson(Map<String, dynamic> json) => SignoVitalDto(
        id: json['id'] as int,
        tipo: json['tipo'] as String,
        valor: (json['valor'] as num).toDouble(),
        fechaMedicion: json['fecha_medicion'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'tipo': tipo,
        'valor': valor,
        'fecha_medicion': fechaMedicion,
      };

  SignoVital toEntity() => SignoVital(
        id: id,
        tipo: TipoSignoVitalX.fromApiValue(tipo),
        valor: valor,
        fechaMedicion: DateTime.parse(fechaMedicion),
      );
}
