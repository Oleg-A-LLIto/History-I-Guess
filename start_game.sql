CREATE PROCEDURE start_game(name VARCHAR(16), pass VARCHAR(32), rid INT)
COMMENT "start_game(username, password, room_id): starts the game if you are its creator"
BEGIN
	DECLARE first INT;
	DECLARE togive INT;
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
					SELECT "Only room administrators can start the game" AS Error;
				ELSE
					IF (SELECT card_id FROM Places WHERE (room_id = rid) LIMIT 1) IS NOT NULL THEN
						SELECT "This game is already running" AS Error;
					ELSE
						-- Deleting the players left from the previous game who did not rejoin
						DELETE FROM InactivePlayers WHERE (room_id = rid);
						-- Encycling the linked list of players
						SET first = (SELECT player_id FROM ActivePlayers WHERE room_id = rid AND (player_id NOT IN (SELECT next_id FROM ActivePlayers WHERE room_id = rid AND next_id IS NOT NULL)));		
						UPDATE ActivePlayers
						SET next_id = first
						WHERE (room_id = rid) AND (next_id IS NULL);
						-- Randomly choosing the first player
						UPDATE Room SET first_id = (SELECT player_id FROM ActivePlayers WHERE room_id=rid ORDER BY rand() LIMIT 1) WHERE (room_id = rid);
						-- Setting a timer for the first player
						UPDATE ActivePlayers
						SET turn = CURRENT_TIMESTAMP
						WHERE player_id = (SELECT first_id FROM Room WHERE room_id=rid);
						-- Counting players
						SET togive = (SELECT COUNT(player_id)*4 FROM ActivePlayers WHERE room_id = rid);
						-- Adding all cards to the game
						INSERT INTO Cards(card_type)
					    	SELECT card_type from CardTypes;
					    -- Creating a temporary table to work with
						CREATE TEMPORARY TABLE AllCards (id INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY)
							SELECT card_id FROM Cards WHERE (card_id>LAST_INSERT_ID()-1) && (card_id<LAST_INSERT_ID()+ROW_COUNT()-1) ORDER BY RAND();
						-- Creating a temporart table of players to join with
						CREATE TEMPORARY TABLE AllPlayers (id INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY)
							SELECT player_id from ActivePlayers WHERE room_id = rid;
						-- Handing the cards in to players
						INSERT INTO CardPlayer(player_id, card_id)
						    SELECT player_id, card_id FROM AllPlayers JOIN AllCards ON ((AllCards.id % 4) + 1 = AllPlayers.id) ORDER BY AllCards.id LIMIT togive;
						DELETE FROM AllCards WHERE card_id IN (SELECT card_id FROM CardPlayer);
						-- Placing the first card on the table
						INSERT INTO Places(position,room_id,card_id)
							VALUES(0, rid, (SELECT card_id FROM AllCards ORDER BY RAND() LIMIT 1));
						DELETE FROM AllCards WHERE card_id IN (SELECT card_id FROM Places);
						-- Placing the rest in the deck
						INSERT INTO CardDeck(room_id,card_id)
							SELECT rid, card_id FROM AllCards ORDER BY RAND();
						CALL refresh_game(name,pass, rid);
					END IF;
				END IF;
			END IF;
		END IF;
	END IF;
END