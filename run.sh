for i in {1..20}
do

	cd /data/grassdata/
	rm -r g$i
	cp -r generate_template/ g$i

	cd /data/kata/bin/
	rm /data/kata/bin/data/* 

	bash generate.sh $i

done