##########################################
# Initalize {deprecated} database schemas
# - Create Database {deprecated}
# - DBA_migration_status
# - DBA_migration_log
##########################################
CREATE DATABASE IF NOT EXISTS `deprecated` DEFAULT CHARACTER SET utf8;

CREATE TABLE IF NOT EXISTS `deprecated`.`DBA_migration_status` (
  `uid` int(11) NOT NULL AUTO_INCREMENT,
  `source` varchar(60) NOT NULL,
  `destination` varchar(60) NOT NULL,
  `object_name` varchar(100) NOT NULL,
  `object_newname` varchar(100) DEFAULT NULL,
  `object_type` varchar(20) NOT NULL,
  `create_date` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_date` datetime NOT NULL ON UPDATE CURRENT_TIMESTAMP,
  `comments` varchar(1000) DEFAULT NULL,
  `status_flag` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`uid`),
  UNIQUE KEY `unique_check` (`source`,`destination`,`object_name`,`object_newname`,`object_type`)
) ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `deprecated`.`DBA_migration_log` (
  `uid` int(11) NOT NULL AUTO_INCREMENT,
  `migration_status_id` int(11) NOT NULL,
  `log_text` text,
  `status_flag_id` int(11) DEFAULT NULL,
  `condition_code` int(11) DEFAULT NULL,
  `error_code` varchar(20) DEFAULT NULL,
  `error_num` int(11) DEFAULT NULL,
  `log_date` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`uid`)
) ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=utf8;
