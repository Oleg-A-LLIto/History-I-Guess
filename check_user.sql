CREATE PROCEDURE check_user(name VARCHAR(16), pass VARCHAR(32))
COMMENT "check_user(name VARCHAR(16), pass VARCHAR(32))"
BEGIN
	IF name NOT IN (SELECT username FROM User) THEN
		SELECT "Wrong username" AS Error;
	ELSE
		IF pass NOT IN (SELECT password FROM User WHERE (username = name)) THEN
			SELECT "Wrong password" AS Error;
		ELSE
			CALL refresh_rooms(1,1,1);
		END IF;
	END IF;
END