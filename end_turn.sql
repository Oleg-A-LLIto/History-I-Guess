CREATE PROCEDURE end_turn(rid INT, uid INT, secret_key CHAR(12))
COMMENT "it’s a secret don’t look"
BEGIN
	DECLARE numofcards INT;
	DECLARE next INT DEFAULT (SELECT next_id FROM ActivePlayers WHERE turn IS NOT NULL AND room_id = rid);
	DECLARE first INT;
	IF secret_key = 'oQCrE109mN.G' THEN
		-- Check if it is the end of this round
		IF next IN (SELECT first_id FROM Room WHERE room_id = rid) THEN
			-- Check if someone won at all;
			CREATE TEMPORARY TABLE winners (id INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY)
				SELECT player_id FROM (SELECT player_id, count(card_id) as crdnum FROM ActivePlayers LEFT JOIN CardPlayer USING (player_id) WHERE room_id = rid GROUP BY player_id) as a WHERE crdnum = 0;
			IF (SELECT count(player_id) FROM winners) > 0 THEN
				-- We either have a winner or a final round
				IF (SELECT count(player_id) FROM winners) = 1 THEN
					SELECT username as winner FROM winners NATURAL JOIN ActivePlayers Natural JOIN User;
					INSERT INTO InactivePlayers(room_id,user_id)
						SELECT rid, user_id FROM ActivePlayers WHERE (room_id = rid) AND (player_id NOT IN (SELECT player_id FROM winners));
					DELETE FROM ActivePlayers WHERE (room_id = rid) AND (player_id NOT IN (SELECT player_id FROM winners));
					UPDATE ActivePlayers SET next_id = NULL WHERE (room_id = rid);
					UPDATE ActivePlayers SET turn = NULL WHERE (room_id = rid);
					UPDATE Room SET wrong = NULL WHERE (room_id = rid);
					DELETE FROM Cards WHERE card_id IN (SELECT card_id FROM Places WHERE room_id = rid
					UNION
					SELECT card_id FROM CardDeck WHERE Room_id = rid
					UNION
					SELECT card_id FROM ActivePlayers NATURAL JOIN CardPlayer WHERE room_id = rid);
				ELSE
					SELECT "final round" as message;
					-- take cards from loosers
					INSERT INTO CardDeck (room_id, card_id)
						SELECT rid, card_id FROM CardPlayer NATURAL JOIN ActivePlayers WHERE (player_id NOT IN (SELECT player_id FROM winners)) AND (room_id = rid);
					DELETE FROM CardPlayer WHERE card_id IN (SELECT card_id FROM CardDeck);
					-- insert loosers into inactive players list
					INSERT INTO InactivePlayers(room_id,user_id)
						SELECT rid, user_id FROM ActivePlayers WHERE (room_id = rid) AND (player_id NOT IN (SELECT player_id FROM winners));
					DELETE FROM ActivePlayers WHERE (room_id = rid) AND (player_id NOT IN (SELECT player_id FROM winners));
					-- relinking the player list 
					CREATE TEMPORARY TABLE newchain
						SELECT ap.player_id, nxt.player_id as next_id FROM ActivePlayers as ap JOIN ActivePlayers as nxt USING (room_id) WHERE nxt.player_id = (SELECT min(player_id) FROM ActivePlayers as ao WHERE ao.player_id > ap.player_id AND room_id = rid);
					UPDATE ActivePlayers SET next_id = (SELECT next_id FROM newchain WHERE ActivePlayers.player_id = newchain.player_id) WHERE room_id = rid;
					SET first = (SELECT min(player_id) FROM ActivePlayers WHERE (room_id = rid));
					UPDATE ActivePlayers SET next_id = first WHERE next_id is NULL AND room_id = rid;
					UPDATE ActivePlayers SET turn = NULL WHERE room_id = rid;
					SET first = (SELECT player_id FROM ActivePlayers WHERE (room_id = rid) ORDER BY RAND() LIMIT 1);
					UPDATE ActivePlayers SET turn = CURRENT_TIMESTAMP() WHERE room_id = rid AND player_id = first;
					-- Creating a temporary table to work with
					SET numofcards = (SELECT count(player_id) FROM winners) * 4;
					CREATE TEMPORARY TABLE AllCards (id INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY)
						SELECT card_id FROM CardDeck WHERE (room_id = rid) ORDER BY RAND() LIMIT numofcards;
					-- Handing the cards in to players
					INSERT INTO CardPlayer(player_id, card_id)
					    SELECT player_id, card_id FROM winners JOIN AllCards ON ((AllCards.id % 4) + 1 = winners.id) ORDER BY AllCards.id;
					DELETE FROM CardDeck WHERE card_id IN (SELECT card_id FROM CardPlayer);
					-- NEXT TURN DUDE
					UPDATE ActivePlayers SET turn = NULL WHERE turn IS NOT NULL AND room_id = rid;
					UPDATE ActivePlayers SET turn = CURRENT_TIMESTAMP WHERE player_id = next;
				END IF;
			ELSE
				UPDATE ActivePlayers SET turn = NULL WHERE turn IS NOT NULL AND room_id = rid;
				UPDATE ActivePlayers SET turn = CURRENT_TIMESTAMP WHERE player_id = next;
			END IF;
		ELSE
			UPDATE ActivePlayers SET turn = NULL WHERE turn IS NOT NULL AND room_id = rid;
			UPDATE ActivePlayers SET turn = CURRENT_TIMESTAMP WHERE player_id = next;
		END IF;
	END IF;
END