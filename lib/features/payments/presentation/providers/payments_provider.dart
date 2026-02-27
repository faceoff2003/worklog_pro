import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worklog_pro/features/payments/data/repositories/payment_repository_impl.dart';
import 'package:worklog_pro/features/payments/domain/entities/payment.dart';
import 'package:worklog_pro/features/payments/domain/repositories/payment_repository.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepositoryImpl(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
  );
});

final paymentsStreamProvider = StreamProvider.family<List<Payment>, String?>((ref, clientId) {
  final repository = ref.watch(paymentRepositoryProvider);
  return repository.watchPayments(clientId: clientId);
});

final paymentsControllerProvider = StateNotifierProvider<PaymentsController, AsyncValue<void>>((ref) {
  return PaymentsController(ref.watch(paymentRepositoryProvider));
});

class PaymentsController extends StateNotifier<AsyncValue<void>> {
  final PaymentRepository _repository;

  PaymentsController(this._repository) : super(const AsyncValue.data(null));

  Future<void> createPayment(Payment payment) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.createPayment(payment));
  }

  Future<void> updatePayment(Payment payment) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.updatePayment(payment));
  }

  Future<void> deletePayment(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.deletePayment(id));
  }
}
