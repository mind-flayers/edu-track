import 'package:edu_track/app/features/students/controllers/student_controller.dart';
import 'package:get/get.dart';

/// Binding for the Student List screen.
/// Lazily initializes [StudentController] when the route is accessed.
class StudentBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<StudentController>(() => StudentController());
  }
}
