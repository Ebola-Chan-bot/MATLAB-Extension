// dllmain.h: 模块类的声明。

class CIconHandlerModule : public ATL::CAtlDllModuleT< CIconHandlerModule >
{
public :
	DECLARE_LIBID(LIBID_IconHandlerLib)
	DECLARE_REGISTRY_APPID_RESOURCEID(IDR_ICONHANDLER, "{ca2e03cb-83ba-40e6-bf6f-48d7463abff4}")
};

extern class CIconHandlerModule _AtlModule;
