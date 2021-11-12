CREATE PROCEDURE leave_room(name VARCHAR(16), pass VARCHAR(32), rid INT)
COMMENT "leave_room(username, password, room_id): leave room -room_id-"
BEGIN
	DECLARE uid INT DEFAULT (SELECT user_id FROM User WHERE (username = name));
	DECLARE pid INT DEFAULT (SELECT player_id FROM ActivePlayers WHERE (user_id = uid) AND (room_id = rid));
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
						SET next = (SELECT next_id FROM ActivePlayers WHERE player_id = pid);
						SET prev = (SELECT player_id FROM ActivePlayers WHERE (next_id = (SELECT player_id FROM ActivePlayers WHERE (user_id = uid)&&(room_id = rid))) && (room_id = rid));
						DELETE FROM ActivePlayers WHERE (user_id = uid)&&(room_id = rid);
						UPDATE ActivePlayers
						SET next_id = next
						WHERE player_id = prev;
						-- if we are creator
						IF (uid = (SELECT creators_id FROM Room WHERE room_id = rid)) THEN
							UPDATE Room
							SET creators_id = (SELECT user_id FROM (SELECT user_id FROM ActivePlayers WHERE room_id = rid UNION SELECT user_id FROM InactivePlayers WHERE room_id = rid) as A ORDER BY RAND() LIMIT 1)
							WHERE (room_id = rid);
						END IF;
						IF pid IN (SELECT first_id FROM Room WHERE room_id = rid) THEN
							UPDATE Room
							SET first_id = (SELECT user_id FROM (SELECT user_id FROM ActivePlayers WHERE room_id = rid UNION SELECT user_id FROM InactivePlayers WHERE room_id = rid) as A ORDER BY RAND() LIMIT 1)
							WHERE (room_id = rid);
						END IF;
						IF (SELECT user_id FROM ActivePlayers WHERE room_id = rid AND turn IS NOT NULL) = uid THEN
							UPDATE ActivePlayers SET turn = CURRENT_TIMESTAMP() WHERE player_id = next;
						END IF;
						-- if we are the last player
						IF (SELECT user_id FROM ActivePlayers WHERE room_id = rid) IS NULL THEN
							IF (SELECT user_id FROM InactivePlayers WHERE room_id = rid) IS NULL THEN
								CALL delete_room(name, pass, rid);
							ELSE
								CALL end_game(rid,'oQCrE109mN.G');
							END IF;
						END IF;
						-- move cards to the deck
						INSERT INTO CardDeck (room_id, card_id)
							SELECT rid, card_id FROM CardPlayer NATURAL JOIN ActivePlayers WHERE (player_id = pid);
						DELETE FROM CardPlayer WHERE card_id IN (SELECT card_id FROM CardDeck);
						-- show lobby
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