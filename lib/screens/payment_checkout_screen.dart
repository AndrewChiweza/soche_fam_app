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
  String? _operatorLogoPath;
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
        _operatorLogoPath = "images/tnm_mpamba.png";
      });
    } else if (cleanNum.startsWith('09') ||
        cleanNum.startsWith('+2659') ||
        cleanNum.startsWith('2659')) {
      setState(() {
        _detectedOperator = "Airtel Money";
        _providerCode = "airtel";
        _operatorLogoPath = "images/airtel_money.png";
      });
    } else {
      setState(() {
        _detectedOperator = "Enter Number";
        _providerCode = "";
        _operatorLogoPath = null;
      });
    }
  }

  /// Listens to Firestore in real time on the same page for PayChangu confirmation
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
        setState(() {
          _awaitingPin = false;
          _isProcessing = false;
        });
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
        setState(() {
          _awaitingPin = false;
          _isProcessing = false;
        });
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
                    ? Colors.green.withValues(alpha: 0.12)
                    : Colors.red.withValues(alpha: 0.12),
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
                  ? "Your contribution of $amountText for '${widget.payment.title}' has been recorded, May God bless you!."
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
    final bool isBusy = _isProcessing || _awaitingPin;

    return Scaffold(
      appBar: AppBar(title: const Text("Mobile Checkout")),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Contribution Details Card
                    Card(
                      color: Theme.of(context)
                          .primaryColor
                          .withValues(alpha: 0.08),
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
                                  "Amount:",
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
                      "Contribution Info.",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
// Full Name Input
                    TextFormField(
                      controller: _nameCtrl,
                      keyboardType: TextInputType.name,
                      enabled: _isGuest && !isBusy,
                      decoration: InputDecoration(
                        labelText: "Your Full Name",
                        prefixIcon: const Icon(Icons.person_outline),
                        helperText: _isGuest
                            ? "Required for Treasurer"
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
                      enabled: !isBusy,
                      decoration: InputDecoration(
                        labelText: "Phone (08XX/09XX)",
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
                          return "Enter a valid Airtel (09XX) or TNM (08XX) number";
                        }
                        if (v.trim().length < 10) {
                          return "Enter a complete 10-digit Malawian number";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),
// Seamless In-Page Linear Loading Bar or Pay Button
                    if (isBusy) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF00674F).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                const Color(0xFF00674F).withValues(alpha: 0.25),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Payment processing...",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Color(0xFF00674F),
                                  ),
                                ),
                                if (_awaitingPin)
                                  GestureDetector(
                                    onTap: () {
                                      _txSubscription?.cancel();
                                      setState(() {
                                        _awaitingPin = false;
                                        _isProcessing = false;
                                      });
                                    },
                                    child: const Text(
                                      "Cancel",
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: const LinearProgressIndicator(
                                minHeight: 6,
                                color: Color(0xFF00674F),
                                backgroundColor: Color(0xFFD0E3DF),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _awaitingPin
                                  ? "Enter your $_detectedOperator PIN to complete payment."
                                  : "Connecting to $_detectedOperator...",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00674F),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
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
                            if (res['success'] == true) {
                              setState(() => _isProcessing = false);
                              _listenForWebhookConfirmation(
                                uniqueRef,
                                finalPayerName,
                                _phoneCtrl.text.trim(),
                              );
                            } else {
                              setState(() => _isProcessing = false);
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
                  ],
                ),
              ),
            ),
          ),
// Pinned Security Badge Footer at the Bottom
          // Pinned PayChangu Security Banner Image at the Bottom
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'images/secured_by_paychangu.png',
                  width: double.infinity,
                  height: 70,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
