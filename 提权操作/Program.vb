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
	End Enum

	Private Sub 公开只读权限(路径 As String)
		Dim 文件信息 As New FileInfo(路径)
		Dim 访问控制 = 文件信息.GetAccessControl
		访问控制.SetAccessRule(New FileSystemAccessRule("Users", FileSystemRights.Read, AccessControlType.Allow))
		文件信息.SetAccessControl(访问控制)
	End Sub

	Private Sub 添加共享路径(新路径 As IEnumerable(Of String))
		Dim 共享路径 As String = Path.Combine(Environment.GetEnvironmentVariable("ProgramData"), "MathWorks\埃博拉酱\共享路径.txt")
		Dim 旧路径 As String = File.ReadAllText(共享路径)
		新路径 = 新路径.Except(旧路径.Split(";"))
		If 新路径.Any Then
			For Each 路径 As String In 新路径
				公开只读权限(路径)
			Next
			File.AppendAllText(共享路径, If(旧路径 = "", "", ";") + String.Join(";", 新路径))
		End If
	End Sub

	Private Sub 移除共享路径(移除路径 As IEnumerable(Of String))
		Dim 共享路径 As String = Path.Combine(Environment.GetEnvironmentVariable("ProgramData"), "MathWorks\埃博拉酱\共享路径.txt")
		Dim 旧路径 As String() = File.ReadAllText(共享路径).Split(";")
		移除路径 = 旧路径.Except(移除路径)
		If 移除路径.Count < 旧路径.Count Then
			File.WriteAllText(共享路径, String.Join(";", 移除路径))
		End If
	End Sub

	Sub Main(args As String())
		Dim 参数流 As MemoryMappedViewStream = MemoryMappedFile.OpenExisting(args(0)).CreateViewStream
		Select Case 参数流.ReadByte
			Case 提权操作.Install_Path_Manager
				Dim MatlabRoot As String = 读入字符串(参数流)
				Dim 安装目录 As String = Path.Combine(Path.GetDirectoryName(Assembly.GetEntryAssembly.Location), "..\安装")
				File.Copy(Path.Combine(安装目录, "savepath.m"), Path.Combine(MatlabRoot, "toolbox\matlab\general\savepath.m"), True)
				Dim 埃博拉酱目录 As String = Path.Combine(Environment.GetEnvironmentVariable("ProgramData"), "MathWorks\埃博拉酱")
				Dim 埃博拉酱internal目录 As String = Path.Combine(埃博拉酱目录, "+MATLAB\+internal")
				Directory.CreateDirectory(埃博拉酱internal目录)
				File.Copy(Path.Combine(安装目录, "RcAddPath.m"), Path.Combine(埃博拉酱internal目录, "RcAddPath.m"), True)
				Dim 共享路径文件 As String = Path.Combine(埃博拉酱目录, "共享路径.txt")
				'必须用文本文件记录路径，因为环境变量最长只有4095字节
				If Not File.Exists(共享路径文件) Then
					'不要覆盖已有文件
					File.Create(共享路径文件)
				End If
				Dim MatlabRC As String = Path.Combine(MatlabRoot, "toolbox\local\matlabrc.m")
				'此处要注意避免重复安装导致重复添加多行
				File.WriteAllLines(MatlabRC, (From 行 As String In File.ReadAllLines(MatlabRC) Select 行 Where Not 行.EndsWith("%埃博拉酱")).Append($"addpath('{埃博拉酱目录}');MATLAB.internal.RcAddPath;%埃博拉酱"))
				公开只读权限(Path.Combine(MatlabRoot, "toolbox\local\pathdef.m"))
			Case 提权操作.Uninstall_Path_Manager
				Dim Matlab路径 As String = 读入字符串(参数流)
				'原版savepath直接放在internal目录下以便调用
				File.Copy(Path.Combine(Path.GetDirectoryName(Assembly.GetEntryAssembly.Location), "..\savepath.m"), Path.Combine(Matlab路径, "toolbox\matlab\general\savepath.m"), True)
				Matlab路径 = Path.Combine(Matlab路径, "toolbox\local\matlabrc.m")
				File.WriteAllLines(Matlab路径, From 行 As String In File.ReadAllLines(Matlab路径) Select 行 Where Not 行.EndsWith("%埃博拉酱"))
			Case 提权操作.Set_shared_path
				File.WriteAllText(Path.Combine(Environment.GetEnvironmentVariable("ProgramData"), "MathWorks\埃博拉酱\共享路径.txt"), 读入字符串(参数流))
			Case 提权操作.Add_shared_path
				添加共享路径(读入字符串(参数流).Split(";"))
			Case 提权操作.Remove_shared_path
				移除共享路径(读入字符串(参数流).Split(";"))
			Case 提权操作.Builtin_bug_fix
				Dim MatlabRoot As String = 读入字符串(参数流)
				Dim 读入器 As New BinaryReader(参数流)
				Dim 包目录 As String = Path.Combine(Path.GetDirectoryName(Assembly.GetEntryAssembly.Location), "..\..")
				Dim 共享目录 As String = Path.Combine(Environment.GetEnvironmentVariable("ProgramData"), "MathWorks\埃博拉酱")
				添加共享路径({共享目录})
				共享目录 = Path.Combine(共享目录, "+MATLAB\+internal")
				For C As Byte = 1 To 读入器.ReadByte
					Select Case 读入器.ReadSByte
						Case 1
							File.Copy(Path.Combine(包目录, "+General\Which.mlx"), Path.Combine(共享目录, "Which.mlx"), True)
							Dim 文件路径 As String = Path.Combine(MatlabRoot, "toolbox\matlab\helptools\+matlab\+internal\+doc\getDocumentationXML.m")
							File.WriteAllText(文件路径, File.ReadAllText(文件路径).Replace("which", "MATLAB.internal.Which"))
						Case -1
							Dim 文件路径 As String = Path.Combine(MatlabRoot, "toolbox\matlab\helptools\+matlab\+internal\+doc\getDocumentationXML.m")
							File.WriteAllText(文件路径, File.ReadAllText(文件路径).Replace("MATLAB.internal.Which", "which"))
						Case 2
							Dim 文件路径 As String = Path.Combine(MatlabRoot, "toolbox\matlab\helptools\+matlab\+internal\+doc\+ui\@CshDocPageHandler\CshDocPageHandler.m")
							File.WriteAllText(文件路径, File.ReadAllText(文件路径).Replace("~isempty(cefWindow)", "false"))
						Case -2
							Dim 文件路径 As String = Path.Combine(MatlabRoot, "toolbox\matlab\helptools\+matlab\+internal\+doc\+ui\@CshDocPageHandler\CshDocPageHandler.m")
							File.WriteAllText(文件路径, File.ReadAllText(文件路径).Replace("false", "~isempty(cefWindow)"))
						Case 3
							File.Copy(Path.Combine(包目录, "+internal\安装\OpenEditor.m"), Path.Combine(共享目录, "OpenEditor.m"), True)
							Dim 文件路径 As String = Path.Combine(MatlabRoot, "toolbox\matlab\codetools\edit.m")
							File.WriteAllText(文件路径, File.ReadAllText(文件路径).Replace("matlab.desktop.editor.Document.openEditor", "MATLAB.internal.OpenEditor"))
						Case -3
							Dim 文件路径 As String = Path.Combine(MatlabRoot, "toolbox\matlab\codetools\edit.m")
							File.WriteAllText(文件路径, File.ReadAllText(文件路径).Replace("MATLAB.internal.OpenEditor", "matlab.desktop.editor.Document.openEditor"))
						Case 4
							File.Copy(Path.Combine(包目录, "+internal\安装\WebSave.m"), Path.Combine(共享目录, "WebSave.m"), True)
							Dim 文件路径 As String = Path.Combine(MatlabRoot, "toolbox\matlab\toolbox_packaging\+matlab\+internal\+addons\+metadata\ToolboxConfigurationReader.m")
							File.WriteAllText(文件路径, File.ReadAllText(文件路径).Replace("websave", "MATLAB.internal.WebSave"))
						Case -4
							Dim 文件路径 As String = Path.Combine(MatlabRoot, "toolbox\matlab\toolbox_packaging\+matlab\+internal\+addons\+metadata\ToolboxConfigurationReader.m")
							File.WriteAllText(文件路径, File.ReadAllText(文件路径).Replace("MATLAB.internal.WebSave", "websave"))
					End Select
				Next
		End Select
	End Sub
End Module
