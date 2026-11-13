import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment_due.dart';
import '../services/paychangu_service.dart';

class PaymentCheckoutScreen extends StatefulWidget {
  final PaymentDue payment;
  final String currentMemberName;
  final String currentMemberEmail;

  const PaymentCheckoutScreen({
    super.key,
    required this.payment,
    required this.currentMemberName,
    required this.currentMemberEmail,
  });

  @override
  State<PaymentCheckoutScreen> createState() => _PaymentCheckoutScreenState();
}

class _PaymentCheckoutScreenState extends State<PaymentCheckoutScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isProcessing = false;
  bool _awaitingPin = false;
  String _detectedOperator = "Enter Number";
  String _providerCode = "";
  String? _operatorLogoPath; // ✅ Holds the brand PNG asset path
  bool _isGuest = true;

  StreamSubscription<DocumentSnapshot>? _txSubscription;

  @override
  void initState() {
    super.initState();
    if (widget.currentMemberName.isNotEmpty &&
        widget.currentMemberName != "Guest" &&
        widget.currentMemberName != "Choir Member") {
      _nameCtrl.text = widget.currentMemberName;
      _isGuest = false;
    }
  }

  @override
  void dispose() {
    _txSubscription?.cancel();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  /// Dynamically detects Malawian mobile money operators and assigns brand PNG logos
  void _detectOperator(String value) {
    final cleanNum = value.replaceAll(RegExp(r'\s+'), '');
    if (cleanNum.startsWith('08') ||
        cleanNum.startsWith('031') ||
        cleanNum.startsWith('+2658') ||
        cleanNum.startsWith('2658')) {
      setState(() {
        _detectedOperator = "TNM Mpamba";
        _providerCode = "tnm";
        _operatorLogoPath = "images/tnm_mpamba.png"; // ✅ TNM Mpamba PNG
      });
    } else if (cleanNum.startsWith('09') ||
        cleanNum.startsWith('+2659') ||
        cleanNum.startsWith('2659')) {
      setState(() {
        _detectedOperator = "Airtel Money";
        _providerCode = "airtel";
        _operatorLogoPath = "images/airtel_money.png"; // ✅ Airtel Money PNG
      });
    } else {
      setState(() {
        _detectedOperator = "Enter Number";
        _providerCode = "";
        _operatorLogoPath = null;
      });
    }
  }

  /// Listens to Firestore in real time for the Render backend / PayChangu Webhook update
  void _listenForWebhookConfirmation(
      String txRef, String payerName, String phone) {
    setState(() => _awaitingPin = true);

    _txSubscription = FirebaseFirestore.instance
        .collection('payments_transactions')
        .doc(txRef)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) return;
      final data = snapshot.data() as Map<String, dynamic>;

      if (data['status'] == 'success') {
        _txSubscription?.cancel();
        if (!mounted) return;
        setState(() => _awaitingPin = false);
        _showNativeFeedbackSheet(
          isSuccess: true,
          reference: txRef,
          payerName: payerName,
          amountText: "MWK ${widget.payment.amount.toStringAsFixed(2)}",
          phone: phone,
        );
      } else if (data['status'] == 'failed') {
        _txSubscription?.cancel();
        if (!mounted) return;
        setState(() => _awaitingPin = false);
        _showNativeFeedbackSheet(
          isSuccess: false,
          reference: txRef,
          payerName: payerName,
          amountText: "MWK ${widget.payment.amount.toStringAsFixed(2)}",
          phone: phone,
        );
      }
    });
  }

  /// Displays native in-app receipt sheet once payment completes or fails
  void _showNativeFeedbackSheet({
    required bool isSuccess,
    required String reference,
    required String payerName,
    required String amountText,
    required String phone,
  }) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSuccess
                    ? Colors.green.withOpacity(0.12)
                    : Colors.red.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSuccess
                    ? CupertinoIcons.check_mark_circled_solid
                    : CupertinoIcons.xmark_circle_fill,
                size: 54,
                color: isSuccess ? Colors.green.shade700 : Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isSuccess ? "Payment Successful!" : "Transaction Failed",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              isSuccess
                  ? "Your contribution of $amountText for '${widget.payment.title}' has been recorded in the choir ledger."
                  : "The transaction was cancelled or declined by your mobile money provider.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Contributor:",
                    style: TextStyle(color: Colors.grey)),
                Text(payerName,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Phone Number:",
                    style: TextStyle(color: Colors.grey)),
                Text(phone,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Reference ID:",
                    style: TextStyle(color: Colors.grey)),
                Text(
                  reference,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    color: Colors.blueGrey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSuccess
                      ? const Color(0xFF00674F)
                      : Colors.grey.shade800,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context); // Dismisses confirmation sheet
                  Navigator.pop(context); // Returns to contributions list
                },
                child: const Text(
                  "Done",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final finalPayerName = _nameCtrl.text.trim().isEmpty
        ? "Guest Contributor"
        : _nameCtrl.text.trim();

    return Scaffold(
      appBar: AppBar(title: const Text("Checkout")),
      body: _awaitingPin
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(28.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_operatorLogoPath != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          _operatorLogoPath!,
                          height: 54,
                          width: 54,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    const CircularProgressIndicator(color: Color(0xFF00674F)),
                    const SizedBox(height: 24),
                    const Text(
                      "Check Your Phone Screen",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "A $_detectedOperator PIN prompt has been sent to ${_phoneCtrl.text.trim()}. Enter your PIN to complete the MWK ${widget.payment.amount.toStringAsFixed(0)} payment.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 30),
                    TextButton(
                      onPressed: () {
                        _txSubscription?.cancel();
                        setState(() => _awaitingPin = false);
                      },
                      child: const Text(
                        "Cancel Waiting",
                        style: TextStyle(color: Colors.red),
                      ),
                    )
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
// Contribution Details Card
                    Card(
                      color: Theme.of(context).primaryColor.withOpacity(0.08),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.payment.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              widget.payment.description,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Amount Due:",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  "MWK ${widget.payment.amount.toStringAsFixed(2)}",
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF00674F),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "Contribution Infor",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
// Full Name Input
                    TextFormField(
                      controller: _nameCtrl,
                      keyboardType: TextInputType.name,
                      enabled: _isGuest,
                      decoration: InputDecoration(
                        labelText: "Your Full Name",
                        prefixIcon: const Icon(Icons.person_outline),
                        helperText: _isGuest
                            ? "Required for Treasury"
                            : "Loaded from profile",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (v) {
                        if (_isGuest && (v == null || v.trim().isEmpty)) {
                          return "Please enter your full name";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
// Mobile Money Phone Field with Brand PNG Logo
                    TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: "Number (08XXX / 09XXX)",
                        prefixIcon: const Icon(Icons.phone_android),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: _operatorLogoPath != null
                            ? Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.asset(
                                    _operatorLogoPath!,
                                    width: 34,
                                    height: 34,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              )
                            : const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: Icon(
                                  CupertinoIcons.creditcard,
                                  color: Colors.grey,
                                ),
                              ),
                      ),
                      onChanged: _detectOperator,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return "Please enter your phone number";
                        }
                        if (_providerCode.isEmpty) {
                          return "Enter a valid Airtel/TNM Number";
                        }
                        if (v.trim().length < 10) {
                          return "Enter a complete 10-digit Malawian number";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),
// Pay Now Button
                    _isProcessing
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF00674F),
                            ),
                          )
                        : SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00674F),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () async {
                                if (!_formKey.currentState!.validate()) return;
                                setState(() => _isProcessing = true);
                                final uniqueRef =
                                    "soche-${DateTime.now().millisecondsSinceEpoch}";
                                final res =
                                    await PayChanguService.initiateDirectCharge(
                                  amount: widget.payment.amount,
                                  rawPhoneNumber: _phoneCtrl.text.trim(),
                                  provider: _providerCode,
                                  memberName: finalPayerName,
                                  email: widget.currentMemberEmail,
                                  txRef: uniqueRef,
                                  paymentDueId: widget.payment.id,
                                );
                                if (!mounted) return;
                                setState(() => _isProcessing = false);
                                if (res['success'] == true) {
                                  _listenForWebhookConfirmation(
                                    uniqueRef,
                                    finalPayerName,
                                    _phoneCtrl.text.trim(),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(res['message']),
                                      backgroundColor: Colors.red.shade700,
                                    ),
                                  );
                                }
                              },
                              child: const Text(
                                "Pay Now",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ),
    );
  }
}
