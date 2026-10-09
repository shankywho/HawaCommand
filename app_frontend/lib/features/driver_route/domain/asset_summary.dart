import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hawa_app/core/utils/contract_enums.dart';

part 'asset_summary.freezed.dart';
part 'asset_summary.g.dart';

/// The driver's machine and its HawaTag.
@freezed
abstract class AssetSummary with _$AssetSummary {
  const factory AssetSummary({
    required String id,
    required String label,
    required String type,
    required bool isSimulated,
    String? tagDeviceId,
    @Default(DeviceStatus.unknown) DeviceStatus tagStatus,
    DateTime? tagLastSeenAt,
  }) = _AssetSummary;

  const AssetSummary._();

  factory AssetSummary.fromJson(Map<String, Object?> json) => _$AssetSummaryFromJson(json);

  /// The HawaTag cannot confirm sprays: manual done becomes available (SCREENS D3).
  bool get tagCannotConfirm => tagStatus.cannotConfirm;
}
