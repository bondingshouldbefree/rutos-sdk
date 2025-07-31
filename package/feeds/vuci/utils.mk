LUAC=$(STAGING_DIR_HOSTPKG)/bin/luac

define JsonMin
	$(FIND) $(1) -type f -name '*.json' | while read src; do \
		if jq -c . < "$$$$src" > "$$$$src.o"; \
		then mv "$$$$src.o" "$$$$src"; fi; \
	done
endef

define CompileLua
	$(FIND) $(1) -type f | while read src; do \
		shebang="$$$$(head -1 "$$$$src")" ;\
		has_shebang="" ;\
		if [[ "$$$$shebang" == "#!"*"lua"* ]]; then has_shebang="1" ; fi ;\
		if [[ "$$$$has_shebang" || "$$$${src: -4}" == ".lua" ]]; then \
			$(LUAC) -s -o "$$$$src" "$$$$src" ;\
			if [[ "$$$$has_shebang" ]]; then \
				sed -i '1i'"$$$$shebang" "$$$$src" ;\
			fi ;\
		fi ;\
	done
endef

define MinifyLua
	$(FIND) $(1) -type f -name '*.lua' | while read src; do \
		if LUA_PATH="$(STAGING_DIR_HOSTPKG)/lib/lua/5.1/?.lua" luasrcdiet --noopt-binequiv --noopt-emptylines -o "$$$$src.o" "$$$$src"; \
		then mv "$$$$src.o" "$$$$src"; fi; \
	done
endef
