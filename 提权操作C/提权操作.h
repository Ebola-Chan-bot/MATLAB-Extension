#pragma once
#include<stdint.h>
enum class 提权操作 
{
	Install_Path_Manager,
	Uninstall_Path_Manager,
	Set_shared_path,
	Add_shared_path,
	Remove_shared_path,
	Builtin_bug_fix,
	Associate_prj_extension,
	Get_pathdef_permission,
};
enum class 提权操作异常
{
	Operation_succeeded,
	Builtin_bug_fix_command_is_0,
};