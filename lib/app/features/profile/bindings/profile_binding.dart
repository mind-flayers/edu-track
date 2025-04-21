import 'package:edu_track/app/features/profile/controllers/profile_controller.dart';
import 'package:get/get.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    // Lazily initialize ProfileController when it's first needed
    Get.lazyPut<ProfileController>(() => ProfileController());
  }
}