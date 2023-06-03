TARGET := iphone:clang:latest:13.0
ARCHS := arm64


include $(THEOS)/makefiles/common.mk

TWEAK_NAME = QuantumultXPatches

QuantumultXPatches_FILES = Tweak.x fishhook.c
QuantumultXPatches_FRAMEWORKS = Network Security
QuantumultXPatches_CFLAGS = -fobjc-arc -fno-autolink

include $(THEOS_MAKE_PATH)/tweak.mk
