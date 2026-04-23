BATS := $(shell command -v bats 2>/dev/null || echo test/bats/bin/bats)

.PHONY: test lint clean

test:
	$(BATS) test/

lint:
	shellcheck --severity=warning hooks/*.sh config.sh install.sh uninstall.sh art/screens.sh

clean:
	rm -f /tmp/.cl4ud3-cr4ck-*
	rm -rf /tmp/.cl4ud3-cr4ck-all-jingles-*
	rm -f /tmp/.cl4ud3-stop-debug.log
