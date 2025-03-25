import 'package:mobx/mobx.dart';
import 'package:boilerplate/core/stores/form/form_store.dart';
import 'package:boilerplate/core/stores/error/error_store.dart';
import 'package:boilerplate/domain/entity/user/user.dart';
import 'package:boilerplate/domain/usecase/user/register_usecase.dart';

part 'register_store.g.dart';

// ignore: library_private_types_in_public_api
class RegisterStore = _RegisterStore with _$RegisterStore;

abstract class _RegisterStore with Store {
  final FormStore formStore;
  final ErrorStore errorStore;
  final RegisterUseCase _registerUseCase;

  _RegisterStore(this.formStore, this.errorStore, this._registerUseCase) {
    _setupDisposers();
  }

  late List<ReactionDisposer> _disposers;
  void _setupDisposers() {
    _disposers = [
      reaction((_) => formStore.userEmail, formStore.validateUserEmail),
      reaction((_) => formStore.password, formStore.validatePassword),
      reaction(
        (_) => formStore.confirmPassword,
        formStore.validateConfirmPassword,
      ),
    ];
  }

  @computed
  bool get canRegister => formStore.canRegister;

  @observable
  bool success = false;

  @observable
  bool loading = false;

  @observable
  ObservableFuture<User?> loginFuture = ObservableFuture.value(null);

  @computed
  bool get isLoading => loginFuture.status == FutureStatus.pending;

  @observable
  ObservableFuture<User?> registerFuture = ObservableFuture.value(null);

  @action
  void setUserEmail(String value) {
    formStore.setUserId(value);
  }

  @action
  void setPassword(String value) {
    formStore.setPassword(value);
  }

  @action
  void setConfirmPassword(String value) {
    formStore.setConfirmPassword(value);
  }

  @action
  Future register() async {}

  @action
  Future registerWithValue(String email, String password) async {
    if (!canRegister) return;

    loading = true;

    final registerParams = RegisterParams(email: email, password: password);

    final future = _registerUseCase.call(params: registerParams);
    registerFuture = ObservableFuture(future);

    try {
      await future.then((user) async {
        if (user != null) {
          loading = false;
          success = true;
        }
      });
    } catch (e) {
      loading = false;
      success = false;
      errorStore.errorMessage = e.toString();
      rethrow;
    }
  }

  void dispose() {
    for (final d in _disposers) {
      d();
    }
  }
}
