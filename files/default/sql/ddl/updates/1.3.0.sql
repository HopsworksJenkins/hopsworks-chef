ALTER TABLE `hopsworks`.`shared_topics` ADD COLUMN `accepted` tinyint(1) NOT NULL DEFAULT '0';
SET SQL_SAFE_UPDATES = 0;
UPDATE `hopsworks`.`shared_topics` SET accepted=1;
SET SQL_SAFE_UPDATES = 1;

ALTER TABLE `hopsworks`.`external_training_dataset` ADD COLUMN `path` VARCHAR(10000);

-- Find the name of the FK
SET @fk_name = (SELECT CONSTRAINT_NAME FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE WHERE TABLE_SCHEMA = "hopsworks" AND TABLE_NAME = "training_dataset" AND REFERENCED_TABLE_NAME="hdfs_users");
SET @s := concat('ALTER TABLE hopsworks.training_dataset DROP FOREIGN KEY `', @fk_name, '`');
PREPARE stmt1 FROM @s;
EXECUTE stmt1;
DEALLOCATE PREPARE stmt1;

ALTER TABLE `hopsworks`.`training_dataset` DROP COLUMN `hdfs_user_id`; 

ALTER TABLE `hopsworks`.`feature_store_feature` MODIFY COLUMN `description` VARCHAR(10000) COLLATE latin1_general_cs;

CREATE TABLE IF NOT EXISTS `feature_store_tag` (
      `id` int(11) NOT NULL AUTO_INCREMENT,
      `name` varchar(255) NOT NULL,
      `type` varchar(45) NOT NULL DEFAULT 'STRING',
      PRIMARY KEY (`id`),
      UNIQUE KEY `name_UNIQUE` (`name`)
) ENGINE=ndbcluster DEFAULT CHARSET=latin1 COLLATE=latin1_general_cs;

ALTER TABLE `hopsworks`.`host_services` CHANGE COLUMN `service` `name` varchar(48) COLLATE latin1_general_cs NOT NULL;
ALTER TABLE `hopsworks`.`host_services` ADD UNIQUE KEY `service_UNIQUE` (`host_id`, `name`);
DELETE FROM `hopsworks`.`jobs` WHERE type="BEAM_FLINK";
ALTER TABLE `hopsworks`.`python_dep` ADD COLUMN `base_env` VARCHAR(45) COLLATE latin1_general_cs;
ALTER TABLE `hopsworks`.`conda_commands` DROP FOREIGN KEY `FK_481_519`;
ALTER TABLE `hopsworks`.`conda_commands` DROP COLUMN `host_id`, DROP INDEX `host_id` ;
ALTER TABLE `hopsworks`.`conda_commands` CHANGE `proj` `docker_image` varchar(255) COLLATE latin1_general_cs NOT NULL;
ALTER TABLE `hopsworks`.`jupyter_project` CHANGE `pid` `cid` varchar(255) COLLATE latin1_general_cs NOT NULL;
ALTER TABLE `hopsworks`.`tensorboard` CHANGE `pid` `cid` varchar(255) COLLATE latin1_general_cs NOT NULL;
ALTER TABLE `hopsworks`.`serving` CHANGE `local_pid` `cid` varchar(255) COLLATE latin1_general_cs NOT NULL;

