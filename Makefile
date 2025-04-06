INSTALL_MARK := .installed

REMINDER="To apply the changes in this session, please run:\\n source \$${HOME}/.bashrc"

all: install

install: $(INSTALL_MARK)

light-install:
	@$(MAKE) BASH_MODE="light" install

$(INSTALL_MARK):
	@echo "Running install..."
	@./setup.sh setup "$(BASH_MODE)"
	@touch $(INSTALL_MARK)
	@echo -e $(REMINDER)

clean:
	@./setup.sh restore
	@rm -f $(INSTALL_MARK)
	@rm -rf ./setup_backup
	@echo -e $(REMINDER)

allclean: clean
    

.PHONY: all install clean allclean