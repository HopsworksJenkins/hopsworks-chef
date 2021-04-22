ALTER TABLE `hopsworks`.`serving` DROP COLUMN `deployed`;
ALTER TABLE `hopsworks`.`serving` DROP COLUMN `revision`;

DROP TABLE `hopsworks`.`cached_feature`;
