

import 'package:rah_app/domain/entities/exit_info.dart';
import 'package:rah_app/domain/repositories/exit_info_repository.dart';

class ExitInfoUseCases {
  const ExitInfoUseCases(this._repository);

  final ExitInfoRepository _repository;

  Future<ExitInfo?> fetch({String? proxy}) => _repository.fetch(proxy: proxy);
}
