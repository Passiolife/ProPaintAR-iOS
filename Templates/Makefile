XCODE_USER_TEMPLATES_DIR=~/Library/Developer/Xcode/Templates/File\ Templates/Custom

TEMPLATES_SOURCE_DIR=Coordinator\ Templates
TEMPLATES_DESTINATION_DIR=Coordinator

all:
	@echo 'To Install, run `make install`';
	@echo 'To Uninstall, run `make uninstall`';

install:
	@mkdir -p $(XCODE_USER_TEMPLATES_DIR)
	@rm -fR $(XCODE_USER_TEMPLATES_DIR)/$(TEMPLATES_DESTINATION_DIR)
	@cp -R $(TEMPLATES_SOURCE_DIR) $(XCODE_USER_TEMPLATES_DIR)/$(TEMPLATES_DESTINATION_DIR)
	@echo 'Coordinator templates successfully installed.';

uninstall:
	@rm -fR $(XCODE_USER_TEMPLATES_DIR)/$(TEMPLATES_DESTINATION_DIR)
	@echo 'Coordinator templates uninstalled.';