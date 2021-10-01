CREATE PROCEDURE create_account(name VARCHAR(16), pass VARCHAR(32))
BEGIN
	IF name IN (SELECT username FROM User) THEN
		SELECT "This username is already taken" AS Error;
	ELSE
		IF LENGTH(pass) < 8 THEN
			SELECT "This password is too short" AS Error;
		ELSE
			INSERT INTO User (username, password) VALUES (name, pass);
			CALL refresh_rooms();
		END IF;
	END IF;
END
