import 'package:worklog_pro/features/payments/domain/entities/payment.dart';

abstract class PaymentRepository {
  /// Watches payments, optionally filtered by client
  Stream<List<Payment>> watchPayments({String? clientId, String? projectId});

  /// Gets payments once, optionally filtered by client
  Future<List<Payment>> getPayments({String? clientId, String? projectId});

  /// Creates a new payment
  Future<void> createPayment(Payment payment);

  /// Updates an existing payment
  Future<void> updatePayment(Payment payment);

  /// Deletes a payment
  Future<void> deletePayment(String id);
}
