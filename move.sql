CREATE PROCEDURE move(name VARCHAR(16), pass VARCHAR(32), rid INT, card INT, position INT)
BEGIN
	DECLARE uid INT DEFAULT (SELECT user_id FROM User WHERE (username = name));
	DECLARE pid INT DEFAULT (SELECT player_id FROM ActivePlayers WHERE user_id = uid AND room_id = rid);
	DECLARE del INT DEFAULT (SELECT DISTINCT t2.position
	      FROM Places
	      JOIN Cards AS c USING (card_id)
	      JOIN CardTypes AS ct USING (card_type)
	      JOIN
	        (SELECT Max(POSITION) AS MAX,
	                Min(POSITION) AS MIN,
	                room_id
	         FROM Places
	         GROUP BY room_id) AS mm
	      JOIN
	        (SELECT room_id,
	                POSITION, date, name
	         FROM Places
	         JOIN Cards USING (card_id)
	         JOIN CardTypes USING (card_type)) AS t2
	      JOIN
	        (SELECT room_id,
	                POSITION, date, name
	         FROM Places
	         JOIN Cards USING (card_id)
	         JOIN CardTypes USING (card_type)) AS t3
	      WHERE (((ct.date > t2.date && Places.position = t2.position - 1 && (ct.date < t3.date && t3.position = t2.position + 1
OR t2.position = MAX))) || ((t3.date < t2.date && t3.position = t2.position + 1 && (ct.date < t3.date && Places.position = t2.position - 1
OR t2.position = MIN)))) && (t2.position != 0) && (t2.room_id = Places.room_id && t2.room_id = t3.room_id && mm.room_id = t2.room_id) && t2.room_id = rid);
	
	DECLARE del_id INT DEFAULT (SELECT card_id FROM Places WHERE room_id = rid AND position = del);
	DECLARE next INT;
	DECLARE time_left INT;
	IF name NOT IN (SELECT username FROM User) THEN
		SELECT "Wrong username" AS Error;
	ELSE
		IF pass NOT IN (SELECT password FROM User WHERE (username = name)) THEN
			SELECT "Wrong password" AS Error;
		ELSE
			IF rid NOT IN (SELECT room_id FROM Room) THEN
				SELECT "This room does not exist" AS Error;
			ELSE
				IF rid NOT IN (SELECT room_id FROM ActivePlayers WHERE user_id = uid) THEN
					SELECT "You are not in this room!" AS Error;
				ELSE
					IF pid NOT IN (SELECT player_id FROM ActivePlayers WHERE room_id = rid AND turn IS NOT NULL) THEN
						SELECT "It is not your turn" AS Error;
					ELSE
						IF card NOT IN (SELECT card_id FROM CardPlayer WHERE player_id = pid AND room_id = rid) THEN
							SELECT "You don't have this card in your hand" AS Error;
						ELSE
							IF ((position > (SELECT max(position) FROM Places WHERE room_id = rid) + 1) OR (position < (SELECT min(position) FROM Places WHERE room_id = rid) - 1)) THEN
								SELECT "Position is incorrect" AS Error;
							ELSE
								SET time_left = (SELECT turn_tl - time as time_left FROM Room NATURAL JOIN (
									SELECT CURRENT_TIMESTAMP-turn as time FROM ActivePlayers WHERE ((room_id = rid) && (turn IS NOT NULL))) as a WHERE Room.room_id = rid);
								IF (time_left<-2) THEN 
									SELECT "It is not your turn" AS Error;
								ELSE
									-- delete if there is a wrong card
									IF del IS NOT NULL THEN
										DELETE FROM Places WHERE card_id = del_id;
										INSERT INTO CardDeck (room_id, card_id) values(rid, del_id);
										IF (del<0) THEN
											UPDATE Places SET Places.position = Places.position + 1 WHERE Places.position <= del ORDER BY Places.position desc;
										ELSE
											UPDATE Places SET Places.position = Places.position - 1 WHERE Places.position >= del ORDER BY Places.position;
										END IF;
									END IF;
									-- If this position is taken, move other cards
									IF position IN (SELECT position FROM Places WHERE room_id = rid) THEN
										IF (position<0) THEN
											UPDATE Places SET Places.position = Places.position - 1 WHERE Places.position <= position ORDER BY Places.position;
										ELSE
											UPDATE Places SET Places.position = Places.position + 1 WHERE Places.position >= position ORDER BY Places.position desc;
										END IF;
									END IF;
									-- Insert this card
									INSERT INTO Places (position, room_id, card_id) values (position,rid,card);
									-- Delete it from player's hand
									DELETE FROM CardPlayer WHERE card_id = card;
								END IF;
								--  Ending this player's turn;
								SET next = (SELECT next_id FROM ActivePlayers WHERE turn IS NOT NULL AND room_id = rid);
								UPDATE ActivePlayers SET turn = NULL WHERE turn IS NOT NULL AND room_id = rid;
								UPDATE ActivePlayers SET turn = CURRENT_TIMESTAMP WHERE player_id = next;
							END IF;
						END IF;
					END IF;
				END IF;
			END IF;
		END IF;
	END IF;
END