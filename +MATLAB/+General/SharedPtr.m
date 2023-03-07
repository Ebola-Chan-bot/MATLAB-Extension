classdef SharedPtr<handle
	%将引用计数智能指针回绕在动态分配的对象周围。
	%本类描述使用引用计数来管理资源的对象。 对象有效保留一个指向其拥有的资源的指针或保留一个零指针。 资源可由多个对象拥有；当拥有特定资源的最后一个对象被销毁后，资源将
	% 释放。一个对象拥有一个资源，如果已使用指向该资源的指针构造它。拥有资源的对象共享控制块。控制块包含该资源的删除器（如果有）。当拥有资源的对象的数目变为零时，可通
	% 过删除该资源或将其地址传递给删除器来释放资源，这取决于最初创建资源所有权的方式。删除器是一个函数句柄，它接受一个参数（即要删除的对象）。
	properties(Access=private)
		OwnerDeleter
	end
	properties(SetAccess=immutable)
		%获取拥有的资源的地址
		Get(1,1)MATLAB.General.Pointer
	end
	properties(Dependent)
		%当前资源的所有者
		Owner
	end
	methods(Static)
		function obj=Allocate(varargin)
			%分配一段新的内存，返回拥有这段内存的指针
			%此方法类似于Pointer.Allocate，但返回的SharedPtr拥有这段内存，能够在内存不再使用时自动释放。
			%See also MATLAB.General.Pointer.Allocate
			obj=MATLAB.General.SharedPtr(MATLAB.General.Pointer.Allocate(varargin{:}));
		end
		function Copy(varargin)
			%从一个指针向另一个指针拷贝数据
			%此方法与Pointer.Copy完全相同
			%See also MATLAB.General.Pointer.Copy
			MATLAB.General.Pointer.Copy(varargin{:});
		end
	end
	methods
		function O=get.Owner(obj)
			if isa(obj.OwnerDeleter,'function_handle')
				O=obj;
			else
				O=obj.OwnerDeleter;
			end
		end
		function obj = SharedPtr(Pointer,OwnerDeleter)
			%使用指针和删除器或所有者构造SharedPtr
			%# 语法
			% ```
			% obj=MATLAB.General.SharedPtr(Pointer,Owner);
			% %指定一个指针和它的拥有者，构造的SharedPtr与拥有者共享该资源指针。SharedPtr在创建和销毁时都会通知Owner的引用计数器，Owner应当负责在计数归零时释放指针。
			%
			% obj=MATLAB.General.SharedPtr(Pointer,Deleter);
			% %指定一个指针和它的删除器，构造的SharedPtr将拥有该指针，并负责引用计数。引用归零时，将把Pointer传递给Deleter函数以执行释放。
			% ```
			%# 输入参数
			% Pointer(1,1)MATLAB.General.Pointer，要共享的资源指针
			% Owner(1,1)handle，资源的所有者，一般来说是使用Deleter语法或Allocate静态方法创建的SharedPtr。你也可以实现自己的资源管理器。
			% Deleter(1,1)function_handle，资源删除器，必须接受Pointer作为唯一输入参数，负责释放Pointer指向的资源。
			obj.Get=Pointer;
			if exist('OwnerDeleter','var')
				obj.OwnerDeleter=OwnerDeleter;
			else
				obj.OwnerDeleter=@Release;
			end
		end
		function delete(obj)
			%如果本对象是指针的拥有者，释放那个指针的资源；否则通知拥有者将引用计数减一。
			if isa(obj.OwnerDeleter,'function_handle')
				obj.OwnerDeleter(obj.Get);
			end
		end
		function Pointer=uint64(obj)
			%获取指针整数值用于运算
			Pointer=uint64(obj.Get);
		end
		function Pointer=int64(obj)
			%获取指针整数值用于运算
			Pointer=int64(obj.Get);
		end
		function Data=Read(obj,varargin)
			%从指针读入指定类型数据
			%此方法和Pointer.Read完全相同
			%See also MATLAB.General.Pointer.Read
			Data=obj.Get.Read(varargin{:});
		end
		function Write(obj,varargin)
			%向指针写出POD数据
			%此方法和Pointer.Write完全相同
			%See also MATLAB.General.Pointer.Write
			obj.Get.Write(varargin{:});
		end
		function obj=plus(obj,Offset)
			%为指针增加一个偏移量
			%此方法类似于Pointer.plus，但返回的SharedPtr不需要手动释放。内存不再使用时将自动释放。
			%See also MATLAB.General.Pointer.plus
			obj=MATLAB.General.SharedPtr(obj.Get+Offset,obj.Owner);
		end
		function OffsetPointer=minus(obj,PointerOffset)
			%为指针减去一个偏移量，或求两个指针之间相差的字节数
			%此方法类似于Pointer.minus，但返回的指针不需要手动释放。内存不再使用时将自动释放。
			OffsetPointer=obj.Get-int64(PointerOffset);
			if ~(isa(PointerOffset,'MATLAB.General.Pointer')||isa(PointerOffset,'MATLAB.General.SharedPtr'))
				OffsetPointer=MATLAB.General.SharedPtr(OffsetPointer,obj.Owner);
			end
		end
		function Release(obj)
			%停止对资源的监控
			%如果对象拥有该资源，Release之后对象将不再负责资源的释放，您需要手动释放资源。如果对象不是资源拥有者，Release将通知拥有者引用计数减一。如果引用计数未归
			% 零，您仍能正常访问该资源。此对象销毁时不会再次通知拥有者。
			obj.OwnerDeleter=[];
		end
	end
end