#!/bin/bash

# Install the 'ct' tool from here:
# https://github.com/coreos/container-linux-config-transpiler/releases

ct -platform vagrant-virtualbox -pretty -strict -in-file cl.conf -out-file config.ign
