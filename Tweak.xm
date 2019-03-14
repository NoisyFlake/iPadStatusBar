#import "Tweak.h"

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

static BOOL enabled, extraPadding;
static BOOL showDate, showDND, showAlarm, showLocationServices, showRotationLock, showCarrier, showLockIcon, showBattery, showBatteryPercent, showAirplane, showVPN;

%hook UIStatusBar_Base
+ (Class)_implementationClass {
  if (enabled) {
    return NSClassFromString(@"UIStatusBar_Modern");
    } else {
      return %orig;
    }

}

+ (void)_setImplementationClass:(Class)arg1 {
  if (enabled) {
      %orig(NSClassFromString(@"UIStatusBar_Modern"));
    } else {
      %orig(arg1);
    }
}
%end

%hook _UIStatusBarVisualProvider_iOS
+ (Class)class {
  if (enabled) {
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"12.1") && extraPadding) {
      return NSClassFromString(@"_UIStatusBarVisualProvider_RoundedPad_ForcedCellular");
    } else {
      return NSClassFromString(@"_UIStatusBarVisualProvider_Pad_ForcedCellular");
    }
  } else {
    return %orig;
  }
}
%end

%hook UIStatusBarWindow
+ (void)setStatusBar:(Class)arg1 {
  if (enabled) {
      %orig(NSClassFromString(@"UIStatusBar_Modern"));
    } else {
      %orig(arg1);
    }
}
%end

%hook SBStatusBarStateAggregator
-(BOOL)_setItem:(int)index enabled:(BOOL)enableItem {
  UIStatusBarItem *item = [%c(UIStatusBarItem) itemWithType:index idiom:0];

  // NSLog(@"iPadStatusBar: %@ has position %i", item.description, index);

  // Unfortunately the date icon doesn't have a name - might break in future iOS versions
  if (index == 1 && !showDate) {
    return %orig(index, NO);
  }

  else if ([item.description containsString:@"Service"] && !showCarrier) {
    return %orig(index, NO);
  }

  else if ([item.description containsString:@"QuietMode"] && !showDND) {
    return %orig(index, NO);
  }

  else if ([item.description containsString:@"AirplaneMode"] && !showAirplane) {
    return %orig(index, NO);
  }

  else if ([item.description containsString:@"BatteryPercentItem"] && !showBatteryPercent) {
    return %orig(index, NO);
  }

  else if ([item.description containsString:@"Alarm"] && !showAlarm) {
    return %orig(index, NO);
  }

  else if ([item.description containsString:@"Location"] && !showLocationServices) {
    return %orig(index, NO);
  }

  else if ([item.description containsString:@"RotationLock"] && !showRotationLock) {
    return %orig(index, NO);
  }

  else if ([item.description containsString:@"VPN"] && !showVPN) {
    return %orig(index, NO);
  }

  else if ([item.description containsString:@"BarLockItem"] && !showLockIcon) {
    return %orig(index, NO);
  }

  return %orig;
}
%end

%hook _UIBatteryView
-(long long)iconSize {
  if (!showBattery) {
    return 0;
  }
  return %orig;
}
%end

static void loadPrefs() {
  NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.noisyflake.ipadstatusbar.plist"];

  if (prefs) {
    enabled = ( [prefs objectForKey:@"enabled"] ? [[prefs objectForKey:@"enabled"] boolValue] : YES );
    extraPadding = ( [prefs objectForKey:@"extraPadding"] ? [[prefs objectForKey:@"extraPadding"] boolValue] : NO );

    showDate = ( [prefs objectForKey:@"showDate"] ? [[prefs objectForKey:@"showDate"] boolValue] : YES );
    showDND = ( [prefs objectForKey:@"showDND"] ? [[prefs objectForKey:@"showDND"] boolValue] : YES );
    showAlarm = ( [prefs objectForKey:@"showAlarm"] ? [[prefs objectForKey:@"showAlarm"] boolValue] : YES );
    showLocationServices = ( [prefs objectForKey:@"showLocationServices"] ? [[prefs objectForKey:@"showLocationServices"] boolValue] : YES );
    showRotationLock = ( [prefs objectForKey:@"showRotationLock"] ? [[prefs objectForKey:@"showRotationLock"] boolValue] : YES );
    showCarrier = ( [prefs objectForKey:@"showCarrier"] ? [[prefs objectForKey:@"showCarrier"] boolValue] : YES );
    showLockIcon = ( [prefs objectForKey:@"showLockIcon"] ? [[prefs objectForKey:@"showLockIcon"] boolValue] : YES );
    showBattery = ( [prefs objectForKey:@"showBattery"] ? [[prefs objectForKey:@"showBattery"] boolValue] : YES );
    showBatteryPercent = ( [prefs objectForKey:@"showBatteryPercent"] ? [[prefs objectForKey:@"showBatteryPercent"] boolValue] : YES );
    showAirplane = ( [prefs objectForKey:@"showAirplane"] ? [[prefs objectForKey:@"showAirplane"] boolValue] : YES );
    showVPN = ( [prefs objectForKey:@"showVPN"] ? [[prefs objectForKey:@"showVPN"] boolValue] : YES );
  }

}

static void update() {
  loadPrefs();

  SBStatusBarStateAggregator *stateAggregator = [%c(SBStatusBarStateAggregator) sharedInstance];
  for (int i = 1; i <= 40; i++) {
      [stateAggregator updateStatusBarItem:i];
  }

}

static void initPrefs() {
  // Copy the default preferences file when the actual preference file doesn't exist
  NSString *path = @"/User/Library/Preferences/com.noisyflake.ipadstatusbar.plist";
  NSString *pathDefault = @"/Library/PreferenceBundles/iPadStatusBar.bundle/defaults.plist";
  NSFileManager *fileManager = [NSFileManager defaultManager];
  if (![fileManager fileExistsAtPath:path]) {
    [fileManager copyItemAtPath:pathDefault toPath:path error:nil];
  }
}

%ctor {
  CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)update, CFSTR("com.noisyflake.ipadstatusbar/prefsupdated"), NULL, CFNotificationSuspensionBehaviorCoalesce);
  initPrefs();
  loadPrefs();
}
