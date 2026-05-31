import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../shared/models/user.dart';
import 'auth_repository.dart';

// --- Events ---

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class AuthLoginRequested extends AuthEvent {
  const AuthLoginRequested({
    required this.identifier,
    required this.password,
    this.rememberMe = false,
  });

  final String identifier;
  final String password;
  final bool rememberMe;

  @override
  List<Object?> get props => [identifier, password, rememberMe];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

// --- States ---

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);

  final User user;

  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  const AuthError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

// --- Bloc ---

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({required this.authRepository}) : super(const AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  final AuthRepository authRepository;

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await authRepository.getCurrentUser();
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (_) {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      final user = await authRepository.login(
        identifier: event.identifier,
        password: event.password,
        rememberMe: event.rememberMe,
      );
      emit(AuthAuthenticated(user));
    } catch (e) {
      final message = _parseError(e);
      emit(AuthError(message));
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await authRepository.logout();
    emit(const AuthUnauthenticated());
  }

  String _parseError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
      return switch (error.type) {
        DioExceptionType.connectionTimeout => 'Sem conexão com o servidor',
        DioExceptionType.receiveTimeout    => 'Servidor demorou muito para responder',
        DioExceptionType.badResponse       => 'Erro ${error.response?.statusCode ?? "desconhecido"}',
        _                                  => 'Erro de rede',
      };
    }
    return error.toString();
  }
}
