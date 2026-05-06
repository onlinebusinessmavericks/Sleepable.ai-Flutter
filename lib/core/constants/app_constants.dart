class AppConstants {
  static const String appName = "GetX Clean App";
  static const String baseUrl = "https://jsonplaceholder.typicode.com";

  // Storage keys
  static const String tokenKey = "auth_token";
  static const String userKey = "user_data";

  // Pagination
  static const int pageSize = 20;

  // Durations
  static const Duration apiTimeout = Duration(seconds: 30);
}
enum MethodType { get, post, delete, put, multipart,patch }

enum LoginType { google, apple, otp, email }

enum UserType { collector, vendor, user }

enum AuthType { signIn, signUp, otpLogin, otpVerification }


class ConstantKeys {
  static const pageKey = 'page';
  static const token = 'token';
  static const perPageKey = 'per_page';
  static const searchKey = 'search';
  static const isAuthenticatedKey = 'is_authenticated';
  static const idKey = 'id';
  static const statusKey = 'status';
  static const typeKey = 'type';
  static const isDefaultKey = 'is_default';
  static const loginTypeKey = 'login_type';
  static const emailKey = 'email';
  static const passwordKey = 'password';
  static const oldPasswordKey = 'old_password';
  static const newPasswordKey = 'new_password';
  static const mobileNumberKey = 'mobile_number';
  static const userTypeKey = 'user_type';
  static const appointmentStatusKey = 'status';
  static const firstNameKey = 'first_name';
  static const lastNameKey = 'last_name';
  static const profileImageKey = 'profile_image';
  static const relationKey = 'relation';
  static const userIdKey = 'user_id';
  static const userNameKey = 'user_name';
  static const genderKey = 'gender';
  static const dobKey = 'dob';
  static const otpKey = 'otp';
  static const socialImageKey = 'social_image';

  //region Appointment
  static const paymentStatusKey = 'payment_status';
  static const customerIdKey = 'customer_id';

  static const collectorIdKey = 'collector_id';
  static const labIdKey = 'lab_id';
  static const vendorIdKey = 'vendor_id';
  static const testTypeKey = 'test_type';
  static const testIdKey = 'test_id';
  static const appointmentId = 'appointment_id';
  static const appointmentDateKey = 'appointment_date';
  static const appointmentTimeKey = 'appointment_time';

  static const rescheduleReasonTimeKey = 'reschedule_reason';
  static const collectionTypeKey = 'collection_type';
  static const paymentTypeKey = 'payment_type';
  static const paymentMethodKey = 'payment_method';
  static const paymentGatewayKey = 'payment_mode';
  static const couponIdKey = 'coupon_id';
  static const medicalReportKey = 'medical_report';

  static const amountKey = 'medical_report';

  //endregion

  //region Location
  static const countryIdKey = 'country_id';
  static const stateIdKey = 'state_id';
  static const cityIdKey = 'city_id';

  //endregion

  //region Help Desk Keys
  static const subjectKey = 'subject';
  static const descriptionKey = 'description';
  static const messageKey = 'message';
  static const priorityKey = 'priority';
  static const categoryKey = 'category';
  static const attachmentCountKey = 'attachment_count';
  static const helpDeskAttachmentKey = 'helpdesk_attachment';
  static const modeKey = 'mode';
  static const contactNumberKey = 'contact_number';

  //endregion

  //region Address
  static const addressKey = 'address';
  static const addressTypeKey = 'type';
  static const searchTypeKey = 'type';

  //endregion

  //region Wallet and bank
  static String bankName = 'bank_name';
  static String branchName = 'branch_name';
  static String accountNo = 'account_no';
  static String ifscCodeKey = 'ifsc_code';
  static String aadharNo = 'aadhar_no';
  static String panNo = 'pan_no';
  static String bankAttachment = 'bank_attachment';
  static String mobileKey = 'mobile';

  static String phoneNumberKey = 'phone_number';

  //endregion
}
