

import 'package:rah_app/data/datasources/exit_info_http_data_source.dart';
import 'package:rah_app/domain/entities/exit_info.dart';
import 'package:rah_app/domain/repositories/exit_info_repository.dart';

class ExitInfoRepositoryImpl implements ExitInfoRepository {
  const ExitInfoRepositoryImpl(this._dataSource);

  final ExitInfoHttpDataSource _dataSource;

  @override
  Future<ExitInfo?> fetch({String? proxy}) => _dataSource.fetch(proxy: proxy);
}
