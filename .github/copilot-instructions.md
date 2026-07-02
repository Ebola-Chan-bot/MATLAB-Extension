# Copilot Instructions

## 项目指南
- 用户要求批量关闭句柄时只进行一次 MATLAB 调用；循环应放在提权操作的 C++ 内部而不是 MATLAB 端。
- MATLAB.IO.CloseHandle 的语法严格区分：双参数形式只接受标量并关闭单个句柄；单表参数形式才支持批量关闭。
- 用户更偏好在 MEX 返回数组时利用 createArrayFromBuffer 的 MemoryLayout 参数处理行/列主序差异，而不是为此修改提权端输出协议。