#!/bin/bash

java -version

cd "$(dirname "$0")"

java -Xms1024m -Xmx1024m -cp "lib/*:plugins/GATE" \
-Dgate.home=. \
-Dgate.plugins.home=./plugins/GATE \
-Dgate.site.config=./plugins/GATE/gate.xml \
-Dgate.user.config=./plugins/GATE/gate.user.xml \
-Dgate.user.session=./plugins/GATE/gate.session \
-Djava.library.path="lib/native/macosx" \
-Xdock:name="Jigsaw" \
-Xdock:icon=jigsaw/resources/views/icon.jpg \
-Dcom.apple.macos.smallTabs=true \
-Dcom.apple.mrj.application.growbox.intrudes=false \
-Dcom.apple.mrj.application.live-resize=true \
jigsaw.Jigsaw 

exit 0

