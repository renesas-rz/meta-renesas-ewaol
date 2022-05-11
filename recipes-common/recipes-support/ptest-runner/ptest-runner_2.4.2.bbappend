# Based on upstream openembedded-core commit 4e6be3fb521b23cfc175d0c09725bcc3ebbc73b2

FILES_${PN}_append = " ${bindir}/ptest-runner-collect-system-data"

do_install_append () {
	install -D -m 0755 ${S}/ptest-runner-collect-system-data ${D}${bindir}/ptest-runner-collect-system-data
}

# pstree is called by ptest-runner-collect-system-data
RDEPENDS_${PN}_append = " pstree"
