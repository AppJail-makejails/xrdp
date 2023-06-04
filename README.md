# Xrdp

Xrdp is a free and open-source implementation of Microsoft RDP (Remote Desktop Protocol) other than Microsoft Windows (such as Linux and BSD-style operating systems) to provide a fully functional RDP-compatible remote desktop experience.

wikipedia.org/wiki/Xrdp

<img src="https://upload.wikimedia.org/wikipedia/commons/thumb/e/ec/Xrdp_logo.svg/1920px-Xrdp_logo.svg.png" alt="xrdp logo" width="40%" height="auto">

## How to use this Makejail

```
INCLUDE options/network.makejail
INCLUDE gh+AppJail-makejails/xrdp

OPTION expose=3389
OPTION template=files/xrdp.conf

CMD pw useradd -n op -m
CMD passwd op
```

Where `options/network.makejail` are the options that suit your environment, for example:

```
ARG network
ARG interface=xrdp

OPTION virtualnet=${network}:${interface} default
OPTION nat
```

The `files/xrdp.conf` template is as follows:

```
exec.start: "/bin/sh /etc/rc"
exec.stop: "/bin/sh /etc/rc.shutdown jail"
mount.devfs
sysvmsg: new
sysvsem: new
sysvshm: new
```

Open a shell and run `appjail makejail`:

```
appjail makejail -j xrdp -- --network home
```
