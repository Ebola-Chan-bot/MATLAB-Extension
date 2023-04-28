classdef MexException<uint8
	enumeration
		Type_conversion_failed(0)
		Memory_copy_failed(1)
		Enumerated_types_cannot_be_copied(2)
		Unsupported_types(3)
		Unsupported_APIs(4)
	end
end