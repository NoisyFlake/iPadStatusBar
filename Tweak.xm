#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

static BOOL enabled, extraPadding;

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

static void loadPrefs() {
  NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.noisyflake.ipadstatusbar.plist"];

  if (prefs) {
    enabled = ( [prefs objectForKey:@"enabled"] ? [[prefs objectForKey:@"enabled"] boolValue] : YES );
    extraPadding = ( [prefs objectForKey:@"extraPadding"] ? [[prefs objectForKey:@"extraPadding"] boolValue] : YES );
  }

  [prefs release];
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
  initPrefs();
  loadPrefs();
}
