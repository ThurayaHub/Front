import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:thuraya/core/auth/auth_scope.dart';
import 'package:thuraya/core/auth/auth_session_controller.dart';
import 'package:thuraya/core/constants/app_spacing.dart';
import 'package:thuraya/core/network/api_client.dart';
import 'package:thuraya/core/theme/app_colors.dart';
import 'package:thuraya/core/theme/app_text_styles.dart';
import 'package:thuraya/core/widgets/thuraya_logo.dart';
import 'package:thuraya/l10n/generated/app_localizations.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

enum _LoginStep { phone, otp, registration }

class _LoginPageState extends State<LoginPage> {
  static const _phoneNumberLength = 10;
  static const _nameMaxLength = 40;
  static const _emailMaxLength = 60;
  static final _invalidNameCharacters = RegExp(
    r'[^A-Za-z\u0621-\u063A\u0641-\u064A ]',
  );
  static final _validName = RegExp(r'^[A-Za-z\u0621-\u063A\u0641-\u064A ]+$');
  static final _invalidEmailCharacters = RegExp(r'[^A-Za-z0-9@._%+\-]');
  static final _validEmail = RegExp(
    r'^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$',
  );

  final _phoneFormKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();
  final _registrationFormKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  _LoginStep _step = _LoginStep.phone;
  bool _isSubmitting = false;
  bool _nameHadInvalidCharacters = false;
  bool _emailHadInvalidCharacters = false;
  String? _errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submitPhone() async {
    if (!_phoneFormKey.currentState!.validate() || _isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      await AuthScope.read(context).requestPhoneOtp(_phoneController.text);
      if (!mounted) {
        return;
      }
      setState(() {
        _step = _LoginStep.otp;
        _isSubmitting = false;
      });
    } on ApiException catch (error) {
      _showError(_localizedOtpError(error));
    } catch (_) {
      if (mounted) {
        _showError(AppLocalizations.of(context).authenticationUnavailable);
      }
    }
  }

  Future<void> _submitOtp() async {
    if (!_otpFormKey.currentState!.validate() || _isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      final result = await AuthScope.read(context).verifyPhoneOtp(
        phoneNumber: _phoneController.text,
        otp: _otpController.text,
      );
      if (!mounted) {
        return;
      }
      if (result == AuthLoginResult.registrationRequired) {
        setState(() {
          _step = _LoginStep.registration;
          _isSubmitting = false;
        });
        return;
      }
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      _showError(_localizedOtpError(error, verifying: true));
    } catch (_) {
      if (mounted) {
        _showError(AppLocalizations.of(context).authenticationUnavailable);
      }
    }
  }

  Future<void> _resendOtp() async {
    if (_isSubmitting) {
      return;
    }
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      await AuthScope.read(context).requestPhoneOtp(_phoneController.text);
      if (!mounted) {
        return;
      }
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).otpSent)),
      );
    } on ApiException catch (error) {
      _showError(_localizedOtpError(error));
    } catch (_) {
      if (mounted) {
        _showError(AppLocalizations.of(context).authenticationUnavailable);
      }
    }
  }

  Future<void> _submitRegistration() async {
    if (!_registrationFormKey.currentState!.validate() || _isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      await AuthScope.read(context).completeRegistration(
        phoneNumber: _phoneController.text,
        name: _nameController.text,
        email: _emailController.text,
      );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      final localizations = AppLocalizations.of(context);
      _showError(
        error.statusCode == 409
            ? localizations.emailAlreadyInUse
            : error.message,
      );
    } catch (_) {
      if (mounted) {
        _showError(AppLocalizations.of(context).authenticationUnavailable);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }
    setState(() {
      _isSubmitting = false;
      _errorMessage = message;
    });
  }

  void _changePhoneNumber() {
    if (_isSubmitting) {
      return;
    }
    setState(() {
      _step = _LoginStep.phone;
      _otpController.clear();
      _errorMessage = null;
    });
  }

  String _localizedOtpError(ApiException error, {bool verifying = false}) {
    final localizations = AppLocalizations.of(context);
    if (error.statusCode == 429) {
      return localizations.otpTooManyRequests;
    }
    if (verifying && (error.statusCode == 400 || error.statusCode == 401)) {
      return localizations.invalidOtp;
    }
    return localizations.otpUnavailable;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final useCompactHeader = MediaQuery.sizeOf(context).height < 700;
    final title = switch (_step) {
      _LoginStep.phone => localizations.loginTitle,
      _LoginStep.otp => localizations.otpTitle,
      _LoginStep.registration => localizations.registrationTitle,
    };
    final subtitle = switch (_step) {
      _LoginStep.phone => localizations.loginSubtitle,
      _LoginStep.otp => localizations.otpSubtitle,
      _LoginStep.registration => localizations.registrationSubtitle,
    };

    return Scaffold(
      key: const ValueKey('login-page'),
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          key: const ValueKey('login-back'),
          tooltip: localizations.back,
          onPressed: _isSubmitting
              ? null
              : () {
                  if (_step == _LoginStep.phone) {
                    Navigator.of(context).pop();
                  } else {
                    _changePhoneNumber();
                  }
                },
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.md,
            AppSpacing.screen,
            AppSpacing.xl,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ThurayaLogo(
                    key: const ValueKey('authentication-thuraya-logo'),
                    height: useCompactHeader ? 88 : 112,
                  ),
                  SizedBox(
                    height: useCompactHeader ? AppSpacing.sm : AppSpacing.md,
                  ),
                  Text(
                    localizations.authenticationWelcome,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.screenTitle,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.cardTitle.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.screenSubtitle,
                  ),
                  SizedBox(
                    height: useCompactHeader ? AppSpacing.lg : AppSpacing.xl,
                  ),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: AppColors.panelBorder),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x141A237E),
                          offset: Offset(0, 8),
                          blurRadius: 28,
                        ),
                      ],
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: switch (_step) {
                        _LoginStep.phone => _buildPhoneForm(localizations),
                        _LoginStep.otp => _buildOtpForm(localizations),
                        _LoginStep.registration => _buildRegistrationForm(
                          localizations,
                        ),
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneForm(AppLocalizations localizations) {
    return Form(
      key: _phoneFormKey,
      child: Column(
        key: const ValueKey('login-phone-step'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AuthTextField(
            key: const ValueKey('login-phone'),
            controller: _phoneController,
            label: localizations.phoneNumber,
            hint: localizations.phoneNumberHint,
            keyboardType: TextInputType.phone,
            textDirection: TextDirection.ltr,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.telephoneNumber],
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(_phoneNumberLength),
            ],
            validator: (value) {
              final phoneNumber = value?.trim() ?? '';
              if (phoneNumber.isEmpty) {
                return localizations.fieldRequired;
              }
              if (!RegExp(r'^05\d{8}$').hasMatch(phoneNumber)) {
                return localizations.invalidSaudiPhone;
              }
              return null;
            },
            onSubmitted: (_) => _submitPhone(),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _AuthError(message: _errorMessage!),
          ],
          const SizedBox(height: AppSpacing.lg),
          _PrimaryAuthButton(
            key: const ValueKey('login-submit'),
            label: localizations.continueLabel,
            isLoading: _isSubmitting,
            onPressed: _submitPhone,
          ),
        ],
      ),
    );
  }

  Widget _buildOtpForm(AppLocalizations localizations) {
    return Form(
      key: _otpFormKey,
      child: Column(
        key: const ValueKey('login-otp-step'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            localizations.otpSentTo(_phoneController.text.trim()),
            textAlign: TextAlign.center,
            style: AppTextStyles.cardMetadata,
          ),
          const SizedBox(height: AppSpacing.md),
          _AuthTextField(
            key: const ValueKey('login-otp'),
            controller: _otpController,
            label: localizations.otpCode,
            hint: localizations.otpHint,
            keyboardType: TextInputType.number,
            textDirection: TextDirection.ltr,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.oneTimeCode],
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(8),
            ],
            validator: (value) {
              final otp = value?.trim() ?? '';
              if (otp.isEmpty) {
                return localizations.fieldRequired;
              }
              if (!RegExp(r'^\d{4,8}$').hasMatch(otp)) {
                return localizations.invalidOtp;
              }
              return null;
            },
            onSubmitted: (_) => _submitOtp(),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _AuthError(message: _errorMessage!),
          ],
          const SizedBox(height: AppSpacing.lg),
          _PrimaryAuthButton(
            key: const ValueKey('otp-submit'),
            label: localizations.verifyOtp,
            isLoading: _isSubmitting,
            onPressed: _submitOtp,
          ),
          const SizedBox(height: AppSpacing.xs),
          TextButton(
            key: const ValueKey('otp-resend'),
            onPressed: _isSubmitting ? null : _resendOtp,
            child: Text(localizations.resendOtp),
          ),
          TextButton(
            key: const ValueKey('otp-change-phone'),
            onPressed: _isSubmitting ? null : _changePhoneNumber,
            child: Text(localizations.changePhoneNumber),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationForm(AppLocalizations localizations) {
    return Form(
      key: _registrationFormKey,
      child: Column(
        key: const ValueKey('login-registration-step'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.panel,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                _phoneController.text.trim(),
                textAlign: TextAlign.center,
                style: AppTextStyles.homeCardTitle.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _AuthTextField(
            key: const ValueKey('registration-name'),
            controller: _nameController,
            label: localizations.fullName,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
            inputFormatters: [
              TextInputFormatter.withFunction((oldValue, newValue) {
                _nameHadInvalidCharacters = _invalidNameCharacters.hasMatch(
                  newValue.text,
                );
                return newValue;
              }),
              FilteringTextInputFormatter.deny(_invalidNameCharacters),
              LengthLimitingTextInputFormatter(_nameMaxLength),
            ],
            validator: (value) {
              final name = value?.trim() ?? '';
              if (_nameHadInvalidCharacters ||
                  (name.isNotEmpty && !_validName.hasMatch(name))) {
                return localizations.invalidNameCharacters;
              }
              if (name.isEmpty) {
                return localizations.fieldRequired;
              }
              if (name.length > _nameMaxLength) {
                return localizations.maximumLengthExceeded(_nameMaxLength);
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          _AuthTextField(
            key: const ValueKey('registration-email'),
            controller: _emailController,
            label: localizations.emailAddress,
            keyboardType: TextInputType.emailAddress,
            textDirection: TextDirection.ltr,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            inputFormatters: [
              TextInputFormatter.withFunction((oldValue, newValue) {
                _emailHadInvalidCharacters = _invalidEmailCharacters.hasMatch(
                  newValue.text,
                );
                return newValue;
              }),
              FilteringTextInputFormatter.deny(_invalidEmailCharacters),
              LengthLimitingTextInputFormatter(_emailMaxLength),
            ],
            validator: (value) {
              final email = value?.trim() ?? '';
              if (_emailHadInvalidCharacters) {
                return localizations.invalidEmailCharacters;
              }
              if (email.isEmpty) {
                return localizations.fieldRequired;
              }
              if (email.length > _emailMaxLength) {
                return localizations.maximumLengthExceeded(_emailMaxLength);
              }
              if (!_validEmail.hasMatch(email)) {
                return localizations.invalidEmail;
              }
              return null;
            },
            onSubmitted: (_) => _submitRegistration(),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _AuthError(message: _errorMessage!),
          ],
          const SizedBox(height: AppSpacing.lg),
          _PrimaryAuthButton(
            key: const ValueKey('registration-submit'),
            label: localizations.createAccount,
            isLoading: _isSubmitting,
            onPressed: _submitRegistration,
          ),
          const SizedBox(height: AppSpacing.xs),
          TextButton(
            key: const ValueKey('registration-change-phone'),
            onPressed: _changePhoneNumber,
            child: Text(localizations.changePhoneNumber),
          ),
        ],
      ),
    );
  }
}

class _AuthTextField extends StatelessWidget {
  const _AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.keyboardType,
    this.textDirection,
    this.textInputAction,
    this.autofillHints,
    this.inputFormatters,
    this.validator,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType? keyboardType;
  final TextDirection? textDirection;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      style: AppTextStyles.homeCardTitle.copyWith(fontWeight: FontWeight.w500),
      cursorColor: AppColors.primary,
      keyboardType: keyboardType,
      textDirection: textDirection,
      textAlign: TextAlign.start,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      inputFormatters: inputFormatters,
      validator: validator,
      onFieldSubmitted: onSubmitted,
      onTapOutside: (_) => FocusScope.of(context).unfocus(),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: AppTextStyles.detailsMetadata,
        floatingLabelStyle: AppTextStyles.detailsMetadata.copyWith(
          color: AppColors.primary,
        ),
        hintStyle: AppTextStyles.screenSubtitle.copyWith(
          color: AppColors.textMuted,
        ),
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.panelBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.panelBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}

class _PrimaryAuthButton extends StatelessWidget {
  const _PrimaryAuthButton({
    super.key,
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: isLoading
            ? const SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(
                  color: AppColors.onPrimary,
                  strokeWidth: 2,
                ),
              )
            : Text(
                label,
                style: AppTextStyles.homeCardTitle.copyWith(
                  color: AppColors.onPrimary,
                ),
              ),
      ),
    );
  }
}

class _AuthError extends StatelessWidget {
  const _AuthError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('auth-error'),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        textAlign: TextAlign.start,
        style: AppTextStyles.cardMetadata.copyWith(color: AppColors.error),
      ),
    );
  }
}
