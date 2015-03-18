#!/bin/bash

usage(){
    echo ""
    echo -n "Usage :"$0
    tput setf 1 ; echo -n " IP:port" ;
    tput setf 6 ; echo " [protocol]";
    tput setf 9; 
    echo ""
    echo -n "Values for the "; tput setf 6; echo -n "protocol"; tput setf 9; echo " option are :"
    echo "-tls (TLS Only)" 
    echo "-ssl (SSL ONLY)" 
    echo ""
    echo -n "If "; tput setf 6; echo -n "protocol"; tput setf 9; echo " is absent both (tls and ssl) will be checked"
    echo ""
}

if test $# -eq 0
then
    usage
    exit 1
else
    if test "$1" = "-h"
    then
        usage
        exit 1
    fi
    if test "$1" = "--help"
    then
        usage
        exit 1
    fi
    case $1 in
        *:*) ;; # correct syntax IP:port
        *) echo ""; tput setf 4 ; echo "Incorrect syntax for arg1"; tput setf 9 ; usage; exit 1 ;;
    esac
fi

ipPort=$1
protocol="ALL"

case "$2" in
    "-tls") protocol="tlsOnly" ;;
    "-ssl") protocol="sslOnly" ;;
    "") ;;
    *) echo "Wrong value for protocol option"
        usage 
        exit 1
        ;;
esac

echo "[set] -protocol "$protocol
echo ""
    

#               sslv2 sslv3 tlsv1 tlsv1.1 tlsv1.2
#SSL_VERSIONS="-ssl2 -ssl3 -tls1 --no_tls1_2 ''"
AVAILIABLE_CIPHERS=`openssl ciphers | sed s/':'/' '/g`

cipher(){
    ipPort=$1
    sslversion=$2
    cipher=$3

    sslversionOpt=""
    cipherOpt=""

    if test -n "$sslversion"
    then
        sslversionOpt=$sslversion
        #[-ssl2] [-ssl3] [-tls1] [-no_ssl2] [-no_ssl3] [-no_tls1] [-no_tls1_1] [-no_tls1_2]
    fi

    if test -n "$cipher"
    then
        cipherOpt="-cipher "$cipher
    fi

    result=$(echo "" | openssl s_client $sslversion $cipherOpt -connect "$ipPort" 2>/dev/null)
    if test $? -eq 0 
    then
        algo=`echo $result | egrep "Cipher\s*:" | sed -e s/".*\(Cipher\s* : [a-zA-Z0-9\-]* \).*"/"\1"/`
        proto=`echo $result | egrep "Protocol\s*:" | sed -e s/".*\(Protocol\s*: [A-Za-z0-9\.\-]*\).*"/"\1"/`
        echo "Accepting "$proto", "$algo
    fi
}

checkCipherFromList(){
    ipPort=$1
    cipherList=$2
    sslVersionOption=$3
    for algo in `echo $cipherList`
    do
        cipher $ipPort "$sslVersionOption" $algo 
    done
}

getSSLVersionOption(){
    algorithm=$1
    algoVersion=$2
    if test "$algorithm" = "ssl"
    then
        case "$algoVersion" in
            "2") #echo "-ssl2"
                 #exit 0
                echo "SSLv2 NOT SUPPORTED ! The openssl s_client option is supposed to be -ssl2, but openssl returns 'unknown option -ssl2'"
                exit 128
                ;;
            "3") echo "-ssl3"
                exit 0
                ;;
            *) echo $algorithm"v"$algoVersion" doesn't exist."
                exit 127
                ;;
        esac
    fi 
    if test "$algorithm" = "tls"
    then
        case "$algoVersion" in
            "1.0") echo "-tls1"
                exit 0
                ;;
            "1.1") echo "-no_tls1_2"
                exit 0
                ;;
            "1.2") echo ""
                exit 0
                ;;
            *) echo $algorithm"v"$algoVersion" doesn't exist."
                exit 127
                ;;
        esac
    else
        echo $algorithm" doesn't exist."
        exit 127
    fi 

}

cipherTest(){
    ipPort=$1
    algo=$2
    algoVersion=$3
    opensslOptionSSLVersion=`getSSLVersionOption "$2" "$3"`
    ret=$?
    if test "$ret" -ne 0
    then
        echo "Error ("$ret"): " $opensslOptionSSLVersion
        #exit $ret
    fi
    echo "Checking "$algo"v"$algoVersion" support"
    checkCipherFromList "$ipPort" "$AVAILIABLE_CIPHERS" "$opensslOptionSSLVersion"
    echo""
}

if test $protocol = "sslOnly" -o $protocol = "ALL"
then
    tput setf 4;
    echo "----"
    echo "SSLv2 Wont work now due to a handling arguments problem in 'openssl s_client'"
    cipherTest $ipPort "ssl" 2
    echo "----"
    echo ""
    tput setf 9;
    cipherTest $ipPort "ssl" 3
fi

if test $protocol = "tlsOnly" -o $protocol = "ALL" 
then
    cipherTest $ipPort "tls" "1.0"
    cipherTest $ipPort "tls" "1.1"
    cipherTest $ipPort "tls" "1.2"
fi

