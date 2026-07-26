# Xrdp

Xrdp is a free and open-source implementation of Microsoft RDP (Remote Desktop Protocol) other than Microsoft Windows (such as Linux and BSD-style operating systems) to provide a fully functional RDP-compatible remote desktop experience.

wikipedia.org/wiki/Xrdp

<img src="https://camo.githubusercontent.com/9aeef4fa2bf49f1806978b551785ab7f3f50760f2fb868db52f8a582e848e2f8/68747470733a2f2f75706c6f61642e77696b696d656469612e6f72672f77696b6970656469612f636f6d6d6f6e732f7468756d622f652f65632f587264705f6c6f676f2e7376672f3139323070782d587264705f6c6f676f2e7376672e706e67" width="30%" height="auto" alt="Xrdp logo">

## How to use this Makejail

The simplest way to deploy Xrdp is by using `appjail oci run`.

```console
$ X11_FLAVOR=xlibre
$ mkdir -p /var/appjail-volumes/xrdp/data
$ appjail oci run -Pd \
    -o template=template.conf \
    -o overwrite=force \
    -o virtualnet=":<random> default" \
    -o nat \
    -o expose=3389 \ # Optional, allow external hosts
    -o fstab="/var/appjail-volumes/xrdp/data /usr/local/etc/xrdp <pseudofs>" \
    ghcr.io/appjail-makejails/xrdp:15.1-${X11_FLAVOR} xrdp
$ echo xrdp | appjail cmd jexec xrdp pw useradd -n xrdp -m -h 0
...
$ appjail jail list -j xrdp name network_ip4
NAME  NETWORK_IP4
xrdp  10.0.0.9
```

**template.conf**:

```
exec.start: "/bin/sh /etc/rc"
exec.stop: "/bin/sh /etc/rc.shutdown jail"
mount.devfs
persist
sysvmsg: new
sysvsem: new
sysvshm: new
```

Assuming you've enabled [DNS in AppJail](https://appjail.readthedocs.io/en/latest/networking/DNS/), you can use either `xrdp:3389` or `10.0.0.9:3389` to connect to it using a client such as [net/freerdp3](https://freshports.org/net/freerdp3). 

```console
$ xfreerdp3 /d: /u:xrdp /p:xrdp /v:xrdp +dynamic-resolution
```

After logging in to the Xrdp instance with our credentials (user `xrdp`, password `xrdp` in this case), `xterm` (the default command) is displayed.

That's fine for demonstration purposes, but it doesn't meet our needs. We might want to install a full desktop environment with applications like MPV and LibreWolf and securely create a default user. To do this, we need to create a new OCI image based on this one.

```dockerfile
ARG FREEBSD_RELEASE=15.1
ARG X11_FLAVOR=xlibre

FROM ghcr.io/appjail-makejails/xrdp:${FREEBSD_RELEASE}-${X11_FLAVOR}

RUN pkg install dbus xfce FreeBSD-bsdconfig

RUN sysrc dbus_enable=YES && \
    echo -e "#!/bin/sh\nexec startxfce4" > /usr/local/etc/xrdp/startwm.sh && \
    chmod 555 /usr/local/etc/xrdp/startwm.sh

#
# Equivalent to 'xrdp' but encrypted using 'openssl passwd -6 "your_password"':
#
ARG XRDP_PASSWORD='$6$bMwoY8o3fpGxiztV$.8rp68XsHpUTFmil1S/VYNInq6YMPEqqsetQVTZryVJiKQ0NzDrIjPekq2aKax7OyUFuj.YydjbbkAU6W1xJu.'

RUN umask 0022; \
    \
    echo "${XRDP_PASSWORD}" | \
        pw useradd -m -H 0 -n xrdp
```

Profit!

```console
$ buildah build --network=host -t my-xrdp .
```

Deployment is the same as before, you just need to change the address.

```console
$ appjail oci run -Pd \
    -o template=template.conf \
    -o overwrite=force \
    -o virtualnet=":<random> default" \
    -o nat \
    localhost/my-xrdp xrdp
```

**Note**: If you plan to use a volume (using the `-o fstab` option), keep in mind that `<pseudofs>` will not copy the file from the jail to the host if it already exists on the host; therefore, if you had previously created an Xrdp container, you will continue to use the old `startwm.sh` (which runs `xterm`). Remove `startwm.sh` from your volume, and then add `-o fstab` to preserve the data and ensure the changes take effect.

### Arguments (stage: build)

* `xrdp_from` (default: `ghcr.io/appjail-makejails/xrdp`): Location of OCI image. See also [OCI Configuration](#oci-configuration).
* `xrdp_tag` (default: `latest`): OCI image tag. See also [OCI Configuration](#oci-configuration).

### Environment (OCI image)

* `PGID` (default: `1000`): Equivalent to `PUID` but for the Process Group ID.
* `PUID` (default: `1000`): Process User ID for the container's main process, allowing you to match the owner of files written to mounted host volumes to your host system's user. Writable volumes are changed based on this environment variable.

### Volumes

| Name | Owner | Group | Perm | Type | Mountpoint |
| --- | --- | --- | --- | --- | --- |
| appjail-bbd5824147-usr_local_etc_xrdp | `${PUID}` | `${PGID}` | - | - | /usr/local/etc/xrdp |

## OCI Configuration

```yaml
build:
  variants:
    - tag: 15.1-xlibre
      containerfile: Containerfile
      aliases: ["latest"]
      default: true
      args:
        FREEBSD_RELEASE: "15.1"
        X11_FLAVOR: xlibre
        PYVER: "312"
        NO_PKGCLEAN: "1"
      cache_dirs: ["pkgcache0:/var/cache/pkg"]
    - tag: 15.1-xorg
      containerfile: Containerfile
      args:
        FREEBSD_RELEASE: "15.1"
        X11_FLAVOR: xorg
        PYVER: "312"
        NO_PKGCLEAN: "1"
      cache_dirs: ["pkgcache0:/var/cache/pkg"]
```

## Notes

1. This image drops privileges in Xrdp. See [Running the xrdp process as non root](https://github.com/neutrinolabs/xrdp/wiki/Running-the-xrdp-process-as-non-root) for more details.
