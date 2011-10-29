##
#  ActionMenu Shorten URL
##

BUNDLE_NAME = ShortURL
ShortURL_FILES = Classes/AMShortenURLController.m Classes/AMShortenURLPlugin.m Classes/AMShortenURLPrefsController.m
ShortURL_LDFLAGS = -licucore
ShortURL_FRAMEWORKS = UIKit SystemConfiguration
ShortURL_PRIVATE_FRAMEWORKS = Preferences
ShortURL_INSTALL_PATH = /Library/ActionMenu/Plugins/

# Extra External Classes (Reachability, RegexKitLite, Google HTML Escaping)
ShortURL_FILES += $(shell find External/Classes/ -iname '*.m')
ShortURL_CFLAGS = -I./External/Classes/

# JSON Framework
ShortURL_FILES += $(shell find External/json-framework/Classes/ -iname '*.m' 2> /dev/null)
ShortURL_CFLAGS += -I./External/json-framework/Classes/

# GData Franework
ShortURL_CFLAGS += -I./External/

include theos/makefiles/common.mk
include $(THEOS_MAKE_PATH)/bundle.mk

# Download GData framework if not downloaded
ifeq ($(shell [ -d "$(THEOS_PROJECT_DIR)/External/GData.framework" ] && echo 1 || echo 0),0)
before-ShortURL-all::
	$(ECHO_NOTHING)$(THEOS_PROJECT_DIR)/get_gdata.sh$(ECHO_END)
endif

# Rename final bundle to proper title with space in it
internal-bundle-stage_::
	$(ECHO_NOTHING)mv "$(THEOS_SHARED_BUNDLE_RESOURCE_PATH)/$(THEOS_CURRENT_INSTANCE)" "$(THEOS_SHARED_BUNDLE_RESOURCE_PATH)/Shorten URL"$(ECHO_END)
	$(ECHO_NOTHING)mv "$(THEOS_SHARED_BUNDLE_RESOURCE_PATH)" "$(THEOS_STAGING_DIR)$($(THEOS_CURRENT_INSTANCE)_INSTALL_PATH)/Shorten URL.$(LOCAL_BUNDLE_EXTENSION)"$(ECHO_END)

# Respring upon install
after-install::
	install.exec 'timeout 10s sbreload || ( ( respring || killall -9 SpringBoard ) && launchctl load /System/Library/LaunchDaemons/com.apple.SpringBoard.plist )'
