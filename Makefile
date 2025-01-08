FINALPACKAGE = 1

ifneq (,$(filter rootless,$(MAKECMDGOALS)))
    THEOS_PACKAGE_SCHEME = rootless
endif

ifeq ($(THEOS_PACKAGE_SCHEME),rootless)
	ARCHS = arm64
	TARGET = iphone:clang:latest:14.5
else
	ARCHS = armv7 armv7s arm64
	TARGET = iphone:clang:latest:9.3
endif

include $(THEOS)/makefiles/common.mk

TOOL_NAME = oslo
oslo_FILES = $(wildcard src/*.m) $(wildcard src/kat/*.c)
oslo_CFLAGS = -fobjc-arc -I./src/kat -I./src
oslo_CODESIGN_FLAGS = -S./other/entitlements.plist
oslo_INSTALL_PATH = /usr/local/bin

include $(THEOS_MAKE_PATH)/tool.mk

all::
	@echo "Building for $(if $(THEOS_PACKAGE_SCHEME),rootless,rootful)"

rootful:
	@true

rootless:
	@true

.PHONY: rootful rootless