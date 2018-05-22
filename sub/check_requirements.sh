#!/bin/bash


for i in "$@"
do
case $i in
	-B=*|--bowtie=*)
        bowtie="${i#*=}"
        shift # past argument with a value
	;;
	-E=*|--email=*)
        email="${i#*=}"
        shift # past argument with a value
        ;;
	-D=*|--disable_email=*)
	disable_email="${i#*=}"
	shift # past argument with a value
	;;
	-V=*|--version=*)
        version="${i#*=}"
        shift # past argument with a value
        ;;
	-N=*|--screenname=*)
        screenname="${i#*=}"
        shift # past argument with a value
        ;;
	*)
	;; # For any unknoqn options
esac
done

# Check if Bowtie is installed
printf "\tChecking Bowtie: $bowtie... "
if [ -f $bowtie ]; then printf "found\n"; else printf "not found\n" && exit 1;fi

# Check if pv is installed
printf "\tChecking pv: ...."
hash pv
if [ "$?" -eq 0 ]; then printf "found\n"; else printf "not found\n" && exit 1; fi

# Check if curl is installed
printf "\tChecking curl..."
hash curl
if [ "$?" -eq 0 ]; then printf "found\n"; else printf "not found\n" && exit 1; fi

# Check internet connection by connecting to Google
nointernet=0
curl www.google.coom -s -f -o /dev/null
if [ "$?" -eq 0 ]; then
  printf "Bummer. You Internet connection seems to be down. It will not be possible to send status updates, logs and errors to your mail address and cannot check for updates.\n Do want to continue [y|n]?"
  read continue
  nointernet=1
  if [[ $continue != "y" ]]; then exit 1; fi
fi

if [[ "$nointernet" -eq 0 ]] && [[ $disable_email != "yes" ]]; then
  # Check if sendmail is correcly configured
  printf "\tChecking sendmail ..."
  hash sendmail
  if [ "$?" -eq 0 ]; then	printf "found "; else printf "not found\n" && exit 1; fi
  me=$(whoami)
  echo -e "Email test\n\n" "Its working" | sendmail e.stickel@nki.nl
  if [ "$?" -eq 0 ]; then printf "and correctly configured\n"; else printf "but not properly configured" && exit 1; fi
else
  printf "\tSkipping sendmail test due to parameters in settings.conf\n"
fi

# Check pigz
printf "\tChecking pigz: ...."
hash pigz
if [ "$?" -eq 0 ]; then printf "found\n"; else printf "not found\n\tContinuing with gzip instead of pigz. Please consider installig pigz for better performance\n."; fi

# Check bedtools
printf "\tChecking bedtools: ...."
hash bedtools
if [ "$?" -eq 0 ]; then printf "found\n"; else printf "not found\n" && exit 1; fi

# Check Rscript
printf "\tChecking Rscript: ...."
hash Rscript
if [ "$?" -eq 0 ]; then printf "found\n"; else printf "not found\n" && exit 1; fi

# Check Python
printf "\tChecking for Python 3.x..."
hash python3
if [ "$?" -eq 0 ]; then printf "found"; else printf "not found\n" && exit 1; fi
python3 sub/check_python_version.py
if [ "$?" -eq 0 ]; then printf " and correct version\n"; else printf " but wrong version\n" && exit 1; fi

# Check Pandas
printf "\tChecking whether pandas is installed system-wide..."
python -c "import pandas"
if [ "$?" -eq 0 ]; then printf "found\n"; else printf "not found\n" && exit 1; fi

# Check Numpy
printf "\tChecking whether numpy is installed system-wide..."
python -c "import numpy"
if [ "$?" -eq 0 ]; then printf "found\n"; else printf "not found\n" && exit 1; fi

# Checking version
if [[ "$nointernet" -eq 0 ]]; then
  printf "\tChecking for pipeline updates... "
  ip=$(curl -s checkip.dyndns.org | sed -e 's/.*Current IP Address: //' -e 's/<.*$//')
  host=$(hostname)
  info="name=$screenname&hostname=$host&ipaddr=$ip&user=$me&type=IPS&version=$version&status=started"
  curl -d $info https://elmerstickel.org/bioinformatics/pipeline_init.php --silent > /tmp/curltmp && rm /tmp/curltmp
  if [ "$?" -ne 0 ]; then
    printf "update server unavailable\n"
  else
    latest=$(curl https://elmerstickel.org/bioinformatics/ips_pipeline_latest.txt --silent)
    if [ "$?" -eq 0 ]; then
      if [[ $version != $latest ]]; then printf "new version ($latest) available\n\t\tPlease contact elmer.stickel@posteo.net to obtain it\n."; else printf "up-to-date\n"; fi
    else
      printf "no info available\n"
    fi
  fi
fi
