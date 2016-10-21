cd /data/grassdata/

for i in {1..20}
do
	zip -r g$i.zip g$i
done

zip g_mapsets.zip g*.zip