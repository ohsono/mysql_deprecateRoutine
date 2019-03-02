CREATE DATABASE IF NOT EXISTS `test`;

DROP PROCEDURE IF EXISTS `test`.`Proc_test1234`;

DELIMITER $$
CREATE PROCEDURE `test`.`Proc_test1234`(name_1 varchar(100))
begin


	DECLARE regex_rule varchar(100);
	SET regex_rule = '^.+_DEPR_([0-9]{8})$';
    select name_1, regex_rule;
	IF name_1 regexp regex_rule then
		select 'yes';
	end if;

end$$
DELIMITER ;


call `deprecated`.`Proc_DBA_DeprecateRoutines` ('test','deprecated','Proc_test1234','procedure');


DROP FUNCTION IF EXISTS `test`.`FN_test1234`;

DELIMITER $$

CREATE FUNCTION `test`.`FN_test1234`() RETURNS tinyint(1)
	READS SQL DATA
begin
	return true;
end$$
DELIMITER ;

call `deprecated`.`Proc_DBA_DeprecateRoutines` ('test','deprecated','Proc_test1234','function');
