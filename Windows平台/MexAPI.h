#pragma once
#include <Mex工具.h>

//SHFileOperation

#ifdef CopyFile
#undef CopyFile
#endif
API声明(CopyFile);
API声明(Delete);
#ifdef MoveFile
#undef MoveFile
#endif
API声明(MoveFile);

//LibZip

API声明(ZipOpen);
API声明(ZipNameLocate);
API声明(ZipFopen);
API声明(ZipFread);
API声明(ZipFclose);
API声明(ZipDiscard);
API声明(ZipGetName);
API声明(ZipGetNumEntries);