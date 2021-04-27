ALTER TABLE `hopsworks`.`serving` ADD COLUMN `deployed` timestamp DEFAULT NULL;
ALTER TABLE `hopsworks`.`serving` ADD COLUMN `revision` VARCHAR(8) DEFAULT NULL;

ALTER TABLE `hopsworks`.`validation_rule` ADD COLUMN `feature_type` VARCHAR(45) COLLATE latin1_general_cs DEFAULT NULL AFTER `accepted_type`;