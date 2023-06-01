install:
	mkdir -p $(DESTDIR)/usr/bin
	cp scripts/stadd/stadd.sh $(DESTDIR)/usr/bin/stadd
	chmod +x $(DESTDIR)/usr/bin/stadd
	cp scripts/stmk/stmk.sh $(DESTDIR)/usr/bin/stmk
	chmod +x $(DESTDIR)/usr/bin/stmk
	cp scripts/stdel/stdel.sh $(DESTDIR)/usr/bin/stdel
	chmod +x $(DESTDIR)/usr/bin/stdel
