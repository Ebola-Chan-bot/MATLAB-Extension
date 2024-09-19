CREATE
OR
REPLACE
	PROCEDURE _MATLAB_合并更新 (输入表名 VARCHAR(32), 输出表名 VARCHAR(32)) COMMENT '输出表的非自增主键列必须均存在于输入表中。输出表的主键列值与输入表相同的行，将被更新为输入表的值。输入表中主键列值不存在于输出表中的行将被插入到输出表中。' NOT DETERMINISTIC MODIFIES SQL DATA SQL SECURITY INVOKER
BEGIN DECLARE 列名列表 TINYTEXT;

DECLARE 更新列表 TINYTEXT;

CALL _MATLAB_取列名和类型 (`输入表名`);

SELECT
	CONCAT(
		'ALTER TABLE ',
		`输出表名`,
		' ADD IF NOT EXISTS(',
		GROUP_CONCAT(
			CONCAT(COLUMN_NAME, ' ', COLUMN_TYPE, ' NULL') SEPARATOR ','
		),
		')'
	),
	GROUP_CONCAT(COLUMN_NAME SEPARATOR ','),
	GROUP_CONCAT(
		CONCAT(
			`输出表名`,
			'.',
			COLUMN_NAME,
			'=',
			`输入表名`,
			'.',
			COLUMN_NAME
		) SEPARATOR ','
	) INTO @`动态语句`,
	列名列表,
	更新列表
FROM
	_MATLAB_列名和类型;

PREPARE 语句准备
FROM
	@`动态语句`;

EXECUTE 语句准备;

SET
	@`动态语句` = CONCAT(
		'INSERT ',
		`输出表名`,
		'(',
		列名列表,
		')SELECT ',
		列名列表,
		' FROM ',
		`输入表名`,
		' ON DUPLICATE KEY UPDATE ',
		更新列表
	);

PREPARE 语句准备
FROM
	@`动态语句`;

EXECUTE 语句准备;

DEALLOCATE PREPARE 语句准备;

END