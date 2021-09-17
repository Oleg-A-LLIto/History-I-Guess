CREATE PROCEDURE create_room(name VARCHAR(16), pass VARCHAR(32), room_name VARCHAR(16), room_pass VARCHAR(32), TL INT)
BEGIN
	DECLARE uid INT DEFAULT (SELECT user_id FROM User WHERE (username = name));
	DECLARE pid INT;
	IF name NOT IN (SELECT username FROM User) THEN
		SELECT "Wrong username" AS Error;
	ELSE
		IF pass NOT IN (SELECT password FROM User WHERE (username = name)) THEN
			SELECT "Wrong password" AS Error;
		ELSE
			IF room_name NOT IN (SELECT Room.name FROM Room) THEN
				IF (TL>10)&&(TL<90) THEN
					INSERT INTO Room (name, password, turn_tl, creators_id)
					VALUES(room_name,room_pass,TL,uid);
					INSERT INTO ActivePlayers(room_id,user_id,next_id,turn) 
					VALUES((SELECT room_id FROM Room WHERE Room.name = room_name),uid,-1,NULL);
					SET pid = (SELECT player_id FROM ActivePlayers WHERE user_id = uid);
					UPDATE ActivePlayers
					SET next_id = pid
					WHERE (room_id = (SELECT room_id FROM Room WHERE Room.name = room_name));
					CALL show_members((SELECT room_id FROM Room WHERE Room.name = room_name));
				ELSE
					SELECT "Time limit should be between 10 and 90 seconds" AS Error;
				END IF;
			ELSE
				SELECT "This room name is already in use" AS Error;
			END IF;
		END IF;
	END IF;
END