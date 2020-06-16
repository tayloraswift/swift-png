rm -r rgba
mkdir png-rgba ;
mkdir rgba ;
cd png ;
for file in *.png ;
do
    cd ..
    convert -depth 16 -define png:color-type=6 "png:png/${file}" "png:png-rgba/${file}" ;
    convert -depth 16 "png:png-rgba/${file}" "rgba:rgba/${file}.rgba" ;
    cd png
done ;
cd .. ;

rm -r png-rgba ;
