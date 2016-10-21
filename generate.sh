export GISBASE=/usr/lib/grass70
 
export GRASS_VERSION="7.0"
 
#generate GISRCRC
MYGISDBASE=/data/grassdata/
MYLOC=g$1
MYMAPSET=PERMANENT
 
# Set the global grassrc file to individual file name
MYGISRC="$HOME/.grassrc.$GRASS_VERSION.$$"
 
echo "GISDBASE: $MYGISDBASE" > "$MYGISRC"
echo "LOCATION_NAME: $MYLOC" >> "$MYGISRC"
echo "MAPSET: $MYMAPSET" >> "$MYGISRC"
echo "GRASS_GUI: text" >> "$MYGISRC"
 
# path to GRASS settings file
export GISRC=$MYGISRC
export GRASS_PYTHON=python
export GRASS_MESSAGE_FORMAT=plain
export GRASS_TRUECOLOR=TRUE
export GRASS_TRANSPARENT=TRUE
export GRASS_PNG_AUTO_WRITE=TRUE
export GRASS_GNUPLOT='gnuplot -persist'
export GRASS_WIDTH=640
export GRASS_HEIGHT=480
export GRASS_HTML_BROWSER=firefox
export GRASS_PAGER=cat
export GRASS_WISH=wish
 
export PATH="$GISBASE/bin:$GISBASE/scripts:$PATH"
export LD_LIBRARY_PATH="$GISBASE/lib"
export GRASS_LD_LIBRARY_PATH="$LD_LIBRARY_PATH"
export PYTHONPATH="$GISBASE/etc/python:$PYTHONPATH"
export MANPATH=$MANPATH:$GISBASE/man


#DEM
r.surf.fractal output=demrand dimension=2.$1 --o
eval `r.univar -g demrand`
r.mapcalc "dem = demrand - $min" --o

#Reservoir
r.reclass input=dem output=reservoirpoints rules=rules.reservoir --o
r.to.vect input=reservoirpoints output=reservoirpoints type=point --o
v.out.ascii input=reservoirpoints output=data/reservoirpoints.ascii --o
sort -R data/reservoirpoints.ascii > data/reservoirpoints.ascii_sorted
head -2 data/reservoirpoints.ascii_sorted | sed 's/|/,/g' | cut -d"," -f1,2 > data/reservoirpoints.ascii_sorted_head
tr '\n' ',' < data/reservoirpoints.ascii_sorted_head > data/reservoirpoints.ascii_sorted_head2
coords=`head -c -1 data/reservoirpoints.ascii_sorted_head2`
r.cost input=dem output=reservoircost start_coordinates=$coords --o
r.reclass input=reservoircost output=reservoir rules=rules.reservoircost --o

#Reservoirs to DEM
#r.mapcalc "dem2 = dem + (reservoir * 250)" 

#Streams
r.stream.extract elevation=dem threshold=100 stream_raster=streams --o

#Buildings
r.to.vect input=streams output=streams type=point --o
v.out.ascii input=streams output=data/streams.ascii --o
sort -R data/streams.ascii > data/streams.ascii_sorted
head -10 data/streams.ascii_sorted | sed 's/|/,/g' | cut -d"," -f1,2 > data/streams.ascii_sorted_head
tr '\n' ',' < data/streams.ascii_sorted_head > data/streams.ascii_sorted_head2
coords=`head -c -1 data/streams.ascii_sorted_head2`
r.cost input=dem output=buildingscost start_coordinates=$coords --o
r.reclass input=buildingscost output=buildings rules=rules.reservoircost --o

#Roads
r.to.vect input=streams output=streams_line type=line --o
v.transform input=streams_line output=roads xshift=20 yshift=20 --o
v.generalize input=roads output=roads2 threshold=1000 method=douglas --o
v.to.rast input=roads2 output=roadsA type=line use=val --o

r.stream.extract elevation=dem threshold=1 stream_raster=streams_1 --o
r.to.vect input=streams_1 output=streams_1_line type=line --o
v.transform input=streams_1_line output=roadsB xshift=20 yshift=20 --o
v.to.rast input=roadsB output=roadsB type=line use=val --o
r.mapcalc "roadsB2 = roadsB * buildings" --o
#r.reclass input=roadsB2 output=roadsB3 rules=rules.null --o

#Roads join
r.null map=roadsA null=0
r.null map=roadsB2 null=0
r.mapcalc "roads = roadsA + roadsB2" --o

#Landuse A
r.reclass input=dem output=landuseA rules=rules.dem --o

#Landuse B
#r.reclass input=buildingscost output=landuseB rules=rules.buildingsaround --o

#Landuse C
#r.mapcalc "landuseC = landuseA + landuseB" 

r.mapcalc "landuseC = landuseA + (buildings * 10)" --o
r.reclass input=landuseC output=landuseD rules=rules.join.buildings --o
r.mapcalc "landuseE = landuseD * 1" --o

r.mapcalc "landuseC = landuseE + (roads * 10)" --o
r.reclass input=landuseC output=landuseD rules=rules.join.roads --o
r.mapcalc "landuseE = landuseD * 1" --o

r.null map=streams null=0
r.mapcalc "landuseC = landuseE + (streams * 10)" --o
r.reclass input=landuseC output=landuseD rules=rules.join.streams --o
r.mapcalc "landuseE = landuseD * 1" --o

r.mapcalc "landuseC = landuseE + (reservoir * 10)" --o
r.reclass input=landuseC output=landuseD rules=rules.join.reservoir --o
r.mapcalc "landuse = landuseD * 1" --o
r.category map=landuse rules=landuse.cats separator=:

g.remove -f type=raster name=reservoir
g.remove -f type=raster name=reservoircost
g.remove -f type=raster name=landuseA
g.remove -f type=raster name=landuseD
g.remove -f type=raster name=roadsA
g.remove -f type=raster name=roadsB
g.remove -f type=raster name=roadsB2
g.remove -f type=raster name=roads
g.remove -f type=raster name=buildings
g.remove -f type=raster name=buildingscost
g.remove -f type=raster name=demrand
g.remove -f type=raster name=streams_1
g.remove -f type=raster name=streams
g.remove -f type=raster name=reservoirpoints
g.remove -f type=vector name=streams
g.remove -f type=vector name=reservoirpoints
g.remove -f type=vector name=streams_line
g.remove -f type=vector name=roads
g.remove -f type=vector name=roads2
g.remove -f type=vector name=roadsB
g.remove -f type=vector name=streams_1_line
g.remove -f type=raster name=landuseC
g.remove -f type=raster name=landuseE