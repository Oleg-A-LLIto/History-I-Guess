CREATE PROCEDURE refresh_rooms()
BEGIN
	SELECT room_id, name, turn_tl, user_number, (password!='0000') AS private FROM Room NATURAL JOIN(
		SELECT count(user_id) as user_number, room_id FROM(
			SELECT user_id, room_id FROM ActivePlayers
			UNION
			SELECT user_id, room_id FROM InactivePlayers) 
		as users GROUP BY room_id
	) as unums 
END