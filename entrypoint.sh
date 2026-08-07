#!/bin/sh

. /lib.subr

set -e

info "Creating non-root user"
create_user

if [ ! -s /usr/local/etc/xrdp/rsakeys.ini ]; then
    info "Generating rsakeys.ini"
    xrdp-keygen xrdp "/usr/local/etc/xrdp/rsakeys.ini"
fi

if [ ! -s /usr/local/etc/xrdp/key.pem ] && [ ! -s /usr/local/etc/xrdp/cert.pem ]; then
    info "Creating *.pem files"
    openssl req \
        -x509 \
        -newkey rsa:4096 \
        -keyout "/usr/local/etc/xrdp/key.pem" \
        -sha256 \
        -nodes \
        -out "/usr/local/etc/xrdp/cert.pem" \
        -days 365 \
        -subj "/CN=$(hostname)"
fi

info "Changing group owner and file mode in *.pem files"
chgrp noroot /usr/local/etc/xrdp/*.pem || warn "/usr/local/etc/xrdp/*.pem: cannot change group owner"
chmod 640 /usr/local/etc/xrdp/*.pem || warn "/usr/local/etc/xrdp/*.pem: cannot change file mode"

info "Changing group owner and file mode in /usr/local/etc/xrdp/rsakeys.ini file"
chgrp noroot /usr/local/etc/xrdp/rsakeys.ini || warn "/usr/local/etc/xrdp/rsakeys.ini: cannot change group owner"
chmod 640 /usr/local/etc/xrdp/rsakeys.ini || warn "/usr/local/etc/xrdp/rsakeys.ini: cannot change file mode"

info "Writing Procfile"
cat << EOF > /Procfile
xrdp: xrdp --nodaemon
xrdp-sesman: xrdp-sesman --nodaemon
EOF

info "Starting ..."
exec goreman -rpc-server=false -f /Procfile start
