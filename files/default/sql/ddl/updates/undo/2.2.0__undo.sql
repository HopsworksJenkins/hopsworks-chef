ALTER TABLE `hopsworks`.`feature_store_tag` ADD COLUMN `type` varchar(45) NOT NULL DEFAULT 'STRING';
ALTER TABLE `hopsworks`.`feature_store_tag` DROP COLUMN `tag_schema`;
DROP TABLE IF EXISTS `validation_rule`;
DROP TABLE IF EXISTS `feature_group_rule`;
DROP TABLE IF EXISTS `feature_group_validation`;
DROP TABLE IF EXISTS `feature_store_expectation_rule`;
ALTER TABLE `hopsworks`.`feature_group` DROP COLUMN `validation_type`;