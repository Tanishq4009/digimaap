import 'package:digimaap/pages/shared/notifications_page.dart';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart'
    as i_o;
import '../routes.dart';
import '../theme/colors.dart';
import '../models/verification_form.dart';
import '../models/data.dart';
import '../pages/inspector/inspection_detail_page.dart';

class SocketService {
  static final SocketService _instance =
      SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  i_o.Socket? socket;
  GlobalKey<NavigatorState>? _navKey;
  ValueNotifier<List<NotificationItem>>?
  _notificationsNotifier;
  String? _officerUserId;
  String? get officerUserId => _officerUserId;
  String? _gatcId;

  void joinOfficerRoom(String userId) {
    _officerUserId = userId;
    if (socket != null && socket!.connected) {
      socket!.emit('join_officer_room', {'userId': userId});
    }
  }

  void joinGatcRoom(String gatcId) {
    _gatcId = gatcId;
    if (socket != null && socket!.connected) {
      socket!.emit('join_gatc_room', {'gatcId': gatcId});
    }
  }

  void init({
    required GlobalKey<NavigatorState> navigatorKey,
    required ValueNotifier<List<NotificationItem>>
    notificationsNotifier,
  }) {
    _navKey = navigatorKey;
    _notificationsNotifier = notificationsNotifier;
  }

  void connect({
    GlobalKey<NavigatorState>? navigatorKey,
    ValueNotifier<List<NotificationItem>>?
    notificationsNotifier,
  }) {
    if (navigatorKey != null) _navKey = navigatorKey;
    if (notificationsNotifier != null) {
      _notificationsNotifier = notificationsNotifier;
    }

    if (socket != null && socket!.connected) {
      debugPrint(
        'Socket is already connected: ${socket!.id}',
      );
      if (_officerUserId != null) {
        socket!.emit('join_officer_room', {'userId': _officerUserId});
      }
      if (_gatcId != null) {
        socket!.emit('join_gatc_room', {'gatcId': _gatcId});
      }
      return;
    }

    socket = i_o.io(
      'http://192.168.1.4:8008',
      i_o.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    socket!.onConnect((_) {
      debugPrint('Connected: ${socket!.id}');
      if (_officerUserId != null) {
        socket!.emit('join_officer_room', {'userId': _officerUserId});
      }
      if (_gatcId != null) {
        socket!.emit('join_gatc_room', {'gatcId': _gatcId});
      }
      sendAck();
    });

    socket!.on('officer_room_joined', (data) {
      debugPrint('Successfully joined officer room: ${data['room']}');
    });

    socket!.on('officer_room_error', (data) {
      debugPrint('Failed to join officer room: ${data['message']}');
    });

    socket!.on('gatc_room_joined', (data) {
      debugPrint('Successfully joined GATC room: ${data['room']}');
    });

    socket!.on('gatc_room_error', (data) {
      debugPrint('Failed to join GATC room: ${data['message']}');
    });

    socket!.on('message', (raw) {
      if (raw != null) {
        try {
          final outer = Map<String, dynamic>.from(raw);
          final inner = outer.containsKey('data')
              ? Map<String, dynamic>.from(outer['data'])
              : outer;

          VerificationForm formData =
              VerificationForm.fromJson(inner);

          debugPrint(
            'Form Received successfully from Server!',
          );
          debugPrint(
            'Manufacturer: ${formData.manufacturerName}',
          );
          debugPrint(
            'Serial No: ${formData.instrumentSerialNumber}',
          );
          debugPrint('Class: ${formData.accuracyClass}');

          final liveId = addLiveInspection(
            business: formData.manufacturerName,
            instrument: formData.instrumentCategory,
            model: formData.modelNo,
            serial: formData.instrumentSerialNumber,
            accuracyClass: formData.accuracyClass,
            applicationId: inner['applicationId']?.toString(),
            assignedOfficerId: inner['assignedOfficerId']?.toString(),
          );

          // Store expected location from form so seal page can verify proximity
          storeInspectionLocation(
            liveId,
            formData.lat,
            formData.long,
          );

          final newNotification = NotificationItem(
            'New Verification Task',
            '${formData.instrumentCategory} at ${formData.manufacturerName}',
            'Just now',
            Icons.assignment_late_outlined,
          );

          if (_notificationsNotifier != null) {
            _notificationsNotifier!.value = [
              newNotification,
              ..._notificationsNotifier!.value,
            ];
          }

          String? currentRouteName;
          _navKey?.currentState?.popUntil((route) {
            if (route.isCurrent) {
              currentRouteName = route.settings.name;
            }
            return true;
          });

          if (currentRouteName == Routes.inspectorHome) {
            _showLmoAlertPopup(formData, liveId);
          } else {
            debugPrint(
              'New task received, but user is on $currentRouteName. Popup suppressed.',
            );
          }
        } catch (e) {
          debugPrint('Error parsing form data: $e');
        }
      }
    });

    socket!.on('route:assigned', (raw) {
      if (raw != null) {
        try {
          final data = Map<String, dynamic>.from(raw);
          final String appNo = data['application_no'] ?? 'Unknown Application';
          final String businessName = data['business_name'] ?? 'Unknown Business';
          final String instrumentCategory = data['instrument_category'] ?? 'Unknown Instrument';
          final String serialNo = data['serial_no'] ?? 'Pending details';
          final String modelNo = data['model_no'] ?? 'Pending details';
          final String? previousUrl = data['previousCertificateUrl'];
          final String? manufacturerUrl = data['manufacturerCertificateUrl'];
          final double? error = data['error'] != null ? double.tryParse(data['error'].toString()) : null;

          debugPrint('New Route Assignment Received: $appNo');

          final newNotification = NotificationItem(
            'New Application Assigned: $appNo',
            '$instrumentCategory at $businessName',
            'Just now',
            Icons.assignment_late_outlined,
          );

          if (_notificationsNotifier != null) {
            _notificationsNotifier!.value = [
              newNotification,
              ..._notificationsNotifier!.value,
            ];
          }

          final liveId = addLiveInspection(
            business: businessName,
            instrument: instrumentCategory,
            model: modelNo,
            serial: serialNo,
            applicationId: appNo,
            assignedOfficerId: data['assigned_id']?.toString(),
            previousCertificateUrl: previousUrl,
            manufacturerCertificateUrl: manufacturerUrl,
            error: error,
          );

          String? currentRouteName;
          _navKey?.currentState?.popUntil((route) {
            if (route.isCurrent) {
              currentRouteName = route.settings.name;
            }
            return true;
          });

          if (currentRouteName == Routes.inspectorHome) {
            _showRouteAssignmentPopup(appNo, businessName, instrumentCategory, liveId);
          } else {
            debugPrint('New assignment received, but user is on $currentRouteName. Popup suppressed.');
          }
        } catch (e) {
          debugPrint('Error parsing route:assigned data: $e');
        }
      }
    });

    socket!.onDisconnect((_) {
      debugPrint('Disconnected');
    });

    socket!.onConnectError((error) {
      debugPrint('Connection error: $error');
    });

    socket!.on('reply', (data) {
      debugPrint('Server replied: $data');
    });

    socket!.connect();
  }

  /// Emits the seal evidence JSON payload to the 'inspection_approved' channel.
  void emitInspectionApproved(Map<String, dynamic> data) {
    debugPrint(
      'Attempting to emit inspection_approved for SN: ${data['instrumentSerialNumber']}',
    );
    debugPrint(
      'lat: ${data['lat']}, long: ${data['long']}',
    );
    final rawBase64 = data['sealImageBase64'] as String?;
    final base64Length = rawBase64 != null
        ? 'data:image/jpeg;base64,$rawBase64'
        : null;
    debugPrint(
      'sealImageBase64: length $base64Length chars',
    );

    if (socket != null && socket!.connected) {
      socket!.emit('inspection_approved', data);
      debugPrint(
        'Successfully emitted "inspection_approved" to server!',
      );
    } else {
      debugPrint(
        'Socket not connected yet. Connecting and attempting emit...',
      );
      if (socket == null) {
        connect();
      } else {
        socket!.connect();
      }
      socket?.emit('inspection_approved', data);
    }
  }

  void emitBiometricAudit(Map<String, dynamic> data) {
    debugPrint('Attempting to emit biometric_audit...');
    if (socket != null && socket!.connected) {
      socket!.emit('biometric_audit', data);
      debugPrint(
        'Successfully emitted "biometric_audit" to server!',
      );
    } else {
      debugPrint(
        'Socket not connected yet. Connecting and attempting emit...',
      );
      if (socket == null) {
        connect();
      } else {
        socket!.connect();
      }
      socket?.emit('biometric_audit', data);
    }
  }

  void _showLmoAlertPopup(
    VerificationForm form,
    String inspectionId,
  ) {
    final context = _navKey?.currentContext;
    if (context == null) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.notifications_active,
                color: AppColors.saffron,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'New Assignment',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Category: ${form.instrumentCategory}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Manufacturer: ${form.manufacturerName}',
                style: const TextStyle(
                  color: AppColors.slate,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Model: ${form.modelNo} (${form.accuracyClass})',
                style: const TextStyle(
                  color: AppColors.slate,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Dismiss',
                style: TextStyle(color: AppColors.slate),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navy,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context);
                _navKey?.currentState?.push(
                  MaterialPageRoute(
                    builder: (_) => InspectionDetailPage(
                      inspectionId: inspectionId,
                    ),
                  ),
                );
              },
              child: const Text('Open inspection'),
            ),
          ],
        );
      },
    );
  }

  void _showRouteAssignmentPopup(
    String appNo,
    String businessName,
    String instrumentCategory,
    String inspectionId,
  ) {
    final context = _navKey?.currentContext;
    if (context == null) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.assignment_late_outlined,
                color: AppColors.saffron,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'New Assignment!',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Application: $appNo',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Category: $instrumentCategory',
                style: const TextStyle(
                  color: AppColors.slate,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Business: $businessName',
                style: const TextStyle(
                  color: AppColors.slate,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Dismiss',
                style: TextStyle(color: AppColors.slate),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navy,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context);
                _navKey?.currentState?.push(
                  MaterialPageRoute(
                    builder: (_) => InspectionDetailPage(
                      inspectionId: inspectionId,
                    ),
                  ),
                );
              },
              child: const Text('View Route'),
            ),
          ],
        );
      },
    );
  }

  void sendAck() {
    if (socket != null && socket!.connected) {
      debugPrint('Sending ack event...');
      socket!.emitWithAck(
        'msg',
        'hello world',
        ack: (data) {
          if (data != null) {
            debugPrint('Ack response from server: $data');
          } else {
            debugPrint("Received Null ack response");
          }
        },
      );
    } else {
      debugPrint('Socket is not connected yet!');
    }
  }
}
