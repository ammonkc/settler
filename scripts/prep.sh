#!/usr/bin/env bash

yum -y install kernel-headers-$(uname -r) kernel-devel-$(uname -r) gcc make perl bzip2
