import 'package:flutter/material.dart';
import '../../shared/widgets/animated_gradient_bg.dart';
import '../../shared/widgets/continue_button.dart';
import '../../core/utils/validators.dart';
import 'widgets/step_progress_bar.dart';
import 'steps/name_step.dart';
import 'steps/dob_step.dart';
import 'steps/height_step.dart';
import 'steps/weight_step.dart';
import 'steps/phone_step.dart';
import 'steps/email_step.dart';
import 'steps/sex_step.dart';
import 'steps/password_step.dart';
import 'steps/complete_step.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/presentation/controllers/auth_controller.dart';
import '../auth/domain/models/user_model.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 8;

  // Controllers for text fields
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Data
  DateTime? _dob;
  int _height = 170;
  double _weight = 70.0;
  String? _sex;

  @override
  void initState() {
    super.initState();
    // Listen to text controllers so _canProceed re-evaluates on every keystroke
    _nameController.addListener(_onFieldChanged);
    _phoneController.addListener(_onFieldChanged);
    _emailController.addListener(_onFieldChanged);
    _passwordController.addListener(_onFieldChanged);
    _confirmPasswordController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    setState(() {}); // triggers _canProceed re-evaluation
  }

  bool get _isLastStep => _currentStep >= _totalSteps;

  bool get _canProceed {
    switch (_currentStep) {
      case 0:
        return _nameController.text.trim().length >= 2;
      case 1:
        return true; // DOB always has a default selection
      case 2:
        return true; // height always has default
      case 3:
        return true; // weight always has default
      case 4:
        // 10-digit phone validation (digits only)
        final digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
        return digits.length == 10;
      case 5:
        return Validators.isEmailValid(_emailController.text);
      case 6:
        return _sex != null;
      case 7:
        return _passwordController.text.length >= 8 &&
            _passwordController.text == _confirmPasswordController.text;
      default:
        return true;
    }
  }

  Future<void> _registerUser() async {
    final userData = UserModel(
      uid: '',
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      dob: _dob?.toIso8601String() ?? '',
      sex: _sex ?? '',
      height: _height.toString(),
      weight: _weight.toString(),
      profileImage: '',
      authProvider: 'email',
      onboardingCompleted: true,
      emailVerified: false,
      createdAt: '',
      lastLogin: '',
      subscriptionTier: 'free',
      subscriptionExpiry: '',
    );

    await ref.read(authControllerProvider.notifier).registerWithEmail(
      _emailController.text.trim(),
      _passwordController.text,
      userData,
    );

    if (!ref.read(authControllerProvider).hasError) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _nextStep() async {
    if (_currentStep < _totalSteps) {
      // Dismiss keyboard before transitioning
      FocusScope.of(context).unfocus();
      
      if (_currentStep == _totalSteps - 1) {
        await _registerUser();
      } else {
        setState(() => _currentStep++);
        _pageController.animateToPage(
          _currentStep,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
        );
      }
    }
  }

  void _handleGoogleSignUp() async {
    final userData = UserModel(
      uid: '',
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      dob: _dob?.toIso8601String() ?? '',
      sex: _sex ?? '',
      height: _height.toString(),
      weight: _weight.toString(),
      profileImage: '',
      authProvider: 'google',
      onboardingCompleted: true,
      emailVerified: true,
      createdAt: '',
      lastLogin: '',
      subscriptionTier: 'free',
      subscriptionExpiry: '',
    );

    await ref.read(authControllerProvider.notifier).signInWithGoogle(onboardingData: userData);
    if (!ref.read(authControllerProvider).hasError) {
      setState(() => _currentStep = _totalSteps);
      _pageController.animateToPage(
        _currentStep,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _prevStep() {
    // Dismiss keyboard before transitioning
    FocusScope.of(context).unfocus();
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_onFieldChanged);
    _phoneController.removeListener(_onFieldChanged);
    _emailController.removeListener(_onFieldChanged);
    _passwordController.removeListener(_onFieldChanged);
    _confirmPasswordController.removeListener(_onFieldChanged);
    _pageController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    ref.listen<AsyncValue<void>>(
      authControllerProvider,
      (_, state) {
        if (state.hasError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error.toString()),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      },
    );

    final isLoading = ref.watch(authControllerProvider).isLoading;

    return Scaffold(
      // Let the body resize when keyboard appears for text steps,
      // but we dismiss keyboard on non-text steps to avoid overflow
      resizeToAvoidBottomInset: true,
      body: AnimatedGradientBackground(
        showParticles: false,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // ─── Top bar ───
              if (!_isLastStep)
                Padding(
                  padding: EdgeInsets.fromLTRB(8, 8, 24, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _prevStep,
                        icon: Icon(Icons.arrow_back_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.06),
                          padding: EdgeInsets.all(12),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: StepProgressBar(
                          currentStep: _currentStep + 1,
                          totalSteps: _totalSteps,
                        ),
                      ),
                    ],
                  ),
                ),

              // ─── Steps ───
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: NeverScrollableScrollPhysics(),
                  children: [
                    NameStep(
                      controller: _nameController,
                      onNext: () => setState(() {}),
                    ),
                    DobStep(
                      onChanged: (date) => setState(() => _dob = date),
                    ),
                    HeightStep(
                      onChanged: (h) => setState(() => _height = h),
                    ),
                    WeightStep(
                      onChanged: (w) => setState(() => _weight = w),
                    ),
                    PhoneStep(
                      controller: _phoneController,
                      onChanged: (_) => setState(() {}),
                    ),
                    EmailStep(
                      controller: _emailController,
                      onChanged: (_) => setState(() {}),
                      onGoogleSignUp: _handleGoogleSignUp,
                    ),
                    SexStep(
                      selectedValue: _sex,
                      onSelected: (v) => setState(() => _sex = v),
                    ),
                    PasswordStep(
                      controller: _passwordController,
                      confirmController: _confirmPasswordController,
                    ),
                    CompleteStep(),
                  ],
                ),
              ),

              // ─── Bottom CTA ───
              if (!_isLastStep)
                Padding(
                  padding: EdgeInsets.fromLTRB(24, 8, 24, bottomPadding + 16),
                  child: ContinueButton(
                    text: isLoading ? 'Processing...' : 'Continue',
                    onPressed: isLoading ? () {} : _nextStep,
                    isEnabled: _canProceed && !isLoading,
                    icon: Icons.arrow_forward_rounded,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
