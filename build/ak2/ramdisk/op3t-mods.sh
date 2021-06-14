#!/system/bin/bash

# change input device
if ! grep -q "event2" "/system/comma/home/.bash_profile"; then
   mount -o rw,remount /system
   sed "s|event1|event2|g" "/system/comma/home/.bash_profile"
   sed -i "s|event1|event2|g" "/system/comma/home/.bash_profile"
   mount -o ro,remount /system
 fi