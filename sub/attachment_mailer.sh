#!/bin/bash

for i in "$@"
do
case $i in
        -M=*|--mailto=*)
        MAILTO="${i#*=}"
        shift # past argument with a value
        ;;
        -S=*|--subject=*)
        SUBJECT="${i#*=}"
        shift # past argument with a value
        ;;
        -C=*|--content=*)
        BODY="${i#*=}"
        shift # past argument with a value
        ;;
        -A=*|--attachment=*)
        ATTACH="${i#*=}"
        shift # past argument with a value
        ;;
        *)
        ;; # For any unknoqn options
esac
done

(
 echo "To: $MAILTO"
 echo "Subject: $SUBJECT"
 echo "MIME-Version: 1.0"
 echo 'Content-Type: multipart/mixed; boundary="-q1w2e3r4t5"'
 echo
 echo '---q1w2e3r4t5'
 echo "Content-Type: text/html"
 echo "Content-Disposition: inline"
 cat $BODY
 echo '---q1w2e3r4t5'
 echo 'Content-Type: application; name="'$(basename $ATTACH)'"'
 echo "Content-Transfer-Encoding: base64"
 echo 'Content-Disposition: attachment; filename="'$(basename $ATTACH)'"'
 uuencode --base64 $ATTACH $(basename $ATTACH)
 echo '---q1w2e3r4t5--'
) | /usr/sbin/sendmail $MAILTO
