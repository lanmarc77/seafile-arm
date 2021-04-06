Seafile server package for Raspberry Pi. Maintained by seafile community.

## Download

- The latest **stable** rpi version is [here](https://github.com/haiwen/seafile-rpi/releases/latest).

## Build
For Seafile versions which use Python 3. Seafile versions higher than 7.0.

E.g. to compile Seafile server v8.0.3:
```
$ wget https://raw.githubusercontent.com/haiwen/seafile-rpi/master/build3.sh
$ chmod u+x build3.sh
$ ./build3.sh 8.0.3
```
Schema of created directory structure
```
seafile@rpi-bionic:~$ ll
-rwxr--r-- 1 seafile seafile 7391 May 20 21:44 build3.sh
drwxr-xr-x 1 seafile seafile   60 May 20 21:18 built-seafile-server-pkgs
drwxr-xr-x 1 seafile seafile  214 May 20 21:14 built-seafile-sources
drwxr-xr-x 1 seafile seafile  160 May 20 21:14 haiwen-build
.
├── built-seafile-server-pkgs
├── built-seafile-sources
└── haiwen-build
    ├── ccnet-server
    ├── libevhtp
    ├── libsearpc
    ├── seafdav
    ├── seafile-server
    ├── seafobj
    ├── seahub
    └── seahub_thirdparty
```

For Seafile versions which use Python 2. Seafile versions lower than 7.1, e.g. v7.0.5:
```
$ git clone https://github.com/haiwen/seafile-rpi.git
$ cd seafile-rpi
$ sudo ./build.sh
```

## Manual and Guides

- [Build Seafile server](https://manual.seafile.com/build_seafile/rpi/)
- [Deploy Seafile server](https://manual.seafile.com/deploy/)

## Reporting Issues / GitHub Issues

If you have any problems or suggestions when using the seafile rpi server package, please report it on [seafile server forum](https://forum.seafile.com/). 

**GitHub Issues support is dropped** and will not  be maintained anymore. If you need help, clarification or report some weird behaviour, please post it on the [seafile server forum](https://forum.seafile.com/) as well.

## Contributors

See [CONTRIBUTORS](CONTRIBUTORS).
