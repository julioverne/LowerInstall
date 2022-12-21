include $(THEOS)/makefiles/common.mk

SUBPROJECTS += lowerinstallhooks
SUBPROJECTS += lowerinstallsettings

include $(THEOS_MAKE_PATH)/aggregate.mk
