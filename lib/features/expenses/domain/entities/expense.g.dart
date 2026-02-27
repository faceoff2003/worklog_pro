// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Expense _$ExpenseFromJson(Map<String, dynamic> json) => _Expense(
      id: json['id'] as String,
      date: DateOnly.fromJson(json['date'] as String),
      clientId: json['clientId'] as String,
      projectId: json['projectId'] as String?,
      category: $enumDecode(_$ExpenseCategoryEnumMap, json['category']),
      amountHT: Money.fromJson((json['amountHT'] as num).toInt()),
      description: json['description'] as String,
      vendor: json['vendor'] as String?,
      materialCategory: $enumDecodeNullable(
          _$MaterialCategoryEnumMap, json['materialCategory']),
      travelMode: $enumDecodeNullable(_$TravelModeEnumMap, json['travelMode']),
      travelDistanceKm: (json['travelDistanceKm'] as num?)?.toDouble(),
      isBillable: json['isBillable'] as bool? ?? true,
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((e) => Attachment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$ExpenseToJson(_Expense instance) => <String, dynamic>{
      'id': instance.id,
      'date': instance.date.toJson(),
      'clientId': instance.clientId,
      'projectId': instance.projectId,
      'category': instance.category.toJson(),
      'amountHT': instance.amountHT.toJson(),
      'description': instance.description,
      'vendor': instance.vendor,
      'materialCategory': instance.materialCategory?.toJson(),
      'travelMode': instance.travelMode?.toJson(),
      'travelDistanceKm': instance.travelDistanceKm,
      'isBillable': instance.isBillable,
      'attachments': instance.attachments.map((e) => e.toJson()).toList(),
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

const _$ExpenseCategoryEnumMap = {
  ExpenseCategory.materials: 'materials',
  ExpenseCategory.travel: 'travel',
  ExpenseCategory.food: 'food',
  ExpenseCategory.other: 'other',
};

const _$MaterialCategoryEnumMap = {
  MaterialCategory.cables: 'cables',
  MaterialCategory.disjoncteurs: 'disjoncteurs',
  MaterialCategory.goulottes: 'goulottes',
  MaterialCategory.outillage: 'outillage',
  MaterialCategory.luminaires: 'luminaires',
  MaterialCategory.prises_interrupteurs: 'prises_interrupteurs',
  MaterialCategory.tableau: 'tableau',
  MaterialCategory.autre: 'autre',
};

const _$TravelModeEnumMap = {
  TravelMode.per_km: 'per_km',
  TravelMode.forfait: 'forfait',
  TravelMode.non_facture: 'non_facture',
};
