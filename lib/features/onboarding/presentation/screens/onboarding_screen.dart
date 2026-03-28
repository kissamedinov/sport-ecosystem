import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile/core/api/onboarding_api_service.dart';
import 'package:mobile/features/auth/providers/auth_provider.dart';
import '../widgets/role_selection_step.dart';
import '../widgets/player_onboarding_step.dart';
import '../widgets/parent_onboarding_step.dart';
import '../widgets/coach_onboarding_step.dart';
import '../widgets/owner_onboarding_step.dart';
import '../widgets/completion_step.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final OnboardingApiService _apiService = OnboardingApiService();
  int _currentStep = 0;
  bool _isLoading = false;

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() => _currentStep++);
  }

  Future<void> _handlePlayerStep(String position) async {
    setState(() => _isLoading = true);
    try {
      await _apiService.setupPlayer(position);
      _nextPage();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleParentStep(String first, String last, DateTime dob, String pos) async {
    setState(() => _isLoading = true);
    try {
      await _apiService.addChild(first, last, dob, pos);
      _nextPage();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleOwnerStep(String name, String address, String schedule) async {
    setState(() => _isLoading = true);
    try {
      await _apiService.setupClub(name, address, schedule);
      _nextPage();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleCoachStep() async {
    setState(() => _isLoading = true);
    try {
      await _apiService.requestCoachAccess();
      _nextPage();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _finishOnboarding() async {
    setState(() => _isLoading = true);
    try {
      await _apiService.completeOnboarding();
      await context.read<AuthProvider>().checkAuthStatus(); // Refresh user data
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final primaryRole = user?.roles?.first ?? 'PLAYER_ADULT';

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: LinearProgressIndicator(
                    value: (_currentStep + 1) / 3,
                    backgroundColor: Colors.white10,
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF00E676)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Step ${_currentStep + 1} of 3', style: const TextStyle(color: Colors.white54)),
                      if (_currentStep > 0)
                        TextButton(
                          onPressed: () {
                             _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                             setState(() => _currentStep--);
                          },
                          child: const Text('Back', style: TextStyle(color: Color(0xFF00E676))),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      RoleSelectionScreen(onNext: _nextPage),
                      _buildRoleSpecificStep(primaryRole),
                      CompletionStep(onFinish: _finishOnboarding),
                    ],
                  ),
                ),
              ],
            ),
            if (_isLoading)
              Container(
                color: Colors.black54,
                child: const Center(child: CircularProgressIndicator(color: Color(0xFF00E676))),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleSpecificStep(String role) {
    if (role.contains('PLAYER')) {
      return PlayerOnboardingStep(onNext: _handlePlayerStep);
    } else if (role == 'PARENT') {
      return ParentOnboardingStep(onNext: _handleParentStep);
    } else if (role == 'COACH') {
      return CoachOnboardingStep(onNext: _handleCoachStep);
    } else if (role == 'CLUB_OWNER') {
      return OwnerOnboardingStep(onNext: _handleOwnerStep);
    } else {
      return CompletionStep(onFinish: _finishOnboarding); // Skip if unknown
    }
  }
}
