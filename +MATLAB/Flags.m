classdef Flags<uint32
	%定义各种旗帜选项，分为多个不同的组，每组旗帜适用于不同的函数参数。
	%你需要根据参数名和函数/类名查找可用的旗帜组。0x开头的旗帜值可以用重载的|运算符进行按位与组合。
	enumeration
		ZERO(0)
		
		%% File DesiredAccess
		
		GENERIC_READ                     (0x80000000)%读取权限
		GENERIC_WRITE                    (0x40000000)%写入权限
		GENERIC_EXECUTE                  (0x20000000)%执行访问权限
		GENERIC_ALL                      (0x10000000)%所有可能的访问权限

		%% ShareMode

		%在文件或设备上启用后续打开操作以请求读取访问权限。
		%否则，如果文件或设备请求读取访问权限，则无法打开该文件或设备。如果未指定此标志，但文件或设备已打开以供读取访问，则函数将失败。
		FILE_SHARE_READ                 (0x00000001)
		%在文件或设备上启用后续打开操作以请求写入访问权限。
		%否则，如果文件或设备请求写入访问权限，则无法打开该文件或设备。如果未指定此标志，但文件或设备已打开进行写入访问或具有写入访问权限的文件映射，则函数将失败。
		FILE_SHARE_WRITE                (0x00000002)
		%在文件或设备上启用后续打开操作以请求删除访问权限。
		%否则，如果文件或设备请求删除访问权限，则无法打开该文件或设备。如果未指定此标志，但文件或设备已打开以删除访问权限，则函数将失败。注意，删除访问权限允许删除和重命名
		% 操作。
		FILE_SHARE_DELETE               (0x00000004)

		%% CreationDisposition

		%仅当该文件尚不存在时才创建一个新文件。
		%如果指定的文件存在，函数将失败。如果指定的文件不存在并且是可写位置的有效路径，则会创建新文件。
		CREATE_NEW          (1)
		%始终创建新文件。
		%如果指定的文件存在且可写，则函数将覆盖文件。如果指定的文件不存在且路径有效，则会创建一个新文件。
		CREATE_ALWAYS       (2)
		%仅当文件或设备存在时，才打开该文件或设备。
		%如果指定的文件或设备不存在，函数将失败。
		OPEN_EXISTING       (3)
		%始终打开文件。
		%如果指定文件存在，则函数成功。如果指定的文件不存在并且是可写位置的有效路径，则函数将创建一个文件。
		OPEN_ALWAYS         (4)
		%打开文件并截断该文件，使其大小为零字节，仅当它存在时。
		%如果指定的文件不存在，函数将失败。调用过程必须打开文件，并将 GENERIC_WRITE 位设置为 DesiredAccess 参数的一部分。
		TRUNCATE_EXISTING   (5)

		%% FlagsAndAttributes

		%文件为只读文件。 应用程序可以读取文件，但无法写入或删除该文件。
		FILE_ATTRIBUTE_READONLY             (0x00000001)
		%文件被隐藏。 不要将其包含在普通目录列表中。
		FILE_ATTRIBUTE_HIDDEN               (0x00000002)
		%该文件是操作系统的一部分或完全使用的文件。
		FILE_ATTRIBUTE_SYSTEM               (0x00000004)
		FILE_ATTRIBUTE_DIRECTORY            (0x00000010)
		%该文件应存档。 应用程序使用此属性来标记要备份或删除的文件。
		FILE_ATTRIBUTE_ARCHIVE              (0x00000020)
		FILE_ATTRIBUTE_DEVICE               (0x00000040)
		%该文件没有设置其他属性。 此属性仅在单独使用时有效。
		FILE_ATTRIBUTE_NORMAL               (0x00000080)
		%该文件用于临时存储。
		FILE_ATTRIBUTE_TEMPORARY            (0x00000100)
		FILE_ATTRIBUTE_SPARSE_FILE          (0x00000200)
		FILE_ATTRIBUTE_REPARSE_POINT        (0x00000400)
		FILE_ATTRIBUTE_COMPRESSED           (0x00000800)
		%文件的数据不能立即可用。 此属性指示文件数据以物理方式移动到脱机存储。 此属性由远程存储（分层存储管理软件）使用。 应用程序不应随意更改此属性。
		FILE_ATTRIBUTE_OFFLINE              (0x00001000)
		FILE_ATTRIBUTE_NOT_CONTENT_INDEXED  (0x00002000)
		%此文件或目录已加密。 对于文件来说，表示文件中的所有数据都是加密的。 对于目录，这意味着加密是新创建的文件和子目录的默认值。
		%如果还指定 了FILE_ATTRIBUTE_SYSTEM ，则此标志无效。家庭版、家庭高级版、初学者版或 ARM 版 Windows 不支持此标志。
		FILE_ATTRIBUTE_ENCRYPTED            (0x00004000)
		FILE_ATTRIBUTE_INTEGRITY_STREAM     (0x00008000)
		FILE_ATTRIBUTE_VIRTUAL              (0x00010000)
		FILE_ATTRIBUTE_NO_SCRUB_DATA        (0x00020000)
		FILE_ATTRIBUTE_EA                   (0x00040000)
		FILE_ATTRIBUTE_PINNED               (0x00080000)
		FILE_ATTRIBUTE_UNPINNED             (0x00100000)
		FILE_ATTRIBUTE_RECALL_ON_OPEN       (0x00040000)
		FILE_ATTRIBUTE_RECALL_ON_DATA_ACCESS(0x00400000)

		%写入操作不会经历任何中间缓存，它们将直接转到磁盘。
		FILE_FLAG_WRITE_THROUGH        (0x80000000)
		%在MATLAB上暂不支持此旗帜。
		FILE_FLAG_OVERLAPPED           (0x40000000)
		%文件或设备正在打开，没有系统缓存来读取和写入数据。 此标志不会影响硬盘缓存或内存映射文件。
		FILE_FLAG_NO_BUFFERING         (0x20000000)
		%访问是随机的。 系统可将此选项用作优化文件缓存的提示。
		%如果文件系统不支持缓存的 I/O 和 FILE_FLAG_NO_BUFFERING，则此标志无效。
		FILE_FLAG_RANDOM_ACCESS        (0x10000000)
		%访问旨在从头到尾的顺序。 系统可将此选项用作优化文件缓存的提示。
		%如果读取隐藏（即使用反向扫描），则不应使用此标志。如果文件系统不支持缓存的 I/O 和 FILE_FLAG_NO_BUFFERING，则此标志无效。
		FILE_FLAG_SEQUENTIAL_SCAN      (0x08000000)
		%文件在其所有句柄都关闭后立即被删除，其中包括指定的句柄和任何其他打开或重复的句柄。
		%如果文件存在现有的打开句柄，则调用会失败，除非这些句柄都使用 FILE_SHARE_DELETE 共享模式打开。针对文件的后续打开请求将失败，除非指定 FILE_SHARE_DELETE 共享模式。
		FILE_FLAG_DELETE_ON_CLOSE      (0x04000000)
		%正在为备份或还原操作打开或创建该文件。 系统确保调用进程在进程具有 SE_BACKUP_NAME 和 SE_RESTORE_NAME 特权时替代文件安全检查。
		%必须设置此标志才能获取目录的句柄。 目录句柄可以传递给某些函数，而不是文件句柄。
		FILE_FLAG_BACKUP_SEMANTICS     (0x02000000)
		%访问将根据 POSIX 规则进行。 这包括允许具有名称的多个文件，仅在支持该命名的文件系统时有所不同。
		%使用此选项时应小心，因为使用此标志创建的文件可能无法由为 MS-DOS 或 16 位 Windows 编写的应用程序访问。
		FILE_FLAG_POSIX_SEMANTICS      (0x01000000)
		%文件或设备正在使用会话感知打开。
		%如果未指定此标志，则会话中的每个会话设备（例如使用 RemoteFX USB 重定向的设备）无法由会话 0 中运行的进程打开。 对于不在会话 0 中的调用方，此标志无效。 此标志仅在
		% Windows 的服务器版本上受支持。Windows Server 2012之前不支持此标志。
		FILE_FLAG_SESSION_AWARE        (0x00800000)
		%不会进行正常的重新分析点处理; 将尝试打开重新分析点。 打开文件时，将返回文件句柄，无论控制重新分析点的筛选器是否正常运行。
		%此标志不能与 CREATE_ALWAYS 标志一起使用。如果文件不是重新分析点，则忽略此标志。
		FILE_FLAG_OPEN_REPARSE_POINT   (0x00200000)
		%请求文件数据，但它应继续位于远程存储中。 不应将其传输回本地存储。 此标志供远程存储系统使用。
		FILE_FLAG_OPEN_NO_RECALL       (0x00100000)
		FILE_FLAG_FIRST_PIPE_INSTANCE  (0x00080000)

		%% MoveMethod

		FILE_BEGIN           (0)%起点为零或文件的开头。 如果指定了此标志，则 DistanceToMove 参数将解释为无符号值。
		FILE_CURRENT         (1)%起点是文件指针的当前值。
		FILE_END             (2)%起始点是当前文件结束位置。

		%% Protect

		%允许映射视图以便进行只读或写入时复制访问。 尝试写入特定区域会导致访问冲突。
		%File 参数指定的文件句柄必须使用GENERIC_READ访问权限创建。
		PAGE_READONLY          (0x02)
		%允许为只读、写入时复制或读取/写入访问映射视图。
		%File 参数指定的文件句柄必须使用GENERIC_READ和GENERIC_WRITE访问权限创建。
		PAGE_READWRITE         (0x04)
		%允许映射视图以便进行只读或写入时复制访问。 此值等效于 PAGE_READONLY。
		%File 参数指定的文件句柄必须使用GENERIC_READ访问权限创建。
		PAGE_WRITECOPY         (0x08)
		PAGE_EXECUTE           (0x10)
		%允许为只读、写入时复制或执行访问权限映射视图。
		%必须使用GENERIC_READ和GENERIC_EXECUTE访问权限创建 File 参数指定的文件句柄。在具有 SP2 和 Windows Server 2003 SP1 的 Windows XP 之前，此值不可用。
		PAGE_EXECUTE_READ      (0x20)
		%允许对视图进行映射，以便进行只读、写入复制、读/写或执行访问。
		%File 参数指定的文件句柄必须使用GENERIC_READ、GENERIC_WRITE和GENERIC_EXECUTE访问权限创建。在具有 SP2 和 Windows Server 2003 SP1 的 Windows XP 之前，
		% 此值不可用。
		PAGE_EXECUTE_READWRITE (0x40)
		%允许为只读、写入时复制或执行访问权限映射视图。 此值等效于 PAGE_EXECUTE_READ。
		%File 参数指定的文件句柄必须使用GENERIC_READ和GENERIC_EXECUTE访问权限创建。只有在具有 SP1 的 Windows Vista 之前，此值才可用。Windows Server 2003 和
		% Windows XP： 不支持此值。
		PAGE_EXECUTE_WRITECOPY (0x80)

		%% MemoryMapping DesiredAccess

		%映射文件的读/写视图。
		%必须使用 PAGE_READWRITE 或 PAGE_EXECUTE_READWRITE 保护创建文件映射对象。(FILE_MAP_WRITE | FILE_MAP_READ) 和 FILE_MAP_ALL_ACCESS 等效于 FILE_MAP_WRITE。
		FILE_MAP_WRITE            (0x0002)
		%映射文件的只读视图。 尝试写入文件视图会导致访问冲突。
		%必须使用 PAGE_READONLY、 PAGE_READWRITE、 PAGE_EXECUTE_READ或 PAGE_EXECUTE_READWRITE 保护创建文件映射对象。
		FILE_MAP_READ             (0x0004)
		%映射文件的读/写视图。
		%必须使用 PAGE_READWRITE 或 PAGE_EXECUTE_READWRITE 保护创建文件映射对象。等效于 FILE_MAP_WRITE。
		FILE_MAP_ALL_ACCESS       (983071)
		%文件可执行文件的映射视图 (映射内存可以作为代码) 运行。
		%必须使用 PAGE_EXECUTE_READ、 PAGE_EXECUTE_WRITECOPY或 PAGE_EXECUTE_READWRITE 保护创建文件映射对象。此值从具有 SP2 的 Windows XP 和 SP1 的 Windows Server
		% 2003 开始可用。not included in FILE_MAP_ALL_ACCESS
		FILE_MAP_EXECUTE          (0x0020)
		%映射文件的复制写入视图。
		%必须使用PAGE_READONLY、PAGE_READ_EXECUTE、PAGE_WRITECOPY、PAGE_EXECUTE_WRITECOPY、PAGE_READWRITE或PAGE_EXECUTE_READWRITE保护创建文件映射对象。当进程写入
		% 到写入时，系统会将原始页面复制到一个新页面，该页面专用于该进程。 新页面由分页文件提供支持。 新页面的保护从写入复制更改为读/写。指定复制时写入访问权限时，系统
		% 和进程提交费用将用于整个视图，因为调用过程可能会写入视图中的每一页，使所有页面都成为私有页面。 新页面的内容永远不会写回原始文件，在取消映射视图时丢失。
		FILE_MAP_COPY             (0x00000001)

		FILE_MAP_RESERVE          (0x80000000)
		%将映射文件中的所有位置设置为控制流防护 (CFG) 的无效目标。
		%将此标志与执行访问权限FILE_MAP_EXECUTE结合使用。 对这些页面中位置的任何间接调用都将失败 CFG 检查，该过程将终止。 分配的可执行页面的默认行为是标记为 CFG 的有
		% 效调用目标。
		FILE_MAP_TARGETS_INVALID  (0x40000000)
		%在MATLAB上暂不支持此旗帜。
		FILE_MAP_LARGE_PAGES      (0x20000000)

		%% RestartDisposition

		Do_not_restart(6)%不要重启
		Restart_now(7)%立刻重启
		Inquire(9)%询问是否重启

		%% FigureAspectRatio

		Narrow(10)
		Amplify(11)

		%% Delete

		%对于显示的任何对话框，都对 “是”进行 响应。
		FOF_NOCONFIRMATION         (0x0010)

		%% DataTypes.Select
		NoOptimization(12)

		%% DataTypes.OptimizeQueryGraph
		DisableLoops(13)
		DisableLinkerOptimize(14)
	end
	methods
		function Combination=or(Flag1,Flag2)
			%Flags的|运算符被重载为按位与bitor
			Combination=bitor(Flag1,Flag2);
		end
	end
end