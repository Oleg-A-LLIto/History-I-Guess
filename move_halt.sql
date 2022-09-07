CREATE PROCEDURE move_halt(name VARCHAR(16), pass VARCHAR(32), rid INT, card INT, pos_to_put INT)
COMMENT "move(username, password, room_id, card_id, position): put your -card- in a -position- on the table"
BEGIN
	DECLARE uid INT DEFAULT (SELECT user_id FROM User WHERE (username = name));
	DECLARE pid INT DEFAULT (SELECT player_id FROM ActivePlayers WHERE user_id = uid AND room_id = rid);
	DECLARE del INT DEFAULT (SELECT wrong FROM Room WHERE room_id = rid);
	DECLARE del_id INT DEFAULT (SELECT card_id FROM Places WHERE room_id = rid AND Places.position = del);
	DECLARE time_left INT;
	DECLARE lef INT;
	DECLARE ctr INT;
	DECLARE righ INT;
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
						IF card NOT IN (SELECT card_id FROM CardPlayer WHERE player_id = pid) THEN
							SELECT "You don't have this card in your hand" AS Error;
						ELSE
							IF ((pos_to_put > (SELECT max(position) FROM Places WHERE room_id = rid) + 1) OR (pos_to_put < (SELECT min(position) FROM Places WHERE room_id = rid) - 1) OR (pos_to_put = 0)) THEN
								SELECT "Position is incorrect" AS Error;
							ELSE
								SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
								START TRANSACTION;
								SET time_left = (SELECT turn_tl - time as time_left FROM Room NATURAL JOIN (
									SELECT TIME_TO_SEC(TIMEDIFF(CURRENT_TIMESTAMP(),turn)) as time FROM ActivePlayers WHERE ((room_id = rid) && (turn IS NOT NULL))) as a WHERE Room.room_id = rid);
								IF (time_left<-2) THEN 
									SELECT "It is not your turn" AS Error;
									CALL end_turn(rid, uid);
								ELSE
									-- delete if there is a wrong card
									IF del IS NOT NULL THEN
										DELETE FROM Places WHERE card_id = del_id;
										INSERT INTO CardDeck (room_id, card_id) values(rid, del_id);
										IF (del<0) THEN
											UPDATE Places SET Places.position = Places.position + 1 WHERE Places.position <= del AND room_id = rid ORDER BY Places.position desc;
										ELSE
											UPDATE Places SET Places.position = Places.position - 1 WHERE Places.position >= del AND room_id = rid ORDER BY Places.position;
										END IF;
										UPDATE Room SET wrong = NULL WHERE room_id = rid;
										SET del = NULL;
									END IF;
									-- If this position is taken, move other cards
									IF pos_to_put IN (SELECT Places.position FROM Places WHERE room_id = rid) THEN
										IF (pos_to_put<0) THEN
											UPDATE Places SET Places.position = Places.position - 1 WHERE Places.position <= pos_to_put AND room_id = rid ORDER BY Places.position;
										ELSE
											UPDATE Places SET Places.position = Places.position + 1 WHERE Places.position >= pos_to_put AND room_id = rid ORDER BY Places.position desc;
										END IF;
									END IF;
									-- Insert this card
									INSERT INTO Places (position, room_id, card_id) values (pos_to_put,rid,card);
									CALL host700505_sandbox.tormoz(6);
									-- Delete it from player's hand
									DELETE FROM CardPlayer WHERE card_id = card;
									-- Check if our new card is correct
									SET lef = (SELECT date FROM Places NATURAL JOIN Cards NATURAL JOIN CardTypes WHERE room_id = rid AND position = pos_to_put-1);
									SET ctr = (SELECT date FROM Places NATURAL JOIN Cards NATURAL JOIN CardTypes WHERE room_id = rid AND position = pos_to_put);
									SET righ = (SELECT date FROM Places NATURAL JOIN Cards NATURAL JOIN CardTypes WHERE room_id = rid AND position = pos_to_put+1);
									IF lef IS NULL THEN 
										IF righ < ctr THEN 
											UPDATE Room SET wrong = pos_to_put WHERE room_id = rid;
										END IF;
									ELSE
										IF righ IS NULL THEN 
											IF lef > ctr THEN 
												UPDATE Room SET wrong = pos_to_put WHERE room_id = rid;
											END IF;
										ELSE
											IF ctr NOT BETWEEN lef AND righ THEN 
												UPDATE Room SET wrong = pos_to_put WHERE room_id = rid;
											END IF;
										END IF;
									END IF;
									-- IF not so, take another card
									IF (SELECT wrong FROM Room WHERE room_id = rid) IS NOT NULL THEN
										SET del_id = (SELECT card_id from CardDeck WHERE room_id = rid ORDER BY RAND() LIMIT 1);
										INSERT INTO CardPlayer (player_id, card_id) VALUES (pid, del_id);
										DELETE FROM CardDeck WHERE room_id = rid AND card_id = del_id;
									END IF;
									CALL end_turn(rid, uid);
								END IF;
								COMMIT;
								CALL refresh_game(name, pass, rid);
							END IF;
						END IF;
					END IF;
				END IF;
			END IF;
		END IF;
	END IF;
END