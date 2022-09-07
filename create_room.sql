CREATE PROCEDURE create_room(name VARCHAR(16), pass VARCHAR(32), room_name VARCHAR(16), room_pass VARCHAR(32), TL INT)
COMMENT "create_room(username, password, room_name, room_pass, TL): creates a room with -room_name- and -room_pass-, time limit of a move (TL) should be between 10 and 90 seconds"
BEGIN
	DECLARE uid INT DEFAULT (SELECT user_id FROM User WHERE (username = name));
	DECLARE rid INT;
	IF name NOT IN (SELECT username FROM User) THEN
		SELECT "Wrong username" AS Error;
	ELSE
		IF pass NOT IN (SELECT password FROM User WHERE (username = name)) THEN
			SELECT "Wrong password" AS Error;
		ELSE
			IF TL BETWEEN 10 AND 90 THEN
				SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
				START TRANSACTION;
					IF !EXISTS(SELECT * FROM Room WHERE Room.name = room_name) THEN
						INSERT INTO Room (name, password, turn_tl, creators_id)
						VALUES(room_name,room_pass,TL,uid);
						SET rid = (SELECT room_id FROM Room WHERE Room.name = room_name);
						INSERT INTO ActivePlayers(room_id,user_id,next_id,turn) 
						VALUES(rid,uid,NULL,NULL);
						CALL show_members(rid);
						SELECT rid;
					ELSE
						ROLLBACK;
						SELECT "This room name is already in use" AS Error;
					END IF;
				COMMIT;
			ELSE
				SELECT "Time limit should be between 10 and 90 seconds" AS Error;
			END IF;
		END IF;
	END IF;
END