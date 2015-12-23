#!/usr/bin/env python

# Based on a script from https://santoku-linux.com/howto/mobile-forensics/how-to-brute-force-android-encryption
#
# Decrypts the master key found in the footer using a supplied password
# Written for Nexus 4 running 4.4.2
#
# How to get header & footer:
# dd if=/dev/block/mmcblk0p18 of=my_footer bs=512 count=32
# dd if=/dev/block/mmcblk0p23 of=my_header bs=512 count=1
#

from os import path
import sys, itertools
import time
from struct import Struct
from M2Crypto import EVP
import hashlib
import scrypt

_PARAMS = Struct("!BBBB")

KEY_LEN_BYTES = 16
IV_LEN_BYTES  = 16


def main(args):

	if len(args) < 3:
		print 'Usage: python bruteforce_stdcrypto.py [header file] [footer file]'
		print ''
		print '[] = Mandatory'
	else:
		footerFile    = args[2]
		headerFile    = args[1]

		assert path.isfile(footerFile), "Footer file '%s' not found." % footerFile
		assert path.isfile(headerFile), "Header file '%s' not found." % headerFile
		fileSize = path.getsize(footerFile)
		assert (fileSize >= 16384), "Input file '%s' must be at least 16384 bytes" % footerFile
		
		
		result = bruteforcePIN(headerFile, footerFile)

		if result: 
			print 'Correct PIN!: ' + result
		else:
			print 'Wrong PIN. :('
			
def bruteforcePIN(headerFile, footerFile):
	# retrive the key and salt from the footer file
	cryptoKey,cryptoSalt = getCryptoData(footerFile)

	# load the header data for testing the password
	headerData = open(headerFile, 'rb').read(32)

	passwdTry = raw_input('Enter password: ')
	print 'Trying: ',passwdTry 

	# make the decryption key from the password
	decKey = decryptDecodeKey(cryptoKey,cryptoSalt,passwdTry)
		
	# try to decrypt the first 32 bytes of the header data (we don't need the iv)
	decData = decryptData(decKey,"",headerData)
		
	# has the test worked?
	#print decData
	if decData[16:32] == "\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0":
		return passwdTry
			
	return None


def getCryptoData(filename):
	data = open(filename, 'rb').read()
	
	# structure taken from cryptfs.h in 4.4.2_r1 source.
	s = Struct('<'+'L H H L L L L L L L 64s L 48s 16s Q Q L B B B B')
	ftrMagic, majorVersion, minorVersion, ftrSize, flags, keySize, spare1, fsSize1, fsSize2, failedDecrypt, cryptoType, spare2, cryptoKey, cryptoSalt, persistoff0, persistoff1, persistsize, kdfType, N_factor, r_factor, p_factor = s.unpack(data[0:192])

	cryptoKey = cryptoKey[0:0+keySize]

	print 'Footer File    :', filename;
	print 'Magic          :', "0x%0.8X" % ftrMagic
	print 'Major Version  :', majorVersion
	print 'Minor Version  :', minorVersion
	print 'Footer Size    :', ftrSize, "bytes"
	print 'Flags          :', "0x%0.8X" % flags
	print 'Key Size       :', keySize * 8, "bits"
	print 'FS Size 1      :', fsSize1
	print 'FS Size 2      :', fsSize2
	print 'Failed Decrypts:', failedDecrypt
	print 'Crypto Type    :', cryptoType.rstrip("\0")
	print 'Encrypted Key  :', "0x" + cryptoKey.encode("hex").upper()
	print 'Salt           :', "0x" + cryptoSalt.encode("hex").upper()
	print 'KDF type       :', kdfType
	print 'N-factor       :', N_factor
	print 'r-factor       :', r_factor
	print 'p-factor       :', p_factor
	print '----------------'

	return cryptoKey,cryptoSalt

def decryptDecodeKey(cryptoKey,cryptoSalt,password):
	# make the key from the password
	ikey = scrypt.hash(password,cryptoSalt,1<<15,1<<3,1<<1, 32)

	key = ikey[:KEY_LEN_BYTES]
	iv = ikey[KEY_LEN_BYTES:]
	
	# do the decrypt
	cipher = EVP.Cipher(alg='aes_128_cbc', key=key, iv=iv, op=0) # 0 is DEC
	cipher.set_padding(padding=0)
	decKey = cipher.update(cryptoKey)
	decKey = decKey + cipher.final()
	
	return decKey

def decryptData(decKey,essiv,data):
	# try to decrypt the actual data 
	cipher = EVP.Cipher(alg='aes_128_cbc', key=decKey, iv=essiv, op=0) # 0 is DEC
	cipher.set_padding(padding=0)
	decData = cipher.update(data)
	decData = decData + cipher.final()
	return decData

if __name__ == "__main__": 
    main(sys.argv)
