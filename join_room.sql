CREATE PROCEDURE join_room(name VARCHAR(16), pass VARCHAR(32), room_name VARCHAR(16), room_pass VARCHAR(32))
COMMENT "join_room(username, password, room_name, room_pass): join room -room_name- with a -room_pass-"
BEGIN
	DECLARE rid INT DEFAULT (SELECT room_id FROM Room WHERE (Room.name = room_name));
	DECLARE uid INT DEFAULT (SELECT user_id FROM User WHERE (username = name));
	DECLARE prev, this, next INT;
	IF name NOT IN (SELECT username FROM User) THEN
		SELECT "Wrong username" AS Error;
	ELSE
		IF pass NOT IN (SELECT password FROM User WHERE (username = name)) THEN
			SELECT "Wrong password" AS Error;
		ELSE
			IF room_name NOT IN (SELECT Room.name FROM Room) THEN
				SELECT "This room does not exist" AS Error;
			ELSE
				IF room_pass NOT IN (SELECT Room.password FROM Room WHERE (Room.name = room_name)) THEN
					SELECT "Wrong room password" AS Error;
				ELSE
					IF (SELECT card_id FROM Places WHERE (room_id = rid)) IS NOT NULL THEN
						SELECT "Cannot join an ongoing game" AS Error;
					ELSE
						IF (SELECT count(player_id) FROM ActivePlayers WHERE room_id = rid) = 4 THEN
							SELECT "This room is already full" as Error;
						ELSE
							IF rid NOT IN (SELECT room_id FROM ActivePlayers WHERE user_id = uid) THEN
								SET prev = (SELECT player_id FROM ActivePlayers WHERE (room_id = rid)&&(next_id IS NULL));
								INSERT INTO ActivePlayers(room_id,user_id,next_id,turn) VALUES(rid,uid,NULL,NULL);
								SET this = (SELECT player_id FROM ActivePlayers WHERE (user_id = uid)&&(room_id = rid));
								UPDATE ActivePlayers
								SET next_id = this
								WHERE player_id = prev;
								CALL show_members(rid);
							ELSE
								SELECT "You are already playing in this room!" AS Error;
							END IF;
						END IF;
					END IF;
				END IF;
			END IF;
		END IF;
	END IF;
END