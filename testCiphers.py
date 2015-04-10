#!/usr/bin/python2.7

"""

    This aims to test cipher support with a simple ssl socket
    It's sightly quicker than the s_client 

    Todo :
        * Add timing option
        * Add selecting SSL/TLS version
        * Interactive version ? 
        * Add Cipher Strength selection 
        * Add option to display only positive matches

"""

import sys, socket, ssl, subprocess

proto={}
cipherStrength=["LOW","EXP","NULL"]
#cipherStrength=["HIGH"]
verbose=False

try:
    ip=sys.argv[1]
    port=sys.argv[2]
    
    print("--- ARGS ---")
    print("")
    print(" IP : "+ip)
    print(" PORT : "+port)
    print("")
    print("-----")
    print("")

except:
    print("Error in args")
    print("$1 should be ip or domain name")
    print("$2 sould be a port number")
    exit(1)

try:
    proto[ssl.PROTOCOL_SSLv2]="ssl.PROTOCOL_SSLv2"
except:
    print("[-] Forcing SSLv2 not supported")
try:
    proto[ssl.PROTOCOL_SSLv3]="ssl.PROTOCOL_SSLv3"
except:
    print("[-] Forcing SSLv3 not supported")
try:
    proto[ssl.PROTOCOL_SSLv23]="ssl.PROTOCOL_SSLv23"
except:
    print("[-] Forcing SSLv23 not supported")
try:
    proto[ssl.PROTOCOL_TLSv1]="ssl.PROTOCOL_TLSv1"
except:
    print("[-] Forcing TLSv1 not supported")
try:
    proto[ssl.PROTOCOL_TLSv1_1]="ssl.PROTOCOL_TLSv1_1"
except:
    print("[-] Forcing TLS1.1 not supported")
try:
    proto[ssl.PROTOCOL_TLSv1_2]="ssl.PROTOCOL_TLSv1_2"
except:
    print("[-] Forcing TLS1.2 not supported")

print("Starting scan :")

for p in proto:
    print("Testing "+proto[p]+"("+str(p)+"):")
    for strength in cipherStrength:
        Hciphers = subprocess.check_output(["openssl","ciphers",strength]).replace("\n","").split(":")
        print(" [ ] Testing openssl ciphers "+strength)
        for c in Hciphers:
            s=socket.socket()
            ss=ssl.SSLSocket(s,ssl_version=p,ciphers=c)
            try:
                ss.connect((ip,int(port)))
                print("  [+] "+c)
            except Exception as ex:
                if verbose:
                    print("  [-] "+c)
            ss.close()
            s.close()
    print("")

