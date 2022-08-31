classdef LibzipException<uint8
	enumeration
		ZIP_ER_OK(0)%No error
		ZIP_ER_MULTIDISK(1)%Multi-disk zip archives not supported
		ZIP_ER_RENAME(2)%Renaming temporary file failed
		ZIP_ER_CLOSE(3)%Closing zip archive failed
		ZIP_ER_SEEK(4)%Seek error
		ZIP_ER_READ(5)%Read error
		ZIP_ER_WRITE(6)%Write error
		ZIP_ER_CRC(7)%CRC error
		ZIP_ER_ZIPCLOSED(8)%Containing zip archive was closed
		ZIP_ER_NOENT(9)%No such file
		ZIP_ER_EXISTS(10)%File already exists
		ZIP_ER_OPEN(11)%Can't open file
		ZIP_ER_TMPOPEN(12)%Failure to create temporary file
		ZIP_ER_ZLIB(13)%Zlib error
		ZIP_ER_MEMORY(14)%Malloc failure
		ZIP_ER_CHANGED(15)%Entry has been changed
		ZIP_ER_COMPNOTSUPP(16)%Compression method not supported
		ZIP_ER_EOF(17)%Premature end of file
		ZIP_ER_INVAL(18)%Invalid argument
		ZIP_ER_NOZIP(19)%Not a zip archive
		ZIP_ER_INTERNAL(20)%Internal error
		ZIP_ER_INCONS(21)%Zip archive inconsistent
		ZIP_ER_REMOVE(22)%Can't remove file
		ZIP_ER_DELETED(23)%Entry has been deleted
		ZIP_ER_ENCRNOTSUPP(24)%Encryption method not supported
		ZIP_ER_RDONLY(25)%Read-only archive
		ZIP_ER_NOPASSWD(26)%No password provided
		ZIP_ER_WRONGPASSWD(27)%Wrong password provided
		ZIP_ER_OPNOTSUPP(28)%Operation not supported
		ZIP_ER_INUSE(29)%Resource still in use
		ZIP_ER_TELL(30)%Tell error
		ZIP_ER_COMPRESSED_DATA(31)%Compressed data invalid
		ZIP_ER_CANCELLED(32)%Operation cancelled
	end
end