CREATE PROCEDURE leave_room(name VARCHAR(16), pass VARCHAR(32), room_name VARCHAR(16))
BEGIN
	DECLARE rid INT DEFAULT (SELECT room_id FROM Room WHERE (Room.name = room_name));
	DECLARE uid INT DEFAULT (SELECT user_id FROM User WHERE (username = name));
	DECLARE prev, next INT; 
	IF name NOT IN (SELECT username FROM User) THEN
		SELECT "Wrong username" AS Error;
	ELSE
		IF pass NOT IN (SELECT password FROM User WHERE (username = name)) THEN
			SELECT "Wrong password" AS Error;
		ELSE
			IF room_name NOT IN (SELECT Room.name FROM Room) THEN 
				SELECT "This room does not exist" AS Error;
			ELSE
				IF rid NOT IN (SELECT room_id FROM InactivePlayers WHERE user_id = uid) THEN
					IF rid NOT IN (SELECT room_id FROM ActivePlayers WHERE user_id = uid) THEN
						SELECT "You are not in this room" AS Error;
					ELSE
						SET next = (SELECT next_id FROM ActivePlayers WHERE (user_id = uid)&&(room_id = rid));
						SET prev = (SELECT player_id FROM ActivePlayers WHERE (next_id = (SELECT player_id FROM ActivePlayers WHERE (user_id = uid)&&(room_id = rid))) && (room_id = rid));
						DELETE FROM ActivePlayers WHERE (user_id = uid)&&(room_id = rid);
						UPDATE ActivePlayers
						SET next_id = next
						WHERE player_id = prev;
						IF (uid = (SELECT creators_id FROM Room WHERE room_id = rid)) THEN
							UPDATE Room
							SET creators_id = (SELECT user_id FROM (SELECT user_id FROM ActivePlayers WHERE room_id = rid UNION SELECT user_id FROM InactivePlayers WHERE room_id = rid) as A ORDER BY RAND() LIMIT 1)
							WHERE (room_id = rid);
						END IF;
						CALL refresh_rooms();
					END IF;
				ELSE
					DELETE FROM InactivePlayers WHERE (user_id = uid)&&(room_id = rid);
					IF (uid = (SELECT creators_id FROM Room WHERE room_id = rid)) THEN
						UPDATE Room
						SET creators_id = (SELECT user_id FROM (SELECT user_id FROM ActivePlayers WHERE room_id = rid UNION SELECT user_id FROM InactivePlayers WHERE room_id = rid) as A ORDER BY RAND() LIMIT 1)
						WHERE (room_id = rid);
						CALL refresh_rooms();
					END IF;
				END IF;
			END IF;
		END IF;
	END IF;
END