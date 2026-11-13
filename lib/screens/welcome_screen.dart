import 'package:flutter/material.dart';
import 'package:soche_fam/components/main_tabs.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0A5F34), // darker green
              Color(0xFF00674F), // main brand green
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // ---------------- WELCOME TEXT ----------------
              const Text(
                "Welcome",
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white70,
                  letterSpacing: 1.2,
                ),
              ),

              const SizedBox(height: 30),

              // ---------------- LOGO ----------------
              Container(
                width: size.width * 0.38,
                height: size.width * 0.38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: Colors.white.withOpacity(0.05),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    'images/ic_launcher.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // ---------------- APP TITLE ----------------
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  "SOCHE FUTURE\nADVENTIST MEN",
                  style: TextStyle(
                    fontSize: 28,
                    color: Colors.white,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const Spacer(),

              // ---------------- GET STARTED BUTTON ----------------
              Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 90,
                      vertical: 16,
                    ),
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0D7840),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 4,
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MainTabs(),
                      ),
                    );
                  },
                  child: const Text(
                    "Get Started",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
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
