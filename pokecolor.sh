#!/bin/bash

TARGET_MAC="98:41:5C:86:62:4E"
echo "PokeColorMix.py Start"
sudo joycontrol-pluginloader -r "$TARGET_MAC" /home/kiikun0530/joycontrol-pluginloader/plugins/samples/PokeColorMix.py
