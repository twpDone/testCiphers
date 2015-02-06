#!/bin/bash

ipPort=$1

#               sslv2 sslv3 tlsv1 tlsv1.1 tlsv1.2
SSL_VERSIONS="-ssl2 -ssl3 -tls1 --no_tls1_2 ''"
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

    result=$(echo "" | openssl s_client $sslversion $cipherOpt -connect $ipPort 2>/dev/null)
    if test $? -eq 0 
    then
        algo=`echo $result | egrep "Cipher\s*:" | sed -e s/".*\(Cipher\s* : [a-zA-Z0-9\-]* \).*"/"\1"/`
        proto=`echo $result | egrep "Protocol\s*:" | sed -e s/".*\(Protocol\s*: [A-Za-z0-9\.\-]*\).*"/"\1"/`
        echo "Accepting "$proto", "$algo
    fi
}
testSSL2(){
    ipPort=$1
    echo "Checking SSLv2 support"
        cipher $ipPort -ssl2 
    echo""
}


testSSL3(){
    ipPort=$1
    echo "Checking SSLv3 support"
        cipher $ipPort -ssl3 
    echo""
}

testTSLv1.0(){
    ipPort=$1
    echo "Checking TSLv1.0 support"
        cipher $ipPort -tls1
    echo""
}

testTSLv1.1(){
    ipPort=$1
    echo "Checking TSLv1.1 support"
        cipher $ipPort -no_tls1_2
    echo""
}

testTSLv1.2(){
    ipPort=$1
    echo "Checking TSLv1.2 support"
        for algo in `echo $AVAILIABLE_CIPHERS`
        do
            #echo $algo
            cipher $ipPort '' $algo
        done
    echo""
}

testSSL2 $ipPort
testSSL3 $ipPort
testTSLv1.0 $ipPort
testTSLv1.1 $ipPort
testTSLv1.2 $ipPort

#echo "[-ssl2] [-ssl3] [-tls1] [-no_ssl2] [-no_ssl3] [-no_tls1] [-no_tls1_1] [-no_tls1_2]"
#read ssl
#
#echo ""
#echo "EXP-RC4-MD5"
#read mcipher
#
#cipher $ipPort $ssl $mcipher

