import 'package:freezed_annotation/freezed_annotation.dart';

/// Address structure for projects/clients
@immutable
class Address {
  final String? street;
  final String? number;
  final String? zip;
  final String? city;
  final String country;

  const Address({
    this.street,
    this.number,
    this.zip,
    this.city,
    this.country = 'Belgique',
  });

  /// Empty address
  static const Address empty = Address();

  /// Check if address has any data
  bool get isEmpty => street == null && number == null && zip == null && city == null;
  bool get isNotEmpty => !isEmpty;

  /// Format as single line
  /// Example: "Rue de la Paix 42, 1000 Bruxelles, Belgique"
  String format() {
    final parts = <String>[];
    
    if (street != null && number != null) {
      parts.add('$street $number');
    } else if (street != null) {
      parts.add(street!);
    }
    
    if (zip != null && city != null) {
      parts.add('$zip $city');
    } else if (city != null) {
      parts.add(city!);
    }
    
    if (parts.isEmpty) {
      return country;
    }
    
    parts.add(country);
    return parts.join(', ');
  }

  /// Format as multi-line
  String formatMultiLine() {
    final lines = <String>[];
    
    if (street != null && number != null) {
      lines.add('$street $number');
    } else if (street != null) {
      lines.add(street!);
    }
    
    if (zip != null && city != null) {
      lines.add('$zip $city');
    } else if (city != null) {
      lines.add(city!);
    }
    
    lines.add(country);
    return lines.join('\n');
  }

  /// Copy with modifications
  Address copyWith({
    String? street,
    String? number,
    String? zip,
    String? city,
    String? country,
  }) {
    return Address(
      street: street ?? this.street,
      number: number ?? this.number,
      zip: zip ?? this.zip,
      city: city ?? this.city,
      country: country ?? this.country,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Address &&
            street == other.street &&
            number == other.number &&
            zip == other.zip &&
            city == other.city &&
            country == other.country;
  }

  @override
  int get hashCode => Object.hash(street, number, zip, city, country);

  @override
  String toString() => format();

  /// Serialize to map for Firestore
  Map<String, dynamic> toJson() {
    return {
      if (street != null) 'street': street,
      if (number != null) 'number': number,
      if (zip != null) 'zip': zip,
      if (city != null) 'city': city,
      'country': country,
    };
  }

  /// Deserialize from map
  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      street: json['street'] as String?,
      number: json['number'] as String?,
      zip: json['zip'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String? ?? 'Belgique',
    );
  }
}
