classdef Mutex<handle
	%互斥锁，防止资源被重复访问
	%注意，此对象不适用于多线程任务
	properties(SetAccess=protected)
		%指示当前是否已锁定
		Locked=false
	end
	methods
		function [Success,Token]=Lock(obj)
			%尝试锁定互斥锁
			%# 语法
			% ```
			% Success=Lock(obj);
			% %尝试锁定，成功返回true，失败返回false。需要Unlock手动解锁。
			%
			% [Success,Token]=Lock(obj);
			% %额外返回一个锁定令牌，令牌对象销毁时会自动解锁
			% ```
			%# 返回值
			% Success(1,1)logical，指示是否成功锁定
			% Token onCleanup，当成功锁定时返回一个令牌对象，令牌对象销毁时会自动解锁。如果失败，返回空数组。
			%See also onCleanup MATLAB.Lang.Mutex.Unlock
			if obj.Locked
				Success=false;
				Token=onCleanup.empty;
			else
				Success=true;
				if nargout
					Token=onCleanup(@()obj.Unlock());
				end
			end
		end
		function Unlock(obj)
			%手动解锁
			%如果锁定时返回了令牌，可以利用令牌对象的销毁而自动解锁，不需要手动解锁。
			%See also MATLAB.Lang.Mutex.Lock
			obj.Locked=false;
		end
	end
end