import 'package:medisync/features/medication/data/models/medicamento_dto.dart';

abstract interface class MedLocalDataSource {
  List<MedicamentoDto>? getCachedMedications();
  void cacheMedications(List<MedicamentoDto> list);
  void clearCache();
}

class MedLocalDataSourceImpl implements MedLocalDataSource {
  List<MedicamentoDto>? _cache;

  @override
  List<MedicamentoDto>? getCachedMedications() => _cache;

  @override
  void cacheMedications(List<MedicamentoDto> list) => _cache = list;

  @override
  void clearCache() => _cache = null;
}
