ALTER TABLE `python_dep` ADD COLUMN `repo_url` VARCHAR(255);

SET SQL_SAFE_UPDATES = 0;
UPDATE `python_dep` `p` SET `repo_url`=(SELECT `url` FROM `anaconda_repo` WHERE `id` = `p`.`repo_id`);
SET SQL_SAFE_UPDATES = 1;

SET @fk_name = (SELECT CONSTRAINT_NAME FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE WHERE TABLE_SCHEMA = "hopsworks" AND TABLE_NAME = "python_dep" AND REFERENCED_TABLE_NAME="anaconda_repo");
SET @s := concat('ALTER TABLE hopsworks.python_dep DROP FOREIGN KEY `', @fk_name, '`');
PREPARE stmt1 FROM @s;
EXECUTE stmt1;
DEALLOCATE PREPARE stmt1;

DROP TABLE `anaconda_repo`;

ALTER TABLE `python_dep` DROP INDEX `dependency`;
ALTER TABLE `python_dep` DROP COLUMN `repo_id`;
ALTER TABLE `python_dep` ADD CONSTRAINT `dependency` UNIQUE (`dependency`, `version`, `install_type`, `repo_url`);