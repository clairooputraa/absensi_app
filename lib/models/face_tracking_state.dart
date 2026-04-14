// lib/models/face_tracking_state.dart
import 'package:flutter/material.dart';

enum FaceTrackingState {
  idle,
  detecting,
  detected,
  verifying,
  verified,
  failed,
}

class FaceTrackingStateModel {
  final FaceTrackingState state;
  final String message;
  final double? confidence;

  FaceTrackingStateModel({
    required this.state,
    required this.message,
    this.confidence,
  });

  factory FaceTrackingStateModel.idle() {
    return FaceTrackingStateModel(
      state: FaceTrackingState.idle,
      message: 'Siap mendeteksi wajah',
    );
  }

  factory FaceTrackingStateModel.detecting() {
    return FaceTrackingStateModel(
      state: FaceTrackingState.detecting,
      message: 'Mendeteksi wajah...',
    );
  }

  factory FaceTrackingStateModel.detected() {
    return FaceTrackingStateModel(
      state: FaceTrackingState.detected,
      message: 'Wajah terdeteksi',
    );
  }

  factory FaceTrackingStateModel.verifying() {
    return FaceTrackingStateModel(
      state: FaceTrackingState.verifying,
      message: 'Memverifikasi wajah...',
    );
  }

  factory FaceTrackingStateModel.verified(double confidence) {
    return FaceTrackingStateModel(
      state: FaceTrackingState.verified,
      message: 'Verifikasi berhasil',
      confidence: confidence,
    );
  }

  factory FaceTrackingStateModel.failed(String error) {
    return FaceTrackingStateModel(
      state: FaceTrackingState.failed,
      message: error,
    );
  }
}
