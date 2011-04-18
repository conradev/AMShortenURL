##
#  ActionMenu Shorten URL
##

BUNDLE_NAME = ShortURL
ShortURL_FILES = AMShortenURL.m AMShortenURLPrefs.m
ShortURL_FILES += $(shell find Classes/ -iname '*.m')
ShortURL_FILES += $(shell find json-framework/Classes/ -iname '*.m') 
ShortURL_CFLAGS = -I./Classes/ -I./json-framework/Classes/
ShortURL_LDFLAGS = -licucore
ShortURL_FRAMEWORKS = UIKit SystemConfiguration
ShortURL_PRIVATE_FRAMEWORKS = Preferences
ShortURL_INSTALL_PATH = /Library/ActionMenu/Plugins/

include theos/makefiles/common.mk
include $(THEOS_MAKE_PATH)/bundle.mk

internal-bundle-stage_::
	$(ECHO_NOTHING)mv "$(FW_SHARED_BUNDLE_RESOURCE_PATH)/$(FW_INSTANCE)" "$(FW_SHARED_BUNDLE_RESOURCE_PATH)/Shorten URL"$(ECHO_END)
	$(ECHO_NOTHING)mv "$(FW_SHARED_BUNDLE_RESOURCE_PATH)" "$(FW_STAGING_DIR)$($(FW_INSTANCE)_INSTALL_PATH)/Shorten URL.$(LOCAL_BUNDLE_EXTENSION)"$(ECHO_END)
	
run : package install
