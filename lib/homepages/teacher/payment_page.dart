import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart' as rpay_mobile;
import 'package:razorpay_web/razorpay_web.dart' as rpay_web;


class PaymentPage extends StatefulWidget {
  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  rpay_mobile.Razorpay? _razorpay; // for Android/iOS
  final _razorpayWeb = rpay_web.Razorpay(); // for Web
  int _studentCount = 0;
  bool _loading = true;

  @override
  void initState() {
     _fetchStudentCount();
    super.initState();
    if (!kIsWeb) {
      _razorpay = rpay_mobile.Razorpay();
      _razorpay!.on(rpay_mobile.Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
      _razorpay!.on(rpay_mobile.Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
      _razorpay!.on(rpay_mobile.Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    }
  }
  
    Future<void> _fetchStudentCount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() { _studentCount = 0; _loading = false; });
      return;
    }
    final query = await FirebaseFirestore.instance
        .collection('classes')
        .where('teacherUid', isEqualTo: user.uid)
        .get();
    int total = 0;
    for (final doc in query.docs) {
      final joined = doc['joinedStudents'];
      if (joined is List) {
        total += joined.length;
      } else if (joined is int) {
        total += joined;
      }
    }
    setState(() { _studentCount = total; _loading = false; });
  }

  void openCheckout() {
    int amount = 100 * _studentCount * 100;
    var options = {
      'key': 'rzp_live_d15gAeECE4a37b',
      'amount': amount, // in paise = ₹1.00
      'name': 'Edubridge',
      'description': 'Payment for using Edubridge',
      'prefill': {
        'contact': '9123456789',
        'email': 'test@razorpay.com',
      },
      'external': {
        'wallets': ['paytm']
      }
    };

    if (kIsWeb) {
      _razorpayWeb.open(options);
    } else {
      _razorpay!.open(options);
    }
  }

  void _handlePaymentSuccess(rpay_mobile.PaymentSuccessResponse response) {
    _showDialog("Payment Successful", "Payment ID: ${response.paymentId}");
  }

  void _handlePaymentError(rpay_mobile.PaymentFailureResponse response) {
    _showDialog("Payment Failed", "Error: ${response.message}");
  }

  void _handleExternalWallet(rpay_mobile.ExternalWalletResponse response) {
    _showDialog("External Wallet", "Wallet Name: ${response.walletName}");
  }

  void _showDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("OK"))
        ],
      ),
    );
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      _razorpay!.clear();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Razorpay Payment")),
      body: Center(
        child: ElevatedButton(
          onPressed: openCheckout,
          child: Text("Pay ₹${_studentCount * 100}"),
        ),
      ),
    );
  }
}
