#pragma once
#include<functional>
#include<optional>
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
template<typename 取值方法类型>
struct function类型转换_s
{
	取值方法类型 方法;
	using 类型 = decltype(std::function(方法));
};
template<typename 取值方法类型>
using function类型转换 = function类型转换_s<取值方法类型>::类型;
template<typename 取值方法类型>
struct 懒加载:function类型转换<取值方法类型>
{
	懒加载(取值方法类型 取值方法) :function类型转换<取值方法类型>(取值方法) {}
	template<typename...参数类型>
	function类型转换<取值方法类型>::result_type& operator()(参数类型...参数)
	{
		if (!容器.has_value())
			容器 = function类型转换<取值方法类型>::operator()(参数...);
		return 容器.value();
	}
protected:
	std::optional<typename function类型转换<取值方法类型>::result_type>容器;
};