CREATE TABLE `anaconda_repo` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `url` varchar(255) COLLATE latin1_general_cs NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `url` (`url`)
) ENGINE=ndbcluster AUTO_INCREMENT=4 DEFAULT CHARSET=latin1 COLLATE=latin1_general_cs;

INSERT INTO `anaconda_repo`(`url`) SELECT DISTINCT `repo_url` FROM `python_dep`;

ALTER TABLE `python_dep` ADD COLUMN `repo_id` INT(11);

SET SQL_SAFE_UPDATES = 0;
UPDATE `python_dep` `p` SET `repo_id`=(SELECT `id` FROM `anaconda_repo` WHERE `url` = `p`.`repo_url`);
SET SQL_SAFE_UPDATES = 1;

ALTER TABLE `python_dep` ADD CONSTRAINT `FK_501_510` FOREIGN KEY (`repo_id`) REFERENCES `anaconda_repo` (`id`) ON DELETE CASCADE ON UPDATE NO ACTION;

ALTER TABLE `python_dep` DROP INDEX `dependency`;
ALTER TABLE `python_dep` DROP COLUMN `repo_url`;
ALTER TABLE `python_dep` ADD CONSTRAINT `dependency` UNIQUE (`dependency`, `version`, `install_type`, `repo_id`);