CREATE PROCEDURE show_members(rid int)
COMMENT "show_members(room_id): shows members of this room"
BEGIN
	IF rid NOT IN (SELECT room_id FROM Room) THEN 
		SELECT "This room does not exist" AS Error;
	ELSE
		SELECT username FROM User NATURAL JOIN(
			SELECT user_id, room_id FROM ActivePlayers WHERE room_id = rid) 
		as users;
	END IF;
END