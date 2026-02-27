/// Client type enumeration
enum ClientType {
  patron,
  client_particulier,
  entreprise;

  String get displayName {
    switch (this) {
      case ClientType.patron:
        return 'Patron';
      case ClientType.client_particulier:
        return 'Client Particulier';
      case ClientType.entreprise:
        return 'Entreprise';
    }
  }

  /// Serialize for Firestore
  String toJson() {
    switch (this) {
      case ClientType.patron:
        return 'patron';
      case ClientType.client_particulier:
        return 'client_particulier';
      case ClientType.entreprise:
        return 'entreprise';
    }
  }

  /// Deserialize from Firestore
  static ClientType fromJson(String value) {
    try {
      return ClientType.values.firstWhere((e) => e.toJson() == value);
    } catch (_) {
      throw ArgumentError('Invalid ClientType: $value');
    }
  }
}

/// Project type enumeration
enum ProjectType {
  nouvelle_installation,
  mise_en_conformite,
  depannage,
  renovation,
  domotique,
  autre;

  String get displayName {
    switch (this) {
      case ProjectType.nouvelle_installation:
        return 'Nouvelle Installation';
      case ProjectType.mise_en_conformite:
        return 'Mise en Conformité';
      case ProjectType.depannage:
        return 'Dépannage';
      case ProjectType.renovation:
        return 'Rénovation';
      case ProjectType.domotique:
        return 'Domotique';
      case ProjectType.autre:
        return 'Autre';
    }
  }

  String toJson() {
    switch (this) {
      case ProjectType.nouvelle_installation:
        return 'nouvelle_installation';
      case ProjectType.mise_en_conformite:
        return 'mise_en_conformite';
      case ProjectType.depannage:
        return 'depannage';
      case ProjectType.renovation:
        return 'renovation';
      case ProjectType.domotique:
        return 'domotique';
      case ProjectType.autre:
        return 'autre';
    }
  }

  static ProjectType fromJson(String value) {
    try {
      return ProjectType.values.firstWhere((e) => e.toJson() == value);
    } catch (_) {
      throw ArgumentError('Invalid ProjectType: $value');
    }
  }
}

/// Project status enumeration
enum ProjectStatus {
  actif,
  termine,
  en_attente;

  String get displayName {
    switch (this) {
      case ProjectStatus.actif:
        return 'Actif';
      case ProjectStatus.termine:
        return 'Terminé';
      case ProjectStatus.en_attente:
        return 'En Attente';
    }
  }

  String toJson() {
    switch (this) {
      case ProjectStatus.actif:
        return 'actif';
      case ProjectStatus.termine:
        return 'termine';
      case ProjectStatus.en_attente:
        return 'en_attente';
    }
  }

  static ProjectStatus fromJson(String value) {
    try {
      return ProjectStatus.values.firstWhere((e) => e.toJson() == value);
    } catch (_) {
      throw ArgumentError('Invalid ProjectStatus: $value');
    }
  }
}

/// Billing mode enumeration
enum BillingMode {
  hourly,
  half_day,
  day,
  fixed_job;

  String get displayName {
    switch (this) {
      case BillingMode.hourly:
        return 'Horaire';
      case BillingMode.half_day:
        return 'Demi-Journée';
      case BillingMode.day:
        return 'Journée';
      case BillingMode.fixed_job:
        return 'Forfait';
    }
  }

  String toJson() {
    switch (this) {
      case BillingMode.hourly:
        return 'hourly';
      case BillingMode.half_day:
        return 'half_day';
      case BillingMode.day:
        return 'day';
      case BillingMode.fixed_job:
        return 'fixed_job';
    }
  }

  static BillingMode fromJson(String value) {
    try {
      return BillingMode.values.firstWhere((e) => e.toJson() == value);
    } catch (_) {
      throw ArgumentError('Invalid BillingMode: $value');
    }
  }
}

/// Expense category enumeration
enum ExpenseCategory {
  materials,
  travel,
  food,
  other;

  String get displayName {
    switch (this) {
      case ExpenseCategory.materials:
        return 'Marchandises';
      case ExpenseCategory.travel:
        return 'Déplacement';
      case ExpenseCategory.food:
        return 'Restauration';
      case ExpenseCategory.other:
        return 'Autre';
    }
  }

  String toJson() {
    switch (this) {
      case ExpenseCategory.materials:
        return 'materials';
      case ExpenseCategory.travel:
        return 'travel';
      case ExpenseCategory.food:
        return 'food';
      case ExpenseCategory.other:
        return 'other';
    }
  }

  static ExpenseCategory fromJson(String value) {
    try {
      return ExpenseCategory.values.firstWhere((e) => e.toJson() == value);
    } catch (_) {
      throw ArgumentError('Invalid ExpenseCategory: $value');
    }
  }
}

/// Material category enumeration
enum MaterialCategory {
  cables,
  disjoncteurs,
  goulottes,
  outillage,
  luminaires,
  prises_interrupteurs,
  tableau,
  autre;

  String get displayName {
    switch (this) {
      case MaterialCategory.cables:
        return 'Câbles';
      case MaterialCategory.disjoncteurs:
        return 'Disjoncteurs';
      case MaterialCategory.goulottes:
        return 'Goulottes';
      case MaterialCategory.outillage:
        return 'Outillage';
      case MaterialCategory.luminaires:
        return 'Luminaires';
      case MaterialCategory.prises_interrupteurs:
        return 'Prises/Interrupteurs';
      case MaterialCategory.tableau:
        return 'Tableau';
      case MaterialCategory.autre:
        return 'Autre';
    }
  }

  String toJson() {
    switch (this) {
      case MaterialCategory.cables:
        return 'cables';
      case MaterialCategory.disjoncteurs:
        return 'disjoncteurs';
      case MaterialCategory.goulottes:
        return 'goulottes';
      case MaterialCategory.outillage:
        return 'outillage';
      case MaterialCategory.luminaires:
        return 'luminaires';
      case MaterialCategory.prises_interrupteurs:
        return 'prises_interrupteurs';
      case MaterialCategory.tableau:
        return 'tableau';
      case MaterialCategory.autre:
        return 'autre';
    }
  }

  static MaterialCategory fromJson(String value) {
    try {
      return MaterialCategory.values.firstWhere((e) => e.toJson() == value);
    } catch (_) {
      throw ArgumentError('Invalid MaterialCategory: $value');
    }
  }
}

/// Travel mode enumeration
enum TravelMode {
  per_km,
  forfait,
  non_facture;

  String get displayName {
    switch (this) {
      case TravelMode.per_km:
        return 'Par Kilomètre';
      case TravelMode.forfait:
        return 'Forfait';
      case TravelMode.non_facture:
        return 'Non Facturé';
    }
  }

  String toJson() {
    switch (this) {
      case TravelMode.per_km:
        return 'per_km';
      case TravelMode.forfait:
        return 'forfait';
      case TravelMode.non_facture:
        return 'non_facture';
    }
  }

  static TravelMode fromJson(String value) {
    try {
      return TravelMode.values.firstWhere((e) => e.toJson() == value);
    } catch (_) {
      throw ArgumentError('Invalid TravelMode: $value');
    }
  }
}

/// Payment method enumeration
enum PaymentMethod {
  cash,
  virement,
  autre;

  String get displayName {
    switch (this) {
      case PaymentMethod.cash:
        return 'Espèces';
      case PaymentMethod.virement:
        return 'Virement';
      case PaymentMethod.autre:
        return 'Autre';
    }
  }

  String toJson() {
    switch (this) {
      case PaymentMethod.cash:
        return 'cash';
      case PaymentMethod.virement:
        return 'virement';
      case PaymentMethod.autre:
        return 'autre';
    }
  }

  static PaymentMethod fromJson(String value) {
    try {
      return PaymentMethod.values.firstWhere((e) => e.toJson() == value);
    } catch (_) {
      throw ArgumentError('Invalid PaymentMethod: $value');
    }
  }
}

/// Payment status (calculated, not stored)
enum PaymentStatus {
  a_facturer,
  facture,
  paye_partiel,
  solde;

  String get displayName {
    switch (this) {
      case PaymentStatus.a_facturer:
        return 'À Facturer';
      case PaymentStatus.facture:
        return 'Facturé';
      case PaymentStatus.paye_partiel:
        return 'Payé Partiellement';
      case PaymentStatus.solde:
        return 'Soldé';
    }
  }
}
