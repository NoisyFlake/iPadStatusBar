ARCHS = arm64 arm64e
FINALPACKAGE=1

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = iPadStatusBar
iPadStatusBar_FILES = Tweak.xm
iPadStatusBar_CFLAGS += -fobjc-arc -I$(THEOS_PROJECT_DIR)/

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += preferences

include $(THEOS_MAKE_PATH)/aggregate.mk

after-install::
	install.exec "killall -9 SpringBoard"
