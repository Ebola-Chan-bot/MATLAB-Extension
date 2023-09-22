classdef EventLogger<handle
	%事件记录器，类似于秒表
	properties(Access=private)
		StartTime
		RawLog
	end
	properties(SetAccess=private)
		%已记录的事件个数
		NumEvents=0
	end
	methods
		function obj = EventLogger
			obj.StartTime=tic;
		end
		function Reset(obj)
			%重置计时器
			obj.NumEvents=0;
			obj.StartTime=tic;
		end
		function LogEvent(obj,Event)
			%记录一个事件
			%# 语法
			% ```
			% obj.LogEvent(Event);
			% ```
			%# 输入参数
			% Event(1,1)，可以允许任意标量数据类型作为事件记录
			if isempty(obj.RawLog)
				obj.RawLog=timetable(seconds(toc(obj.StartTime)),Event);
				obj.NumEvents=1;
			else
				NewSize=obj.NumEvents+1;
				if NewSize>height(obj.RawLog)
					obj.RawLog.Event(NewSize*2)=Event;
				end
				obj.RawLog.Time(NewSize)=seconds(toc(obj.StartTime));
				obj.RawLog.Event(NewSize)=Event;
				obj.NumEvents=NewSize;
			end
		end
		function TT=GetTimeTable(obj)
			%返回事件记录时间表
            %# 语法
            % ```
            % TT=obj.GetTimeTable;
            % ```
            %# 返回值
            % TT timetable，表包含一个Time列，记录每个事件相对于上次Reset或创建对象时经过的时间；以及一个Event列，包含LogEvent所记录的每个事件。如果没有记录任何事件，
            %  将返回一个(0,0)timetable。
            if isempty(obj.RawLog)
                TT=timetable;
            else
    			TT=obj.RawLog(1:obj.NumEvents,:);
            end
        end
	end
end