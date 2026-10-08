
import 'package:rah_app/domain/entities/exit_info.dart';

abstract interface class ExitInfoRepository {
  Future<ExitInfo?> fetch({String? proxy});
}
