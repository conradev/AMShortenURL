##
#  ActionMenu Shorten URL
##

GO_EASY_ON_ME=1

BUNDLE_NAME = ShortURL
ShortURL_FILES = $(shell find Classes/ -iname '*.m')
ShortURL_LDFLAGS = -licucore
ShortURL_FRAMEWORKS = UIKit SystemConfiguration
ShortURL_PRIVATE_FRAMEWORKS = Preferences
ShortURL_INSTALL_PATH = /Library/ActionMenu/Plugins/

# Extra External Classes (Reachability, RegexKitLite, Google HTML Escaping)
ShortURL_FILES += $(shell find External/Classes/ -iname '*.m')
ShortURL_CFLAGS = -I./External/Classes/ 

# JSON Framework (For Goo.gl)
ShortURL_FILES += $(shell find External/json-framework/Classes/ -iname '*.m') 
ShortURL_CFLAGS += -I./External/json-framework/Classes/

# GData Framework (For Goo.gl)
ShortURL_LDFLAGS += -F./External/ -framework GData

include theos/makefiles/common.mk
include $(THEOS_MAKE_PATH)/bundle.mk

# Auto-download GData framework
ifeq ($(shell [ -d "$(FW_PROJECT_DIR)/External/GData.framework" ] && echo 1 || echo 0),0)
before-ShortURL-all::
	$(ECHO_NOTHING)$(FW_PROJECT_DIR)/get_gdata.sh$(ECHO_END)
endif

# Rename final bundle to proper title with space in it
internal-bundle-stage_::
	$(ECHO_NOTHING)mv "$(FW_SHARED_BUNDLE_RESOURCE_PATH)/$(FW_INSTANCE)" "$(FW_SHARED_BUNDLE_RESOURCE_PATH)/Shorten URL"$(ECHO_END)
	$(ECHO_NOTHING)mv "$(FW_SHARED_BUNDLE_RESOURCE_PATH)" "$(FW_STAGING_DIR)$($(FW_INSTANCE)_INSTALL_PATH)/Shorten URL.$(LOCAL_BUNDLE_EXTENSION)"$(ECHO_END)
