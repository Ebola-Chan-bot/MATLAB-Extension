classdef MatlabException<uint8&MATLAB.Lang.IEnumerableException
	enumeration
		Success(0)
		Input_is_not_a_string(1)
		File_operation_failed(2)
		Zip_failed_to_open(3)
		Zip_filename_search_failed(4)
		Zip_file_failed_to_open(5)
		Wrong_input_parameter_type(6)
		Zip_file_read_failed(7)
		Wrong_number_of_input_parameters(8)
		Zip_archive_is_invalid(9)
		Failed_to_get_Zip_file_name(10)
		Failed_to_get_the_stat_of_the_Zip_file(11)
		Zip_doesnt_log_file_size(12)
		File_creation_failed(13)
		Failed_to_get_file_size(14)
		Failed_to_read_file(15)
		Set_file_end_failed(16)
		Failed_to_set_file_pointer(17)
		Failed_to_write_out_file(18)
		Failed_to_close_file(19)
		Failed_to_create_file_mapping(20)
		Failed_to_map_file_view(21)
		Memory_copy_failed(22)
		Unsupported_readin_types(23)
		Unsupported_writeout_types(24)
		Unsupported_array_types(25)
		MEX_exception(26)
		FillData_larger_than_NumBytes(27)
		Failed_to_open_file_mapping(28)
		Device_not_found(29)
		Fill_color_data_type_error(30)
		Invalid_pointer(31)
		Unknown_exception(32)
		Failed_to_save_shortcut(33)
		Failed_to_open_the_file(34)
		Failed_to_obtain_metadata(35)
		Failed_to_decode_pixel_data(36)

		Empty_inputs_may_return_unexpected_types(232)
		Query_graph_contains_cycles(233)
		Selected_tables_not_sharing_key_columns(234)
		Two_columns_not_connected(235)
		Dot_reference_is_unsupported(236)
		Specified_name_was_not_found(237)
		Example_exception(238)
		NumWantNew_is_too_big(239)
		Range_is_not_a_numerical_type(240)
		Invalid_RestartDisposition(241)
		PathManager_not_installed(242)
		Number_of_EdgeColors_does_not_match_number_of_lines(243)
		Number_of_LineStyles_does_not_match_number_of_lines(244)
		Cannot_own_a_non_handle_value(245)
		Stack_is_empty(246)
		Queue_is_empty(247)
		Empty_vector_must_specify_a_padding_value(248)
		Vector_is_empty(249)
		Index_exceeds_vector_size(250)
		Missing_matching_key(251)
		Column_not_found_in_tables(252)
		Error_copying_file(253)
		Error_deleting_file(254)
		Error_moving_file(255)
	end
end