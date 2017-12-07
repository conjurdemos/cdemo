# docker-hsm

![](https://media.giphy.com/media/IrWD6XLtH5jaw/giphy.gif)

A simple `Dockerfile` that wraps [SoftHSM](https://www.opendnssec.org/softhsm/) using [PKCS11-Proxy](https://github.com/SUNET/pkcs11-proxy) in order
to help test software that interacts with network connected HSMs (and move
signing completely out of process when using SoftHSM locally). Requires
the PKCS11-proxy module to communicate. 

The Slot 0 PIN is set to `1234` and the SO PIN is `0000`. Port `5657` is exposed for
PKCS11 communication. `key.pem` should be replaced with something actually useful
before building the Docker image.

```
# build/run the container
$ docker build -t some-unique-name .
...
$ docker run some-unique-name
...

$ PKCS11_PROXY_SOCKET="tcp://172.17.0.2:5657" pkcs11-tool --module=/usr/lib/libpkcs11-proxy.so  -L Available
Available slots:
Slot 0 (0x0): SoftHSM
  token label        : key
  token manufacturer : SoftHSM
  token model        : SoftHSM
  token flags        : rng, login required, PIN initialized, token initialized, other flags=0x40
  hardware version   : 1.3
  firmware version   : 1.3
  serial num         : 1
```

**This is not safe. It will not protect your keys. Don't use it for real things.**

