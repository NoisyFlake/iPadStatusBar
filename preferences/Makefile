include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = iPadStatusBar
iPadStatusBar_FILES = $(wildcard *.m)
iPadStatusBar_INSTALL_PATH = /Library/PreferenceBundles
iPadStatusBar_FRAMEWORKS = CoreGraphics UIKit
iPadStatusBar_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/iPadStatusBar.plist$(ECHO_END)
