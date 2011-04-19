##
#  ActionMenu Shorten URL
##

GO_EASY_ON_ME=1

BUNDLE_NAME = ShortURL
ShortURL_FILES = $(shell find Classes/ -iname '*.m')
ShortURL_LDFLAGS = -licucore
ShortURL_FRAMEWORKS = UIKit SystemConfiguration GData
ShortURL_PRIVATE_FRAMEWORKS = Preferences
ShortURL_INSTALL_PATH = /Library/ActionMenu/Plugins/

# Extra External Classes (Reachability, RegexKitLite, Google HTML Escaping)
ShortURL_FILES += $(shell find External/Classes/ -iname '*.m')
ShortURL_CFLAGS = -I./External/Classes/ 

# JSON Framework
ShortURL_FILES += $(shell find External/json-framework/Classes/ -iname '*.m') 
ShortURL_CFLAGS += -I./External/json-framework/Classes/

# GData Framework
ShortURL_LDFLAGS += -F./External/ -framework GData

include theos/makefiles/common.mk
include $(THEOS_MAKE_PATH)/bundle.mk

# Auto-download GData framework
ifeq ($(shell [ -d "$(THEOS_PROJECT_DIR)/External/GData.framework" ] && echo 1 || echo 0),0)
before-ShortURL-all::
	$(ECHO_NOTHING)$(THEOS_PROJECT_DIR)/get_gdata.sh$(ECHO_END)
endif

# Fix GData framework link path manually (*cough* DHowett, rpetrich *cough*)
after-ShortURL-all::
	$(ECHO_NOTHING)install_name_tool -change /GData.framework/GData /System/Library/Frameworks/GData.framework/GData $(THEOS_OBJ_DIR)/$(THEOS_CURRENT_INSTANCE)$(ECHO_END)

# Rename final bundle to proper title with space in it
internal-bundle-stage_::
	$(ECHO_NOTHING)mv "$(THEOS_SHARED_BUNDLE_RESOURCE_PATH)/$(THEOS_CURRENT_INSTANCE)" "$(THEOS_SHARED_BUNDLE_RESOURCE_PATH)/Shorten URL"$(ECHO_END)
	$(ECHO_NOTHING)mv "$(THEOS_SHARED_BUNDLE_RESOURCE_PATH)" "$(THEOS_STAGING_DIR)$($(THEOS_CURRENT_INSTANCE)_INSTALL_PATH)/Shoten URL.$(LOCAL_BUNDLE_EXTENSION)"$(ECHO_END)
