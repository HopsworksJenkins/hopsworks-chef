ALTER TABLE `hopsworks`.`shared_topics` ADD COLUMN `accepted` tinyint(1) NOT NULL DEFAULT '0';
SET SQL_SAFE_UPDATES = 0;
UPDATE `hopsworks`.`shared_topics` SET accepted=1;
SET SQL_SAFE_UPDATES = 1;

ALTER TABLE `hopsworks`.`host_services` CHANGE COLUMN `service` `name` varchar(48) COLLATE latin1_general_cs NOT NULL;
ALTER TABLE `hopsworks`.`host_services` ADD UNIQUE KEY `service_UNIQUE` (`host_id`, `name`);