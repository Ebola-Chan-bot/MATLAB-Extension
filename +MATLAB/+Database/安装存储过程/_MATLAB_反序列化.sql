CREATE
OR REPLACE PROCEDURE `_MATLAB_反序列化` (输出表名 VARCHAR(32) CHARSET utf16 COLLATE utf16_bin) COMMENT '调用前必须先创建一个临时表`_MATLAB_反序列化_输入`，包含`名称`、`类型`、`长度`、`序列`4列，每行对应输出表的一列。名称为VARCHAR，表示输出列的名称；类型为VARCHAR，表示输出列的类型，可以指定 UNSIGNED, CHARACTER SET, COLLATE 修饰，但不能指定是否为NULL，VARCHAR类型必须指定长度上限，字符串类型必须为utf16le编码；长度表示变长类型每一行的长度或数据的有无，指定为任意BLOB类型，为序列化的 INT UNSIGNED 数组，每个值对应输出表一行该列的变长长度，长度为0xFFFFFFFF表示NULL；对标量类型则为1表示不为空，0表示NULL；序列为任意BLOB类型，存储该列所有行值序列化的字节，变长类型直接简单拼接，POINT的序列必须是两个 SMALLINT UNSIGNED 的拼接，DATETIME必须是DOUBLE类型的POSIX秒数。该PROCEDURE返回后，将产生一个临时表存储反序列化后的数据，表名由`输出表名`参数所指定。如果那个表已存在，不会覆盖，而是尝试根据主键将数据合并到那个表中。' NOT DETERMINISTIC MODIFIES SQL DATA SQL SECURITY INVOKER 提前结束: BEGIN DECLARE 存在性检查 TINYINT;

DECLARE `名称` VARCHAR(32) CHARSET utf16 COLLATE utf16_bin;

DECLARE 基本类型 VARCHAR(10) CHARSET utf16 COLLATE utf16_bin;

-- ENUM完全类型可能会很长。MariaDB注释语法要求--后面必须跟空格
DECLARE `完全类型` VARCHAR(512) CHARSET utf16 COLLATE utf16_bin;

DECLARE 序列化长度 MEDIUMBLOB;

DECLARE 序列 LONGBLOB;

DECLARE `字节数` TINYINT UNSIGNED;

DECLARE 终点 INT UNSIGNED;

DECLARE 转码语句 TINYTEXT CHARSET utf16 COLLATE utf16_bin;

DECLARE 循环结束 BIT(1) DEFAULT FALSE;

DECLARE 表存在 BIT(1);

DECLARE 列名列表 TINYTEXT CHARSET utf16 COLLATE utf16_bin;

DECLARE 更新列表 TEXT CHARSET utf16 COLLATE utf16_bin;

DECLARE `列` CURSOR FOR
SELECT
	_MATLAB_反序列化_输入.名称,
	_MATLAB_类型.类型 AS 基本类型,
	_MATLAB_反序列化_输入.类型 AS 完全类型,
	_MATLAB_反序列化_输入.长度,
	_MATLAB_反序列化_输入.序列,
	_MATLAB_类型.字节数
FROM
	_MATLAB_反序列化_输入
	INNER JOIN _MATLAB_类型 ON _MATLAB_反序列化_输入.类型 LIKE CONCAT(_MATLAB_类型.类型, '%');

DECLARE CONTINUE HANDLER FOR NOT FOUND
SET
	循环结束 = TRUE;

OPEN `列`;

-- 第一FETCH后要做很多特殊的操作在后续循环中复用，所以不放在WHILE中
FETCH NEXT
FROM
	`列` INTO `名称`,
	基本类型,
	`完全类型`,
	序列化长度,
	序列,
	`字节数`;

SET
	终点 = OCTET_LENGTH(序列化长度) -6;

CREATE
OR REPLACE TEMPORARY TABLE _MATLAB_反序列化_截取 (
	索引 INT UNSIGNED NOT NULL,
	长度 INT UNSIGNED NOT NULL DEFAULT 0,
	起点 BIGINT UNSIGNED NOT NULL DEFAULT 1,
	子序列 MEDIUMBLOB NULL,
	PRIMARY KEY (索引)
) AS WITH RECURSIVE 等差数列 AS (
	SELECT
		1 AS 索引
	UNION ALL
	SELECT
		索引 + 4
	FROM
		等差数列
	WHERE
		索引 < 终点
)
SELECT
	索引
FROM
	等差数列;

CREATE
OR REPLACE TEMPORARY TABLE _MATLAB_反序列化_输出 AS
SELECT
	索引 AS _MATLAB_索引
FROM
	_MATLAB_反序列化_截取;

列循环: WHILE TRUE DO
UPDATE
	_MATLAB_反序列化_截取
SET
	子序列 = SUBSTRING(序列化长度, 索引, 4);

-- 必须在这里设置长度，因为可能会有上一个循环遗留的值
UPDATE
	_MATLAB_反序列化_截取
SET
	子序列 = NULL,
	长度 = 0
WHERE
	子序列 = 0xFFFFFFFF;

UPDATE
	_MATLAB_反序列化_截取
SET
	长度 = CONV(HEX(REVERSE(子序列)), 16, 10) * 字节数
WHERE
	子序列 IS NOT NULL;

-- 截取表的起点第1行实际上永不更新，始终为默认值1
UPDATE
	_MATLAB_反序列化_截取
	INNER JOIN (
		SELECT
			SUM(_MATLAB_反序列化_截取.长度) OVER (
				ORDER BY
					索引
			) AS 起点,
			索引
		FROM
			_MATLAB_反序列化_截取
	) AS 起点表 ON _MATLAB_反序列化_截取.索引 = 起点表.索引 + 4
SET
	_MATLAB_反序列化_截取.起点 = 1 + 起点表.起点;

UPDATE
	_MATLAB_反序列化_截取
SET
	子序列 = SUBSTRING(序列, 起点, 长度)
WHERE
	子序列 IS NOT NULL;

SET
	@语句文本 = CONCAT(
		'ALTER TABLE _MATLAB_反序列化_输出 ADD IF NOT EXISTS ',
		名称,
		' ',
		完全类型,
		' NULL'
	);

PREPARE `语句准备`
FROM
	@语句文本;

EXECUTE `语句准备`;

SET
	@语句文本 = CONCAT(
		'UPDATE _MATLAB_反序列化_输出 INNER JOIN _MATLAB_反序列化_截取 ON _MATLAB_反序列化_输出._MATLAB_索引=_MATLAB_反序列化_截取.索引 SET ',
		名称,
		'='
	);

IF 基本类型 IN ('BIT', 'TINYINT', 'SMALLINT', 'INT', 'BIGINT') THEN
SET
	转码语句 = 'CONV(HEX(REVERSE(子序列)),16,10)';

ELSEIF 基本类型 = 'FLOAT' THEN
SET
	转码语句 = '_MATLAB_Blob转Float(子序列)';

ELSEIF 基本类型 = 'DOUBLE' THEN
SET
	转码语句 = '_MATLAB_Blob转Double(子序列)';

ELSEIF 基本类型 IN (
	'VARCHAR',
	'TINYTEXT',
	'TEXT',
	'MEDIUMTEXT',
	'LONGTEXT',
	'CHAR',
	'JSON',
	'ENUM'
) THEN
SET
	转码语句 = 'CONVERT(子序列 USING utf16le)';

ELSEIF 基本类型 IN (
	'TINYBLOB',
	'BLOB',
	'MEDIUMBLOB',
	'LONGBLOB',
	'BINARY',
	'VARBINARY'
) THEN
SET
	转码语句 = '子序列';

ELSEIF 基本类型 = 'POINT' THEN
SET
	转码语句 = '_MATLAB_Blob转Point(子序列)';

ELSEIF 基本类型 = 'DATETIME' THEN
SET
	转码语句 = "DATE_ADD('1970-01-01',INTERVAL CONV(HEX(REVERSE(子序列)),16,10)SECOND)";

ELSEIF 基本类型 = 'TIME(3)' THEN
SET
	转码语句 = 'SEC_TO_TIME(ROUND(_MATLAB_Blob转Double(子序列),3))';

END IF;

SET
	@语句文本 = CONCAT(@语句文本, 转码语句);

PREPARE `语句准备`
FROM
	@语句文本;

EXECUTE `语句准备`;

FETCH NEXT
FROM
	`列` INTO `名称`,
	基本类型,
	`完全类型`,
	序列化长度,
	序列,
	`字节数`;

IF 循环结束 THEN LEAVE 列循环;

END IF;

END WHILE;

ALTER TABLE
	_MATLAB_反序列化_输出 DROP _MATLAB_索引;

CALL _MATLAB_表存在(输出表名, 表存在);

IF 表存在 THEN
SELECT
	CONCAT(
		'ALTER TABLE ',
		`输出表名`,
		' ADD IF NOT EXISTS(',
		GROUP_CONCAT(CONCAT(名称, ' ', 类型, ' NULL') SEPARATOR ','),
		')'
	) INTO @语句文本
FROM
	_MATLAB_反序列化_输入;

ELSE
SET
	@语句文本 = CONCAT(
		'CREATE TABLE IF NOT EXISTS ',
		`输出表名`,
		' LIKE _MATLAB_反序列化_输出'
	);

END IF;

PREPARE 语句准备
FROM
	@语句文本;

EXECUTE 语句准备;

SELECT
	GROUP_CONCAT(_MATLAB_反序列化_输入.名称 SEPARATOR ','),
	GROUP_CONCAT(
		CONCAT(
			`输出表名`,
			'.',
			_MATLAB_反序列化_输入.名称,
			'=_MATLAB_反序列化_输出.',
			_MATLAB_反序列化_输入.名称
		) SEPARATOR ','
	) INTO 列名列表,
	更新列表
FROM
	_MATLAB_反序列化_输入;

SET
	@语句文本 = CONCAT(
		'INSERT ',
		`输出表名`,
		'(',
		列名列表,
		')SELECT ',
		列名列表,
		' FROM _MATLAB_反序列化_输出 ON DUPLICATE KEY UPDATE ',
		更新列表
	);

PREPARE 语句准备
FROM
	@语句文本;

EXECUTE 语句准备;

END