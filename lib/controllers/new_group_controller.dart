import 'package:flutter/foundation.dart';
import 'package:tokwalker/services/group_service.dart';

class NewGroupController extends ChangeNotifier {
  final List<String> selectedUserIds = [];

  String groupName = '';

  bool get canCreate =>
      groupName.trim().isNotEmpty && selectedUserIds.isNotEmpty;

  void toggleUser(String uid) {
    if (selectedUserIds.contains(uid)) {
      selectedUserIds.remove(uid);
    } else {
      selectedUserIds.add(uid);
    }
    notifyListeners();
  }

  void setGroupName(String value) {
    groupName = value;
    notifyListeners();
  }

  Future<String?> createGroup() async {
    if (!canCreate) return null;

    return GroupService.createGroup(
      name: groupName.trim(),
      memberIds: selectedUserIds,
    );
  }
}
