

/* this ALWAYS GENERATED file contains the definitions for the interfaces */


 /* File created by MIDL compiler version 8.01.0628 */
/* at Tue Jan 19 11:14:07 2038
 */
/* Compiler settings for IconHandler.idl:
    Oicf, W1, Zp8, env=Win64 (32b run), target_arch=AMD64 8.01.0628 
    protocol : all , ms_ext, c_ext, robust
    error checks: allocation ref bounds_check enum stub_data 
    VC __declspec() decoration level: 
         __declspec(uuid()), __declspec(selectany), __declspec(novtable)
         DECLSPEC_UUID(), MIDL_INTERFACE()
*/
/* @@MIDL_FILE_HEADING(  ) */



/* verify that the <rpcndr.h> version is high enough to compile this file*/
#ifndef __REQUIRED_RPCNDR_H_VERSION__
#define __REQUIRED_RPCNDR_H_VERSION__ 500
#endif

#include "rpc.h"
#include "rpcndr.h"

#ifndef __RPCNDR_H_VERSION__
#error this stub requires an updated version of <rpcndr.h>
#endif /* __RPCNDR_H_VERSION__ */

#ifndef COM_NO_WINDOWS_H
#include "windows.h"
#include "ole2.h"
#endif /*COM_NO_WINDOWS_H*/

#ifndef __IconHandler_i_h__
#define __IconHandler_i_h__

#if defined(_MSC_VER) && (_MSC_VER >= 1020)
#pragma once
#endif

#ifndef DECLSPEC_XFGVIRT
#if defined(_CONTROL_FLOW_GUARD_XFG)
#define DECLSPEC_XFGVIRT(base, func) __declspec(xfg_virtual(base, func))
#else
#define DECLSPEC_XFGVIRT(base, func)
#endif
#endif

/* Forward Declarations */ 

#ifndef __IIconHandlerClient_FWD_DEFINED__
#define __IIconHandlerClient_FWD_DEFINED__
typedef interface IIconHandlerClient IIconHandlerClient;

#endif 	/* __IIconHandlerClient_FWD_DEFINED__ */


#ifndef __IconHandlerClient_FWD_DEFINED__
#define __IconHandlerClient_FWD_DEFINED__

#ifdef __cplusplus
typedef class IconHandlerClient IconHandlerClient;
#else
typedef struct IconHandlerClient IconHandlerClient;
#endif /* __cplusplus */

#endif 	/* __IconHandlerClient_FWD_DEFINED__ */


/* header files for imported files */
#include "oaidl.h"
#include "ocidl.h"
#include "shobjidl.h"

#ifdef __cplusplus
extern "C"{
#endif 


#ifndef __IIconHandlerClient_INTERFACE_DEFINED__
#define __IIconHandlerClient_INTERFACE_DEFINED__

/* interface IIconHandlerClient */
/* [unique][uuid][object] */ 


EXTERN_C const IID IID_IIconHandlerClient;

#if defined(__cplusplus) && !defined(CINTERFACE)
    
    MIDL_INTERFACE("73a6ffaa-7865-4621-a6e1-cfc1afe2234a")
    IIconHandlerClient : public IUnknown
    {
    public:
    };
    
    
#else 	/* C style interface */

    typedef struct IIconHandlerClientVtbl
    {
        BEGIN_INTERFACE
        
        DECLSPEC_XFGVIRT(IUnknown, QueryInterface)
        HRESULT ( STDMETHODCALLTYPE *QueryInterface )( 
            IIconHandlerClient * This,
            /* [in] */ REFIID riid,
            /* [annotation][iid_is][out] */ 
            _COM_Outptr_  void **ppvObject);
        
        DECLSPEC_XFGVIRT(IUnknown, AddRef)
        ULONG ( STDMETHODCALLTYPE *AddRef )( 
            IIconHandlerClient * This);
        
        DECLSPEC_XFGVIRT(IUnknown, Release)
        ULONG ( STDMETHODCALLTYPE *Release )( 
            IIconHandlerClient * This);
        
        END_INTERFACE
    } IIconHandlerClientVtbl;

    interface IIconHandlerClient
    {
        CONST_VTBL struct IIconHandlerClientVtbl *lpVtbl;
    };

    

#ifdef COBJMACROS


#define IIconHandlerClient_QueryInterface(This,riid,ppvObject)	\
    ( (This)->lpVtbl -> QueryInterface(This,riid,ppvObject) ) 

#define IIconHandlerClient_AddRef(This)	\
    ( (This)->lpVtbl -> AddRef(This) ) 

#define IIconHandlerClient_Release(This)	\
    ( (This)->lpVtbl -> Release(This) ) 


#endif /* COBJMACROS */


#endif 	/* C style interface */




#endif 	/* __IIconHandlerClient_INTERFACE_DEFINED__ */



#ifndef __IconHandlerLib_LIBRARY_DEFINED__
#define __IconHandlerLib_LIBRARY_DEFINED__

/* library IconHandlerLib */
/* [version][uuid] */ 


EXTERN_C const IID LIBID_IconHandlerLib;

EXTERN_C const CLSID CLSID_IconHandlerClient;

#ifdef __cplusplus

class DECLSPEC_UUID("00a7f0d3-6740-4a38-b1ee-20d811f70612")
IconHandlerClient;
#endif
#endif /* __IconHandlerLib_LIBRARY_DEFINED__ */

/* Additional Prototypes for ALL interfaces */

/* end of Additional Prototypes */

#ifdef __cplusplus
}
#endif

#endif


