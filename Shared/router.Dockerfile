# FRRouting: open-source routing suite
FROM frrouting/frr:v8.4.0

# By default only zebra and staticd run

# Activate the daemons required by the subject
# Empty vtysh.conf: removes the "can't open vtysh.conf" warning
RUN sed -i -e 's/^bgpd=no/bgpd=yes/' \
           -e 's/^ospfd=no/ospfd=yes/' \
           -e 's/^isisd=no/isisd=yes/' /etc/frr/daemons \
 && touch /etc/frr/vtysh.conf

# busybox is included in the base image.
# No IP address is configured by default

# Verification:
#   ps -> zebra, bgpd, ospfd, isisd, staticd running
#   vtysh -c "show version"