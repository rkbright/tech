java -version
java -Xms1024m -Xmx1024m -cp "lib/*;plugins/GATE" ^
-Dgate.home=. ^
-Dgate.plugins.home=./plugins/GATE ^
-Dgate.site.config=./plugins/GATE/gate.xml ^
-Dgate.user.config=./plugins/GATE/gate.user.xml ^
-Dgate.user.session=./plugins/GATE/gate.session ^
-Djava.library.path="lib/native/windows-i586" ^
jigsaw.Jigsaw