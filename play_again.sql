CREATE PROCEDURE play_again(name VARCHAR(16), pass VARCHAR(32), rid INT)
COMMENT "play_again(username, password, room_id): play again in a room -room_id-"
BEGIN
	DECLARE uid INT DEFAULT (SELECT user_id FROM User WHERE (username = name));
	DECLARE prev, next, this INT; 
	IF name NOT IN (SELECT username FROM User) THEN
		SELECT "Wrong username" AS Error;
	ELSE
		IF pass NOT IN (SELECT password FROM User WHERE (username = name)) THEN
			SELECT "Wrong password" AS Error;
		ELSE
			IF rid NOT IN (SELECT Room.room_id FROM Room) THEN 
				SELECT "This room does not exist" AS Error;
			ELSE
				IF rid NOT IN (SELECT room_id FROM InactivePlayers WHERE user_id = uid) THEN
					SELECT "You have not played in this room" AS Error;
				ELSE
					IF (SELECT card_id FROM Places WHERE (room_id = rid)) IS NOT NULL THEN
						SELECT "This game has not ended yet" AS Error;
					ELSE
						SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
						START TRANSACTION;
						DELETE FROM InactivePlayers WHERE (user_id = uid)&&(room_id = rid);
						IF (SELECT count(player_id) FROM ActivePlayers WHERE room_id = rid FOR UPDATE) = 8 THEN
							SELECT "This room is already full" as Error;
							COMMIT;
						ELSE
							SET prev = (SELECT player_id FROM ActivePlayers WHERE (room_id = rid)&&(next_id IS NULL));
							INSERT INTO ActivePlayers(room_id,user_id,next_id,turn) VALUES(rid,uid,NULL,NULL);
							SET this = (SELECT player_id FROM ActivePlayers WHERE (user_id = uid)&&(room_id = rid));
							UPDATE ActivePlayers
							SET next_id = this
							WHERE player_id = prev;
							CALL show_members(rid);
							COMMIT;
						END IF;
					END IF;
				END IF;
			END IF;
		END IF;
	END IF;
END