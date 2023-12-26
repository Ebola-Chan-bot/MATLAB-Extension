#pragma once
#include<stdint.h>
namespace 提权操作
{
	namespace 内部
	{

	}
}
enum class 提权操作 :uint8_t
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
