BEGIN {
	FS="\t"
}
{
	Gene=$1
	High=$2
	HT=$3
	Low=$4
	LT=$5
	Pv=$6
	FCPv=$7
	if (Low == 0) {
		LC=1;
		LTC=LT-1;
	}
	else {
		LC=Low;
		LTC=LT;
	}
	if (High == 0) {
		HC=1;
		HTC=HT-1;
	}
	else {
		HC=High;
		HTC=HT;
	}
	Insertions=LC+HC
	MI=((HC/HTC)/(LC/LTC))
	print ","Gene","Low","LT","High","HT","Pv","FCPv","LC","LTC","HC","HTC","MI","Insertions
}
