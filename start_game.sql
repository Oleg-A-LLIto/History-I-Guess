CREATE PROCEDURE start_game(name VARCHAR(16), pass VARCHAR(32), rid INT)
COMMENT "start_game(username, password, room_id): starts the game if you are its creator"
BEGIN
	DECLARE first INT;
	DECLARE togive INT;
	IF name NOT IN (SELECT username FROM User) THEN
		SELECT "Wrong username" AS Error;
	ELSE
		IF pass NOT IN (SELECT password FROM User WHERE (username = name)) THEN
			SELECT "Wrong password" AS Error;
		ELSE
			IF rid NOT IN (SELECT room_id FROM Room) THEN 
				SELECT "This room does not exist" AS Error;
			ELSE
				IF (SELECT user_id FROM User WHERE (username = name)) NOT IN (SELECT creators_id FROM Room WHERE (room_id = rid)) THEN
					SELECT "Only room administrators can start the game" AS Error;
				ELSE
					IF (SELECT card_id FROM Places WHERE (room_id = rid) LIMIT 1) IS NOT NULL THEN
						SELECT "This game is already running" AS Error;
					ELSE
						IF (SELECT COUNT(*) FROM ActivePlayers WHERE room_id = rid) < 2 THEN
							SELECT "You are alone in this room" AS Error;
						ELSE
							SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
							START TRANSACTION;
								CALL start(rid);
							COMMIT;
							CALL refresh_game(name,pass, rid);
						END IF;
					END IF;
				END IF;
			END IF;
		END IF;
	END IF;
END