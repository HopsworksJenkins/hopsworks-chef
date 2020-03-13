ALTER TABLE `hopsworks`.`shared_topics` DROP COLUMN `accepted`;

ALTER TABLE `hopsworks`.`host_services` DROP KEY `service_UNIQUE`;
ALTER TABLE `hopsworks`.`host_services` CHANGE COLUMN `name` `service` varchar(48) COLLATE latin1_general_cs NOT NULL;