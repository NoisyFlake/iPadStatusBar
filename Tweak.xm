#import "Tweak.h"

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

static BOOL enabled, extraPadding;
static BOOL showDate, showDND, showAlarm, showLocationServices, showRotationLock, showSignal, showLockIcon,
showBattery, showBatteryPercent, showAirplane, showVPN, showBreadcrumb, showActivity, showTime, showCarrier,
showBatteryPercentSign, showWifi, showData;


// ===== MODERN STATUS BAR ===== //

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

// ===== ITEM HIDING ===== //

%hook SBStatusBarStateAggregator
-(BOOL)_setItem:(int)index enabled:(BOOL)enableItem {
  if (!enabled) return %orig;

  UIStatusBarItem *item = [%c(UIStatusBarItem) itemWithType:index idiom:0];

  // Unfortunately the date icon doesn't have a name - might break in future iOS versions
  if (index == 1 && !showDate) {
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

  else if ([item.description containsString:@"ActivityItem"] && !showActivity) {
    return %orig(index, NO);
  }

  return %orig;
}
%end

%hook _UIBatteryView
-(long long)iconSize {
  if (enabled && !showBattery) {
    return 0;
  }
  return %orig;
}
%end

%hook _UIStatusBarData
- (void)setBackNavigationEntry:(id)arg1 {
  if (enabled && !showBreadcrumb) {
    return;
  } else {
    %orig;
  }
}
%end

%hook _UIStatusBarCellularItem
-(_UIStatusBarStringView *)serviceNameView {
  _UIStatusBarStringView *orig = %orig;
  orig.isCarrier = YES;
  return orig;
}
-(_UIStatusBarStringView *)networkTypeView {
  _UIStatusBarStringView *orig = %orig;
  orig.isData = YES;
  return orig;
}
%end

%hook _UIStatusBarStringView
%property (nonatomic, assign) BOOL isCarrier;
%property (nonatomic, assign) BOOL isData;
-(void)setText:(id)arg1 {
  %orig;

  if (!enabled) return;

  if (!showTime && [arg1 containsString:@":"]) {
    %orig(@"");
  }

  if (!showCarrier && self.isCarrier) {
    %orig(@"");
  }

  if (!showBatteryPercentSign && [arg1 containsString:@"%"]) {
    NSString* percentageOnly = [arg1 substringToIndex:[arg1 length] - 1];
    %orig(percentageOnly);
  }

  if (!showData && self.isData) {
    %orig(@"");
  }

}
%end

%hook _UIStatusBarCellularSignalView
-(double)_heightForBarAtIndex:(long long)arg1 mode:(long long)arg2 {
  if (enabled && !showSignal) {
      return 0;
    } else {
      return %orig;
    }
}
%end

%hook _UIStatusBarWifiSignalView
+(double)_totalWidthForIconSize:(long long)arg1 {
  if (enabled && !showWifi) {
    return 0;
  } else {
    return %orig;
  }
}
+(double)_interspaceForIconSize:(long long)arg1 {
  if (enabled && !showWifi) {
    return 0;
  } else {
    return %orig;
  }
}
+(double)_barThicknessAtIndex:(unsigned long long)arg1 iconSize:(long long)arg2 {
  if (enabled && !showWifi) {
    return 0;
  } else {
    return %orig;
  }
}
%end

// ===== PREFERENCE HANDLING ===== //

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
    showSignal = ( [prefs objectForKey:@"showSignal"] ? [[prefs objectForKey:@"showSignal"] boolValue] : YES );
    showLockIcon = ( [prefs objectForKey:@"showLockIcon"] ? [[prefs objectForKey:@"showLockIcon"] boolValue] : YES );
    showBattery = ( [prefs objectForKey:@"showBattery"] ? [[prefs objectForKey:@"showBattery"] boolValue] : YES );
    showBatteryPercent = ( [prefs objectForKey:@"showBatteryPercent"] ? [[prefs objectForKey:@"showBatteryPercent"] boolValue] : YES );
    showAirplane = ( [prefs objectForKey:@"showAirplane"] ? [[prefs objectForKey:@"showAirplane"] boolValue] : YES );
    showVPN = ( [prefs objectForKey:@"showVPN"] ? [[prefs objectForKey:@"showVPN"] boolValue] : YES );
    showBreadcrumb = ( [prefs objectForKey:@"showBreadcrumb"] ? [[prefs objectForKey:@"showBreadcrumb"] boolValue] : YES );
    showActivity = ( [prefs objectForKey:@"showActivity"] ? [[prefs objectForKey:@"showActivity"] boolValue] : YES );
    showTime = ( [prefs objectForKey:@"showTime"] ? [[prefs objectForKey:@"showTime"] boolValue] : YES );
    showCarrier = ( [prefs objectForKey:@"showCarrier"] ? [[prefs objectForKey:@"showCarrier"] boolValue] : YES );
    showBatteryPercentSign = ( [prefs objectForKey:@"showBatteryPercentSign"] ? [[prefs objectForKey:@"showBatteryPercentSign"] boolValue] : YES );
    showWifi = ( [prefs objectForKey:@"showWifi"] ? [[prefs objectForKey:@"showWifi"] boolValue] : YES );
    showData = ( [prefs objectForKey:@"showData"] ? [[prefs objectForKey:@"showData"] boolValue] : YES );
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
