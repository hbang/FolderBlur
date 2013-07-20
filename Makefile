TARGET = :clang

include theos/makefiles/common.mk

# dylib is HBFolderBlur so it is alphabetically after
# FolderEnhancer, and therefore loaded after it.
TWEAK_NAME = HBFolderBlur
HBFolderBlur_FILES = Tweak.xm
HBFolderBlur_FRAMEWORKS = UIKit QuartzCore

include $(THEOS_MAKE_PATH)/tweak.mk
