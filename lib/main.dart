import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:ui';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

void main() {
  runApp(LegalMindApp());
}

// ─────────────────────────────────────────────
// CONSTANTS
// ─────────────────────────────────────────────

const kAuthBase = "http://localhost:8000"; 
const kApiBase  = "http://localhost:9000"; 

// Glassmorphism brand colors
const kTeal    = Color(0xFF00B4DB);
const kIndigo  = Color(0xFF0083B0);
const kPurple  = Color(0xFF6A0572);
const kNavy    = Color(0xFF101B2B);

// ─────────────────────────────────────────────
// ROOT APP
// ─────────────────────────────────────────────

class LegalMindApp extends StatefulWidget {
  @override
  _LegalMindAppState createState() => _LegalMindAppState();
}

class _LegalMindAppState extends State<LegalMindApp> {
  bool isLoggedIn = false;
  String userRole = "user";

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isLoggedIn = prefs.getBool("isLoggedIn") ?? false;
      userRole   = prefs.getString("role") ?? "user";
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Legal Mind",
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark, // Default to dark text/theme for glass over dark bg
        textTheme: GoogleFonts.outfitTextTheme(Theme.of(context).textTheme).apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
        ),
      ),
      home: isLoggedIn
          ? (userRole == "lawyer" ? LawyerNavigation() : MainNavigation())
          : LoginScreen(),
    );
  }
}

// ─────────────────────────────────────────────
// GLASS WIDGETS
// ─────────────────────────────────────────────

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const GlassContainer({
    required this.child,
    this.blur = 15.0,
    this.opacity = 0.15,
    this.borderRadius,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final br = borderRadius ?? BorderRadius.circular(24);
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: br,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: -5,
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: br,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(opacity),
              borderRadius: br,
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(opacity + 0.1),
                  Colors.white.withOpacity(opacity - 0.05 < 0 ? 0 : opacity - 0.05),
                ],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class AnimatedBackground extends StatelessWidget {
  final Widget child;
  const AnimatedBackground({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F2027), // Dark slate
            Color(0xFF203A43), // Deep teal
            Color(0xFF2C5364), // Slate teal
          ],
        ),
      ),
      child: Stack(
        children: [
          // Ambient glowing orbs
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kTeal.withOpacity(0.3),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: Container(),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kPurple.withOpacity(0.3),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 120, sigmaY: 120),
                child: Container(),
              ),
            ),
          ),
          SafeArea(child: child),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// REUSABLE INPUT
// ─────────────────────────────────────────────

Widget buildInput(TextEditingController c, String label, {bool isPassword = false, IconData? icon, bool enabled = true}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextField(
      controller: c,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        prefixIcon: icon != null ? Icon(icon, color: Colors.white.withOpacity(0.8)) : null,
        filled: true,
        fillColor: Colors.black.withOpacity(0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.5), width: 1.5),
        ),
      ),
    ),
  );
}

// ─────────────────────────────────────────────
// SIGNUP
// ─────────────────────────────────────────────

class SignUpScreen extends StatefulWidget {
  @override _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _name   = TextEditingController();
  final _state  = TextEditingController();
  final _mobile = TextEditingController();
  final _email  = TextEditingController();
  final _pass   = TextEditingController();
  String _role  = "user"; // default
  bool _loading = false;

  Future _signup() async {
    setState(() => _loading = true);
    try {
      final url = Uri.parse("$kAuthBase/signup");
      debugPrint("[SIGNUP] POST $url");
      final res = await http.post(url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "name": _name.text.trim(), "state": _state.text.trim(),
            "mobile": _mobile.text.trim(), "email": _email.text.trim(),
            "password": _pass.text.trim(), "role": _role,
          }));
      debugPrint("[SIGNUP] status=${res.statusCode}  body=${res.body}");
      final data = jsonDecode(res.body);
      if (data["status"] == "success") {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Signup Successful! Please login."),
            backgroundColor: kTeal));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(data["message"] ?? "Error"), backgroundColor: Colors.redAccent));
      }
    } catch (e) {
      debugPrint("[SIGNUP] EXCEPTION: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Connection error: $e"), backgroundColor: Colors.redAccent));
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: Text("Create Account"), leading: BackButton(color: Colors.white)),
      body: AnimatedBackground(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 80, 24, 24),
          child: GlassContainer(
            padding: EdgeInsets.all(28),
            child: Column(children: [
              buildInput(_name,   "Full Name", icon: Icons.person),
              buildInput(_state,  "State",     icon: Icons.location_on),
              buildInput(_mobile, "Mobile",    icon: Icons.phone),
              buildInput(_email,  "Email",     icon: Icons.email),
              buildInput(_pass,   "Password",  icon: Icons.lock, isPassword: true),
              
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: DropdownButtonFormField<String>(
                  value: _role,
                  decoration: InputDecoration(
                    labelText: "Register As",
                    labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                    prefixIcon: Icon(Icons.badge, color: Colors.white.withOpacity(0.8)),
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.2),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                  dropdownColor: Color(0xFF101B2B),
                  style: TextStyle(color: Colors.white),
                  items: [
                    DropdownMenuItem(value: "user", child: Text("Normal User")),
                    DropdownMenuItem(value: "lawyer", child: Text("Lawyer")),
                  ],
                  onChanged: (val) => setState(() => _role = val ?? "user"),
                ),
              ),
              
              SizedBox(height: 12),
              SizedBox(
                width: double.infinity, height: 55,
                child: ElevatedButton(
                  onPressed: _loading ? null : _signup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.white.withOpacity(0.4)),
                    ),
                  ),
                  child: _loading
                      ? SpinKitThreeBounce(color: Colors.white, size: 20)
                      : Text("SIGN UP", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// LOGIN
// ─────────────────────────────────────────────

class LoginScreen extends StatefulWidget {
  @override _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pass  = TextEditingController();
  String _role = "user"; // default
  bool _loading = false;

  Future _login() async {
    setState(() => _loading = true);
    try {
      final url = Uri.parse("$kAuthBase/login");
      debugPrint("[LOGIN] POST $url");
      final res = await http.post(url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"email": _email.text.trim(), "password": _pass.text.trim(), "role": _role}));
      debugPrint("[LOGIN] status=${res.statusCode}  body=${res.body}");
      final data = jsonDecode(res.body);
      if (data["status"] == "success") {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool("isLoggedIn", true);
        await prefs.setString("name",  data["name"]  ?? "");
        await prefs.setString("email", data["email"] ?? "");
        await prefs.setString("role",  data["role"]  ?? "user");
        
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => data["role"] == "lawyer" ? LawyerNavigation() : MainNavigation()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(data["message"] ?? "Wrong Email or Password"), backgroundColor: Colors.redAccent));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Connection error: $e"), backgroundColor: Colors.redAccent));
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Column(
              children: [
                // Logo
                GlassContainer(
                  borderRadius: BorderRadius.circular(40),
                  padding: EdgeInsets.all(24),
                  child: Icon(Icons.gavel_rounded, size: 64, color: Colors.white),
                ),
                SizedBox(height: 24),
                Text("Legal Mind",
                    style: GoogleFonts.outfit(
                        fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)),
                Text("Your AI Legal Assistant",
                    style: TextStyle(color: Colors.white70, fontSize: 16, letterSpacing: 0.5)),
                SizedBox(height: 48),

                // Card
                GlassContainer(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    children: [
                      buildInput(_email, "Email",    icon: Icons.email_outlined),
                      buildInput(_pass,  "Password", icon: Icons.lock_outline, isPassword: true),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: DropdownButtonFormField<String>(
                          value: _role,
                          decoration: InputDecoration(
                            labelText: "Login As",
                            labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                            prefixIcon: Icon(Icons.badge, color: Colors.white.withOpacity(0.8)),
                            filled: true,
                            fillColor: Colors.black.withOpacity(0.2),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          ),
                          dropdownColor: Color(0xFF101B2B),
                          style: TextStyle(color: Colors.white),
                          items: [
                            DropdownMenuItem(value: "user", child: Text("Normal User")),
                            DropdownMenuItem(value: "lawyer", child: Text("Lawyer")),
                          ],
                          onChanged: (val) => setState(() => _role = val ?? "user"),
                        ),
                      ),
                      SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity, height: 55,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.2),
                            foregroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Colors.white.withOpacity(0.5)),
                            ),
                          ),
                          child: _loading
                              ? SpinKitThreeBounce(color: Colors.white, size: 20)
                              : Text("LOGIN", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 16)),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextButton(
                        onPressed: () => Navigator.push(
                            context, MaterialPageRoute(builder: (_) => SignUpScreen())),
                        child: Text("Don't have an account? Sign Up",
                            style: TextStyle(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// MAIN NAVIGATION
// ─────────────────────────────────────────────

class MainNavigation extends StatefulWidget {
  @override _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _index = 0;
  final _pages = [HomePage(), LawyersPage(), NewsPage(), DocumentAnalysisPage(), ProfilePage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: _pages[_index],
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            color: Colors.black.withOpacity(0.3),
            child: NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              backgroundColor: Colors.transparent,
              indicatorColor: Colors.white.withOpacity(0.2),
              destinations: [
                NavigationDestination(
                    icon: Icon(Icons.search, color: Colors.white70),
                    selectedIcon: Icon(Icons.search, color: Colors.white), label: "Search"),
                NavigationDestination(
                    icon: Icon(Icons.gavel_outlined, color: Colors.white70),
                    selectedIcon: Icon(Icons.gavel, color: Colors.white), label: "Lawyers"),
                NavigationDestination(
                    icon: Icon(Icons.article_outlined, color: Colors.white70),
                    selectedIcon: Icon(Icons.article, color: Colors.white), label: "News"),
                NavigationDestination(
                    icon: Icon(Icons.document_scanner_outlined, color: Colors.white70),
                    selectedIcon: Icon(Icons.document_scanner, color: Colors.white), label: "Analyze"),
                NavigationDestination(
                    icon: Icon(Icons.person_outline, color: Colors.white70),
                    selectedIcon: Icon(Icons.person, color: Colors.white), label: "Profile"),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// LAWYER NAVIGATION & PAGES
// ─────────────────────────────────────────────

class LawyerNavigation extends StatefulWidget {
  @override _LawyerNavigationState createState() => _LawyerNavigationState();
}

class _LawyerNavigationState extends State<LawyerNavigation> {
  int _index = 0;
  final _pages = [HomePage(), ClientsPage(), NewsPage(), LawyerProfilePage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: _pages[_index],
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            color: Colors.black.withOpacity(0.3),
            child: NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              backgroundColor: Colors.transparent,
              indicatorColor: Colors.white.withOpacity(0.2),
              destinations: [
                NavigationDestination(
                    icon: Icon(Icons.search, color: Colors.white70),
                    selectedIcon: Icon(Icons.search, color: Colors.white), label: "Search"),
                NavigationDestination(
                    icon: Icon(Icons.people_outline, color: Colors.white70),
                    selectedIcon: Icon(Icons.people, color: Colors.white), label: "Clients"),
                NavigationDestination(
                    icon: Icon(Icons.article_outlined, color: Colors.white70),
                    selectedIcon: Icon(Icons.article, color: Colors.white), label: "News"),
                NavigationDestination(
                    icon: Icon(Icons.person_outline, color: Colors.white70),
                    selectedIcon: Icon(Icons.person, color: Colors.white), label: "Profile"),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ClientsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppointmentsListPage();
  }
}

class LawyerProfilePage extends StatefulWidget {
  @override _LawyerProfilePageState createState() => _LawyerProfilePageState();
}

class _LawyerProfilePageState extends State<LawyerProfilePage> {
  final _nameController       = TextEditingController();
  final _specController        = TextEditingController();
  final _expController         = TextEditingController();
  final _locController         = TextEditingController();
  final _contactController     = TextEditingController();
  final _bioController         = TextEditingController();
  final _winRateController     = TextEditingController();
  final _courtsController      = TextEditingController();
  final _langsController       = TextEditingController();
  final _enrollmentController  = TextEditingController();

  String _email = "";
  bool _loading = false;

  @override
  void initState() { super.initState(); _loadProfile(); }

  bool _isEditing = false;

  Future _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final userEmail = prefs.getString("email") ?? "";
    setState(() { _email = userEmail; });
    
    // Fetch lawyer to see if they exist
    setState(() => _loading = true);
    try {
      final res = await http.get(Uri.parse("$kAuthBase/lawyers"));
      final data = json.decode(res.body);
      if (data["status"] == "success") {
        final lawyers = data["lawyers"] as List;
        final me = lawyers.firstWhere((l) => l["email"] == userEmail, orElse: () => null);
        if (me != null) {
          _nameController.text       = me["name"] ?? "";
          _specController.text        = me["specialization"] ?? "";
          _expController.text         = (me["experience"] ?? "").toString();
          _contactController.text     = me["contact"] ?? "";
          _locController.text         = me["location"] ?? "";
          _bioController.text         = me["bio"] ?? "";
          _winRateController.text     = (me["win_rate"] ?? "").toString();
          _courtsController.text      = me["courts"] ?? "";
          _langsController.text       = me["languages"] ?? "";
          _enrollmentController.text  = me["enrollment_number"] ?? "";
          setState(() => _isEditing = false); // exists, so view mode
        } else {
          _nameController.text = prefs.getString("name") ?? "";
          setState(() => _isEditing = true); // new, so edit mode
        }
      }
    } catch (e) {
      print("[LOAD-PROFILE] $e");
    }
    setState(() => _loading = false);
  }

  Future _updateProfile() async {
    setState(() => _loading = true);
    try {
      final res = await http.post(
        Uri.parse("$kAuthBase/register-lawyer"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email":             _email,
          "name":              _nameController.text.trim(),
          "specialization":    _specController.text.trim(),
          "experience":        _expController.text.trim(),
          "contact":           _contactController.text.trim(),
          "location":          _locController.text.trim(),
          "bio":               _bioController.text.trim(),
          "win_rate":          double.tryParse(_winRateController.text.trim()) ?? 0,
          "courts":            _courtsController.text.trim(),
          "languages":         _langsController.text.trim(),
          "enrollment_number": _enrollmentController.text.trim(),
        }),
      );
      final data = jsonDecode(res.body);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(data["message"] ?? "Updated"),
        backgroundColor: data["status"] == "success" ? kTeal : Colors.redAccent,
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Error: $e"), backgroundColor: Colors.redAccent));
    }
    setState(() => _loading = false);
  }

  void _showAddCaseDialog() {
    final titleC = TextEditingController();
    final descC  = TextEditingController();
    final yearC  = TextEditingController(text: DateTime.now().year.toString());
    String caseType    = "Criminal";
    String caseOutcome = "Won";

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: Color(0xFF101B2B),
          title: Text("Add Case to Portfolio", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                controller: titleC,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(labelText: "Case Title", labelStyle: TextStyle(color: Colors.white54),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: kTeal)),
                ),
              ),
              SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: caseType,
                dropdownColor: Color(0xFF101B2B),
                style: TextStyle(color: Colors.white),
                items: ["Criminal","Civil","Family","Corporate","Property","Consumer","Labour","Other"]
                    .map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setS(() => caseType = v ?? caseType),
                decoration: InputDecoration(labelText: "Case Type", labelStyle: TextStyle(color: Colors.white54),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24))),
              ),
              SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: caseOutcome,
                dropdownColor: Color(0xFF101B2B),
                style: TextStyle(color: Colors.white),
                items: ["Won","Lost","Settled","Ongoing"].map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
                onChanged: (v) => setS(() => caseOutcome = v ?? caseOutcome),
                decoration: InputDecoration(labelText: "Outcome", labelStyle: TextStyle(color: Colors.white54),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24))),
              ),
              SizedBox(height: 12),
              TextField(
                controller: yearC,
                keyboardType: TextInputType.number,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(labelText: "Year", labelStyle: TextStyle(color: Colors.white54),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: kTeal))),
              ),
              SizedBox(height: 12),
              TextField(
                controller: descC,
                maxLines: 3,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(labelText: "Brief Description", labelStyle: TextStyle(color: Colors.white54),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: kTeal))),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Cancel", style: TextStyle(color: Colors.white54))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: kTeal),
              onPressed: () async {
                if (titleC.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                try {
                  await http.patch(
                    Uri.parse("$kAuthBase/add-case"),
                    headers: {"Content-Type": "application/json"},
                    body: jsonEncode({
                      "email":       _email,
                      "title":       titleC.text.trim(),
                      "type":        caseType,
                      "year":        yearC.text.trim(),
                      "outcome":     caseOutcome,
                      "description": descC.text.trim(),
                    }),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Case added to your portfolio! ✅"), backgroundColor: kTeal));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent));
                }
              },
              child: Text("Add Case", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future _signOut() async {
    final p = await SharedPreferences.getInstance();
    await p.clear();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBackground(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, 60, 24, 100),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Lawyer Profile", style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: Icon(_isEditing ? Icons.close : Icons.edit, color: Colors.white),
                  onPressed: () => setState(() => _isEditing = !_isEditing),
                )
              ],
            ),
            Text(_email, style: TextStyle(color: Colors.white70)),
            SizedBox(height: 32),

            GlassContainer(
              padding: EdgeInsets.all(24),
              child: Column(children: [
                buildInput(_nameController,    "Full Name",                  icon: Icons.person, enabled: _isEditing),
                buildInput(_specController,    "Specialization",             icon: Icons.gavel, enabled: _isEditing),
                buildInput(_expController,     "Years of Experience",        icon: Icons.timeline, enabled: _isEditing),
                buildInput(_locController,     "Primary Location",           icon: Icons.location_on, enabled: _isEditing),
                buildInput(_contactController, "Contact / Phone",            icon: Icons.phone, enabled: _isEditing),
                buildInput(_bioController,     "Professional Bio",           icon: Icons.description, enabled: _isEditing),
                buildInput(_winRateController, "Win Rate % (e.g. 80)",       icon: Icons.emoji_events, enabled: _isEditing),
                buildInput(_courtsController,     "Courts (comma-separated)",      icon: Icons.account_balance, enabled: _isEditing),
                buildInput(_langsController,      "Languages (comma-separated)",   icon: Icons.language, enabled: _isEditing),
                buildInput(_enrollmentController, "Bar Council Enrollment No.",    icon: Icons.badge, enabled: _isEditing),
                SizedBox(height: 16),
                if (_isEditing) SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _updateProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.white.withOpacity(0.5)),
                      ),
                    ),
                    child: _loading ? SpinKitThreeBounce(color: Colors.white, size: 20)
                        : Text("Update Professional Details", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ]),
            ),

            SizedBox(height: 16),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton.icon(
                onPressed: _showAddCaseDialog,
                icon: Icon(Icons.add_circle_outline, color: Colors.white),
                label: Text("Add Case to Portfolio", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kIndigo.withOpacity(0.7), foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: kTeal.withOpacity(0.5))),
                ),
              ),
            ),

            SizedBox(height: 32),
            SizedBox(
              width: double.infinity, height: 55,
              child: ElevatedButton.icon(
                onPressed: _signOut,
                icon: Icon(Icons.logout, color: Colors.redAccent),
                label: Text("Sign Out", style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.1), elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.redAccent.withOpacity(0.5))),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────
// HOME / SEARCH PAGE
// ─────────────────────────────────────────────


class HomePage extends StatefulWidget {
  @override _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List   _results = [];
  String _query   = "";
  bool   _loading = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future _search(String q) async {
    setState(() { _query = q; });
    if (q.trim().isEmpty) { setState(() => _results = []); return; }
    setState(() => _loading = true);
    try {
      final url = Uri.parse("$kApiBase/search?query=${Uri.encodeComponent(q)}");
      final res  = await http.get(url);
      final data = json.decode(res.body);
      setState(() => _results = data["results"] ?? []);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Error: $e"), backgroundColor: Colors.redAccent));
    }
    setState(() => _loading = false);
  }

  void _showLlmSheet(String endpoint, String key, String title, IconData icon) {
    if (_query.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Type a question first"), backgroundColor: Colors.orange));
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LlmBottomSheet(endpoint: endpoint, key_: key, title: title, query: _query, icon: icon),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBackground(
      child: Column(
        children: [
          // Header & Search
          Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Search Laws", style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold)),
                SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  onChanged: _search,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Search Indian Laws or Ask AI...",
                    hintStyle: TextStyle(color: Colors.white60),
                    prefixIcon: Icon(Icons.search, color: Colors.white70),
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.6)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Actions
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _GlassActionButton(
                      label: "Explain Law", icon: Icons.auto_awesome,
                      onTap: () => _showLlmSheet("chat", "reply", "AI Law Explanation", Icons.auto_awesome),
                    )),
                    SizedBox(width: 16),
                    Expanded(child: _GlassActionButton(
                      label: "Legal Advice", icon: Icons.balance,
                      onTap: () => _showLlmSheet("advice", "advice", "AI Legal Advice", Icons.balance),
                    )),
                  ],
                ),
                SizedBox(height: 16),
                SizedBox(
                  width: double.infinity, height: 60,
                  child: ElevatedButton.icon(
                    onPressed: () {
                       Navigator.push(context, MaterialPageRoute(builder: (_) => LegalChatBotPage()));
                    },
                    icon: Icon(Icons.smart_toy, color: Colors.white, size: 28),
                    label: Text("Continuous AI Chat Assistant", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kIndigo.withOpacity(0.8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: kTeal.withOpacity(0.5))),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Results
          Expanded(
            child: _loading
                ? Center(child: SpinKitThreeBounce(color: Colors.white, size: 24))
                : _results.isEmpty && _query.isNotEmpty
                    ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.search_off, size: 64, color: Colors.white30),
                        SizedBox(height: 16),
                        Text("No matching laws found", style: TextStyle(color: Colors.white60, fontSize: 16)),
                      ]))
                    : ListView.separated(
                        padding: EdgeInsets.fromLTRB(20, 0, 20, 100), // padding for bottom nav
                        itemCount: _results.length,
                        separatorBuilder: (_, __) => SizedBox(height: 12),
                        itemBuilder: (_, i) {
                          final r = _results[i];
                          final score = ((r["score"] ?? 0.0) * 100).toInt();
                          final keywords = r["keywords"] as List? ?? [];
                          
                          return GestureDetector(
                            onTap: () {
                              final text = r["title"] ?? "";
                              _searchController.text = text;
                              _search(text);
                            },
                            child: GlassContainer(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(Icons.menu_book, color: Colors.white, size: 24),
                                      ),
                                      SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text("${r["law"] ?? ""} · ${r["section"] ?? ""}",
                                                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 13)),
                                            SizedBox(height: 4),
                                            Text(r["title"] ?? "",
                                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: score > 60 ? Colors.greenAccent.withOpacity(0.2) : Colors.orangeAccent.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: score > 60 ? Colors.greenAccent.withOpacity(0.5) : Colors.orangeAccent.withOpacity(0.5)),
                                        ),
                                        child: Text("$score%",
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                                color: score > 60 ? Colors.greenAccent : Colors.orangeAccent)),
                                      ),
                                    ],
                                  ),
                                  if (keywords.isNotEmpty) ...[
                                    SizedBox(height: 12),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: keywords.map((kw) => GestureDetector(
                                        onTap: () {
                                          _searchController.text = kw.toString();
                                          _search(kw.toString());
                                        },
                                        child: Container(
                                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.white.withOpacity(0.2)),
                                          ),
                                          child: Text(kw.toString(), style: TextStyle(fontSize: 11, color: Colors.white70)),
                                        ),
                                      )).toList(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _GlassActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _GlassActionButton({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// LLM BOTTOM SHEET (GLASS)
// ─────────────────────────────────────────────

class _LlmBottomSheet extends StatefulWidget {
  final String title, endpoint, key_, query;
  final IconData icon;
  const _LlmBottomSheet({
    required this.title, required this.endpoint,
    required this.key_,  required this.query, required this.icon,
  });
  @override _LlmBottomSheetState createState() => _LlmBottomSheetState();
}

class _LlmBottomSheetState extends State<_LlmBottomSheet> {
  String? _result;
  String? _error;
  bool    _loading = true;

  @override void initState() { super.initState(); _fetch(); }

  Future _fetch() async {
    try {
      final url = Uri.parse("$kApiBase/${widget.endpoint}?query=${Uri.encodeComponent(widget.query)}");
      final res  = await http.get(url).timeout(Duration(seconds: 60));
      final data = json.decode(res.body);
      final raw  = (data[widget.key_] ?? "No response").toString();
      setState(() { _result = raw; _loading = false; });
      // Fire-and-forget: save to chat history
      _saveHistory(raw);
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future _saveHistory(String response) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString("email") ?? "";
      if (email.isEmpty) return;
      await http.post(
        Uri.parse("$kAuthBase/save-history"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_email": email,
          "query":      widget.query,
          "response":   response,
          "type":       widget.endpoint == "chat" ? "explain" : "advice",
        }),
      );
    } catch (_) {} // silent fail — history is non-critical
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9, maxChildSize: 0.95, minChildSize: 0.5,
      builder: (_, controller) => ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            color: Color(0xFF101B2B).withOpacity(0.7), // Deep dark glass
            child: Column(
              children: [
                Container(
                  margin: EdgeInsets.only(top: 12, bottom: 12),
                  width: 50, height: 5,
                  decoration: BoxDecoration(color: Colors.white30, borderRadius: BorderRadius.circular(10)),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Row(
                    children: [
                      Icon(widget.icon, color: Colors.white),
                      SizedBox(width: 12),
                      Expanded(child: Text(widget.title, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold))),
                      IconButton(icon: Icon(Icons.close, color: Colors.white70), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                ),
                Divider(color: Colors.white10, height: 1),
                Expanded(
                  child: _loading
                      ? Center(child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SpinKitThreeBounce(color: Colors.white, size: 30),
                            SizedBox(height: 16),
                            Text("Analyzing Indian Law...", style: TextStyle(color: Colors.white60)),
                          ],
                        ))
                      : _error != null
                          ? Center(child: Text(_error!, style: TextStyle(color: Colors.redAccent)))
                          : Markdown(
                              controller: controller,
                              data: _result ?? "",
                              padding: EdgeInsets.fromLTRB(24, 16, 24, 40),
                              styleSheet: MarkdownStyleSheet(
                                h3: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.lightBlueAccent),
                                h2: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.lightBlueAccent),
                                p: TextStyle(fontSize: 15, height: 1.6, color: Colors.white.withOpacity(0.9)),
                                strong: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                listBullet: TextStyle(color: Colors.white),
                                blockquoteDecoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border(left: BorderSide(color: Colors.lightBlueAccent, width: 4)),
                                ),
                                blockquote: TextStyle(color: Colors.white70),
                              ),
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// LAWYER DETAILS PAGE
// ─────────────────────────────────────────────

class LawyerDetailsPage extends StatefulWidget {
  final Map lawyer;
  LawyerDetailsPage({required this.lawyer});
  @override _LawyerDetailsPageState createState() => _LawyerDetailsPageState();
}

class _LawyerDetailsPageState extends State<LawyerDetailsPage> {
  int    _selectedRating = 0;
  bool   _submitting     = false;
  bool   _requestingAppt = false;
  bool   _loadingReviews = true;
  List   _reviews        = [];
  List   _cases          = [];
  final  _reviewController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cases = List.from(widget.lawyer["cases"] ?? []);
    _loadReviews();
  }

  Future _loadReviews() async {
    try {
      final email = widget.lawyer["email"] ?? "";
      if (email.isEmpty) { setState(() => _loadingReviews = false); return; }
      final res  = await http.get(Uri.parse("$kAuthBase/reviews?lawyer_email=${Uri.encodeComponent(email)}"));
      final data = jsonDecode(res.body);
      setState(() { _reviews = data["reviews"] ?? []; _loadingReviews = false; });
    } catch (_) { setState(() => _loadingReviews = false); }
  }

  Future _bookAppointment() async {
    setState(() => _requestingAppt = true);
    try {
      final prefs     = await SharedPreferences.getInstance();
      final userEmail = prefs.getString("email") ?? "";
      final userName  = prefs.getString("name")  ?? "User";
      final res = await http.post(Uri.parse("$kAuthBase/request-appointment"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"user_email": userEmail, "user_name": userName,
          "lawyer_email": widget.lawyer["email"], "lawyer_name": widget.lawyer["name"]}));
      final data = jsonDecode(res.body);
      if (data["status"] == "success") {
        Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(
          appointmentId: data["appointment_id"], otherName: widget.lawyer["name"])));
      } else throw Exception(data["message"] ?? "Failed");
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent));
    }
    setState(() => _requestingAppt = false);
  }

  Future _submitReview() async {
    if (_selectedRating == 0 && _reviewController.text.trim().isEmpty) return;
    setState(() => _submitting = true);
    try {
      final prefs     = await SharedPreferences.getInstance();
      final userEmail = prefs.getString("email") ?? "";
      final userName  = prefs.getString("name")  ?? "Anonymous";
      final lawyerEmail = widget.lawyer["email"] ?? "";
      // Save rating
      if (_selectedRating > 0) {
        await http.post(Uri.parse("$kAuthBase/rate-lawyer"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"lawyer_email": lawyerEmail, "rating": _selectedRating}));
      }
      // Save review text
      if (_reviewController.text.trim().isNotEmpty) {
        await http.post(Uri.parse("$kAuthBase/add-review"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "lawyer_email": lawyerEmail,
            "user_email":   userEmail,
            "user_name":    userName,
            "review_text":  _reviewController.text.trim(),
            "rating":       _selectedRating,
          }));
      }
      _reviewController.clear();
      setState(() => _selectedRating = 0);
      await _loadReviews();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Review submitted! ✅"), backgroundColor: kTeal));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent));
    }
    setState(() => _submitting = false);
  }

  Color _outcomeColor(String outcome) {
    switch (outcome.toLowerCase()) {
      case "won":     return Colors.greenAccent;
      case "lost":    return Colors.redAccent;
      case "settled": return Colors.orangeAccent;
      default:        return Colors.blueAccent;
    }
  }

  String _outcomeEmoji(String outcome) {
    switch (outcome.toLowerCase()) {
      case "won":     return "✅";
      case "lost":    return "❌";
      case "settled": return "⚖️";
      default:        return "🔵";
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.lawyer;
    final name       = l["name"]           ?? "Unknown Lawyer";
    final spec       = l["specialization"] ?? "General Law";
    final exp        = l["experience"]?.toString() ?? "0";
    final winRate    = l["win_rate"]?.toString()    ?? "0";
    final bio        = (l["bio"]       ?? "").toString();
    final courts     = List<String>.from(l["courts"]    ?? []);
    final languages  = List<String>.from(l["languages"] ?? []);
    final ratingAvg  = l["rating_avg"]  ?? 0.0;
    final ratingCnt  = l["rating_count"] ?? 0;
    final casesCount = _cases.length;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: Text(name, overflow: TextOverflow.ellipsis),
          leading: BackButton(color: Colors.white), backgroundColor: Colors.transparent, elevation: 0),
      body: AnimatedBackground(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 100, 24, 60),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // ── HERO HEADER ──
            Center(child: Column(children: [
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [kNavy, kIndigo], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white54, width: 2),
                  boxShadow: [BoxShadow(color: kTeal.withOpacity(0.4), blurRadius: 20)],
                ),
                alignment: Alignment.center,
                child: Text(name[0].toUpperCase(), style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold)),
              ),
              SizedBox(height: 12),
              Text(name, style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold)),
              Container(
                margin: EdgeInsets.only(top: 6),
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(color: kTeal.withOpacity(0.2), borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: kTeal.withOpacity(0.5))),
                child: Text(spec, style: TextStyle(color: kTeal, fontWeight: FontWeight.w600)),
              ),
              if ((ratingAvg as num) > 0) ...[
                SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  ...List.generate(5, (i) => Icon(i < ratingAvg.round() ? Icons.star : Icons.star_border, color: Colors.amber, size: 18)),
                  SizedBox(width: 6),
                  Text("$ratingAvg ($ratingCnt)", style: TextStyle(color: Colors.white70, fontSize: 13)),
                ]),
              ],
            ])),

            SizedBox(height: 24),

            // ── STATS ROW ──
            Row(children: [
              _statCard("Experience", "$exp yrs", Icons.timeline),
              SizedBox(width: 10),
              _statCard("Win Rate", "$winRate%", Icons.emoji_events),
              SizedBox(width: 10),
              _statCard("Cases", "$casesCount", Icons.folder_open),
            ]),

            SizedBox(height: 16),

            // ── BIO CARD ──
            if (bio.isNotEmpty)
              GlassContainer(
                padding: EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [Icon(Icons.description_outlined, color: kTeal, size: 18), SizedBox(width: 8),
                    Text("Professional Bio", style: TextStyle(color: kTeal, fontWeight: FontWeight.bold, fontSize: 14))]),
                  SizedBox(height: 8),
                  Text(bio, style: TextStyle(color: Colors.white70, height: 1.5)),
                ]),
              ),

            if (bio.isNotEmpty) SizedBox(height: 16),

            // ── DETAILS CARD ──
            GlassContainer(
              padding: EdgeInsets.all(16),
              child: Column(children: [
                _detailRow(Icons.location_on,       "Location", l["location"] ?? "Not specified"),
                _detailRow(Icons.email_outlined,     "Email",    l["email"]    ?? "Not specified"),
                _detailRow(Icons.phone_outlined,     "Phone",    l["contact"]  ?? "Not specified"),
                if (courts.isNotEmpty)
                  _chipsRow(Icons.account_balance,   "Courts",    courts),
                if (languages.isNotEmpty)
                  _chipsRow(Icons.language,          "Languages", languages),
              ]),
            ),

            SizedBox(height: 16),

            // ── ACTION BUTTONS ──
            SizedBox(width: double.infinity, height: 52,
              child: ElevatedButton.icon(
                onPressed: _requestingAppt ? null : _bookAppointment,
                icon: _requestingAppt ? SizedBox() : Icon(Icons.chat_bubble_outline),
                label: _requestingAppt ? SpinKitThreeBounce(color: Colors.white, size: 18)
                    : Text("Message / Book Appointment", style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: kNavy, foregroundColor: Colors.white,
                  side: BorderSide(color: kTeal.withOpacity(0.5))),
              )),

            SizedBox(height: 10),

            if ((l["contact"] ?? "").toString().isNotEmpty)
              SizedBox(width: double.infinity, height: 52,
                child: ElevatedButton.icon(
                  onPressed: () async { if (await canLaunchUrl(Uri.parse("tel:${l['contact']}"))) launchUrl(Uri.parse("tel:${l['contact']}")); },
                  icon: Icon(Icons.phone),
                  label: Text("Call Now", style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
                )),

            SizedBox(height: 24),

            // ── CASE PORTFOLIO ──
            if (_cases.isNotEmpty) ...[
              Text("📁 Case Portfolio", style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold)),
              SizedBox(height: 12),
              ..._cases.map((c) {
                final outcome = (c["outcome"] ?? "").toString();
                return Container(
                  margin: EdgeInsets.only(bottom: 12),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _outcomeColor(outcome).withOpacity(0.35)),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text(c["title"] ?? "Untitled",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: _outcomeColor(outcome).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _outcomeColor(outcome).withOpacity(0.5))),
                        child: Text("${_outcomeEmoji(outcome)} $outcome",
                            style: TextStyle(color: _outcomeColor(outcome), fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                    ]),
                    SizedBox(height: 4),
                    Row(children: [
                      _typeBadge(c["type"] ?? "General"),
                      SizedBox(width: 8),
                      Text(c["year"] ?? "", style: TextStyle(color: Colors.white54, fontSize: 12)),
                    ]),
                    if ((c["description"] ?? "").toString().isNotEmpty) ...[
                      SizedBox(height: 6),
                      Text(c["description"], style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.4)),
                    ]
                  ]),
                );
              }).toList(),
              SizedBox(height: 24),
            ],

            // ── RATE & REVIEW ──
            Text("⭐ Rate & Review", style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            GlassContainer(
              padding: EdgeInsets.all(20),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (i) {
                  int s = i + 1;
                  return IconButton(
                    icon: Icon(s <= _selectedRating ? Icons.star : Icons.star_border, color: Colors.amber, size: 34),
                    onPressed: () => setState(() => _selectedRating = s),
                  );
                })),
                SizedBox(height: 12),
                TextField(
                  controller: _reviewController,
                  maxLines: 3,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Write your review here...",
                    hintStyle: TextStyle(color: Colors.white38),
                    filled: true, fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white12)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kTeal)),
                  ),
                ),
                SizedBox(height: 12),
                SizedBox(width: double.infinity, height: 48,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submitReview,
                    style: ElevatedButton.styleFrom(backgroundColor: kTeal, foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: _submitting ? SpinKitThreeBounce(color: Colors.white, size: 20)
                        : Text("Submit Review", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  )),
              ]),
            ),

            SizedBox(height: 24),

            // ── REVIEWS SECTION ──
            Text("💬 User Reviews", style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            if (_loadingReviews)
              Center(child: SpinKitThreeBounce(color: Colors.white54, size: 20))
            else if (_reviews.isEmpty)
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
                child: Center(child: Text("No reviews yet. Be the first to review!", style: TextStyle(color: Colors.white54))),
              )
            else
              ..._reviews.map((r) => Container(
                margin: EdgeInsets.only(bottom: 12),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.07), borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.1))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    CircleAvatar(
                      radius: 18, backgroundColor: kIndigo,
                      child: Text((r["user_name"] ?? "?")[0].toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                    SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(r["user_name"] ?? "Anonymous", style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(r["created_at"]?.toString().split("T").first ?? "", style: TextStyle(color: Colors.white38, fontSize: 11)),
                    ])),
                    Row(children: List.generate((r["rating"] ?? 0).round().clamp(0, 5), (_) => Icon(Icons.star, color: Colors.amber, size: 14))),
                  ]),
                  if ((r["review_text"] ?? "").toString().isNotEmpty) ...[
                    SizedBox(height: 8),
                    Text(r["review_text"], style: TextStyle(color: Colors.white70, height: 1.4)),
                  ]
                ]),
              )).toList(),
          ]),
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Expanded(child: Container(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(children: [
        Icon(icon, color: kTeal, size: 22),
        SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.white54, fontSize: 11)),
      ]),
    ));
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: Colors.white54, size: 20),
        SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w600)),
          SizedBox(height: 2),
          Text(value, style: TextStyle(color: Colors.white, fontSize: 14)),
        ])),
      ]),
    );
  }

  Widget _chipsRow(IconData icon, String label, List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: Colors.white54, size: 20),
        SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w600)),
          SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 6, children: items.map((t) => Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: kIndigo.withOpacity(0.3), borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12)),
            child: Text(t, style: TextStyle(fontSize: 12, color: Colors.white70)),
          )).toList()),
        ])),
      ]),
    );
  }

  Widget _typeBadge(String type) {
    final colors = {"Criminal": Colors.redAccent, "Civil": Colors.blueAccent, "Family": Colors.pinkAccent,
      "Corporate": Colors.orangeAccent, "Property": Colors.greenAccent, "Consumer": Colors.tealAccent};
    final c = colors[type] ?? Colors.white54;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: c.withOpacity(0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: c.withOpacity(0.4))),
      child: Text(type, style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

// ─────────────────────────────────────────────
// LAWYERS PAGE
// ─────────────────────────────────────────────

class LawyersPage extends StatefulWidget {
  @override _LawyersPageState createState() => _LawyersPageState();
}

class _LawyersPageState extends State<LawyersPage> {
  List    _lawyers = [];
  bool    _loading = true;
  String? _error;

  @override void initState() { super.initState(); _load(); }

  Future _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res  = await http.get(Uri.parse("$kAuthBase/lawyers"));
      setState(() => _lawyers = json.decode(res.body)["lawyers"] ?? []);
    } catch (e) {
      setState(() => _error = e.toString());
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBackground(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Text("Find a Lawyer", style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: _loading
                ? Center(child: SpinKitThreeBounce(color: Colors.white, size: 24))
                : _error != null
                    ? Center(child: Text("Error: $_error", style: TextStyle(color: Colors.redAccent)))
                    : _lawyers.isEmpty
                        ? Center(child: Text("No lawyers registered", style: TextStyle(color: Colors.white60)))
                        : ListView.separated(
                            padding: EdgeInsets.fromLTRB(20, 0, 20, 100),
                            itemCount: _lawyers.length,
                            separatorBuilder: (_, __) => SizedBox(height: 16),
                            itemBuilder: (_, i) {
                              final l = _lawyers[i];
                              return GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => LawyerDetailsPage(lawyer: l)),
                                ),
                                child: GlassContainer(
                                  padding: EdgeInsets.all(20),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 56, height: 56,
                                        decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.2),
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white54)),
                                        alignment: Alignment.center,
                                        child: Text((l["name"] ?? "?")[0].toUpperCase(),
                                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                                      ),
                                      SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(l["name"] ?? "", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                            SizedBox(height: 4),
                                            Text(l["specialization"] ?? "General Law", style: TextStyle(color: Colors.white70)),
                                            SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(Icons.location_on, size: 14, color: Colors.white54),
                                                SizedBox(width: 4),
                                                Text(l["location"] ?? "Unknown", style: TextStyle(fontSize: 12, color: Colors.white54)),
                                                SizedBox(width: 12),
                                                Icon(Icons.work, size: 14, color: Colors.white54),
                                                SizedBox(width: 4),
                                                Text("${l["experience"] ?? 0} yrs", style: TextStyle(fontSize: 12, color: Colors.white54)),
                                              ],
                                            ),
                                            SizedBox(height: 4),
                                            if (l["rating_avg"] != null && l["rating_avg"] > 0)
                                              Row(
                                                children: [
                                                  Icon(Icons.star, size: 14, color: Colors.amber),
                                                  SizedBox(width: 4),
                                                  Text("${l['rating_avg']} (${l['rating_count'] ?? 0} reviews)", 
                                                    style: TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w600)),
                                                ],
                                              ),
                                          ],
                                        ),
                                      ),
                                      Icon(Icons.chevron_right, color: Colors.white54),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// APPOINTMENTS LIST PAGE
// ─────────────────────────────────────────────

class AppointmentsListPage extends StatefulWidget {
  @override _AppointmentsListPageState createState() => _AppointmentsListPageState();
}

class _AppointmentsListPageState extends State<AppointmentsListPage> {
  List _appts = [];
  bool _loading = true;
  String? _email, _role;

  @override void initState() { super.initState(); _load(); }

  Future _load() async {
    final prefs = await SharedPreferences.getInstance();
    _email = prefs.getString("email");
    _role  = prefs.getString("role");
    
    if (_email == null) return;

    try {
      final res = await http.get(Uri.parse("$kAuthBase/appointments?email=$_email&role=$_role"));
      final data = jsonDecode(res.body);
      if (mounted) setState(() => _appts = data["appointments"] ?? []);
    } catch (e) {
      print("Error loading appts: $e");
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_role == "lawyer" ? "My Clients" : "Lawyer Appointments")),
      body: AnimatedBackground(
        child: _loading 
          ? Center(child: SpinKitThreeBounce(color: Colors.white, size: 24))
          : _appts.isEmpty
            ? Center(child: Text("No active chats found", style: TextStyle(color: Colors.white60)))
            : ListView.separated(
                padding: EdgeInsets.all(20),
                itemCount: _appts.length,
                separatorBuilder: (_, __) => SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final a = _appts[i];
                  final otherName = _role == "lawyer" ? a["user_name"] : a["lawyer_name"];
                  return GlassContainer(
                    child: ListTile(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(
                        appointmentId: a["appointment_id"],
                        otherName: otherName,
                      ))),
                      leading: CircleAvatar(
                        backgroundColor: Colors.white24,
                        child: Text(otherName[0].toUpperCase(), style: TextStyle(color: Colors.white)),
                      ),
                      title: Text(otherName, style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("Appointment Active", style: TextStyle(color: Colors.white54, fontSize: 12)),
                      trailing: Icon(Icons.chat, color: kTeal, size: 20),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// CHAT SCREEN
// ─────────────────────────────────────────────

class ChatScreen extends StatefulWidget {
  final String appointmentId, otherName;
  ChatScreen({required this.appointmentId, required this.otherName});

  @override _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _tc = TextEditingController();
  List _msgs = [];
  bool _loading = true;
  String? _myEmail;
  Timer? _timer;

  @override void initState() { 
    super.initState(); 
    _init(); 
    _timer = Timer.periodic(Duration(seconds: 3), (_) => _fetchMsgs());
  }
  
  @override void dispose() { _timer?.cancel(); super.dispose(); }

  Future _init() async {
    final prefs = await SharedPreferences.getInstance();
    _myEmail = prefs.getString("email");
    _fetchMsgs();
  }

  Future _fetchMsgs() async {
    try {
      final res = await http.get(Uri.parse("$kAuthBase/messages?appointment_id=${widget.appointmentId}"));
      final data = jsonDecode(res.body);
      if (mounted) setState(() { _msgs = data["messages"] ?? []; _loading = false; });
    } catch (e) { print("Chat fetch error: $e"); }
  }

  Future _send() async {
    final text = _tc.text.trim();
    if (text.isEmpty || _myEmail == null) return;
    _tc.clear();
    
    try {
      await http.post(
        Uri.parse("$kAuthBase/send-message"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "appointment_id": widget.appointmentId,
          "sender_email": _myEmail,
          "text": text
        }),
      );
      _fetchMsgs();
    } catch (e) { print("Send error: $e"); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.otherName)),
      body: AnimatedBackground(
        child: Column(
          children: [
            Expanded(
              child: _loading 
                ? Center(child: SpinKitThreeBounce(color: Colors.white, size: 24))
                : ListView.builder(
                    padding: EdgeInsets.all(20),
                    reverse: true,
                    itemCount: _msgs.length,
                    itemBuilder: (_, i) {
                      final m = _msgs[_msgs.length - 1 - i];
                      final isMe = m["sender_email"] == _myEmail;
                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: EdgeInsets.symmetric(vertical: 4),
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isMe ? kTeal.withOpacity(0.8) : Colors.white10,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(m["text"], style: TextStyle(color: Colors.white)),
                        ),
                      );
                    },
                  ),
            ),
            GlassContainer(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              borderRadius: BorderRadius.zero,
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _tc,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Type a message...",
                          hintStyle: TextStyle(color: Colors.white30),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    IconButton(icon: Icon(Icons.send, color: kTeal), onPressed: _send),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// NEWS PAGE
// ─────────────────────────────────────────────

class NewsPage extends StatefulWidget {
  @override _NewsPageState createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  List    _news    = [];
  bool    _loading = true;

  @override void initState() { super.initState(); _load(); }

  Future _load() async {
    setState(() => _loading = true);
    try {
      final res  = await http.get(Uri.parse("$kApiBase/legal-news")).timeout(Duration(seconds: 15));
      final data = json.decode(res.body);
      setState(() => _news = data["news"] ?? []);
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBackground(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Legal News", style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold)),
                IconButton(icon: Icon(Icons.refresh, color: Colors.white), onPressed: _load),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? Center(child: SpinKitThreeBounce(color: Colors.white, size: 24))
                : ListView.separated(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 100),
                    itemCount: _news.length,
                    separatorBuilder: (_, __) => SizedBox(height: 16),
                    itemBuilder: (_, i) {
                      final article = _news[i];
                      return GestureDetector(
                        onTap: () async {
                          final uri = Uri.tryParse(article["url"] ?? "");
                          if (uri != null && await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
                        },
                        child: GlassContainer(
                          padding: EdgeInsets.zero,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (article["image"] != null)
                                CachedNetworkImage(
                                  imageUrl: article["image"],
                                  height: 180, width: double.infinity, fit: BoxFit.cover,
                                  placeholder: (_, __) => Container(height: 180, color: Colors.white10),
                                  errorWidget: (_, __, ___) => Container(height: 100, color: Colors.white10, child: Icon(Icons.image_not_supported)),
                                ),
                              Padding(
                                padding: EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (article["source"] != null)
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        margin: EdgeInsets.only(bottom: 8),
                                        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
                                        child: Text(article["source"], style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                      ),
                                    Text(article["title"] ?? "Untitled", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, height: 1.4)),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          )
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// PROFILE PAGE
// ─────────────────────────────────────────────

class ProfilePage extends StatefulWidget {
  @override _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _name = "", _email = "";
  bool _notifications = true;
  bool _darkMode = true;

  @override void initState() { super.initState(); _load(); }

  Future _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() { 
      _name = prefs.getString("name") ?? ""; 
      _email = prefs.getString("email") ?? ""; 
      _notifications = prefs.getBool("notifications") ?? true;
      _darkMode = prefs.getBool("darkMode") ?? true;
    });
  }

  Future _toggleNotifications(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("notifications", val);
    setState(() => _notifications = val);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(val ? "Notifications Enabled" : "Notifications Disabled"), backgroundColor: kTeal));
  }

  Future _toggleDarkMode(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("darkMode", val);
    setState(() => _darkMode = val);
    // Since the app uses a fixed dark aesthetic, we just show a message.
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(val ? "Dark Mode Enabled" : "Light Mode currently unsupported in Beta"), backgroundColor: kTeal));
  }

  void _showHelpSupport() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Color(0xFF101B2B),
        title: Text("Help & Support", style: TextStyle(color: Colors.white)),
        content: Text("If you need assistance with the Legal Mind app, please contact support@legalmind.ai or call 1800-LAW-HELP.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Close", style: TextStyle(color: Colors.lightBlueAccent))),
        ],
      )
    );
  }

  Widget _buildProfileItem(IconData icon, String title, VoidCallback onTap) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: Colors.white),
          title: Text(title, style: TextStyle(color: Colors.white)),
          trailing: Icon(Icons.chevron_right, color: Colors.white54),
          onTap: onTap,
        ),
        Divider(color: Colors.white10, height: 1),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBackground(
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 0, 24, 100),
          child: Column(
            children: [
              GlassContainer(
                borderRadius: BorderRadius.circular(100),
                padding: EdgeInsets.all(24),
                child: Text(_name.isNotEmpty ? _name[0].toUpperCase() : "?",
                    style: GoogleFonts.outfit(fontSize: 64, fontWeight: FontWeight.bold)),
              ),
              SizedBox(height: 24),
              Text(_name, style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold)),
              Text(_email, style: TextStyle(color: Colors.white70, fontSize: 16)),
              SizedBox(height: 48),

              // User Details Card
              GlassContainer(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person, color: Colors.white70), SizedBox(width: 16),
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text("Name", style: TextStyle(fontSize: 12, color: Colors.white54)),
                          Text(_name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ])
                      ],
                    ),
                    Divider(color: Colors.white24, height: 32),
                    Row(
                      children: [
                        Icon(Icons.email, color: Colors.white70), SizedBox(width: 16),
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text("Email", style: TextStyle(fontSize: 12, color: Colors.white54)),
                          Text(_email, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ])
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32),

              // Legal Preferences Section
              Align(
                alignment: Alignment.centerLeft,
                child: Text("Legal Preferences", style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              SizedBox(height: 16),
              GlassContainer(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.bookmark_border, color: Colors.white),
                      title: Text("Saved Laws", style: TextStyle(color: Colors.white)),
                      trailing: Icon(Icons.chevron_right, color: Colors.white54),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => SavedLawsPage()));
                      },
                    ),
                    Divider(color: Colors.white10, height: 1),
                    ListTile(
                      leading: Icon(Icons.history, color: Colors.white),
                      title: Text("Past Legal Advice", style: TextStyle(color: Colors.white)),
                      trailing: Icon(Icons.chevron_right, color: Colors.white54),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => HistoryPage()));
                      },
                    ),
                    Divider(color: Colors.white10, height: 1),
                    ListTile(
                      leading: Icon(Icons.calendar_today, color: Colors.white),
                      title: Text("Lawyer Appointments", style: TextStyle(color: Colors.white)),
                      trailing: Icon(Icons.chevron_right, color: Colors.white54),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => AppointmentsListPage()));
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32),

              // App Settings Section
              Align(
                alignment: Alignment.centerLeft,
                child: Text("App Settings", style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              SizedBox(height: 16),
              GlassContainer(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    SwitchListTile(
                      activeColor: Colors.lightBlueAccent,
                      secondary: Icon(Icons.notifications_active_outlined, color: Colors.white),
                      title: Text("Push Notifications", style: TextStyle(color: Colors.white)),
                      value: _notifications,
                      onChanged: _toggleNotifications,
                    ),
                    Divider(color: Colors.white10, height: 1),
                    SwitchListTile(
                      activeColor: Colors.lightBlueAccent,
                      secondary: Icon(Icons.dark_mode_outlined, color: Colors.white),
                      title: Text("Dark Mode", style: TextStyle(color: Colors.white)),
                      value: _darkMode,
                      onChanged: _toggleDarkMode,
                    ),
                    Divider(color: Colors.white10, height: 1),
                    ListTile(
                      leading: Icon(Icons.headset_mic_outlined, color: Colors.white),
                      title: Text("Help & Support", style: TextStyle(color: Colors.white)),
                      trailing: Icon(Icons.chevron_right, color: Colors.white54),
                      onTap: _showHelpSupport,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 48),

              SizedBox(
                width: double.infinity, height: 55,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final p = await SharedPreferences.getInstance();
                    await p.clear();
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen()));
                  },
                  icon: Icon(Icons.logout, color: Colors.redAccent),
                  label: Text("Sign Out", style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.1),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.redAccent.withOpacity(0.5)),
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
// ─────────────────────────────────────────────
// HISTORY PAGE
// ─────────────────────────────────────────────

class HistoryPage extends StatefulWidget {
  @override _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString("email") ?? "";
    if (email.isEmpty) { setState(() => _loading = false); return; }

    try {
      final res = await http.get(Uri.parse("$kAuthBase/history?user_email=$email"));
      final data = json.decode(res.body);
      if (data["status"] == "success") {
        setState(() { _history = data["history"] ?? []; });
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Past Legal Advice"), backgroundColor: Color(0xFF101B2B)),
      body: AnimatedBackground(
        child: _loading
            ? Center(child: SpinKitThreeBounce(color: Colors.white, size: 20))
            : _history.isEmpty
                ? Center(child: Text("No history yet", style: TextStyle(color: Colors.white54)))
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _history.length,
                    itemBuilder: (context, index) {
                      final h = _history[index];
                      return Card(
                        color: Colors.white.withOpacity(0.05),
                        margin: EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(h['query'] ?? "", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          subtitle: Text((h['response'] ?? "").toString().split("\n")[0] + "...", style: TextStyle(color: Colors.white70)),
                          trailing: Icon(Icons.chevron_right, color: Colors.white54),
                          onTap: () => _showDialog(h['query'], h['response'] ?? ""),
                        )
                      );
                    },
                  ),
      ),
    );
  }

  void _showDialog(String? query, String response) {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: Color(0xFF101B2B),
      title: Text(query ?? "Advice", style: TextStyle(color: Colors.white)),
      content: SingleChildScrollView(child: Text(response, style: TextStyle(color: Colors.white70))),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text("Close"))],
    ));
  }
}

// ─────────────────────────────────────────────
// DOCUMENT ANALYSIS PAGE
// ─────────────────────────────────────────────

class DocumentAnalysisPage extends StatefulWidget {
  @override _DocumentAnalysisPageState createState() => _DocumentAnalysisPageState();
}

class _DocumentAnalysisPageState extends State<DocumentAnalysisPage> {
  String _extractedText = "";
  String _analysisResult = "";
  bool _loading = false;
  final _textController = TextEditingController();

  Future _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() { _loading = true; _extractedText = ""; _analysisResult = ""; });
      try {
        final inputImage = InputImage.fromFilePath(image.path);
        final textRecognizer = TextRecognizer(script: TextRecognitionScript.devanagiri);
        final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
        _textController.text = recognizedText.text;
        setState(() => _extractedText = recognizedText.text);
        textRecognizer.close();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("OCR Error: $e")));
      }
      setState(() => _loading = false);
    }
  }

  Future _pickPdf() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null) {
      setState(() { _loading = true; _extractedText = ""; _analysisResult = ""; });
      try {
        PdfDocument document = PdfDocument(inputBytes: File(result.files.single.path!).readAsBytesSync());
        String text = PdfTextExtractor(document).extractText();
        document.dispose();
        _textController.text = text;
        setState(() => _extractedText = text);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("PDF Extraction Error: $e")));
      }
      setState(() => _loading = false);
    }
  }

  Future _analyzeDocument() async {
    if (_textController.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      final res = await http.post(
        Uri.parse("http://172.20.10.3:8000/api/llm/analyze-document"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"extracted_text": _textController.text.trim()}),
      ).timeout(Duration(seconds: 120));
      final data = json.decode(res.body);
      setState(() => _analysisResult = data["analysis"] ?? "No analysis available.");
    } catch (e) {
      setState(() => _analysisResult = "Analysis error: $e");
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBackground(
      child: SafeArea(
        child: Column(
          children: [
            Padding(padding: EdgeInsets.all(24), child: Text("Document Analysis", style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white))),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              ElevatedButton.icon(onPressed: _pickImage, icon: Icon(Icons.image), label: Text("Image OCR")),
              SizedBox(width: 16),
              ElevatedButton.icon(onPressed: _pickPdf, icon: Icon(Icons.picture_as_pdf), label: Text("Extract PDF")),
            ]),
            if (_loading) Padding(padding: EdgeInsets.all(20), child: SpinKitThreeBounce(color: Colors.white, size: 20)),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_extractedText.isNotEmpty && _analysisResult.isEmpty)
                      Column(children: [
                        TextField(
                          controller: _textController,
                          maxLines: 8, style: TextStyle(color: Colors.white70),
                          decoration: InputDecoration(
                            labelText: "Extracted Text (Edit if needed)",
                            fillColor: Colors.black26, filled: true, border: OutlineInputBorder()
                          ),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(onPressed: _analyzeDocument, child: Text("Analyze Text"), style: ElevatedButton.styleFrom(backgroundColor: kTeal, padding: EdgeInsets.all(16)))
                      ]),
                    if (_analysisResult.isNotEmpty)
                      Container(
                        padding: EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(12)),
                        child: MarkdownBody(data: _analysisResult, styleSheet: MarkdownStyleSheet(p: TextStyle(color: Colors.white, fontSize: 15))),
                      )
                  ],
                ),
              ),
            )
          ],
        )
      )
    );
  }
}

// ─────────────────────────────────────────────
// SAVED LAWS PAGE
// ─────────────────────────────────────────────

class SavedLawsPage extends StatefulWidget {
  @override _SavedLawsPageState createState() => _SavedLawsPageState();
}

class _SavedLawsPageState extends State<SavedLawsPage> {
  List _laws = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLaws();
  }

  Future _loadLaws() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString("email") ?? "";
    if (email.isEmpty) { setState(() => _loading = false); return; }

    try {
      final res = await http.get(Uri.parse("$kAuthBase/saved-laws?user_email=$email"));
      final data = json.decode(res.body);
      if (data["status"] == "success") {
        setState(() { _laws = data["laws"] ?? []; });
      }
    } finally {
      setState(() => _loading = false);
    }
  }
  
  Future _removeLaw(String lawId) async {
    try {
      final res = await http.delete(Uri.parse("$kAuthBase/remove-law?law_id=$lawId"));
      final data = json.decode(res.body);
      if(data["status"] == "success") {
        setState(() { _laws.removeWhere((l) => l["law_id"] == lawId); });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Law Removed"), backgroundColor: Colors.redAccent));
      }
    } catch (e) {
      print("Remove law error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Saved Laws"), backgroundColor: Color(0xFF101B2B)),
      body: AnimatedBackground(
        child: _loading
            ? Center(child: SpinKitThreeBounce(color: Colors.white, size: 20))
            : _laws.isEmpty
                ? Center(child: Text("No saved laws yet", style: TextStyle(color: Colors.white54)))
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _laws.length,
                    itemBuilder: (context, index) {
                      final h = _laws[index];
                      return Card(
                        color: Colors.white.withOpacity(0.05),
                        margin: EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(h['law_title'] ?? "", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          subtitle: Text((h['law_description'] ?? "").toString().split("\n")[0] + "...", style: TextStyle(color: Colors.white70)),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () => _removeLaw(h["law_id"]),
                          ),
                          onTap: () => _showDialog(h['law_title'], h['law_description'] ?? ""),
                        )
                      );
                    },
                  ),
      ),
    );
  }

  void _showDialog(String? query, String response) {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: Color(0xFF101B2B),
      title: Text(query ?? "Saved Law", style: TextStyle(color: Colors.white)),
      content: SingleChildScrollView(child: Text(response, style: TextStyle(color: Colors.white70))),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text("Close"))],
    ));
  }
}

// ─────────────────────────────────────────────
// CONTINUOUS AI CHATBOT PAGE
// ─────────────────────────────────────────────

class LegalChatBotPage extends StatefulWidget {
  @override _LegalChatBotPageState createState() => _LegalChatBotPageState();
}

class _LegalChatBotPageState extends State<LegalChatBotPage> {
  final List<Map<String, String>> _messages = [];
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _messages.add({"role": "assistant", "content": "Hello! I am LegalMind, your continuous AI Legal Assistant. How can I help you regarding Indian Law today?"});
  }

  Future _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({"role": "user", "content": text});
      _isLoading = true;
    });
    _msgController.clear();
    _scrollToBottom();

    try {
      final res = await http.post(
        Uri.parse("$kApiBase/chatbot"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"messages": _messages}),
      );
      final data = jsonDecode(res.body);
      setState(() {
        _messages.add({"role": "assistant", "content": data["reply"] ?? "Error processing request"});
      });
    } catch (e) {
      setState(() {
        _messages.add({"role": "assistant", "content": "Connection Error: $e"});
      });
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("AI Legal Assistant", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFF101B2B),
        elevation: 0,
      ),
      body: AnimatedBackground(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isUser = msg["role"] == "user";
                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: EdgeInsets.only(bottom: 12),
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                      decoration: BoxDecoration(
                        color: isUser ? kTeal.withOpacity(0.8) : Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                          bottomLeft: isUser ? Radius.circular(16) : Radius.zero,
                          bottomRight: isUser ? Radius.zero : Radius.circular(16),
                        ),
                        border: isUser ? null : Border.all(color: Colors.white24),
                      ),
                      child: MarkdownBody(
                        data: msg["content"] ?? "",
                        styleSheet: MarkdownStyleSheet(
                          p: TextStyle(color: Colors.white, fontSize: 16),
                          code: TextStyle(color: Colors.tealAccent, backgroundColor: Colors.transparent),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_isLoading)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: SpinKitThreeBounce(color: kTeal, size: 20),
              ),
            Container(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 24),
              color: Colors.black.withOpacity(0.6),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Type your message...",
                        hintStyle: TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  SizedBox(width: 8),
                  GestureDetector(
                    onTap: _isLoading ? null : _sendMessage,
                    child: CircleAvatar(
                      radius: 25,
                      backgroundColor: kTeal,
                      child: Icon(Icons.send, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
