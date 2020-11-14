ALTER TABLE `hopsworks`.`conda_commands` ADD CONSTRAINT `FK_284_520` FOREIGN KEY (`project_id`) REFERENCES `project` (`id`) ON DELETE CASCADE ON UPDATE NO ACTION;

ALTER TABLE `hopsworks`.`conda_commands` CHANGE `environment_file` `environment_yml` VARCHAR(1000) COLLATE latin1_general_cs DEFAULT NULL;

ALTER TABLE `hopsworks`.`python_environment` DROP FOREIGN KEY `FK_PROJECT_ID`;

ALTER TABLE `hopsworks`.`project` DROP COLUMN `python_env_id`;

DROP TABLE IF EXISTS `hopsworks`.`python_environment`;

ALTER TABLE `hopsworks`.`project` ADD COLUMN `conda` tinyint(1) DEFAULT '0';
ALTER TABLE `hopsworks`.`project` ADD COLUMN `python_version` varchar(25) COLLATE latin1_general_cs DEFAULT NULL;
