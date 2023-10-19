Imports System.IO
Imports System.IO.MemoryMappedFiles
Imports System.Reflection
Imports System.Runtime.InteropServices
Imports System.Security.AccessControl
Imports Microsoft.Win32

Module Program
	Function 读入字符串(流 As MemoryMappedViewStream) As String
		Dim 字符数 As Byte = 流.ReadByte
		Dim 字符串(字符数 - 1) As Char
		流.ReadExactly(MemoryMarshal.AsBytes(字符串.AsSpan))
		Return 字符串
	End Function

	Enum 提权操作 As Byte
		Install_Path_Manager
		Uninstall_Path_Manager
		Set_shared_path
		Add_shared_path
		Remove_shared_path
		Builtin_bug_fix
		Associate_prj_extension
		Get_pathdef_permission
	End Enum

	Private Sub 公开只读权限(路径 As String)
		Dim 文件信息 As New FileInfo(路径)
		Dim 访问控制 = 文件信息.GetAccessControl
		访问控制.SetAccessRule(New FileSystemAccessRule("Users", FileSystemRights.Read, AccessControlType.Allow))
		文件信息.SetAccessControl(访问控制)
	End Sub

	Sub Main(args As String())
		Static 埃博拉酱目录 As String = Path.Combine(Environment.GetEnvironmentVariable("ProgramData"), "MathWorks\埃博拉酱")
		Static 共享路径 As String = Path.Combine(埃博拉酱目录, "共享路径.txt")
		Dim 参数流 As MemoryMappedViewStream = MemoryMappedFile.OpenExisting(args(0)).CreateViewStream
		Select Case 参数流.ReadByte
			Case 提权操作.Install_Path_Manager
				Dim MatlabRoot As String = 读入字符串(参数流)
				Static 安装目录 As String = Path.Combine(Path.GetDirectoryName(Assembly.GetEntryAssembly.Location), "..\安装")
				File.Copy(Path.Combine(安装目录, "savepath.m"), Path.Combine(MatlabRoot, "toolbox\matlab\general\savepath.m"), True)
				Static 埃博拉酱internal目录 As String = Path.Combine(埃博拉酱目录, "+MATLAB\+internal")
				Directory.CreateDirectory(埃博拉酱internal目录)
				File.Copy(Path.Combine(安装目录, "RcAddPath.m"), Path.Combine(埃博拉酱internal目录, "RcAddPath.m"), True)
				'必须用文本文件记录路径，因为环境变量最长只有4095字节
				If Not File.Exists(共享路径) Then
					'不要覆盖已有文件
					File.Create(共享路径)
				End If
				Dim MatlabRC As String = Path.Combine(MatlabRoot, "toolbox\local\matlabrc.m")
				'此处要注意避免重复安装导致重复添加多行
				File.WriteAllLines(MatlabRC, (From 行 As String In File.ReadAllLines(MatlabRC) Select 行 Where Not 行.EndsWith("%埃博拉酱")).Append($"addpath('{埃博拉酱目录}');MATLAB.internal.RcAddPath;%埃博拉酱"))
				公开只读权限(Path.Combine(MatlabRoot, "toolbox\local\pathdef.m"))
			Case 提权操作.Uninstall_Path_Manager
				Dim Matlab路径 As String = 读入字符串(参数流)
				'原版savepath直接放在internal目录下以便调用
				File.Copy(Path.Combine(Path.GetDirectoryName(Assembly.GetEntryAssembly.Location), "..\原文件\savepath.m"), Path.Combine(Matlab路径, "toolbox\matlab\general\savepath.m"), True)
				Matlab路径 = Path.Combine(Matlab路径, "toolbox\local\matlabrc.m")
				File.WriteAllLines(Matlab路径, From 行 As String In File.ReadAllLines(Matlab路径) Select 行 Where Not 行.EndsWith("%埃博拉酱"))
			Case 提权操作.Set_shared_path
				File.WriteAllText(共享路径, 读入字符串(参数流))
			Case 提权操作.Add_shared_path
				Dim 旧路径 As String = File.ReadAllText(共享路径)
				Dim 新路径 As IEnumerable(Of String) = 读入字符串(参数流).Split(";").Except(旧路径.Split(";"))
				If 新路径.Any Then
					For Each 路径 As String In 新路径
						公开只读权限(路径)
					Next
					File.AppendAllText(共享路径, If(旧路径 = "", "", ";") + String.Join(";", 新路径))
				End If
			Case 提权操作.Remove_shared_path
				Dim 旧路径 As String() = File.ReadAllText(共享路径).Split(";")
				Dim 移除路径 As IEnumerable(Of String) = 旧路径.Except(读入字符串(参数流).Split(";"))
				If 移除路径.Count < 旧路径.Count Then
					File.WriteAllText(共享路径, String.Join(";", 移除路径))
				End If
			Case 提权操作.Builtin_bug_fix
				Dim 读入器 As New BinaryReader(参数流)
				Static 文件名 As String() = {"getDocumentationXML.m", "CshDocPageHandler.m", "Document.m", "ToolboxConfigurationReader.m", "getReferencePage.m"}
				Static 目标目录 As String() = {
						"toolbox\matlab\helptools\+matlab\+internal\+doc",
						"toolbox\matlab\helptools\+matlab\+internal\+doc\+ui\@CshDocPageHandler",
						"toolbox\matlab\codetools\+matlab\+desktop\+editor\@Document",
						"toolbox\matlab\toolbox_packaging\+matlab\+internal\+addons\+metadata",
						"toolbox\matlab\helptools\+matlab\+internal\+doc\+reference"
					}
				Static 包目录 As String = Path.Combine(Path.GetDirectoryName(Assembly.GetEntryAssembly.Location), "..\..\+internal")
				Dim MatlabRoot As String = 读入字符串(参数流)
				For C As Byte = 1 To 读入器.ReadByte
					Dim 命令 As SByte = 读入器.ReadSByte
					If 命令 > 0 Then
						命令 -= 1
						File.Copy(Path.Combine(包目录, "新文件", 文件名(命令)), Path.Combine(MatlabRoot, 目标目录(命令), 文件名(命令)), True)
					ElseIf 命令 < 0 Then
						命令 = -1 - 命令
						File.Copy(Path.Combine(包目录, "原文件", 文件名(命令)), Path.Combine(MatlabRoot, 目标目录(命令), 文件名(命令)), True)
					Else
						Throw New ArgumentNullException("Command不能为0")
					End If
				Next
			Case 提权操作.Associate_prj_extension
				Dim 键A As RegistryKey = Registry.ClassesRoot.CreateSubKey(".prj")
				Dim MATLAB版本 As String = 读入字符串(参数流)
				Dim prj类 As String = $"MATLAB.prj.{MATLAB版本}.0"
				键A.SetValue(Nothing, prj类)
				键A.SetValue("PerceivedType", "mwopc")
				键A.CreateSubKey("OpenWithProgids").SetValue(prj类, "", RegistryValueKind.String)
				Dim 键B As RegistryKey = 键A.CreateSubKey("ShellEx")
				键B.CreateSubKey("{BB2E617C-0920-11d1-9A0B-00C04FC2D6C1}").SetValue(Nothing, "{44121072-A222-48f2-A58A-6D9AD51EBBE9}")
				键B.CreateSubKey("{E357FCCD-A995-4576-B01F-234630154E96}").SetValue(Nothing, "{44121072-A222-48f2-A58A-6D9AD51EBBE9}")
				键B = 键A.CreateSubKey("Versions").CreateSubKey(prj类)
				键B.SetValue("FileVersionLS", 0, RegistryValueKind.DWord)
				Dim 子版本号 As String() = MATLAB版本.Split(".")
				键B.SetValue("FileVersionMS", (CUInt(子版本号(0)) << 16) + CUInt(子版本号(1)), RegistryValueKind.DWord)
				键A = Registry.ClassesRoot.CreateSubKey(prj类)
				Dim MatlabRoot As String = 读入字符串(参数流)
				键A.CreateSubKey("DefaultIcon").SetValue(Nothing, $"""{Path.Combine(MatlabRoot, "bin\win64\osintegplugins\osintegplugins\mlproj\mwmlprojfaplugin.dll")}"",0")
				键A = 键A.CreateSubKey("Shell").CreateSubKey("Open")
				键A.SetValue(Nothing, "Open")
				键A.CreateSubKey("command").SetValue(Nothing, $"""{Path.Combine(MatlabRoot, "bin\win64\matlab.exe")}"" -r ""uiopen('%1',1)""")
				键A = 键A.CreateSubKey("ddeexec")
				键A.SetValue(Nothing, "uiopen('%1',1)")
				键A.CreateSubKey("application").SetValue(Nothing, $"ShellVerbs.MATLAB.{MATLAB版本}.0")
				键A.CreateSubKey("topic").SetValue(Nothing, "system")
			Case 提权操作.Get_pathdef_permission
				Dim 文件信息 As New FileInfo(读入字符串(参数流))
				Dim 访问控制 = 文件信息.GetAccessControl
				访问控制.SetAccessRule(New FileSystemAccessRule(Environment.UserName, FileSystemRights.FullControl, AccessControlType.Allow))
				文件信息.SetAccessControl(访问控制)
		End Select
	End Sub
End Module
