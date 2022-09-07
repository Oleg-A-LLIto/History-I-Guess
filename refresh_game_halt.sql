CREATE PROCEDURE refresh_game_halt(name VARCHAR(16), pass VARCHAR(32), rid INT)
COMMENT "refresh_game(username, password, room_id): refreshes the game status: your cards, other peoples numbers of cards, cards on the table, username of the player whose turn this one is, the amount of time they have left and a number of watchers"
BEGIN
	DECLARE uid INT DEFAULT (SELECT user_id FROM User WHERE (username = name));
	DECLARE time_left INT;
	SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
	IF name NOT IN (SELECT username FROM User) THEN
		SELECT "Wrong username" AS Error;
	ELSE
		IF pass NOT IN (SELECT password FROM User WHERE (username = name)) THEN
			SELECT "Wrong password" AS Error;
		ELSE
			IF rid NOT IN (SELECT room_id FROM Room) THEN
				SELECT "This room does not exist" AS Error;
			ELSE
				IF (SELECT turn_tl FROM Room WHERE room_id = rid) IS NOT NULL THEN
					SET time_left = (SELECT turn_tl - time as time_left FROM Room NATURAL JOIN (
						SELECT TIME_TO_SEC(TIMEDIFF(CURRENT_TIMESTAMP(),turn)) as time FROM ActivePlayers WHERE ((room_id = rid) && (turn IS NOT NULL))) as a WHERE Room.room_id = rid);
					IF (time_left<-2) THEN 
						CALL end_turn(rid, (SELECT user_id FROM ActivePlayers WHERE ((room_id = rid) && (turn IS NOT NULL))));
						SET time_left = (SELECT turn_tl FROM Room WHERE room_id = rid);
					END IF;
				END IF;
				IF rid NOT IN (SELECT room_id FROM InactivePlayers WHERE user_id = uid) THEN
					IF rid NOT IN (SELECT room_id FROM ActivePlayers WHERE user_id = uid) THEN
						SELECT "You are not in this room!" AS Error;
					ELSE
						IF (SELECT count(*) FROM Places WHERE room_id = rid) = 0 THEN
							IF (SELECT winner_id FROM Room WHERE room_id = rid) IS NULL THEN
								CALL show_members(rid);
							ELSE
								SELECT username as winner FROM Room JOIN User ON (user_id = winner_id) WHERE (room_id = rid);
							END IF;
						ELSE
							START TRANSACTION READ ONLY;
								-- Player whose move this one is and how much time they have left
								IF (SELECT turn_tl FROM Room WHERE room_id = rid) IS NOT NULL THEN
									SELECT username as thinking, time_left FROM ActivePlayers NATURAL JOIN User WHERE room_id = rid AND turn IS NOT NULL;
								ELSE
									SELECT username as thinking FROM ActivePlayers NATURAL JOIN User WHERE room_id = rid AND turn IS NOT NULL;
								END IF;
								-- Player's cards
								SELECT card_id, card_type, CardTypes.name FROM ActivePlayers NATURAL JOIN CardPlayer NATURAL JOIN Cards NATURAL JOIN CardTypes WHERE user_id = uid AND room_id = rid;
								-- Cards on a table
								SELECT position, card_id as pos_id, card_type as pos_type, CardTypes.name as pos_name, CardTypes.date as pos_date, CASE WHEN position = wrong THEN "no" ELSE "yes" END as correct FROM Places NATURAL JOIN Room NATURAL JOIN Cards JOIN CardTypes USING (card_type) WHERE room_id = rid ORDER BY position;
								CALL host700505_sandbox.tormoz(6);
								-- Each player's number of cards
								SELECT username, count(card_id) as cardsonhands FROM ActivePlayers LEFT JOIN CardPlayer USING (player_id) NATURAL JOIN User WHERE room_id = rid AND user_id != uid GROUP BY player_id;
								-- Number of watchers for this room
								SELECT count(user_id) as watchers FROM InactivePlayers WHERE (room_id = rid);
							COMMIT;
						END IF;
					END IF;
				ELSE
					IF (SELECT winner_id FROM Room WHERE room_id = rid) IS NULL THEN
						START TRANSACTION READ ONLY;
							-- Player whose move this one is and how much time they have left
							IF (SELECT turn_tl FROM Room WHERE room_id = rid) IS NOT NULL THEN
								SELECT username as thinking, time_left FROM ActivePlayers NATURAL JOIN User WHERE room_id = rid AND turn IS NOT NULL;
							ELSE
								SELECT username as thinking FROM ActivePlayers NATURAL JOIN User WHERE room_id = rid AND turn IS NOT NULL;
							END IF;
							-- Cards on a table
							SELECT position, card_id as pos_id, card_type as pos_type, CardTypes.name as pos_name, CardTypes.date as pos_date, CASE WHEN position = wrong THEN "no" ELSE "yes" END as correct FROM Places NATURAL JOIN Room NATURAL JOIN Cards JOIN CardTypes USING (card_type) WHERE room_id = rid ORDER BY position;
							-- Each player's number of cards
							SELECT username, count(card_id) as cardsonhands FROM ActivePlayers LEFT JOIN CardPlayer USING (player_id) NATURAL JOIN User WHERE room_id = rid AND user_id != uid GROUP BY player_id;
							-- Number of watchers for this room
							SELECT count(user_id) as watchers FROM InactivePlayers WHERE (room_id = rid);
						COMMIT;
					ELSE
						SELECT username as winner FROM Room JOIN User ON (user_id = winner_id) WHERE (room_id = rid);
					END IF;
				END IF;
			END IF;
		END IF;
	END IF;
END