#include"CppPointer.h"
API声明(CppGetPointer)
{
	struct 数组注入
	{
		virtual ~数组注入() {}
		std::shared_ptr<impl::ArrayImpl> pImpl;
	};
	size_t buffer;
	void (*deleter)(size_t) ;
    const std::shared_ptr<impl::ArrayImpl>& pImpl = ((数组注入*)&inputs[1])->pImpl;
    auto 函数=matlab::data::detail::resolveFunction<int(*)(impl::ArrayImpl*, bool, size_t*, void (**deleter)(size_t))>(matlab::data::detail::FunctionType::ARRAY_RELEASE_BUFFER);
	//00007FFEFF1907D7 4C 8D 4D 28          lea         r9, [deleter]
	size_t r9 = (size_t)deleter;
	//	00007FFEFF1907DB 4C 8D 45 08          lea         r8, [buffer]
	size_t r8 = (size_t)buffer;
	//	00007FFEFF1907DF 0F B6 95 70 01 00 00 movzx       edx, byte ptr[rbp + 170h]
	//	00007FFEFF1907E6 48 8B C8             mov         rcx, rax
	size_t rcx = (size_t)pImpl.get();
	//	00007FFEFF1907E9 FF 95 68 01 00 00    call        qword ptr[rbp + 168h]

	//	00007FFF4A988990 40 53                push        rbx
	//	00007FFF4A988992 48 83 EC 20          sub         rsp, 20h
	//	00007FFF4A988996 4D 8B D9             mov         r11, r9
	size_t r11 = r9;
	//	00007FFF4A988999 49 8B D8             mov         rbx, r8
	size_t rbx = r8;
	//	00007FFF4A98899C 4C 8B D1             mov         r10, rcx
	size_t r10 = rcx;
	//	00007FFF4A98899F 84 D2                test        dl, dl
	//	00007FFF4A9889A1 74 1C                je          00007FFF4A9889BF
	//	00007FFF4A9889A3 48 8B 41 08          mov         rax, qword ptr[rcx + 8]
	size_t rax = *(size_t*)(rcx + 8);
	//	00007FFF4A9889A7 90                   nop
	//	00007FFF4A9889A8 48 83 F8 01          cmp         rax, 1
	//	00007FFF4A9889AC 77 11                ja          00007FFF4A9889BF
	//	00007FFF4A9889AE 48 8B 01             mov         rax, qword ptr[rcx]
	rax = *(size_t*)rcx;
	//	00007FFF4A9889B1 4D 8B C1             mov         r8, r9
	r8 = r9;
	//	00007FFF4A9889B4 48 8B D3             mov         rdx, rbx
	size_t rdx = rbx;
	//	00007FFF4A9889B7 FF 90 30 01 00 00    call        qword ptr[rax + 130h]

	//	00007FFF460E7FE0 48 89 74 24 10       mov         qword ptr[rsp + 10h], rsi
	//	00007FFF460E7FE5 48 89 7C 24 18       mov         qword ptr[rsp + 18h], rdi
	//	00007FFF460E7FEA 41 56                push        r14
	//	00007FFF460E7FEC 48 83 EC 30          sub         rsp, 30h
	//	00007FFF460E7FF0 48 8B F9             mov         rdi, rcx
	//	00007FFF460E7FF3 49 8B F0             mov         rsi, r8
	//	00007FFF460E7FF6 48 8B 49 10          mov         rcx, qword ptr[rcx + 10h]
	rcx = *(size_t*)(rcx + 0x10);
	//	00007FFF460E7FFA 4C 8B F2             mov         r14, rdx
	size_t r14 = rdx;
	//	00007FFF460E7FFD 48 8B 01             mov         rax, qword ptr[rcx]
	rax = *(size_t*)rcx;
	//	00007FFF460E8000 FF 50 48             call        qword ptr[rax + 48h]
	
	//	00007FFF460E8003 84 C0                test        al, al
	//	00007FFF460E8005 74 23                je          00007FFF460E802A
	//	00007FFF460E8007 48 8B 07             mov         rax, qword ptr[rdi]
	//	00007FFF460E800A 4C 8B C6             mov         r8, rsi
	//	00007FFF460E800D 49 8B D6             mov         rdx, r14
	//	00007FFF460E8010 48 8B CF             mov         rcx, rdi
	//	00007FFF460E8013 48 8B 74 24 48       mov         rsi, qword ptr[rsp + 48h]
	//	00007FFF460E8018 48 8B 7C 24 50       mov         rdi, qword ptr[rsp + 50h]
	//	00007FFF460E801D 48 83 C4 30          add         rsp, 30h
	//	00007FFF460E8021 41 5E                pop         r14
	//	00007FFF460E8023 48 FF A0 28 01 00 00 jmp         qword ptr[rax + 128h]

	//	00007FFF460DB030 48 89 5C 24 08       mov         qword ptr[rsp + 8], rbx
	//	00007FFF460DB035 48 89 6C 24 10       mov         qword ptr[rsp + 10h], rbp
	//	00007FFF460DB03A 48 89 74 24 18       mov         qword ptr[rsp + 18h], rsi
	//	00007FFF460DB03F 48 89 7C 24 20       mov         qword ptr[rsp + 20h], rdi
	//	00007FFF460DB044 41 56                push        r14
	//	00007FFF460DB046 48 83 EC 20          sub         rsp, 20h
	//	00007FFF460DB04A 48 8B 01             mov         rax, qword ptr[rcx]
	//	00007FFF460DB04D 4D 8B F0             mov         r14, r8
	//	00007FFF460DB050 48 8B DA             mov         rbx, rdx
	//	00007FFF460DB053 48 8B F1             mov         rsi, rcx
	//	00007FFF460DB056 FF 90 88 00 00 00    call        qword ptr[rax + 88h]
	//	00007FFF460DB05C 48 8B D0             mov         rdx, rax
	//	00007FFF460DB05F 48 C1 E2 03          shl         rdx, 3
	//	00007FFF460DB063 48 85 D2             test        rdx, rdx
	//	00007FFF460DB066 74 15                je          00007FFF460DB07D
	//	00007FFF460DB068 48 8B 05 A9 05 06 00 mov         rax, qword ptr[7FFF4613B618h]
	//	00007FFF460DB06F 48 8B 08             mov         rcx, qword ptr[rax]
	//	00007FFF460DB072 48 8B 01             mov         rax, qword ptr[rcx]
	//	00007FFF460DB075 FF 50 10             call        qword ptr[rax + 10h]
	//	00007FFF460DB078 48 8B E8             mov         rbp, rax
	//	00007FFF460DB07B EB 02                jmp         00007FFF460DB07F
	//	00007FFF460DB07D 33 ED xor ebp, ebp
	//	00007FFF460DB07F 48 89 2B             mov         qword ptr[rbx], rbp
	//	00007FFF460DB082 48 8B CE             mov         rcx, rsi
	//	00007FFF460DB085 48 8B 06             mov         rax, qword ptr[rsi]
	//	00007FFF460DB088 FF 90 88 00 00 00    call        qword ptr[rax + 88h]
	//	00007FFF460DB08E 48 8B 16             mov         rdx, qword ptr[rsi]
	//	00007FFF460DB091 48 8B CE             mov         rcx, rsi
	//	00007FFF460DB094 48 8B F8             mov         rdi, rax
	//	00007FFF460DB097 48 C1 E7 03          shl         rdi, 3
	//	00007FFF460DB09B FF 92 70 01 00 00    call        qword ptr[rdx + 170h]
	函数(pImpl.get(), pImpl.use_count() == 1, &buffer, &deleter);
	outputs[1] = 数组工厂.createScalar(buffer);
	deleter(buffer);
}