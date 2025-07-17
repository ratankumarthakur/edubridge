import 'dart:math';

import 'package:flutter/material.dart';
import 'package:tution/video_call/constants.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

final userId =Random().nextInt(9999);
class CallPage extends StatelessWidget {
  const CallPage({super.key, required this.callID});
  final String callID;

  @override
  Widget build(BuildContext context) {
    return ZegoUIKitPrebuiltCall(
      appID: appinfo.appId, // Fill in the appID that you get from ZEGOCLOUD Admin Console.
      appSign: appinfo.appSign, // Fill in the appSign that you get from ZEGOCLOUD Admin Console.
      userID: userId.toString(), // Fill in the userID that you get from your authentication system.
      userName: 'UserName $userId',
      callID: callID,
      // You can also use groupVideo/groupVoice/oneOnOneVoice to make more types of calls.
      config: ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall(),
    );
  }
}
