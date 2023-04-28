classdef MexException<uint8
	enumeration
		No_abnormalities(0)
		Type_conversion_failed(1)
		Memory_copy_failed(2)
		Enumerated_types_cannot_be_copied(3)
		Unsupported_types(4)
		Unsupported_APIs(5)
		This_Array_cannot_be_converted_to_CharArray(6)
		This_Array_cannot_be_converted_to_String(7)
		This_Array_cannot_be_converted_to_stdstring(8)
		This_Array_cannot_be_converted_to_StringArray(9)
		This_Array_cannot_be_converted_to_MATLABString(10)
		This_Array_cannot_be_copied_as_char(11)
		This_Array_cannot_be_copied_as_wchar_t(12)
	end
end