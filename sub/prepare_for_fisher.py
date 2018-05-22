from collections import Counter
import sys 
import numpy as np
import pandas
from pandas import *
 
LO = sys.argv[1]
HI = sys.argv[2]
OUT = sys.argv[3]
ARR = [LO,HI]
DICT = {name: 0 for name in ARR}

for x in LO,HI:
	sense_ = open(x)
	name = (x[0:x.find('.')]) 
	data = [] 
	#define a list 'all_insertions' and append all genes to the list
	all_insertions_in_genes = []
	for insertion in sense_:
		splitinsertion = insertion.rstrip("\n").split("\t")
		gene = splitinsertion[3]
		all_insertions_in_genes.append(gene)

	#use Counter to make a dictionary of counts per gene
	output_ = Counter(all_insertions_in_genes)
	total_ = sum(output_.values())

	#print dictionary in neat format
	for genename in output_:
		data.append([genename, output_[genename], total_-output_[genename], total_])      		
	DICT[x] = pandas.DataFrame(data)	
	
DICT[LO] 


# read totals of lo and hi channel
sum_lo = DICT[LO].iloc[3][3]
sum_hi = DICT[HI].iloc[3][3]

# join based on gene name 
merged = merge(DICT[HI], DICT[LO], left_on=0, right_on=0, how='outer')

# replace NaN with 0 and totals
merged[['1_x', '1_y']] = merged[['1_x', '1_y']].fillna(0)
merged['2_x'] = merged['2_x'].fillna(sum_hi)
merged['2_y'] = merged['2_y'].fillna(sum_lo)

# put  columns type to integers for columsn containing values 
merged[['1_x', '2_x', '1_y', '2_y']] = merged[['1_x', '2_x', '1_y', '2_y']].astype(int)

# write to output file
merged.to_csv(OUT, sep='\t', header = None, index=False, columns=(0,'1_x','2_x', '1_y', '2_y'))
