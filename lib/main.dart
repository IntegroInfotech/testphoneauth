import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'notification_controller.dart';

late FirebaseApp firebase;
late FirebaseAuth firebaseAuth;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationController.initializeLocalNotifications(debug: true);
  await NotificationController.initializeRemoteNotifications(debug: true);
  await NotificationController.initializeIsolateReceivePort();
  firebaseAuth = FirebaseAuth.instance;
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    NotificationController.startListeningNotificationEvents();
    NotificationController.requestFirebaseToken();
    super.initState();
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: firebaseAuth.userChanges(),
        builder: (context, AsyncSnapshot<User?> snapshot) {
          if (snapshot.data == null) {
            return const LoginScreen();
          }
          return const MyHomePage(title: 'Flutter Demo Home Page');
        },
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final phoneNumberController = TextEditingController();
  final oneTimePassController = TextEditingController();

  String? verificationId;

  final _formKey = GlobalKey<FormState>();

  int? forceResendingToken;

  String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Visibility(
                  visible: errorMessage != null,
                  child: Text(
                    errorMessage ?? '',
                    style: const TextStyle(
                      color: Colors.red,
                    ),
                  ),
                ),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    hintText: 'Enter you phone Number with Country Code',
                  ),
                  controller: phoneNumberController,
                  keyboardType: TextInputType.phone,
                  validator: (String? value) =>
                      value != null && value!.isNotEmpty ? null : "Required",
                ),
                Visibility(
                  visible: verificationId != null,
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'One Time Password',
                      hintText: 'Enter OTP Sent over message',
                    ),
                    controller: oneTimePassController,
                    keyboardType: TextInputType.phone,
                  ),
                ),
                ElevatedButton(
                  onPressed: verificationId == null
                      ? () {
                          if (_formKey.currentState?.validate() ?? false) {
                            firebaseAuth.verifyPhoneNumber(
                              phoneNumber: phoneNumberController.text.trim(),
                              verificationCompleted: _onVerificationComplete,
                              verificationFailed: _onVerificationFailed,
                              codeSent: _onCodeSent,
                              codeAutoRetrievalTimeout:
                                  _onCodeAutoRetrievalTimeOut,
                              forceResendingToken: forceResendingToken,
                            );
                          }
                        }
                      : null,
                  child: const Text('Request OTP'),
                ),
                ElevatedButton(
                  onPressed: verificationId != null
                      ? () async {
                          if (verificationId != null &&
                              oneTimePassController.text.trim().isNotEmpty) {
                            PhoneAuthCredential credential =
                                PhoneAuthProvider.credential(
                              verificationId: verificationId!,
                              smsCode: oneTimePassController.text.trim(),
                            );
                            await firebaseAuth.signInWithCredential(credential);
                          }
                        }
                      : null,
                  child: const Text('Verify'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onVerificationComplete(PhoneAuthCredential phoneAuthCredential) async {
    await firebaseAuth.signInWithCredential(phoneAuthCredential);
  }

  void _onVerificationFailed(FirebaseAuthException error) {
    setState(() {
      errorMessage = error.message;
    });
    if (kDebugMode) {
      print(error.toString());
    }
    Future.delayed(
      const Duration(seconds: 5),
      () => setState(() {
        errorMessage = null;
      }),
    );
  }

  void _onCodeSent(String verificationId, int? forceResendingToken) {
    setState(() {
      this.verificationId = verificationId;
      this.forceResendingToken = forceResendingToken;
    });
  }

  void _onCodeAutoRetrievalTimeOut(String verificationId) {}
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            onPressed: () {
              if (firebaseAuth.currentUser != null) {
                firebaseAuth.signOut();
              }
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'You have pushed the button this many times:',
            ),
          ],
        ),
      ),
    );
  }
}
