CREATE OR REPLACE PROCEDURE `_MATLAB_反序列化` () COMMENT '调用前必须先创建一个临时表`_MATLAB_反序列化_输入`，包含`名称`、`类型`、`长度`、`序列`4列，每行对应输出表的一列。名称为VARCHAR，表示输出列的名称；类型为VARCHAR，表示输出列的类型，可以指定UNSIGNED，不能指定是否为NULL，VARCHAR类型必须指定长度上限，字符串类型必须为UTF16编码，POINT的序列必须是两个 SMALLINT UNSIGNED 的拼接，DATETIME必须是DOUBLE类型的POSIX秒数；长度仅当类型为VARCHAR、任意TEXT、任意BLOB类型时才需要指定，指定为任意BLOB类型，为序列化的 INT UNSIGNED 数组，每个值对应输出表一行该列的变长长度；序列为任意BLOB类型，存储该列所有行值序列化的字节，变长类型直接简单拼接。该PROCEDURE返回后，将产生一个临时表存储反序列化后的数据，表名为`_MATLAB_反序列化_输出`。' NOT DETERMINISTIC MODIFIES SQL DATA SQL SECURITY INVOKER
BEGIN DECLARE 存在性检查 TINYINT;

DECLARE `名称` VARCHAR(32);

DECLARE 基本类型 VARCHAR(10);

DECLARE `完全类型` VARCHAR(10);

DECLARE `长度` MEDIUMBLOB;

DECLARE 序列 LONGBLOB;

DECLARE `字节数` TINYINT UNSIGNED;

DECLARE 变长类型 BIT(1);

DECLARE `继续` BIT(1) DEFAULT TRUE;

DECLARE 第一列 BIT(1) DEFAULT TRUE;

DECLARE 终点 INT UNSIGNED;

DECLARE 转码语句 TINYTEXT;

DECLARE `列` CURSOR FOR
SELECT
	名称,
	_MATLAB_类型.类型 AS 基本类型,
	_MATLAB_反序列化_输入.类型 AS 完全类型,
	长度,
	序列,
	字节数,
	变长类型
FROM
	_MATLAB_反序列化_输入
	INNER JOIN _MATLAB_类型 ON _MATLAB_类型.类型 LIKE CONCAT(_MATLAB_反序列化_输入.类型, '%');

DECLARE CONTINUE
HANDLER FOR NOT FOUND
SET
	`继续` = FALSE;

OPEN `列`;

WHILE `继续` DO
FETCH NEXT
FROM
	`列` INTO `名称`,
	基本类型,
	`完全类型`,
	`长度`,
	序列,
	`字节数`,
	变长类型;

IF 变长类型 THEN
SET
	终点 = OCTET_LENGTH(长度) -6;

CREATE OR REPLACE TEMPORARY TABLE _MATLAB_反序列化_截取 (
	长度 INT UNSIGNED NOT NULL,
	索引 BIGINT UNSIGNED NOT NULL,
	子序列 MEDIUMBLOB NULL,
	PRIMARY KEY (索引)
) AS
WITH RECURSIVE
	等差数列 AS (
		SELECT
			1 AS 起点
		UNION ALL
		SELECT
			起点 + 4
		FROM
			等差数列
		WHERE
			起点 < 终点
	)
SELECT
	CONV(HEX(SUBSTRING(长度, 起点, 4)), 16, 10) * 字节数 AS 长度,
	起点 AS 索引
FROM
	等差数列;

UPDATE _MATLAB_反序列化_截取
SET
	子序列 = SUBSTRING(
		序列,
		SUM(长度) OVER (
			ORDER BY
				索引
		) - (
			SELECT
				长度
			FROM
				_MATLAB_反序列化_截取
			WHERE
				索引 = 1
		) + 1,
		长度
	);

ELSE
SET
	终点 = OCTET_LENGTH(序列) - 字节数 * 2 + 2;

CREATE OR REPLACE TEMPORARY TABLE _MATLAB_反序列化_截取 AS
WITH RECURSIVE
	等差数列 AS (
		SELECT
			1 AS 起点
		UNION ALL
		SELECT
			起点 + 字节数
		FROM
			等差数列
		WHERE
			起点 < 终点
	)
SELECT
	SUBSTRING(序列, 起点, 字节数) AS 子序列,
	起点 AS 索引
FROM
	等差数列;

END IF;

IF 第一列 THEN
SET
	@`加列语句` = CONCAT(
		'CREATE OR REPLACE TEMPORARY TABLE _MATLAB_反序列化_输出(',
		名称,
		' ',
		完全类型,
		' NULL)Engine=InnoDB'
	);

SET
	@`插值语句` = CONCAT('INSERT _MATLAB_反序列化_输出(', `名称`, ')');

SET
	第一列 = FALSE;

ELSE
SET
	@`加列语句` = CONCAT(
		'ALTER TABLE _MATLAB_反序列化_输出 ADD ',
		名称,
		' ',
		完全类型,
		' NULL'
	);

SET
	@`插值语句` = CONCAT('UPDATE _MATLAB_反序列化_输出 SET ', 名称, ' =');

END IF;

PREPARE `语句准备`
FROM
	@`加列语句`;

EXECUTE `语句准备`;

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
	'JSON'
) THEN
SET
	转码语句 = 'CONVERT(子序列 USING utf16)';

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
	转码语句 = "DATE_ADD('1970-01-01',INTERVAL _MATLAB_Blob转Double(子序列) SECOND)";

END IF;

SET
	@`插值语句` = CONCAT(
		@`插值语句`,
		'(SELECT ',
		转码语句,
		' FROM _MATLAB_反序列化_截取 ORDER BY 索引)'
	);

PREPARE `语句准备`
FROM
	@`插值语句`;

EXECUTE `语句准备`;

END WHILE;

DEALLOCATE PREPARE `语句准备`;

END