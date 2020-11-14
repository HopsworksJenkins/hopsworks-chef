SET @fk_name = (SELECT CONSTRAINT_NAME FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE WHERE TABLE_SCHEMA = "hopsworks" AND TABLE_NAME = "conda_commands" AND REFERENCED_TABLE_NAME="project");
# If fk does not exist, then just execute "SELECT 1"
SET @s = (SELECT IF((@fk_name) is not null,
                    concat('ALTER TABLE hopsworks.conda_commands DROP FOREIGN KEY `', @fk_name, '`'),
                    "SELECT 1"));
PREPARE stmt1 FROM @s;
EXECUTE stmt1;
DEALLOCATE PREPARE stmt1;

ALTER TABLE `hopsworks`.`conda_commands` CHANGE `environment_yml` `environment_file` VARCHAR(1000) COLLATE latin1_general_cs DEFAULT NULL;

ALTER TABLE `hopsworks`.`project` ADD COLUMN `python_env_id` int(11) DEFAULT NULL;

CREATE TABLE IF NOT EXISTS `python_environment` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `project_id` int(11) NOT NULL,
  `python_version` VARCHAR(25) COLLATE latin1_general_cs NOT NULL,
  `jupyter_conflicts` TINYINT(1) NOT NULL DEFAULT '0',
  `conflicts` VARCHAR(12000) COLLATE latin1_general_cs DEFAULT NULL,
  UNIQUE KEY `project_env` (`project_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `FK_PROJECT_ID` FOREIGN KEY (`project_id`) REFERENCES `project` (`id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=ndbcluster AUTO_INCREMENT=119 DEFAULT CHARSET=latin1 COLLATE=latin1_general_cs;

ALTER TABLE `hopsworks`.`project` DROP COLUMN `conda`;

ALTER TABLE `hopsworks`.`project` DROP COLUMN `python_version`;
