ALTER TABLE `hopsworks`.`oauth_client` 
ADD COLUMN `end_session_endpoint` VARCHAR(1024) DEFAULT NULL,
ADD COLUMN `logout_redirect_param` VARCHAR(45) DEFAULT NULL;