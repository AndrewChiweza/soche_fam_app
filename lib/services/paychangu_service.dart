import 'dart:convert';
import 'package:http/http.dart' as http;

class PayChanguService {
  // Replace with your exact Render URL + /api
  static const String _backendBaseUrl =
      "https://soche-fam-backend.onrender.com/api";

  /// Normalizes Malawian phone numbers to 265XXXXXXXXX format
  static String formatMalawiPhone(String input) {
    String clean = input.replaceAll(RegExp(r'[\s\-\+]'), '');
    if (clean.startsWith('0')) {
      return '265${clean.substring(1)}';
    }
    return clean;
  }

  /// Triggers the USSD PIN push via your live Render backend
  static Future<Map<String, dynamic>> initiateDirectCharge({
    required double amount,
    required String rawPhoneNumber,
    required String provider, // 'tnm' or 'airtel'
    required String memberName,
    required String email,
    required String txRef,
    required String paymentDueId,
  }) async {
    try {
      final formattedPhone = formatMalawiPhone(rawPhoneNumber);
      final url = Uri.parse('$_backendBaseUrl/direct-charge');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amount': amount.toInt().toString(),
          'phone_number': formattedPhone,
          'provider': provider,
          'first_name': memberName,
          'email': email.isEmpty ? 'member@sochefam.com' : email,
          'tx_ref': txRef,
          'payment_due_id': paymentDueId,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == 'success') {
        return {'success': true, 'message': 'USSD prompt sent to phone.'};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Charge rejected.'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
}
