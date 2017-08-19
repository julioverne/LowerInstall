include theos/makefiles/common.mk

TWEAK_NAME = LowerInstall

LowerInstall_FILES = /mnt/d/codes/lowerinstall/lowerinstallhooks/LowerInstall.xm
LowerInstall_FRAMEWORKS = CydiaSubstrate Foundation
LowerInstall_LIBRARIES = MobileGestalt
LowerInstall_LDFLAGS = -Wl,-segalign,4000

export ARCHS = armv7 arm64
LowerInstall_ARCHS = armv7 arm64

include $(THEOS_MAKE_PATH)/tweak.mk
	
all::
	