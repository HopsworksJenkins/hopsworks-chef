DROP TABLE IF EXISTS `hopsworks`.`featurestore_statistic`;

CREATE TABLE `feature_store_statistic` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `commit_time` VARCHAR(20) COLLATE latin1_general_cs NOT NULL,
  `inode_pid` BIGINT(20) NOT NULL,
  `inode_name` VARCHAR(255) COLLATE latin1_general_cs NOT NULL,
  `partition_id` BIGINT(20) NOT NULL,
  `feature_group_id` INT(11),
  `training_dataset_id`INT(11),
  PRIMARY KEY (`id`),
  KEY `feature_group_id` (`feature_group_id`),
  KEY `training_dataset_id` (`training_dataset_id`),
  CONSTRAINT `fg_fk` FOREIGN KEY (`feature_group_id`) REFERENCES `feature_group` (`id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  CONSTRAINT `td_fk` FOREIGN KEY (`training_dataset_id`) REFERENCES `training_dataset` (`id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  CONSTRAINT `inode_fk` FOREIGN KEY (`inode_pid`,`inode_name`,`partition_id`) REFERENCES `hops`.`hdfs_inodes` (`parent_id`,`name`,`partition_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=ndbcluster DEFAULT CHARSET=latin1 COLLATE=latin1_general_cs;

ALTER TABLE `hopsworks`.`feature_group` DROP COLUMN `cluster_analysis_enabled`;
ALTER TABLE `hopsworks`.`feature_group` DROP COLUMN `num_clusters`;
ALTER TABLE `hopsworks`.`feature_group` DROP COLUMN `num_bins`;
ALTER TABLE `hopsworks`.`feature_group` DROP COLUMN `corr_method`;

/*
The following changes are related to Migration to NDB8
The following changes are implemented using procedures 
so that database upgrades do not fail as these changes 
might be applied twice. First at the time of manually 
migrationg NDB and later by karamel. 
*/
DELIMITER $$
/*
    DROP_FOREIGN_KEY_IF_EXISTS
*/

DROP PROCEDURE IF EXISTS DROP_FOREIGN_KEY_IF_EXISTS$$

CREATE PROCEDURE DROP_FOREIGN_KEY_IF_EXISTS(IN tableName VARCHAR(128), IN constraintName VARCHAR(128))
BEGIN
    IF EXISTS(
        SELECT * FROM information_schema.TABLE_CONSTRAINTS
        WHERE 
            TABLE_SCHEMA    = DATABASE()     AND
            TABLE_NAME      = tableName      AND
            CONSTRAINT_NAME = constraintName AND
            CONSTRAINT_TYPE = 'FOREIGN KEY')
    THEN
        SET @query = CONCAT('ALTER TABLE ', DATABASE(), ".", tableName, ' DROP FOREIGN KEY ', constraintName);
        PREPARE stmt FROM @query; 
        EXECUTE stmt; 
        DEALLOCATE PREPARE stmt; 
    ELSE
        SELECT concat('Unable to delete foreign key as it does not exist. Foreign Key: ', constraintName) AS ' ';
    END IF; 
END$$

/*
    CREATE_FOREIGN_KEY_IF_NOT_EXISTS
*/
DROP PROCEDURE IF EXISTS CREATE_FOREIGN_KEY_IF_NOT_EXISTS$$

CREATE PROCEDURE CREATE_FOREIGN_KEY_IF_NOT_EXISTS(
    IN tableName VARCHAR(128),
    IN tableColumn VARCHAR(128),
    IN constraintName VARCHAR(128),
    IN constraintTable VARCHAR(128),
    IN contraintColumn VARCHAR(128))
BEGIN
    IF EXISTS(
        SELECT * FROM information_schema.TABLE_CONSTRAINTS
        WHERE 
            TABLE_SCHEMA    = DATABASE()     AND
            TABLE_NAME      = tableName      AND
            CONSTRAINT_NAME = constraintName AND
            CONSTRAINT_TYPE = 'FOREIGN KEY')
    THEN
        SELECT concat('Unable to create foreign key as it already exists. Foreign Key: ', constraintName) AS ' ';
    ELSE
        SET @query = CONCAT('ALTER TABLE ', DATABASE(), ".", tableName, ' ADD CONSTRAINT ', constraintName, ' FOREIGN KEY (', tableColumn, ') REFERENCES ', constraintTable, '(', contraintColumn, ') ', '  ON DELETE CASCADE ON UPDATE NO ACTION '  );
        PREPARE stmt FROM @query; 
        EXECUTE stmt; 
        DEALLOCATE PREPARE stmt; 
    END IF; 
END$$


CALL DROP_FOREIGN_KEY_IF_EXISTS('conda_commands', 'user_fk')$$
CALL CREATE_FOREIGN_KEY_IF_NOT_EXISTS('conda_commands', 'user_id', 'user_fk_conda', 'users', 'uid')$$

CALL DROP_FOREIGN_KEY_IF_EXISTS('feature_group', 'on_demand_feature_group_fk')$$
CALL CREATE_FOREIGN_KEY_IF_NOT_EXISTS('feature_group', 'on_demand_feature_group_id', 'on_demand_feature_group_fk2', 'on_demand_feature_group', 'id')$$

CALL DROP_FOREIGN_KEY_IF_EXISTS('schemas', 'project_idx')$$
CALL CREATE_FOREIGN_KEY_IF_NOT_EXISTS('schemas', 'project_id', 'project_idx_schemas', 'project', 'id')$$

CALL DROP_FOREIGN_KEY_IF_EXISTS('subjects', 'project_idx')$$
CALL CREATE_FOREIGN_KEY_IF_NOT_EXISTS('subjects', 'project_id', 'project_idx_subjects', 'project', 'id')$$

CALL DROP_FOREIGN_KEY_IF_EXISTS('subjects_compatibility', 'project_idx')$$
CALL CREATE_FOREIGN_KEY_IF_NOT_EXISTS('subjects_compatibility', 'project_id', 'project_idx_sub_comp', 'project', 'id')$$

CALL DROP_FOREIGN_KEY_IF_EXISTS('project_topics', 'project_idx')$$
CALL CREATE_FOREIGN_KEY_IF_NOT_EXISTS('project_topics', 'project_id', 'project_idx_proj_topics', 'project', 'id')$$

CALL DROP_FOREIGN_KEY_IF_EXISTS('rstudio_settings', 'FK_262_309')$$
CALL CREATE_FOREIGN_KEY_IF_NOT_EXISTS('rstudio_settings', 'team_member', 'RS_FK_USERS', 'users', 'email')$$

CALL DROP_FOREIGN_KEY_IF_EXISTS('rstudio_settings', 'FK_284_308')$$
CALL CREATE_FOREIGN_KEY_IF_NOT_EXISTS('rstudio_settings', 'project_id', 'RS_FK_PROJS', 'project', 'id')$$

CALL DROP_FOREIGN_KEY_IF_EXISTS('serving', 'user_fk')$$
CALL CREATE_FOREIGN_KEY_IF_NOT_EXISTS('serving', 'creator', 'user_fk_serving', 'users', 'uid')$$

CALL DROP_FOREIGN_KEY_IF_EXISTS('shared_topics', 'topic_idx')$$
CALL CREATE_FOREIGN_KEY_IF_NOT_EXISTS('shared_topics', 'topic_name, owner_id', 'topic_idx_shared', 'project_topics', 'topic_name, project_id')$$

CALL DROP_FOREIGN_KEY_IF_EXISTS('topic_acls', 'topic_idx')$$
CALL CREATE_FOREIGN_KEY_IF_NOT_EXISTS('topic_acls', 'topic_name, project_id', 'topic_idx_topic_acls', 'project_topics', 'topic_name, project_id')$$

CALL DROP_FOREIGN_KEY_IF_EXISTS('feature_store_feature', 'on_demand_feature_group_fk')$$
CALL CREATE_FOREIGN_KEY_IF_NOT_EXISTS('feature_store_feature', 'on_demand_feature_group_id', 'on_demand_feature_group_fk1', 'on_demand_feature_group', 'id')$$

DELIMITER ;
