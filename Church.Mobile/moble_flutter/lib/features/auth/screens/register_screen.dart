import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../models/auth_models.dart';
import '../providers/auth_providers.dart';
import '../utils/auth_role_utils.dart';
import '../../../shared/widgets/app_form_fields.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/validation_message_localizer.dart';
import '../utils/registration_navigation.dart';
import '../utils/phone_number_validator.dart';

enum _RegisterType { servant, churchAdmin, meetingAdmin }

/// Which registration form to present. Chosen by the registration entry /
/// new-church role screens, so the form no longer shows a type dropdown.
enum RegisterFormMode {
  existingChurchMember,
  newChurchMeetingAdmin,
  newChurchSuperAdmin,
}

class RegisterScreen extends ConsumerStatefulWidget {
  final RegisterFormMode mode;

  const RegisterScreen({
    super.key,
    this.mode = RegisterFormMode.existingChurchMember,
  });

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  final _nameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();
  final _churchIdFocus = FocusNode();
  final _requestedMeetingFocus = FocusNode();
  final _meetingAdminPhoneFocus = FocusNode();
  final _churchNameFocus = FocusNode();
  final _meetingNameFocus = FocusNode();
  final _weeklyFocus = FocusNode();

  // Shared controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Existing-church member controllers
  final _churchIdController = TextEditingController();
  final _requestedMeetingController = TextEditingController();
  final _meetingAdminPhoneController = TextEditingController();

  // Requested role for existing-church member registration.
  String _requestedRole = 'Servant';

  // Church/Meeting admin controllers
  final _churchNameController = TextEditingController();
  final _meetingNameController = TextEditingController();
  final _weeklyAppointmentController = TextEditingController();
  String _selectedMeetingDay = 'Saturday';
  TimeOfDay? _selectedWeeklyTime;

  // Optional controllers
  final _birthController = TextEditingController();
  final _joiningController = TextEditingController();

  File? _image;
  _RegisterType _selectedType = _RegisterType.servant;
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;
  Map<String, List<String>> _serverFieldErrors = {};

  static const _fieldOrder = [
    'name',
    'phone',
    'password',
    'confirmPassword',
    'churchPublicId',
    'requestedMeetingName',
    'meetingAdminPhone',
    'churchName',
    'meetingName',
    'weeklyAppointment',
  ];

  @override
  void initState() {
    super.initState();

    _selectedType = switch (widget.mode) {
      RegisterFormMode.existingChurchMember => _RegisterType.servant,
      RegisterFormMode.newChurchMeetingAdmin => _RegisterType.meetingAdmin,
      RegisterFormMode.newChurchSuperAdmin => _RegisterType.churchAdmin,
    };
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _nameFocus.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    _churchIdFocus.dispose();
    _requestedMeetingFocus.dispose();
    _meetingAdminPhoneFocus.dispose();
    _churchNameFocus.dispose();
    _meetingNameFocus.dispose();
    _weeklyFocus.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _churchIdController.dispose();
    _requestedMeetingController.dispose();
    _meetingAdminPhoneController.dispose();
    _churchNameController.dispose();
    _meetingNameController.dispose();
    _weeklyAppointmentController.dispose();
    _birthController.dispose();
    _joiningController.dispose();
    super.dispose();
  }

  FocusNode? _focusForField(String key) => switch (key) {
        'name' => _nameFocus,
        'phone' => _phoneFocus,
        'password' => _passwordFocus,
        'confirmPassword' => _confirmFocus,
        'churchPublicId' => _churchIdFocus,
        'requestedMeetingName' => _requestedMeetingFocus,
        'meetingAdminPhone' => _meetingAdminPhoneFocus,
        'churchName' => _churchNameFocus,
        'meetingName' => _meetingNameFocus,
        'weeklyAppointment' => _weeklyFocus,
        _ => null,
      };

  String? _serverError(String key) {
    final messages = _serverFieldErrors[key];
    if (messages == null || messages.isEmpty) return null;
    return messages.join('\n');
  }

  void _clearServerError(String key) {
    if (!_serverFieldErrors.containsKey(key)) return;
    setState(() {
      _serverFieldErrors = Map<String, List<String>>.from(_serverFieldErrors)
        ..remove(key);
    });
  }

  String? Function(String?) _composeValidator(
    String key,
    String? Function(String?) local,
  ) {
    return (value) => _serverError(key) ?? local(value);
  }

  String? _mapApiFieldKey(String rawKey) {
    final key = rawKey.trim();
    final normalized = key.toLowerCase().replaceAll('_', '');

    if (normalized == 'name' || normalized == 'username') return 'name';
    if (normalized == 'phonenumber' || normalized == 'phone') return 'phone';
    if (normalized.startsWith('password') ||
        normalized.contains('passwordrequires') ||
        normalized == 'passwordtooshort') {
      return 'password';
    }
    if (normalized == 'confirmpassword') return 'confirmPassword';
    if (normalized == 'churchpublicid' ||
        normalized == 'meetingpublicid' ||
        normalized == 'organizationpublicid') {
      return 'churchPublicId';
    }
    if (normalized == 'requestedmeetingname') return 'requestedMeetingName';
    if (normalized == 'meetingadminphonenumber') return 'meetingAdminPhone';
    if (normalized == 'churchname') return 'churchName';
    if (normalized == 'meetingname') return 'meetingName';
    if (normalized == 'weeklyappointment' ||
        normalized == 'weekly_appointment'.replaceAll('_', '')) {
      return 'weeklyAppointment';
    }
    return null;
  }

  Map<String, List<String>> _mapApiErrors(
    AppLocalizations l10n,
    Map<String, List<String>> apiErrors,
  ) {
    final mapped = <String, List<String>>{};
    apiErrors.forEach((apiKey, messages) {
      final localKey = _mapApiFieldKey(apiKey);
      if (localKey == null) return;
      final localized = ValidationMessageLocalizer.localizeAll(
        l10n,
        messages,
        apiFieldKey: apiKey,
      );
      mapped.putIfAbsent(localKey, () => []).addAll(localized);
    });
    return mapped;
  }

  List<String> _unmappedApiMessages(
    AppLocalizations l10n,
    Map<String, List<String>> apiErrors,
  ) {
    final messages = <String>[];
    apiErrors.forEach((apiKey, values) {
      if (_mapApiFieldKey(apiKey) == null) {
        messages.addAll(
          ValidationMessageLocalizer.localizeAll(
            l10n,
            values,
            apiFieldKey: apiKey,
          ),
        );
      }
    });
    return messages;
  }

  Future<void> _focusFirstInvalidField({
    Iterable<String>? preferKeys,
  }) async {
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    final candidates = [
      ...?preferKeys,
      ..._fieldOrder,
    ];

    for (final key in candidates) {
      final hasServerError = _serverError(key) != null;
      if (!hasServerError) continue;
      final focus = _focusForField(key);
      if (focus == null || !focus.canRequestFocus) continue;
      focus.requestFocus();
      final ctx = focus.context;
      if (ctx != null && ctx.mounted) {
        await Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: 0.15,
        );
      }
      return;
    }

    if (!mounted) return;

    // Fall back: walk FormField states under the form.
    final formContext = _formKey.currentContext;
    if (formContext == null) return;
    final invalid = <BuildContext>[];
    void visitor(Element element) {
      if (element is StatefulElement && element.state is FormFieldState) {
        final state = element.state as FormFieldState;
        if (state.hasError) {
          invalid.add(element);
        }
      }
      element.visitChildren(visitor);
    }

    formContext.visitChildElements(visitor);
    if (invalid.isEmpty) return;
    final first = invalid.first;
    if (!first.mounted) return;
    await Scrollable.ensureVisible(
      first,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      alignment: 0.15,
    );
    if (!first.mounted) return;
    FocusScope.of(first).requestFocus();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _image = File(picked.path));
  }

  Future<void> _register() async {
    if (_loading) return;

    setState(() {
      _serverFieldErrors = {};
      _autovalidateMode = AutovalidateMode.always;
    });

    final formValid = _formKey.currentState?.validate() ?? false;
    if (!formValid) {
      await _focusFirstInvalidField();
      return;
    }

    final l10n = AppLocalizations.of(context);
    if (_selectedType == _RegisterType.meetingAdmin &&
        _selectedWeeklyTime == null) {
      setState(() {
        _serverFieldErrors = {
          'weeklyAppointment': [l10n.weeklyAppointmentRequired],
        };
      });
      _formKey.currentState?.validate();
      await _focusFirstInvalidField(preferKeys: ['weeklyAppointment']);
      return;
    }

    setState(() => _loading = true);
    try {
      final phone = PhoneNumberValidator.normalize(_phoneController.text) ??
          _phoneController.text.trim();
      final meetingAdminPhone = _requestedRole == 'Servant'
          ? (PhoneNumberValidator.normalize(_meetingAdminPhoneController.text) ??
              _meetingAdminPhoneController.text.trim().nullIfEmpty)
          : null;

      AuthFlowResult result;
      switch (_selectedType) {
        case _RegisterType.servant:
          result = await ref.read(authRepositoryProvider).registerServant(
            RegisterServantDto(
              name: _nameController.text.trim(),
              phoneNumber: phone,
              password: _passwordController.text,
              confirmPassword: _confirmPasswordController.text,
              churchPublicId: _churchIdController.text.trim(),
              requestedMeetingName: _requestedRole == 'ChurchAdmin'
                  ? ''
                  : _requestedMeetingController.text.trim(),
              requestedRole: _requestedRole,
              meetingAdminPhoneNumber: meetingAdminPhone,
              birthDate: _birthController.text.trim().nullIfEmpty,
              joiningDate: _joiningController.text.trim().nullIfEmpty,
              image: _image,
            ),
          );
          break;

        case _RegisterType.churchAdmin:
          result = await ref.read(authRepositoryProvider)
              .registerChurchSuperAdmin(
            RegisterChurchSuperAdminDto(
              name: _nameController.text.trim(),
              phoneNumber: phone,
              password: _passwordController.text,
              confirmPassword: _confirmPasswordController.text,
              churchName: _churchNameController.text.trim(),
              birthDate: _birthController.text.trim().nullIfEmpty,
              joiningDate: _joiningController.text.trim().nullIfEmpty,
              image: _image,
            ),
          );
          break;

        case _RegisterType.meetingAdmin:
          result = await ref.read(authRepositoryProvider).registerMeetingAdmin(
            RegisterMeetingAdminDto(
              name: _nameController.text.trim(),
              phoneNumber: phone,
              password: _passwordController.text,
              confirmPassword: _confirmPasswordController.text,
              churchName: _churchNameController.text.trim(),
              meetingName: _meetingNameController.text.trim(),
              weeklyAppointment: _selectedWeeklyTime!,
              dayOfWeek: _selectedMeetingDay,
              birthDate: _birthController.text.trim().nullIfEmpty,
              joiningDate: _joiningController.text.trim().nullIfEmpty,
              image: _image,
            ),
          );
          break;
      }

      if (!result.hasToken) {
        if (mounted) {
          // Never surface phone-verification copy from any API payload.
          showSuccessSnackbar(
            context,
            l10n.registrationSuccessfulPleaseSignIn,
          );
          context.go(AppRoutes.login);
        }
        return;
      }

      final token = result.token!;
      final role = AuthRoleUtils.extractPrimaryRole(token);

      ref.read(authSessionEpochProvider.notifier).state++;
      ref.read(authStateProvider.notifier).state = true;

      if (mounted) {
        context.go(AuthRoleUtils.routeForRole(role));
      }
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);

      if (e is ApiException && e.hasFieldErrors) {
        final mapped = _mapApiErrors(l10n, e.fieldErrors);
        final unmapped = _unmappedApiMessages(l10n, e.fieldErrors);

        setState(() {
          _serverFieldErrors = mapped;
          _autovalidateMode = AutovalidateMode.always;
        });
        _formKey.currentState?.validate();
        await _focusFirstInvalidField(preferKeys: mapped.keys);

        if (unmapped.isNotEmpty) {
          showErrorSnackbar(context, unmapped.join('\n'));
        } else if (mapped.isEmpty) {
          showErrorSnackbar(
            context,
            ValidationMessageLocalizer.localize(l10n, e.message),
          );
        }
        return;
      }

      if (e is ApiException) {
        final localizedMessage =
            ValidationMessageLocalizer.localize(l10n, e.message);
        final msg = e.message.toLowerCase();
        final isPhoneDuplicate = (e.statusCode == 409 || e.statusCode == 400) &&
            (msg.contains('phone') ||
                msg.contains('phonenumber') ||
                msg.contains('mobile')) &&
            (msg.contains('exist') ||
                msg.contains('already') ||
                msg.contains('duplicate') ||
                msg.contains('taken') ||
                msg.contains('use'));

        if (isPhoneDuplicate) {
          setState(() {
            _serverFieldErrors = {
              'phone': [l10n.phoneAlreadyUsed],
            };
            _autovalidateMode = AutovalidateMode.always;
          });
          _formKey.currentState?.validate();
          await _focusFirstInvalidField(preferKeys: ['phone']);
          return;
        }

        showErrorSnackbar(context, localizedMessage);
        return;
      }

      showErrorSnackbar(context, userFriendlyMessage(e, l10n));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formTitle(AppLocalizations l10n) {
    switch (widget.mode) {
      case RegisterFormMode.existingChurchMember:
        return l10n.joinExistingChurchTitle;
      case RegisterFormMode.newChurchMeetingAdmin:
        return l10n.registerTypeMeetingAdmin;
      case RegisterFormMode.newChurchSuperAdmin:
        return l10n.registerTypeChurchAdmin;
    }
  }

  Widget _buildImagePicker(AppLocalizations l10n) {
    return GestureDetector(
      onTap: _pickImage,
      child: Center(
        child: CircleAvatar(
          radius: 48,
          backgroundColor: AppColors.primary,
          backgroundImage: _image != null ? FileImage(_image!) : null,
          child: _image == null
              ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.camera_alt, size: 28, color: Colors.white),
              const SizedBox(height: 4),
              Text(
                l10n.tapToSelectImage,
                style:
                const TextStyle(color: Colors.white, fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ],
          )
              : null,
        ),
      ),
    );
  }

  String get _backFallbackRoute => switch (widget.mode) {
        RegisterFormMode.existingChurchMember => AppRoutes.register,
        RegisterFormMode.newChurchMeetingAdmin => AppRoutes.registerNewChurch,
        RegisterFormMode.newChurchSuperAdmin => AppRoutes.registerNewChurch,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return registrationBackScope(
      context: context,
      fallbackRoute: _backFallbackRoute,
      child: Scaffold(
        appBar: registrationAppBar(
          context: context,
          title: l10n.createAccount,
          fallbackRoute: _backFallbackRoute,
        ),
        body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            autovalidateMode: _autovalidateMode,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _formTitle(l10n),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                // ✅ Image picker FIRST
                _buildImagePicker(l10n),

                const SizedBox(height: 16),

                // Shared fields
                AppTextField(
                  controller: _nameController,
                  focusNode: _nameFocus,
                  label: l10n.fullName,
                  hint: l10n.enterName,
                  onChanged: (_) => _clearServerError('name'),
                  validator: _composeValidator(
                    'name',
                    (v) => (v == null || v.trim().isEmpty)
                        ? l10n.nameRequired
                        : null,
                  ),
                ),
                const SizedBox(height: 16),

                AppTextField(
                  controller: _phoneController,
                  focusNode: _phoneFocus,
                  label: l10n.phoneNumber,
                  hint: l10n.enterPhoneNumber,
                  keyboardType: TextInputType.phone,
                  onChanged: (_) => _clearServerError('phone'),
                  validator: _composeValidator(
                    'phone',
                    (v) => PhoneNumberValidator.validate(v, l10n: l10n),
                  ),
                ),
                const SizedBox(height: 16),

                AppTextField(
                  controller: _passwordController,
                  focusNode: _passwordFocus,
                  label: l10n.password,
                  hint: l10n.enterPassword,
                  obscureText: _obscurePassword,
                  onChanged: (_) => _clearServerError('password'),
                  validator: _composeValidator(
                    'password',
                    (v) => (v == null || v.length < 6)
                        ? l10n.passwordTooShort
                        : null,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),

                const SizedBox(height: 16),

                AppTextField(
                  controller: _confirmPasswordController,
                  focusNode: _confirmFocus,
                  label: l10n.confirmPassword,
                  hint: l10n.enterConfirmPassword,
                  obscureText: _obscureConfirm,
                  onChanged: (_) => _clearServerError('confirmPassword'),
                  validator: _composeValidator(
                    'confirmPassword',
                    (v) {
                      if (v == null || v.isEmpty) {
                        return l10n.pleaseConfirmPassword;
                      }
                      if (v != _passwordController.text) {
                        return l10n.passwordsDoNotMatch;
                      }
                      return null;
                    },
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),

                const SizedBox(height: 16),

                AppDateField(
                  controller: _birthController,
                  label: l10n.birthDate,
                ),
                const SizedBox(height: 16),
                AppDateField(
                  controller: _joiningController,
                  label: l10n.joiningDate,
                ),
                const SizedBox(height: 16),

                if (_selectedType == _RegisterType.servant) ...[
                  AppTextField(
                    controller: _churchIdController,
                    focusNode: _churchIdFocus,
                    label: l10n.churchOrMeetingIdLabel,
                    hint: l10n.enterChurchOrMeetingId,
                    onChanged: (_) => _clearServerError('churchPublicId'),
                    validator: _composeValidator(
                      'churchPublicId',
                      (v) {
                        if (v == null || v.trim().isEmpty) {
                          return l10n.churchOrMeetingIdRequired;
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _requestedRole,
                    decoration: InputDecoration(
                      labelText: l10n.requestedRoleLabel,
                      errorMaxLines: 6,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'Servant',
                        child: Text(l10n.registerTypeServant),
                      ),
                      DropdownMenuItem(
                        value: 'MeetingAdmin',
                        child: Text(l10n.registerTypeMeetingAdmin),
                      ),
                      DropdownMenuItem(
                        value: 'ChurchAdmin',
                        child: Text(l10n.registerTypeChurchAdmin),
                      ),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() {
                        _requestedRole = v;
                        _serverFieldErrors = Map<String, List<String>>.from(
                          _serverFieldErrors,
                        )
                          ..remove('requestedMeetingName')
                          ..remove('meetingAdminPhone');
                      });
                    },
                  ),
                  // Church Admin manages the whole church, so no meeting is requested.
                  if (_requestedRole != 'ChurchAdmin') ...[
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _requestedMeetingController,
                      focusNode: _requestedMeetingFocus,
                      label: l10n.requestedMeetingName,
                      hint: l10n.enterRequestedMeetingName,
                      onChanged: (_) =>
                          _clearServerError('requestedMeetingName'),
                      validator: _composeValidator(
                        'requestedMeetingName',
                        (v) {
                          if (v == null || v.trim().isEmpty) {
                            return l10n.requestedMeetingNameRequired;
                          }
                          return null;
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        l10n.requestedMeetingNameChurchIdHint,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                  if (_requestedRole == 'Servant') ...[
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _meetingAdminPhoneController,
                      focusNode: _meetingAdminPhoneFocus,
                      label: l10n.meetingAdminPhone,
                      hint: l10n.enterMeetingAdminPhone,
                      keyboardType: TextInputType.phone,
                      onChanged: (_) =>
                          _clearServerError('meetingAdminPhone'),
                      validator: _composeValidator(
                        'meetingAdminPhone',
                        (v) => PhoneNumberValidator.validate(v, l10n: l10n),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        l10n.meetingAdminPhoneChurchIdHint,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ],

                if (_selectedType == _RegisterType.churchAdmin) ...[
                  AppTextField(
                    controller: _churchNameController,
                    focusNode: _churchNameFocus,
                    label: l10n.churchName,
                    hint: l10n.enterChurchName,
                    onChanged: (_) => _clearServerError('churchName'),
                    validator: _composeValidator(
                      'churchName',
                      (v) => (v == null || v.trim().isEmpty)
                          ? l10n.churchNameRequired
                          : null,
                    ),
                  ),
                ],

                if (_selectedType == _RegisterType.meetingAdmin) ...[
                  AppTextField(
                    controller: _churchNameController,
                    focusNode: _churchNameFocus,
                    label: l10n.churchName,
                    hint: l10n.enterChurchName,
                    onChanged: (_) => _clearServerError('churchName'),
                    validator: _composeValidator(
                      'churchName',
                      (v) => (v == null || v.trim().isEmpty)
                          ? l10n.churchNameRequired
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _meetingNameController,
                    focusNode: _meetingNameFocus,
                    label: l10n.meetingName,
                    hint: l10n.enterMeetingName,
                    onChanged: (_) => _clearServerError('meetingName'),
                    validator: _composeValidator(
                      'meetingName',
                      (v) => (v == null || v.trim().isEmpty)
                          ? l10n.meetingNameRequired
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedMeetingDay,
                    decoration: InputDecoration(
                      labelText: l10n.meetingDayOfWeek,
                      errorMaxLines: 6,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'Saturday',
                        child: Text(l10n.weekdaySaturday),
                      ),
                      DropdownMenuItem(
                        value: 'Sunday',
                        child: Text(l10n.weekdaySunday),
                      ),
                      DropdownMenuItem(
                        value: 'Monday',
                        child: Text(l10n.weekdayMonday),
                      ),
                      DropdownMenuItem(
                        value: 'Tuesday',
                        child: Text(l10n.weekdayTuesday),
                      ),
                      DropdownMenuItem(
                        value: 'Wednesday',
                        child: Text(l10n.weekdayWednesday),
                      ),
                      DropdownMenuItem(
                        value: 'Thursday',
                        child: Text(l10n.weekdayThursday),
                      ),
                      DropdownMenuItem(
                        value: 'Friday',
                        child: Text(l10n.weekdayFriday),
                      ),
                    ],
                    onChanged: (v) => setState(() => _selectedMeetingDay = v!),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? l10n.required
                        : null,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _weeklyAppointmentController,
                    focusNode: _weeklyFocus,
                    label: l10n.weeklyAppointment,
                    hint: l10n.weeklyAppointmentHint,
                    readOnly: true,
                    onChanged: (_) => _clearServerError('weeklyAppointment'),
                    onTap: () async {
                      if (_loading) return;
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _selectedWeeklyTime ?? TimeOfDay.now(),
                      );
                      if (!mounted) return;
                      if (picked == null) return;
                      setState(() {
                        _selectedWeeklyTime = picked;
                        _weeklyAppointmentController.text =
                            picked.format(context);
                        _serverFieldErrors =
                            Map<String, List<String>>.from(_serverFieldErrors)
                              ..remove('weeklyAppointment');
                      });
                    },
                    validator: _composeValidator(
                      'weeklyAppointment',
                      (_) => _selectedWeeklyTime == null
                          ? l10n.weeklyAppointmentRequired
                          : null,
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                  onPressed: _register,
                  child: Text(l10n.register),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }
}

extension _StringExt on String {
  String? get nullIfEmpty => isEmpty ? null : this;
}