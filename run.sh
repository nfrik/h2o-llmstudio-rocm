#!/bin/bash

docker run -it --device=/dev/kfd --device=/dev/dri --group-add video --shm-size=64g h2ollm-rocm1 /bin/bash
