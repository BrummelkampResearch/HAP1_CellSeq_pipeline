# Purpose: calculte fisher test, one tail test
# input: parsed data based by symbol 
# input: 4fisherTest
# output: pvalue_added.txt

args <- commandArgs(trailingOnly = TRUE)

x =read.table(args[1], header=FALSE, sep="\t")
my.results = matrix(data=NA, ncol=6, nrow=nrow(x))


for (i in 1:nrow(x) ) { 

	symbol = x[i,1]

	a <- matrix(c(x[i,2], x[i,3], x[i,4], x[i,5]),	nrow = 2, ncol = 2)

	fisher.pvalue = fisher.test(a, alternative="two.sided")$p.value 

	my.results[i,] = c(as.vector(symbol), x[i,2], x[i,3], x[i,4], x[i,5], fisher.pvalue)

}

# correct pvalue with FDR
adj <- p.adjust(as.numeric(my.results[,6]), "fdr")

# write to file
write.table(cbind(my.results,adj), file=args[2], sep="\t", quote=F, row.names=F, col.names=F)
