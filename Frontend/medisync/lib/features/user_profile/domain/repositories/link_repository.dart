import 'package:medisync/core/errors/either.dart';
import 'package:medisync/core/errors/failures.dart';
import 'package:medisync/features/user_profile/domain/entities/vinculo.dart';

abstract interface class LinkRepository {
  Future<Either<Failure, Vinculo>> requestLink(RequestLinkParams params);
  Future<Either<Failure, Vinculo>> respondLink(RespondLinkParams params);
  Future<Either<Failure, List<Vinculo>>> listLinks();
  Future<Either<Failure, void>> revokeLink(int vinculoId);
}

class RequestLinkParams {
  final String targetEmail;
  final TipoVinculo rol;

  const RequestLinkParams({required this.targetEmail, required this.rol});
}

class RespondLinkParams {
  final int vinculoId;
  final bool aceptar;

  const RespondLinkParams({required this.vinculoId, required this.aceptar});
}
