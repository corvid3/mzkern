#!/bin/bash

qemu-system-x86_64 -M q35 -m 2G -cdrom mzkern.iso -boot d -vga std
