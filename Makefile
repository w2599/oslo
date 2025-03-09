FINALPACKAGE = 1
THEOS=/Users/zqbb/theos_roothide
THEOS_DEVICE_IP=192.168.31.158
THEOS_DEVICE_PORT=2222
ARCHS=arm64e
THEOS_PACKAGE_SCHEME = roothide

TARGET = iphone:clang:latest:15.0

include $(THEOS)/makefiles/common.mk

TOOL_NAME = oslo
oslo_FILES = $(wildcard src/*.m) $(wildcard src/kat/*.c)
oslo_CFLAGS = -fobjc-arc -I./src/kat -I./src
oslo_CODESIGN_FLAGS = -S./other/entitlements.plist
oslo_INSTALL_PATH = /usr/local/bin

include $(THEOS_MAKE_PATH)/tool.mk

