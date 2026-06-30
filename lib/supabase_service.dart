import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  SupabaseService._();

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await client.auth.signInWithPassword(email: email, password: password);
  }

  static Future<String> register({
    required String name,
    required String email,
    required String password,
    required String role,
    required String organisation,
    required String city,
  }) async {
    final response = await client.auth.signUp(
      email: email,
      password: password,
      data: {
        'name': name,
        'account_type': role,
        'organisation': organisation,
        'city': city,
      },
    );
    final user = response.user;
    if (user == null) {
      throw const AuthException('Registration did not create a user.');
    }

    return user.id;
  }

  static Future<void> signOut() => client.auth.signOut();

  static Future<Map<String, dynamic>?> currentOrganisation() async {
    final user = client.auth.currentUser;
    if (user == null) return null;

    final membership = await client
        .from('memberships')
        .select('organisation_id')
        .eq('user_id', user.id)
        .limit(1)
        .maybeSingle();
    if (membership == null) return null;

    final organisation = await client
        .from('organisations')
        .select('id, name, type, city, verified')
        .eq('id', membership['organisation_id'])
        .maybeSingle();
    if (organisation == null) return null;

    return {
      ...organisation,
      'email': user.email,
      'display_name': user.userMetadata?['name'],
    };
  }

  static Future<List<Map<String, dynamic>>> fetchLawyers() async {
    final rows = await client
        .from('organisations')
        .select('id, name, city')
        .eq('type', 'lawyer')
        .order('name');
    return rows.cast<Map<String, dynamic>>();
  }

  static Future<List<Map<String, dynamic>>> fetchCases() async {
    final caseRows = await client.from('raf_cases').select('''
          id,
          patient_name,
          accident_city,
          status,
          assigned_lawyer_id,
          assigned_lawyer_name,
          created_at,
          hospital:organisations!raf_cases_hospital_id_fkey(name)
        ''').order('created_at', ascending: false);

    final documentRows = await client
        .from('case_documents')
        .select('case_id, file_name')
        .order('created_at', ascending: true);
    final messageRows = await client
        .from('case_messages')
        .select('case_id, body, created_at')
        .order('created_at', ascending: true);

    final documentsByCase = <String, List<String>>{};
    for (final row in documentRows) {
      final caseId = row['case_id'] as String;
      documentsByCase.putIfAbsent(caseId, () => []).add(row['file_name']);
    }

    final messagesByCase = <String, List<Map<String, dynamic>>>{};
    for (final row in messageRows) {
      final caseId = row['case_id'] as String;
      messagesByCase.putIfAbsent(caseId, () => []).add(row);
    }

    return caseRows
        .map<Map<String, dynamic>>((row) => {
              ...row,
              'documents': documentsByCase[row['id']] ?? <String>[],
              'messages': messagesByCase[row['id']] ?? <Map<String, dynamic>>[],
            })
        .toList();
  }

  static Future<void> saveCase({
    required String id,
    required String patientName,
    required String city,
    required String status,
    String? lawyerName,
    String? lawyerId,
  }) async {
    final user = client.auth.currentUser;
    if (user == null) return;
    final membership = await client
        .from('memberships')
        .select('organisation_id')
        .eq('user_id', user.id)
        .limit(1)
        .maybeSingle();
    if (membership == null) return;

    final existing =
        await client.from('raf_cases').select('id').eq('id', id).maybeSingle();

    if (existing != null) {
      await client.from('raf_cases').update({
        'status': status,
        'assigned_lawyer_id': lawyerId,
        'assigned_lawyer_name': lawyerName,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
      return;
    }

    await client.from('raf_cases').insert({
      'id': id,
      'patient_name': patientName,
      'hospital_id': membership['organisation_id'],
      'accident_city': city,
      'status': status,
      'assigned_lawyer_id': lawyerId,
      'assigned_lawyer_name': lawyerName,
      'created_by': user.id,
    });
  }

  static Future<void> sendMessage({
    required String caseId,
    required String body,
  }) async {
    final user = client.auth.currentUser;
    if (user == null) return;
    await client.from('case_messages').insert({
      'case_id': caseId,
      'sender_id': user.id,
      'body': body,
    });
  }

  static Future<void> uploadDocument({
    required String caseId,
    required String fileName,
    required List<int> bytes,
  }) async {
    final user = client.auth.currentUser;
    if (user == null) {
      throw const AuthException('Sign in before uploading.');
    }
    final path = '$caseId/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    await client.storage.from('case-documents').uploadBinary(
          path,
          Uint8List.fromList(bytes),
          fileOptions: const FileOptions(upsert: false),
        );
    await client.from('case_documents').insert({
      'case_id': caseId,
      'uploaded_by': user.id,
      'file_name': fileName,
      'storage_path': path,
    });
  }
}
