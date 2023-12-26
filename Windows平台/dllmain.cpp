// dllmain.cpp : 定义 DLL 应用程序的入口点。
#include "pch.h"
HMODULE Module;
BOOL APIENTRY DllMain( HMODULE hModule,
					   DWORD  ul_reason_for_call,
					   LPVOID lpReserved
					 )
{
	Module = hModule;
	return TRUE;
}