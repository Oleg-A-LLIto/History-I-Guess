CREATE PROCEDURE kick(name VARCHAR(16), pass VARCHAR(32), room_name VARCHAR(16), to_kick VARCHAR(16))
COMMENT "kick(username, password, room_name, to_kick): kick a player -to_kick- (only works when waiting for a game to start)"
BEGIN
	DECLARE rid INT DEFAULT (SELECT room_id FROM Room WHERE (Room.name = room_name));
	DECLARE uid INT DEFAULT (SELECT user_id FROM User WHERE (username = name));
	DECLARE kid INT DEFAULT (SELECT user_id FROM User WHERE (username = to_kick));
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
				IF uid NOT IN (SELECT creators_id FROM Room WHERE (Room.name = room_name)) THEN
					SELECT "Only room administrators can kick players" AS Error;
				ELSE
					IF to_kick NOT IN (SELECT username FROM User) THEN
						SELECT "This player does not exist" AS Error;
					ELSE
						IF rid NOT IN (SELECT room_id FROM InactivePlayers WHERE user_id = kid) THEN
							IF rid NOT IN (SELECT room_id FROM ActivePlayers WHERE user_id = kid) THEN
								SELECT "This player is not present in this room" AS Error;
							ELSE
								IF (SELECT card_id FROM Places WHERE (room_id = rid)) IS NOT NULL THEN
									SELECT "Cannot kick a player during the game" AS Error;
								ELSE
									SET next = (SELECT next_id FROM ActivePlayers WHERE (user_id = kid)&&(room_id = rid));
									SET prev = (SELECT player_id FROM ActivePlayers WHERE (next_id = (SELECT player_id FROM ActivePlayers WHERE (user_id = kid)&&(room_id = rid))) && (room_id = rid));
									DELETE FROM ActivePlayers WHERE (user_id = kid)&&(room_id = rid);
									UPDATE ActivePlayers
									SET next_id = next
									WHERE player_id = prev;
									IF (kid = uid) THEN
										UPDATE Room
										SET creators_id = (SELECT user_id FROM (SELECT user_id FROM ActivePlayers WHERE room_id = rid UNION SELECT user_id FROM InactivePlayers WHERE room_id = rid) as A ORDER BY RAND() LIMIT 1)
		 								WHERE (room_id = rid);
									END IF;
								END IF;
							END IF;
						ELSE
							DELETE FROM InactivePlayers WHERE (user_id = kid)&&(room_id = rid);
							IF (kid = uid) THEN
								UPDATE Room
								SET creators_id = (SELECT user_id FROM (SELECT user_id FROM ActivePlayers WHERE room_id = rid UNION SELECT user_id FROM InactivePlayers WHERE room_id = rid) as A ORDER BY RAND() LIMIT 1)
 								WHERE (room_id = rid);
							END IF;
						END IF;
					END IF;
				END IF;
			END IF;
		END IF;
	END IF;
END