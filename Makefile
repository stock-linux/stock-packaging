install:
	mkdir -p $(DESTDIR)/usr/bin
	cp scripts/stadd/stadd.sh $(DESTDIR)/usr/bin/stadd
	chmod +x $(DESTDIR)/usr/bin/stadd
	cp scripts/stmk/stmk.sh $(DESTDIR)/usr/bin/stmk
	chmod +x $(DESTDIR)/usr/bin/stmk
	cp scripts/stdel/stdel.sh $(DESTDIR)/usr/bin/stdel
	chmod +x $(DESTDIR)/usr/bin/stdel
	cp scripts/squirrel/squirrel.sh $(DESTDIR)/usr/bin/squirrel
	chmod +x $(DESTDIR)/usr/bin/squirrel
	cp scripts/hazel/hazel.sh $(DESTDIR)/usr/bin/hazel
	chmod +x $(DESTDIR)/usr/bin/hazel

squirrel:
        mkdir -p $(DESTDIR)/usr/bin
	install -T scripts/stadd/stadd.sh $(DESTDIR)/usr/bin/stadd
	install -T scripts/stdel/stdel.sh $(DESTDIR)/usr/bin/stdel
	install -T scripts/squirrel/squirrel.sh $(DESTDIR)/usr/bin/squirrel

hazel:
	mkdir -p $(DESTDIR)/usr/bin
	install -T scripts/stadd/stadd.sh $(DESTDIR)/usr/bin/stadd
	install -T scripts/squirrel/squirrel.sh $(DESTDIR)/usr/bin/squirrel
	install -T scripts/hazel/hazel.sh $(DESTDIR)/usr/bin/hazel

update:
	git pull
	[[ -e $(DESTDIR)/usr/bin/stadd ]] && install -T scripts/stadd/stadd.sh $(DESTDIR)/usr/bin/stadd
	[[ -e $(DESTDIR)/usr/bin/stdel ]] && install -T scripts/stdel/stdel.sh $(DESTDIR)/usr/bin/stdel
	[[ -e $(DESTDIR)/usr/bin/stmk ]] && install -T scripts/stmk/stmk.sh $(DESTDIR)/usr/bin/stmk
	[[ -e $(DESTDIR)/usr/bin/squirrel ]] && install -T scripts/squirrel/squirrel.sh $(DESTDIR)/usr/bin/squirrel
	[[ -e $(DESTDIR)/usr/bin/hazel ]] && install -T scripts/hazel/hazel.sh $(DESTDIR)/usr/bin/hazel
