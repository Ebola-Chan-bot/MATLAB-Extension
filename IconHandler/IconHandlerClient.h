// IconHandlerClient.h: CIconHandlerClient 的声明

#pragma once
#include "resource.h"       // 主符号



#include "IconHandler_i.h"
#include <ShlObj_core.h>
#include <fstream>


#if defined(_WIN32_WCE) && !defined(_CE_DCOM) && !defined(_CE_ALLOW_SINGLE_THREADED_OBJECTS_IN_MTA)
#error "Windows CE 平台(如不提供完全 DCOM 支持的 Windows Mobile 平台)上无法正确支持单线程 COM 对象。定义 _CE_ALLOW_SINGLE_THREADED_OBJECTS_IN_MTA 可强制 ATL 支持创建单线程 COM 对象实现并允许使用其单线程 COM 对象实现。rgs 文件中的线程模型已被设置为“Free”，原因是该模型是非 DCOM Windows CE 平台支持的唯一线程模型。"
#endif

using namespace ATL;


// CIconHandlerClient

class ATL_NO_VTABLE CIconHandlerClient :
	public CComObjectRootEx<CComSingleThreadModel>,
	public CComCoClass<CIconHandlerClient, &CLSID_IconHandlerClient>,
	public IIconHandlerClient,
	public IPersistFile,
	public IExtractIcon
{
public:
	CIconHandlerClient()
	{
	}

DECLARE_REGISTRY_RESOURCEID(106)

DECLARE_NOT_AGGREGATABLE(CIconHandlerClient)

BEGIN_COM_MAP(CIconHandlerClient)
	COM_INTERFACE_ENTRY(IIconHandlerClient)
END_COM_MAP()



	DECLARE_PROTECT_FINAL_CONSTRUCT()

	HRESULT FinalConstruct()
	{
		return S_OK;
	}

	void FinalRelease()
	{
	}

public:        
	HRESULT STDMETHODCALLTYPE GetClassID(
		/* [out] */ __RPC__out CLSID* pClassID)noexcept override;
	HRESULT STDMETHODCALLTYPE IsDirty(void)noexcept override;

	HRESULT STDMETHODCALLTYPE Load(
		/* [in] */ __RPC__in LPCOLESTR pszFileName,
		/* [in] */ DWORD dwMode)noexcept override;

	HRESULT STDMETHODCALLTYPE Save(
		/* [unique][in] */ __RPC__in_opt LPCOLESTR pszFileName,
		/* [in] */ BOOL fRemember)noexcept override;

	HRESULT STDMETHODCALLTYPE SaveCompleted(
		/* [unique][in] */ __RPC__in_opt LPCOLESTR pszFileName)noexcept override;

	HRESULT STDMETHODCALLTYPE GetCurFile(
		/* [out] */ __RPC__deref_out_opt LPOLESTR* ppszFileName)noexcept override;
	HRESULT STDMETHODCALLTYPE GetIconLocation(THIS_
		UINT   uFlags,
		_Out_writes_(cchMax) PWSTR  pszIconFile,
		UINT   cchMax,
		_Out_ int* piIndex,
		_Out_ UINT* pwFlags)noexcept override;
	HRESULT STDMETHODCALLTYPE Extract(THIS_
		_In_ PCWSTR  pszFile,
		UINT    nIconIndex,
		_Out_opt_ HICON* phiconLarge,
		_Out_opt_ HICON* phiconSmall,
		UINT    nIconSize)noexcept override;
protected:
	std::ifstream 文件流;
};

OBJECT_ENTRY_AUTO(__uuidof(IconHandlerClient), CIconHandlerClient)
