// IconHandlerClient.cpp: CIconHandlerClient 的实现

#include "pch.h"
#include "IconHandlerClient.h"
#include <fstream>

// CIconHandlerClient

HRESULT STDMETHODCALLTYPE CIconHandlerClient::GetClassID(
	/* [out] */ __RPC__out CLSID* pClassID)noexcept
{
	*pClassID = CLSID_IconHandlerClient;
	return S_OK;
}
HRESULT STDMETHODCALLTYPE CIconHandlerClient::IsDirty(void)noexcept
{
	return S_FALSE;
}
HRESULT STDMETHODCALLTYPE CIconHandlerClient::Load(
	/* [in] */ __RPC__in LPCOLESTR pszFileName,
	/* [in] */ DWORD dwMode)noexcept
{
	文件流 = std::ifstream(pszFileName);
	return S_OK;
}
HRESULT STDMETHODCALLTYPE CIconHandlerClient::Save(
	/* [unique][in] */ __RPC__in_opt LPCOLESTR pszFileName,
	/* [in] */ BOOL fRemember)noexcept
{
	return E_NOTIMPL;
}
HRESULT STDMETHODCALLTYPE CIconHandlerClient::SaveCompleted(
	/* [unique][in] */ __RPC__in_opt LPCOLESTR pszFileName)noexcept
{
	return E_NOTIMPL;
}
HRESULT STDMETHODCALLTYPE CIconHandlerClient::GetCurFile(
	/* [out] */ __RPC__deref_out_opt LPOLESTR* ppszFileName)noexcept
{
	return E_NOTIMPL;
}
HRESULT STDMETHODCALLTYPE CIconHandlerClient::GetIconLocation(THIS_
	UINT   uFlags,
	_Out_writes_(cchMax) PWSTR  pszIconFile,
	UINT   cchMax,
	_Out_ int* piIndex,
	_Out_ UINT* pwFlags)noexcept
{

}
HRESULT STDMETHODCALLTYPE CIconHandlerClient::Extract(THIS_
	_In_ PCWSTR  pszFile,
	UINT    nIconIndex,
	_Out_opt_ HICON* phiconLarge,
	_Out_opt_ HICON* phiconSmall,
	UINT    nIconSize)noexcept
{

}