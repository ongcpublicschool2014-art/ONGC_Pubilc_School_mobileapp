import 'models/student_model.dart';
import 'models/fee_model.dart';
import 'models/payment_model.dart';
import 'models/notification_model.dart';

/// Dummy data for testing and development
/// Note: This is deprecated - use Supabase data instead
class DummyData {
  DummyData._();

  // Dummy Students - updated to match new Supabase schema
  static final List<StudentModel> students = [
    StudentModel(
      stuId: 1,
      insId: 1,
      inscode: 'KSI001',
      stuadmno: 'KSI2024001',
      stuadmdate: DateTime(2024, 4, 1),
      stuname: 'Aarav Sharma',
      stugender: 'M',
      studob: DateTime(2010, 5, 15),
      stumobile: '9876543210',
      stuemail: 'aarav@example.com',
      stuclass: 'Class 10',
      stuserId: 'STU001',
      createdon: DateTime.now(),
    ),
    StudentModel(
      stuId: 2,
      insId: 1,
      inscode: 'KSI001',
      stuadmno: 'KSI2024002',
      stuadmdate: DateTime(2024, 4, 1),
      stuname: 'Ananya Sharma',
      stugender: 'F',
      studob: DateTime(2013, 8, 22),
      stumobile: '9876543211',
      stuemail: 'ananya@example.com',
      stuclass: 'Class 7',
      stuserId: 'STU002',
      createdon: DateTime.now(),
    ),
  ];

  // Dummy Fees - updated to match new Supabase schema
  static List<FeeModel> getFeesForStudent(int studentId) {
    if (studentId == 1) {
      return [
        FeeModel(
          demId: 1,
          demno: 'DEM001',
          insId: 1,
          inscode: 'KSI001',
          yrId: 1,
          demseqtype: 'T',
          stuId: 1,
          stuadmno: 'KSI2024001',
          stuclass: 'Class 10',
          demfeeyear: '2024-25',
          demfeeterm: 'Term 1',
          demfeetype: 'Tuition Fee',
          feeamount: 25000,
          conId: 1,
          conamount: 2500,
          paidamount: 22500,
          balancedue: 0,
          paidstatus: 'P',
          createdby: 'admin',
          createdat: DateTime(2024, 6, 30),
        ),
        FeeModel(
          demId: 2,
          demno: 'DEM002',
          insId: 1,
          inscode: 'KSI001',
          yrId: 1,
          demseqtype: 'T',
          stuId: 1,
          stuadmno: 'KSI2024001',
          stuclass: 'Class 10',
          demfeeyear: '2024-25',
          demfeeterm: 'Term 2',
          demfeetype: 'Tuition Fee',
          feeamount: 25000,
          conId: 1,
          conamount: 2500,
          paidamount: 10000,
          balancedue: 12500,
          paidstatus: 'U',
          createdby: 'admin',
          createdat: DateTime(2024, 12, 31),
        ),
      ];
    }
    return [];
  }

  // Dummy Payments - updated to match new Supabase schema
  static List<PaymentModel> getPaymentsForStudent(int studentId) {
    if (studentId == 1) {
      return [
        PaymentModel(
          payId: 1,
          insId: 1,
          inscode: 'KSI001',
          paydate: DateTime(2024, 6, 25, 10, 30),
          paystatus: 'C',
          paymethod: 'UPI',
          payreference: 'TXN123456789',
          createdat: DateTime(2024, 6, 25, 10, 30),
        ),
      ];
    }
    return [];
  }

  // Dummy Notifications
  static List<NotificationModel> getNotifications() {
    return [
      NotificationModel(
        id: 'notif-001',
        schoolId: 'school-001',
        parentId: 'parent-001',
        studentId: 'student-001',
        title: 'Fee Payment Reminder',
        message: 'Sports Fee of Rs. 3,500 is overdue. Please pay immediately to avoid further late charges.',
        type: NotificationType.feeReminder,
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      NotificationModel(
        id: 'notif-002',
        schoolId: 'school-001',
        parentId: 'parent-001',
        studentId: 'student-001',
        title: 'Payment Successful',
        message: 'Payment of Rs. 10,000 received for Term 2 Tuition Fee. Thank you!',
        type: NotificationType.paymentSuccess,
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }
}
