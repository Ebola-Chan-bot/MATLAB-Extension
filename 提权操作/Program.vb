Imports System.IO
Imports System.IO.MemoryMappedFiles
Imports System.Runtime.InteropServices

Module Program
	Function 读入字符串(流 As MemoryMappedViewStream) As String
		Dim 字符数 As Byte = 流.ReadByte
		Dim 字符串(字符数 - 1) As Char
		流.ReadExactly(MemoryMarshal.AsBytes(字符串.AsSpan))
		Return 字符串
	End Function

	Sub Main(args As String())
		Dim 参数流 = MemoryMappedFile.OpenExisting(args(0)).CreateViewStream
		Select Case 读入字符串(参数流)
			Case "文件字符串替换"
				For a As Byte = 1 To 参数流.ReadByte
					Dim 文件路径 As String = 读入字符串(参数流)
					Dim 旧字符串 As String = 读入字符串(参数流)
					Dim 新字符串 As String = 读入字符串(参数流)
					File.WriteAllText(文件路径, File.ReadAllText(文件路径).Replace(旧字符串, 新字符串))
				Next
			Case Else
				Console.WriteLine("错误：无效命令")
		End Select
	End Sub
End Module
