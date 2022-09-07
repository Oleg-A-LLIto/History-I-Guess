CREATE PROCEDURE start(rid INT)
SQL SECURITY INVOKER
COMMENT "it’s a secret don’t look"
BEGIN
	DECLARE first INT;
	DECLARE togive INT;
	-- Deleting the players left from the previous game who did not rejoin
	DO (SELECT count(*) FROM ActivePlayers FOR UPDATE);
	DELETE FROM InactivePlayers WHERE (room_id = rid);
	UPDATE Room SET winner_id = NULL WHERE (room_id = rid);
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
	    SELECT player_id, card_id FROM AllPlayers JOIN AllCards ON ((AllCards.id % (togive/4)) + 1 = AllPlayers.id) ORDER BY AllCards.id LIMIT togive;
	DELETE FROM AllCards WHERE card_id IN (SELECT card_id FROM CardPlayer);
	-- Placing the first card on the table
	INSERT INTO Places(position,room_id,card_id)
		VALUES(0, rid, (SELECT card_id FROM AllCards ORDER BY RAND() LIMIT 1));
	DELETE FROM AllCards WHERE card_id IN (SELECT card_id FROM Places);
	-- Placing the rest in the deck
	INSERT INTO CardDeck(room_id,card_id)
		SELECT rid, card_id FROM AllCards ORDER BY RAND();
END