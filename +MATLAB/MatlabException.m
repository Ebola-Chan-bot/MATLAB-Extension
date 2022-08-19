classdef MatlabException<uint8&MATLAB.IEnumerableException
	enumeration
		Success(0)
		Input_is_not_a_string(1)
		File_operation_failed(2)

		Missing_matching_key(251)
		Fields_not_found_in_tables(252)
		Error_copying_file(253)
		Error_deleting_file(254)
		Error_moving_file(255)
	end
end