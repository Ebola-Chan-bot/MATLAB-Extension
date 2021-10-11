classdef MmfSemaphore<handle
	%使用内存映射文件来模拟一个信号量，用于跨进程资源分配。
	%Windows的命名信号量十分坑爹，一旦设定好，重启系统之前都无法修改，因此退而求其次采用MATLAB内存映射文件实现跨进程资源分配。
	properties(Access=private)
		Mmf(1,1)
	end	
	methods
		function obj = MmfSemaphore(FilePath)
			arguments
				FilePath(1,1)string=fullfile(fileparts(mfilename("fullpath")),"Mmf")
			end
			%定义一个内存映射文件信号量。
			%输入参数：FilePath(1,1)string，可选，内存映射文件路径
			%如果指定文件不存在，将创建该文件，写入一个字节0，表示当前无资源可供分配。
			if ~isfile(FilePath)
				Fid=fopen(FilePath,"w");
				fwrite(Fid,0,"uint8");
				fclose(Fid);
			end
			obj.Mmf=memmapfile(FilePath,Writable=true);
		end
		function Fill(obj,Number)
			%填充信号量中的资源
			%输入参数：Number(1,1)uint8，填充资源数量
			obj.Mmf.Data=uint8(Number);
		end
		function Success=RequestOne(obj)
			%求取一个资源配额
			%返回值：Success(1,1)logical，求取是否成功
			Success=obj.Mmf.Data>0;
			if Success
				obj.Mmf.Data=obj.Mmf.Data-1;
			end
		end
		function ReturnOne(obj)
			%归还一个资源配额。将直接导致资源数量+1，不会检查是否超出Fill的量。
			obj.Mmf.Data=obj.Mmf.Data+1;
		end
	end
end