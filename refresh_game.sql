CREATE PROCEDURE refresh_game(name VARCHAR(16), pass VARCHAR(32), rid INT)
BEGIN
	DECLARE uid INT DEFAULT (SELECT user_id FROM User WHERE (username = name));
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
				SET time_left = (SELECT turn_tl - time as time_left FROM Room NATURAL JOIN (
					SELECT CURRENT_TIMESTAMP-turn as time FROM ActivePlayers WHERE ((room_id = rid) && (turn IS NOT NULL))) as a WHERE Room.room_id = rid);
				IF (time_left<-2) THEN 
					SELECT "Next turn" as message;
					SET next = (SELECT next_id FROM ActivePlayers WHERE turn IS NOT NULL AND room_id = rid);
					UPDATE ActivePlayers SET turn = NULL WHERE turn IS NOT NULL AND room_id = rid;
					UPDATE ActivePlayers SET turn = CURRENT_TIMESTAMP WHERE player_id = next AND room_id = rid;
					SET time_left = (SELECT turn_tl FROM Room WHERE room_id = rid);
				END IF;
				IF rid NOT IN (SELECT room_id FROM InactivePlayers WHERE user_id = uid) THEN
					IF rid NOT IN (SELECT room_id FROM ActivePlayers WHERE user_id = uid) THEN
						SELECT "You are not in this room!" AS Error;
					ELSE
						-- Player whose move this one is and how much time they have left
						SELECT username as thinking, time_left FROM ActivePlayers NATURAL JOIN User WHERE room_id = rid AND turn IS NOT NULL;
						-- Player's cards
						SELECT card_id, date, CardTypes.name FROM ActivePlayers NATURAL JOIN CardPlayer NATURAL JOIN Cards NATURAL JOIN CardTypes WHERE user_id = uid AND room_id = rid;
						-- Cards on a table
						CALL wrong_cards(uid, rid, 'oQCrE109mN.G');
						-- SELECT position, date, CardTypes.name FROM Places NATURAL JOIN Cards NATURAL JOIN CardTypes WHERE room_id = rid;
						-- Each player's number of cards
						SELECT username, COUNT(card_id) FROM ActivePlayers NATURAL JOIN CardPlayer NATURAL JOIN User WHERE (room_id = rid) && (user_id != uid) GROUP BY user_id;
						-- Number of watchers for this room
						SELECT count(user_id) as watchers FROM InactivePlayers WHERE (room_id = rid);
					END IF;
				ELSE
					-- Player whose move this one is and how much time they have left
					SELECT username as thinking, time_left FROM ActivePlayers NATURAL JOIN User WHERE room_id = rid AND turn IS NOT NULL;
					-- Cards on a table
					CALL wrong_cards(uid, rid, 'oQCrE109mN.G');
					-- SELECT position, date, CardTypes.name FROM Places NATURAL JOIN Cards NATURAL JOIN CardTypes WHERE room_id = rid;
					-- Each player's number of cards
					SELECT username, COUNT(card_id) FROM ActivePlayers NATURAL JOIN CardPlayer NATURAL JOIN User WHERE (room_id = rid) && (user_id != uid) GROUP BY user_id;
					-- Number of watchers for this room
					SELECT count(user_id) as watchers FROM InactivePlayers WHERE (room_id = rid);
				END IF;
			END IF;
		END IF;
	END IF;
END