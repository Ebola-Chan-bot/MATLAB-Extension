CREATE
OR REPLACE TABLE _MATLAB_类型 (
	`类型` VARCHAR(10) CHARSET utf16 COLLATE utf16_bin NOT NULL,
	`字节数` TINYINT UNSIGNED NOT NULL,
	PRIMARY KEY (`类型` (10))
) ENGINE = InnoDB;

INSERT INTO
	`_MATLAB_类型` (`类型`, `字节数`)
VALUES
	('BIT', 1),
	('TINYINT', 1),
	('SMALLINT', 2),
	('INT', 4),
	('BIGINT', 8),
	('FLOAT', 4),
	('DOUBLE', 8),
	('CHAR', 2),
	('VARCHAR', 2),
	('BINARY', 1),
	('VARBINARY', 1),
	('TINYTEXT', 2),
	('TEXT', 2),
	('MEDIUMTEXT', 2),
	('LONGTEXT', 2),
	('TINYBLOB', 1),
	('BLOB', 1),
	('MEDIUMBLOB', 1),
	('LONGBLOB', 1),
	('POINT', 4),
	('DATETIME', 4),
	('JSON', 2),
	('ENUM', 2),
	('TIME(3)', 8)