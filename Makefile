INSTALL_MARK := .installed


REMINDER="To apply the changes in this session, please run:\nsource \$${HOME}/.bashrc"

all: install
#	@echo "Please run 'make install'"

install: $(INSTALL_MARK)

$(INSTALL_MARK):
	@echo "Running install..."
	@./setup.sh setup
	@touch $(INSTALL_MARK)
	@echo $(REMINDER)

clean:
	@./setup.sh restore
	@rm -f $(INSTALL_MARK)
	@rm -rf ./setup_backup
	@echo $(REMINDER)

allclean: clean
	

.PHONY: all install clean allclean

