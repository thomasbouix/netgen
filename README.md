# NetGen
Neural Network Framework for Zynq7 SoC

# Developer's Guide

## Adding a new HDL IP
```
- ips/Makefile          : add the IP in the "all" and "clean" rules
- ip/Makefile           : change IP's name
- ip/script/ip_packager : change IP's name
- ip/src                : change hdl file's name
- ip/tb                 : change test bench's name
```

## IP packaging
To package all the IP inside the framework
```
$ make ips
```

## Vivado project
Project configuration, synthesis and implementation inside the vivado/ directory
```
$ make vivado
```

## Vitis project
Project configuration inside the vitis/ directory
```
$ make vitis
```

# User's Guide


