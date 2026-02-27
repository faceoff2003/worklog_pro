import 'package:freezed_annotation/freezed_annotation.dart';

/// Objet-Valeur (Value Object) représentant un montant monétaire.
/// 
/// **CRITIQUE** : L'argent informatique ne doit jamais être stocké en nombre 
/// à virgule flottante (`double`) sous peine d'erreurs d'arrondis subtiles
/// (ex: 0.1 + 0.2 = 0.30000000000000004).
/// C'est pourquoi cet objet force le stockage de TOUT montant en **centimes**
/// (un Entier `int`).
/// 
/// Exemple :
/// - 150,00€ → Money.fromCents(15000)
/// - 25,50€ → Money.fromCents(2550)
@immutable
class Money implements Comparable<Money> {
  /// Montant brut stocké en centimes (entier strictement exact).
  final int amountCents;

  const Money._(this.amountCents);

  /// Instancie depuis une somme en centimes.
  factory Money.fromCents(int cents) {
    return Money._(cents);
  }

  /// Instancie depuis une somme en Euros bruts (double).
  /// À utiliser avec précaution. Convertit et arrondit au centime le plus proche.
  factory Money.fromEuros(double euros) {
    final cents = (euros * 100).round();
    return Money._(cents);
  }

  /// Représente la valeur absolue de Zéro Euro (0 €).
  static const Money zero = Money._(0);

  /// Convertit la valeur en Euros (double).
  /// **ATTENTION** : À utiliser UNIQUEMENT pour l'affichage visuel, 
  /// JAMAIS pour des calculs ultérieurs (perte de précision).
  double get inEuros => amountCents / 100.0;

  /// Formatte la somme en chaîne lisible. Ex: "1 250,50 €" ou "-1 250,50 €".
  String toEurosString() {
    final absCents = amountCents.abs();
    final euros = absCents ~/ 100;
    final cents = absCents % 100;
    
    // Format euros with space thousands separator
    final eurosStr = euros.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]} ',
    );
    
    final sign = amountCents < 0 ? '-' : '';
    return '$sign$eurosStr,${cents.toString().padLeft(2, '0')} €';
  }

  /// Additionne deux montants monétaires de façon exacte.
  Money operator +(Money other) {
    return Money._(amountCents + other.amountCents);
  }

  /// Soustrait deux montants de façon exacte.
  Money operator -(Money other) {
    return Money._(amountCents - other.amountCents);
  }

  /// Multiplie le montant par un taux (le résultat est arrondi au centime le plus proche).
  Money operator *(num factor) {
    return Money._((amountCents * factor).round());
  }

  /// Divide by a factor (rounds to nearest cent)
  Money operator /(num divisor) {
    if (divisor == 0) {
      throw ArgumentError('Cannot divide by zero');
    }
    return Money._((amountCents / divisor).round());
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Money && amountCents == other.amountCents;
  }

  @override
  int get hashCode => amountCents.hashCode;

  bool operator <(Money other) => amountCents < other.amountCents;
  bool operator <=(Money other) => amountCents <= other.amountCents;
  bool operator >(Money other) => amountCents > other.amountCents;
  bool operator >=(Money other) => amountCents >= other.amountCents;
  
  Money operator -() => Money._(-amountCents);

  @override
  int compareTo(Money other) => amountCents.compareTo(other.amountCents);

  /// For debugging
  @override
  String toString() => toEurosString();

  /// Serialize to int for Firestore
  int toJson() => amountCents;

  /// Deserialize from int
  factory Money.fromJson(int cents) => Money.fromCents(cents);
}
