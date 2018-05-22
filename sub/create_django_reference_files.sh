#!/bin/bash
tagcountref=$1
printf "id,name,chromosome,orientation,description\n" > for_django_gene_ref_$1.csv
sort -u -k4,4 $tagcountref | awk '{print ","$4","substr($1,4)","$6","}' >> for_django_gene_ref_$1.csv
printf "id,relgenename,startpos,endpos\n" > for_django_location_ref$1.csv
cat $tagcountref | sort | awk '{print ","$4","$2","$3}' >> for_django_location_ref$1.csv
