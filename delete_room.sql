CREATE PROCEDURE delete_room(name VARCHAR(16), pass VARCHAR(32), rid INT)
COMMENT "delete_room(username, password, room_id): deletes the room if you are the creator and the game is not going right now"
BEGIN
	DECLARE first INT;
	DECLARE togive INT;
	IF ((SELECT COUNT(*) FROM ActivePlayers WHERE room_id = rid) + (SELECT COUNT(*) FROM InactivePlayers WHERE room_id = rid)) = 0 THEN
		DELETE FROM Cards WHERE card_id IN (SELECT card_id FROM Places WHERE Room_id = rid
		UNION
		SELECT card_id FROM CardDeck WHERE Room_id = rid
		UNION
		SELECT card_id FROM ActivePlayers NATURAL JOIN CardPlayer WHERE Room_id = rid);
		DELETE FROM Room WHERE room_id = rid;
	ELSE
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
						SELECT "Only room administrators can delete the room" AS Error;
					ELSE
						SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
						START TRANSACTION;
						IF EXISTS(SELECT * FROM Places WHERE (room_id = rid) FOR UPDATE) THEN
							ROLLBACK;
							SELECT "This game is running" AS Error;
						ELSE
							DELETE FROM Cards WHERE card_id IN (SELECT card_id FROM Places WHERE room_id = rid
							UNION
							SELECT card_id FROM CardDeck WHERE room_id = rid
							UNION
							SELECT card_id FROM ActivePlayers NATURAL JOIN CardPlayer WHERE room_id = rid);
							DELETE FROM ActivePlayers WHERE room_id = rid;
							DELETE FROM InactivePlayers WHERE room_id = rid;
							DELETE FROM Room WHERE room_id = rid;
							COMMIT;
						END IF;
					END IF;
				END IF;
			END IF;
		END IF;
	END IF;
END