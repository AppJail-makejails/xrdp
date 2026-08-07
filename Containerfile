ARG FREEBSD_RELEASE

FROM ghcr.io/appjail-makejails/core:${FREEBSD_RELEASE}

ARG X11_FLAVOR
ARG NO_PKGCLEAN

LABEL org.opencontainers.image.title="Xrdp" \
    org.opencontainers.image.description="Open source Remote Desktop Protocol (RDP) server" \
    org.opencontainers.image.source="https://github.com/AppJail-makejails/xrdp" \
    org.opencontainers.image.url="https://github.com/AppJail-makejails/xrdp" \
    org.opencontainers.image.vendor="DtxdF" \
    org.opencontainers.image.authors="Jesús Daniel Colmenares Oviedo <dtxdf@disroot.org>"

RUN set -xe; \
    \
    pkg update; \
    pkg install -U xrdp goreman FreeBSD-pam; \
    if [ "${X11_FLAVOR}" = "xlibre" ]; then \
        pkg install -U xlibre xlibre-xorgxrdp; \
    elif [ "${X11_FLAVOR}" = "xorg" ]; then \
        pkg install -U xorg xorgxrdp; \
    else \
        echo "${X11_FLAVOR}: invalid x11 flavor."; \
        exit 1; \
    fi; \
    \
    if [ -z "${NO_PKGCLEAN}" ]; then \
        pkg clean -a; \
        rm -rf /var/cache/pkg/*; \
    fi; \
    rm -rf /var/db/pkg/repos/*; \
    \
    chmod 755 /usr/local/sbin

COPY entrypoint.sh /

RUN set -xe; \
    \
    chmod +x /entrypoint.sh; \
    \
    ln -s /dev/stdout /var/log/xrdp.log; \
    ln -s /dev/stdout /var/log/xrdp-sesman.log; \
    \
    sed -i '' -Ee 's/^#runtime_(user|group)=.+/runtime_\1=noroot/' /usr/local/etc/xrdp/xrdp.ini; \
    sed -i '' -Ee 's/^#SessionSockdirGroup=.+/SessionSockdirGroup=noroot/' /usr/local/etc/xrdp/sesman.ini; \
    \
    echo -n | tee "/usr/local/etc/xrdp/rsakeys.ini"; \
    echo -n | tee "/usr/local/etc/xrdp/key.pem"; \
    echo -n | tee "/usr/local/etc/xrdp/cert.pem"

VOLUME ["/usr/local/etc/xrdp"]

CMD ["/entrypoint.sh"]
