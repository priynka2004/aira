// FILE: utils/autostart_helper.dart
// Android helper: asks the user to enable Autostart so notifications work on Xiaomi/Oppo/etc.

import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Autostart Helper.
class AutostartHelper {
  static const _promptedKey = 'autostart_prompt_shown';
  static const Map<String, List<Map<String, String>>> _candidatesByBrand = {
    'vivo': [
      {'pkg': 'com.vivo.permissionmanager', 'cls': 'com.vivo.permissionmanager.activity.BgStartUpManagerActivity'},
      {'pkg': 'com.iqoo.secure', 'cls': 'com.iqoo.secure.ui.phoneoptimize.AddWhiteListActivity'},
      {'pkg': 'com.iqoo.secure', 'cls': 'com.iqoo.secure.ui.phoneoptimize.BgStartUpManager'},
      {'pkg': 'com.vivo.permissionmanager', 'cls': 'com.vivo.permissionmanager.activity.PurviewTabActivity'},
    ],
    'xiaomi': [
      {'pkg': 'com.miui.securitycenter', 'cls': 'com.miui.permcenter.autostart.AutoStartManagementActivity'},
    ],
    'redmi': [
      {'pkg': 'com.miui.securitycenter', 'cls': 'com.miui.permcenter.autostart.AutoStartManagementActivity'},
    ],
    'poco': [
      {'pkg': 'com.miui.securitycenter', 'cls': 'com.miui.permcenter.autostart.AutoStartManagementActivity'},
    ],
    'oppo': [
      {'pkg': 'com.coloros.safecenter', 'cls': 'com.coloros.safecenter.permission.startup.StartupAppListActivity'},
      {'pkg': 'com.coloros.safecenter', 'cls': 'com.coloros.safecenter.startupapp.StartupAppListActivity'},
      {'pkg': 'com.oppo.safe', 'cls': 'com.oppo.safe.permission.startup.StartupAppListActivity'},
    ],
    'oneplus': [
      {'pkg': 'com.oneplus.security', 'cls': 'com.oneplus.security.chainlaunch.view.ChainLaunchAppListActivity'},
      {'pkg': 'com.coloros.safecenter', 'cls': 'com.coloros.safecenter.permission.startup.StartupAppListActivity'},
    ],
    'realme': [
      {'pkg': 'com.coloros.safecenter', 'cls': 'com.coloros.safecenter.permission.startup.StartupAppListActivity'},
      {'pkg': 'com.oppo.safe', 'cls': 'com.oppo.safe.permission.startup.StartupAppListActivity'},
    ],
    'huawei': [
      {'pkg': 'com.huawei.systemmanager', 'cls': 'com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity'},
      {'pkg': 'com.huawei.systemmanager', 'cls': 'com.huawei.systemmanager.optimize.process.ProtectActivity'},
      {'pkg': 'com.huawei.systemmanager', 'cls': 'com.huawei.systemmanager.appcontrol.activity.StartupAppControlActivity'},
    ],
    'honor': [
      {'pkg': 'com.hihonor.systemmanager', 'cls': 'com.hihonor.systemmanager.startupmgr.ui.StartupNormalAppListActivity'},
      {'pkg': 'com.huawei.systemmanager', 'cls': 'com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity'},
    ],
    'samsung': [
      {'pkg': 'com.samsung.android.lool', 'cls': 'com.samsung.android.sm.ui.battery.BatteryActivity'},
      {'pkg': 'com.samsung.android.sm', 'cls': 'com.samsung.android.sm.ui.battery.BatteryActivity'},
    ],
    'asus': [
      {'pkg': 'com.asus.mobilemanager', 'cls': 'com.asus.mobilemanager.autostart.AutoStartActivity'},
      {'pkg': 'com.asus.mobilemanager', 'cls': 'com.asus.mobilemanager.MainActivity'},
    ],
    'meizu': [
      {'pkg': 'com.meizu.safe', 'cls': 'com.meizu.safe.permission.PermissionMainActivity'},
      {'pkg': 'com.meizu.safe', 'cls': 'com.meizu.safe.security.SHOW_APPSEC'},
    ],
    'letv': [
      {'pkg': 'com.letv.android.letvsafe', 'cls': 'com.letv.android.letvsafe.AutobootManageActivity'},
    ],
    'lenovo': [
      {'pkg': 'com.lenovo.security', 'cls': 'com.lenovo.security.purebackground.PureBackgroundActivity'},
    ],
    'zte': [
      {'pkg': 'com.zte.heartyservice', 'cls': 'com.zte.heartyservice.autorun.AppAutoRunManager'},
    ],
    'nubia': [
      {'pkg': 'com.zte.heartyservice', 'cls': 'com.zte.heartyservice.autorun.AppAutoRunManager'},
    ],
  };

  /// Prompt if needed.
  static Future<void> promptIfNeeded(BuildContext context) async {
    if (!Platform.isAndroid) return;

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_promptedKey) == true) return;

    final info = await DeviceInfoPlugin().androidInfo;
    final brand = '${info.manufacturer} ${info.brand}'.toLowerCase();
    final candidates = _candidatesByBrand.entries
        .firstWhere((e) => brand.contains(e.key), orElse: () => const MapEntry('', []))
        .value;
    if (candidates.isEmpty) return;

    await prefs.setBool(_promptedKey, true);
    if (!context.mounted) return;

    final proceed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Turn On Autostart', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
          "Your Phone Blocks New Apps From Running In The Background By "
              "Default, Which Stops Booking, Chat And Support Notifications "
              "From Arriving Once The App Is Closed. Enable Autostart To Keep "
              "Getting Them.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Later')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Open Settings')),
        ],
      ),
    );

    if (proceed == true) {
      await _openFirstWorking(candidates);
    }
  }

  /// Opens first working.
  static Future<void> _openFirstWorking(List<Map<String, String>> candidates) async {
    for (final c in candidates) {
      try {
        final intent = AndroidIntent(
          action: 'android.intent.action.MAIN',
          package: c['pkg'],
          componentName: c['cls'],
        );
        await intent.launch();
        return;
      } catch (_) {
        continue;
      }
    }

    try {
      final packageName = (await PackageInfo.fromPlatform()).packageName;
      final fallback = AndroidIntent(
        action: 'android.settings.APPLICATION_DETAILS_SETTINGS',
        data: 'package:$packageName',
      );
      await fallback.launch();
    } catch (_) {
    }
  }
}
