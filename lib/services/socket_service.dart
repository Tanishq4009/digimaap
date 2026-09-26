import 'dart:convert';
import 'package:digimaap/pages/shared/notifications_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart'
    as i_o;
import '../routes.dart';
import '../theme/colors.dart';
import '../models/data.dart';
import '../pages/inspector/inspection_detail_page.dart';
import '../config/env_config.dart';

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
        socket!.emit('join_officer_room', {
          'userId': _officerUserId,
        });
      }
      if (_gatcId != null) {
        socket!.emit('join_gatc_room', {'gatcId': _gatcId});
      }
      return;
    }

    socket = i_o.io(
      EnvConfig.webPortalUrl,
      i_o.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    socket!.onConnect((_) {
      debugPrint('Connected: ${socket!.id}');
      if (_officerUserId != null) {
        socket!.emit('join_officer_room', {
          'userId': _officerUserId,
        });
      }
      if (_gatcId != null) {
        socket!.emit('join_gatc_room', {'gatcId': _gatcId});
      }
      sendAck();
    });

    socket!.on('officer_room_joined', (data) {
      debugPrint(
        'Successfully joined officer room: ${data['room']}',
      );
    });

    socket!.on('officer_room_error', (data) {
      debugPrint(
        'Failed to join officer room: ${data['message']}',
      );
    });

    socket!.on('gatc_room_joined', (data) {
      debugPrint(
        'Successfully joined GATC room: ${data['room']}',
      );
    });

    socket!.on('gatc_room_error', (data) {
      debugPrint(
        'Failed to join GATC room: ${data['message']}',
      );
    });

    socket!.on(
      'message',
      (raw) => _handleIncomingPayload(raw, 'message'),
    );
    socket!.on(
      'route:assigned',
      (raw) =>
          _handleIncomingPayload(raw, 'route:assigned'),
    );
    socket!.on(
      'new_application',
      (raw) =>
          _handleIncomingPayload(raw, 'new_application'),
    );

    socket!.on('certificate_generated', (raw) {
      if (raw != null) {
        try {
          final data = Map<String, dynamic>.from(raw);
          final String status =
              data['status'] ?? 'APPROVED_CHECKLIST';
          final String appId =
              data['applicationId'] ??
              data['applicationNo'] ??
              '';
          final String serial =
              data['instrumentSerialNumber'] ?? '';

          debugPrint(
            '[SOCKET] certificate_generated received: status=$status, appId=$appId, serial=$serial',
          );

          final targetId = _findMatchingInspectionId(
            appId,
            serial,
          );
          if (targetId != null) {
            if (status == 'APPROVED_CHECKLIST') {
              markInspectionDone(targetId);
            } else if (status == 'FAILED_CHECKLIST') {
              markInspectionRejected(targetId);
            }
          }
        } catch (e) {
          debugPrint(
            'Error handling certificate_generated: $e',
          );
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

  String? _findMatchingInspectionId(
    String appId,
    String serial,
  ) {
    for (final entry in inspections.entries) {
      if ((appId.isNotEmpty &&
              entry.value.applicationId == appId) ||
          (serial.isNotEmpty &&
              entry.value.serial == serial) ||
          entry.key == appId) {
        return entry.key;
      }
    }
    return appId.isNotEmpty
        ? appId
        : (serial.isNotEmpty ? serial : null);
  }

  void _handleIncomingPayload(
    dynamic raw,
    String eventName,
  ) {
    if (raw == null) return;
    try {
      final outer = Map<String, dynamic>.from(raw);
      final data = outer.containsKey('data')
          ? Map<String, dynamic>.from(outer['data'])
          : outer;

      final String appId = data['app_id']?.toString() ?? '';
      final String appNo =
          data['application_no'] ??
          data['applicationNo'] ??
          data['applicationId'] ??
          (appId.isNotEmpty ? appId : 'Unknown Application');
      final String businessName =
          data['business_name'] ??
          data['businessName'] ??
          data['manufacturerName'] ??
          'Unknown Business';
      final String instrumentCategory =
          data['instrument_category'] ??
          data['instrumentCategory'] ??
          'Unknown Instrument';
      final String serialNo =
          data['serial_no'] ??
          data['instrumentSerialNumber'] ??
          data['serialNo'] ??
          'Pending details';
      final String modelNo =
          data['model_no'] ??
          data['modelNo'] ??
          'Pending details';
      final String? assignedType =
          data['assigned_type']?.toString() ?? data['assignedType']?.toString();
      final String? assignedId =
          data['assigned_id']?.toString() ?? data['assignedId']?.toString();
      final String? assignedTo =
          data['assigned_to']?.toString() ?? data['assignedTo']?.toString();
      final String? previousUrl =
          data['previousCertificateUrl'];
      final String? manufacturerUrl =
          data['manufacturerCertificateUrl'];
      final double? error = data['error'] != null
          ? double.tryParse(data['error'].toString())
          : null;

      // Extract & format timestamp string
      final String rawTimestamp = data['timestamp']?.toString() ?? '';
      String formattedTime = 'Just now';
      if (rawTimestamp.isNotEmpty) {
        try {
          final dt = DateTime.parse(rawTimestamp).toLocal();
          final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
          final minute = dt.minute.toString().padLeft(2, '0');
          final period = dt.hour >= 12 ? 'PM' : 'AM';
          formattedTime = '$hour:$minute $period';
        } catch (_) {
          formattedTime = 'Just now';
        }
      }

      debugPrint(
        '[$eventName] Parsed payload: appNo=$appNo, business=$businessName, time=$formattedTime, MPE error=$error',
      );

      final newNotification = NotificationItem(
        'New Verification Request: $appNo',
        '$instrumentCategory at $businessName',
        formattedTime,
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
        assignedOfficerId: assignedId ?? assignedTo,
        assignedType: assignedType,
        assignedTo: assignedTo,
        applicant: assignedTo ?? '—',
        previousCertificateUrl: previousUrl,
        manufacturerCertificateUrl: manufacturerUrl,
        error: error,
        time: formattedTime,
        customId: appId.isNotEmpty ? appId : null,
      );

      // Hit GET /api/instrument/history/<application-id> and print result in console
      final String targetAppId = appId.isNotEmpty ? appId : appNo;
      _fetchInstrumentHistory(targetAppId);

      final lat = (data['lat'] as num?)?.toDouble() ?? 0.0;
      final lng =
          (data['long'] as num?)?.toDouble() ??
          (data['lng'] as num?)?.toDouble() ??
          0.0;
      if (lat != 0.0 || lng != 0.0) {
        storeInspectionLocation(liveId, lat, lng);
      }

      String? currentRouteName;
      _navKey?.currentState?.popUntil((route) {
        if (route.isCurrent) {
          currentRouteName = route.settings.name;
        }
        return true;
      });

      if (currentRouteName == Routes.inspectorHome) {
        _showRouteAssignmentPopup(
          appNo,
          businessName,
          instrumentCategory,
          liveId,
        );
      }
    } catch (e) {
      debugPrint(
        'Error parsing $eventName socket data: $e',
      );
    }
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

  /// Emits the rejection certificate JSON payload to the 'inspection_approved' channel (status: FAILED_CHECKLIST) per app.ts rules.
  void emitInspectionRejected(Map<String, dynamic> data) {
    final payload = {
      ...data,
      'status': 'FAILED_CHECKLIST',
      'sealImageUrls':
          data['sealImageUrls'] ??
          data['defectImageUrls'] ??
          [],
    };

    debugPrint(
      'Attempting to emit inspection_approved (FAILED_CHECKLIST) for SN: ${payload['instrumentSerialNumber']}',
    );

    if (socket != null && socket!.connected) {
      socket!.emit('inspection_approved', payload);
      socket!.emit('inspection_rejected', payload);
      debugPrint(
        'Successfully emitted rejection to server!',
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
      socket?.emit('inspection_approved', payload);
      socket?.emit('inspection_rejected', payload);
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

  Future<List<String>> _fetchInstrumentHistory(String applicationId) async {
    if (applicationId.isEmpty) return [];
    try {
      final String baseUrl = EnvConfig.webPortalUrl;
      final Uri uri = Uri.parse('$baseUrl/api/instrument/history/$applicationId');

      debugPrint('[InstrumentHistory] Fetching GET $uri ...');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final dynamic body = jsonDecode(response.body);
        debugPrint('[InstrumentHistory Raw Response]: $body');

        List<String> urls = [];
        if (body is Map<String, dynamic>) {
          // Format: { "success": true, "data": [ "url1", "url2" ] }
          final dynamic dataField = body['data'] ?? body['urls'] ?? body['history'];
          if (dataField is List) {
            urls = dataField.map((e) => e.toString()).toList();
          } else if (body['url'] != null) {
            urls = [body['url'].toString()];
          }
        } else if (body is List) {
          urls = body.map((e) => e.toString()).toList();
        }

        saveInstrumentHistoryUrls(applicationId, urls);

        debugPrint('====================================================');
        debugPrint('[INSTRUMENT HISTORY URLS RECEIVED] AppID: $applicationId');
        debugPrint('Success: ${body is Map ? body['success'] : true}');
        debugPrint('URLs List (${urls.length}): $urls');
        debugPrint('====================================================');
        return urls;
      } else {
        debugPrint(
          '[InstrumentHistory Error] Status: ${response.statusCode}, Body: ${response.body}',
        );
        return [];
      }
    } catch (e) {
      debugPrint(
        '[InstrumentHistory Exception] Failed to fetch history for $applicationId: $e',
      );
      return [];
    }
  }
}
