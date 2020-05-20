ALTER TABLE `hopsworks`.`jupyter_settings` CHANGE COLUMN `base_dir` `base_dir` varchar(255) COLLATE latin1_general_cs DEFAULT NULL;

UPDATE `hopsworks`.`jupyter_settings` `j`
JOIN `hopsworks`.`project` `p`
ON `j`.`project_id` = `p`.`id`
SET `j`.`base_dir` = CONCAT('/Projects/',`p`.`projectname`,'/Jupyter');