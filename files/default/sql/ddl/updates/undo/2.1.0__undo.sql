ALTER TABLE `hopsworks`.`feature_store_jdbc_connector` DROP INDEX `jdbc_connector_feature_store_id_name`;
ALTER TABLE `hopsworks`.`feature_store_s3_connector` DROP INDEX `s3_connector_feature_store_id_name`;
ALTER TABLE `hopsworks`.`feature_store_s3_connector` DROP INDEX `fk_feature_store_s3_connector_1_idx`;

ALTER TABLE `hopsworks`.`feature_store_s3_connector` DROP COLUMN `iam_role`;
ALTER TABLE `hopsworks`.`feature_store_s3_connector` DROP COLUMN `key_secret_uid`;
ALTER TABLE `hopsworks`.`feature_store_s3_connector` DROP COLUMN `key_secret_name`;

DROP TABLE IF EXISTS `hopsworks`.`feature_store_redshift_connector`;