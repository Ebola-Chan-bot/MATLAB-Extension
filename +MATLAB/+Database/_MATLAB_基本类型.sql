CREATE OR REPLACE TABLE _MATLAB_类型 (
	`类型` VARCHAR(10) CHARACTER SET utf16 COLLATE utf16_bin NOT NULL,
	`字节数` TINYINT UNSIGNED NOT NULL,
	变长类型 BIT(1) NOT NULL,
	PRIMARY KEY (`类型` (10))
) ENGINE = InnoDB;

INSERT INTO
	`_MATLAB_类型` (`类型`, `字节数`, 变长类型)
VALUES
	('BIT', 1, 0),
	('TINYINT', 1, 0),
	('SMALLINT', 2, 0),
	('INT', 4, 0),
	('BIGINT', 8, 0),
	('FLOAT', 4, 0),
	('DOUBLE', 8, 0),
	('CHAR', 2, 1),
	('VARCHAR', 2, 1),
	('BINARY', 1, 1),
	('VARBINARY', 1, 1),
	('TINYTEXT', 2, 1),
	('TEXT', 2, 1),
	('MEDIUMTEXT', 2, 1),
	('LONGTEXT', 2, 1),
	('TINYBLOB', 1, 1),
	('BLOB', 1, 1),
	('MEDIUMBLOB', 1, 1),
	('LONGBLOB', 1, 1),
	('POINT', 4, 0),
	('DATETIME', 8, 0),
	('JSON', 2, 1);