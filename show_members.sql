CREATE PROCEDURE show_members(rid int)
BEGIN
	IF room_name NOT IN (SELECT Room.name FROM Room) THEN 
		SELECT "This room does not exist" AS Error;
	ELSE
		SELECT username FROM User NATURAL JOIN(
			SELECT user_id, room_id FROM ActivePlayers WHERE room_id = rid
			UNION
			SELECT user_id, room_id FROM InactivePlayers WHERE room_id = rid) 
		as users 
	END IF;
END