CREATE PROCEDURE end_turn_halt(rid INT, uid INT)
SQL SECURITY INVOKER
COMMENT "it’s a secret don’t look"
BEGIN
	DECLARE first INT;
	DECLARE winner_id INT;
	DECLARE numofcards INT;
	DECLARE next INT DEFAULT (SELECT next_id FROM ActivePlayers WHERE turn IS NOT NULL AND room_id = rid);
	-- Check if it is the end of this round
	IF next IN (SELECT first_id FROM Room WHERE room_id = rid) THEN
		-- Check if someone won at all;
		-- WHERE NOT EXISTS
		CREATE TEMPORARY TABLE winners (id INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY)
			SELECT player_id FROM (SELECT player_id, count(card_id) as crdnum FROM ActivePlayers LEFT JOIN CardPlayer USING (player_id) WHERE room_id = rid GROUP BY player_id FOR UPDATE) as a WHERE crdnum = 0;
		IF (SELECT count(player_id) FROM winners) > 0 THEN
			-- We either have a winner or a final round
			IF (SELECT count(player_id) FROM winners) = 1 THEN
				-- We have a winner
				CALL host700505_sandbox.tormoz(6);
				SET winner_id = (SELECT user_id FROM winners NATURAL JOIN ActivePlayers NATURAL JOIN User);
				UPDATE Room SET Room.winner_id = winner_id WHERE room_id = rid;
				INSERT INTO InactivePlayers(room_id,user_id)
					SELECT rid, user_id FROM ActivePlayers WHERE (room_id = rid);
				DELETE FROM ActivePlayers WHERE (room_id = rid);
				UPDATE ActivePlayers SET next_id = NULL WHERE (room_id = rid);
				UPDATE ActivePlayers SET turn = NULL WHERE (room_id = rid);
				UPDATE Room SET wrong = NULL WHERE (room_id = rid);
				DELETE FROM Cards WHERE card_id IN (SELECT card_id FROM Places WHERE room_id = rid
				UNION
				SELECT card_id FROM CardDeck WHERE Room_id = rid
				UNION
				SELECT card_id FROM ActivePlayers NATURAL JOIN CardPlayer WHERE room_id = rid);
			ELSE
				-- take cards from loosers
				INSERT INTO CardDeck (room_id, card_id)
					SELECT rid, card_id FROM CardPlayer NATURAL JOIN ActivePlayers WHERE (player_id NOT IN (SELECT player_id FROM winners)) AND (room_id = rid);
				DELETE FROM CardPlayer WHERE card_id IN (SELECT card_id FROM CardDeck);
				-- insert loosers into inactive players list
				INSERT INTO InactivePlayers(room_id,user_id)
					SELECT rid, user_id FROM ActivePlayers WHERE (room_id = rid) AND (player_id NOT IN (SELECT player_id FROM winners));
				DELETE FROM ActivePlayers WHERE (room_id = rid) AND (player_id NOT IN (SELECT player_id FROM winners));
				CALL host700505_sandbox.tormoz(6);
				-- relinking the player list 
				CREATE TEMPORARY TABLE newchain
					SELECT ap.player_id, nxt.player_id as next_id FROM ActivePlayers as ap JOIN ActivePlayers as nxt USING (room_id) WHERE nxt.player_id = (SELECT min(player_id) FROM ActivePlayers as ao WHERE ao.player_id > ap.player_id AND room_id = rid);
				UPDATE ActivePlayers SET next_id = (SELECT next_id FROM newchain WHERE ActivePlayers.player_id = newchain.player_id) WHERE room_id = rid;
				-- encycling (first temporary stands for the one that noone references as next)
				SET first = (SELECT player_id FROM ActivePlayers WHERE room_id = rid AND (player_id NOT IN (SELECT next_id FROM ActivePlayers WHERE room_id = rid AND next_id IS NOT NULL)));		
				UPDATE ActivePlayers
				SET next_id = first
				WHERE (room_id = rid) AND (next_id IS NULL);
				-- get initial first id (now first is the one who actually turns first)
				SET first = (SELECT first_id FROM Room WHERE room_id = rid);
				-- Changing first_id if it's different now
				IF first NOT IN (SELECT player_id FROM ActivePlayers WHERE (room_id = rid)) THEN
					IF (SELECT COUNT(*) FROM ActivePlayers WHERE room_id = rid AND player_id > first) > 0 THEN
						SET first = (SELECT min(player_id) FROM ActivePlayers WHERE (room_id = rid) AND player_id > first);
					ELSE
						SET first = (SELECT min(player_id) FROM ActivePlayers WHERE (room_id = rid));
					END IF;
					UPDATE Room SET first_id = first WHERE room_id = rid;
				END IF;
				-- this should be the first players turn
				UPDATE ActivePlayers SET turn = NULL WHERE room_id = rid;
				UPDATE ActivePlayers SET turn = CURRENT_TIMESTAMP() WHERE room_id = rid AND player_id = first;
				-- Creating a temporary table to work with
				UPDATE ActivePlayers SET next_id = first WHERE next_id is NULL AND room_id = rid;
				SET numofcards = (SELECT count(player_id) FROM winners) * 4;
				CREATE TEMPORARY TABLE AllCards (id INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY)
					SELECT card_id FROM CardDeck WHERE (room_id = rid) ORDER BY RAND() LIMIT numofcards;
				-- Handing the cards in to players
				INSERT INTO CardPlayer(player_id, card_id)
				    SELECT player_id, card_id FROM winners JOIN AllCards ON ((AllCards.id % (numofcards/4)) + 1 = winners.id) ORDER BY AllCards.id;
				DELETE FROM CardDeck WHERE card_id IN (SELECT card_id FROM CardPlayer);
				-- Getting rid of temporary tables 
				DROP TEMPORARY TABLE AllCards;
				DROP TEMPORARY TABLE newchain;
			END IF;
		ELSE
			UPDATE ActivePlayers SET turn = NULL WHERE turn IS NOT NULL AND room_id = rid;
			UPDATE ActivePlayers SET turn = CURRENT_TIMESTAMP WHERE player_id = next;
		END IF;
		DROP TEMPORARY TABLE winners;
	ELSE
		UPDATE ActivePlayers SET turn = NULL WHERE turn IS NOT NULL AND room_id = rid;
		UPDATE ActivePlayers SET turn = CURRENT_TIMESTAMP WHERE player_id = next;
	END IF;
END