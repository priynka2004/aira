import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A long list of Android OEM skins (Vivo, Xiaomi, Oppo, OnePlus, Realme,
/// Huawei, Honor, Samsung, Asus, Meizu, Letv, Lenovo, ZTE/Nubia...) disable
/// "Autostart" / background-run permission for freshly installed apps and
/// freeze or kill the process in the background — this is why push
/// notifications stop arriving the moment the app is swiped away, no
/// matter how correctly Firebase/FCM is set up on the Dart side. There's
/// no code fix for that; it's a device setting only the user can flip.
/// This shows a one-time prompt (once per install) that deep-links
/// straight into the right settings screen for whichever brand the app is
/// running on.
class AutostartHelper {
  static const _promptedKey = 'autostart_prompt_shown';

  // Known component names for each brand's autostart / background-run
  // permission screen. These vary across ROM/OS versions (and sometimes
  // don't exist at all on a given build), so every candidate for the
  // detected brand is tried in order until one actually launches; if none
  // do, promptIfNeeded falls back to the app's own system settings page.
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
      // Newer OxygenOS builds (post OPPO/OnePlus merge) reuse ColorOS's screen.
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
      // "Device care" battery screen — Samsung has no dedicated autostart
      // page, but this is the closest equivalent (unmonitored/sleeping apps).
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

  /// Call once, e.g. from the app shell after first frame. No-ops on iOS,
  /// on brands that don't need this, and after the first time it's shown.
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
        title: const Text('Turn on Autostart', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
          "Your phone blocks new apps from running in the background by "
              "default, which stops booking, chat and support notifications "
              "from arriving once the app is closed. Enable Autostart to keep "
              "getting them.",
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

  static Future<void> _openFirstWorking(List<Map<String, String>> candidates) async {
    for (final c in candidates) {
      try {
        final intent = AndroidIntent(
          action: 'android.intent.action.MAIN',
          package: c['pkg'],
          componentName: c['cls'],
        );
        await intent.launch();
        return; // stop at the first screen that actually opens
      } catch (_) {
        continue; // that component doesn't exist on this ROM version — try the next
      }
    }

    // None of the known screens exist on this ROM version — fall back to
    // the app's own system settings page, one tap away from the right spot.
    try {
      final packageName = (await PackageInfo.fromPlatform()).packageName;
      final fallback = AndroidIntent(
        action: 'android.settings.APPLICATION_DETAILS_SETTINGS',
        data: 'package:$packageName',
      );
      await fallback.launch();
    } catch (_) {
      // Nothing more we can do — the manual steps still work regardless.
    }
  }
}
