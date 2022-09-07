CREATE PROCEDURE create_account_halt(name VARCHAR(16), pass VARCHAR(32))
COMMENT "create_account(username, password): creates an account"
BEGIN
	IF LENGTH(pass) < 8 THEN
		SELECT "This password is too short" AS Error;
	ELSE
		SET TRANSACTION ISOLATION LEVEL READ COMMITED;
		START TRANSACTION;
			IF EXISTS (SELECT * FROM User where username = name FOR UPDATE) THEN
				SELECT "This username is already taken" AS Error;
				ROLLBACK;
			ELSE
				CALL host700505_sandbox.tormoz(6);
				INSERT INTO User (username, password) VALUES (name, pass);
				CALL refresh_rooms(1,1,1);
			END IF;
		COMMIT;
	END IF;
END
