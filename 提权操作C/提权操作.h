#pragma once
#include<optional>
#include<functional>
namespace 提权操作
{
	enum class 提权操作函数
	{
		Install_Path_Manager,
		Uninstall_Path_Manager,
		Set_shared_path,
		Add_shared_path,
		Remove_shared_path,
		Builtin_bug_fix,
		Associate_prj_extension,
		Get_pathdef_permission,
		Serialport_snatch,
		Shutdown_server
	};
	enum class 提权操作异常
	{
		Operation_succeeded,
		Builtin_bug_fix_command_is_0,
		COM_number_not_found,
	};
	template<typename 值类型>
	struct 懒加载
	{
		const std::function<值类型()>取值方法;
		懒加载(std::function<值类型()>&&取值方法) :取值方法(std::move(取值方法)) {}
		值类型& operator()()noexcept
		{
			if (!容器.has_value())
				容器 = 取值方法();
			return 容器.value();
		}
	protected:
		std::optional<值类型>容器;
	};
}