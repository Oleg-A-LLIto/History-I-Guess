CREATE PROCEDURE refresh_rooms(full boolean, playing boolean, priv boolean)
COMMENT "refresh_rooms(full, playing, priv): outputs the list of rooms. FULL (if false) filters the rooms that are full, PLAYING filters the ones where the game has already started and PRIV filters the private (password protected) ones"
BEGIN
	IF playing THEN
		IF full THEN
			IF priv THEN
				SELECT room_id, name, turn_tl, CONCAT(user_number,"/4"), (password!='') AS private, CASE WHEN position IS NULL THEN "Waiting" ELSE "Playing" END as status FROM Room NATURAL JOIN(
					SELECT count(user_id) as user_number, room_id FROM(
						SELECT user_id, room_id FROM ActivePlayers
						UNION
						SELECT user_id, room_id FROM InactivePlayers) 
					as users GROUP BY room_id
				) as unums LEFT JOIN Places USING (room_id) GROUP BY room_id;
			ELSE
				SELECT room_id, name, turn_tl, CONCAT(user_number,"/4"), (password!='') AS private, CASE WHEN position IS NULL THEN "Waiting" ELSE "Playing" END as status FROM Room NATURAL JOIN(
					SELECT count(user_id) as user_number, room_id FROM(
						SELECT user_id, room_id FROM ActivePlayers
						UNION
						SELECT user_id, room_id FROM InactivePlayers) 
					as users GROUP BY room_id
				) as unums LEFT JOIN Places USING (room_id) WHERE password='' GROUP BY room_id;
			END IF;
		ELSE
			IF priv THEN
				SELECT room_id, name, turn_tl, CONCAT(user_number,"/4"), (password!='') AS private, CASE WHEN position IS NULL THEN "Waiting" ELSE "Playing" END as status FROM Room NATURAL JOIN(
					SELECT count(user_id) as user_number, room_id FROM(
						SELECT user_id, room_id FROM ActivePlayers
						UNION
						SELECT user_id, room_id FROM InactivePlayers) 
					as users GROUP BY room_id
				) as unums LEFT JOIN Places USING (room_id) WHERE (user_number < 4) GROUP BY room_id;
			ELSE
				SELECT room_id, name, turn_tl, CONCAT(user_number,"/4"), (password!='') AS private, CASE WHEN position IS NULL THEN "Waiting" ELSE "Playing" END as status FROM Room NATURAL JOIN(
					SELECT count(user_id) as user_number, room_id FROM(
						SELECT user_id, room_id FROM ActivePlayers
						UNION
						SELECT user_id, room_id FROM InactivePlayers) 
					as users GROUP BY room_id
				) as unums LEFT JOIN Places USING (room_id) WHERE (password='') AND (user_number < 4) GROUP BY room_id;
			END IF;
		END IF;
	ELSE
		IF full THEN
			IF priv THEN
				SELECT room_id, name, turn_tl, CONCAT(user_number,"/4"), (password!='') AS private, CASE WHEN position IS NULL THEN "Waiting" ELSE "Playing" END as status FROM Room NATURAL JOIN(
					SELECT count(user_id) as user_number, room_id FROM(
						SELECT user_id, room_id FROM ActivePlayers
						UNION
						SELECT user_id, room_id FROM InactivePlayers) 
					as users GROUP BY room_id
				) as unums LEFT JOIN Places USING (room_id) WHERE (position IS NULL) GROUP BY room_id;
			ELSE
				SELECT room_id, name, turn_tl, CONCAT(user_number,"/4"), (password!='') AS private, CASE WHEN position IS NULL THEN "Waiting" ELSE "Playing" END as status FROM Room NATURAL JOIN(
					SELECT count(user_id) as user_number, room_id FROM(
						SELECT user_id, room_id FROM ActivePlayers
						UNION
						SELECT user_id, room_id FROM InactivePlayers) 
					as users GROUP BY room_id
				) as unums LEFT JOIN Places USING (room_id) WHERE (password='') AND (position IS NULL) GROUP BY room_id;
			END IF;
		ELSE
			IF priv THEN
				SELECT room_id, name, turn_tl, CONCAT(user_number,"/4"), (password!='') AS private, CASE WHEN position IS NULL THEN "Waiting" ELSE "Playing" END as status FROM Room NATURAL JOIN(
					SELECT count(user_id) as user_number, room_id FROM(
						SELECT user_id, room_id FROM ActivePlayers
						UNION
						SELECT user_id, room_id FROM InactivePlayers) 
					as users GROUP BY room_id
				) as unums LEFT JOIN Places USING (room_id) WHERE (user_number < 4) AND (position IS NULL) GROUP BY room_id;
			ELSE
				SELECT room_id, name, turn_tl, CONCAT(user_number,"/4"), (password!='') AS private, CASE WHEN position IS NULL THEN "Waiting" ELSE "Playing" END as status FROM Room NATURAL JOIN(
					SELECT count(user_id) as user_number, room_id FROM(
						SELECT user_id, room_id FROM ActivePlayers
						UNION
						SELECT user_id, room_id FROM InactivePlayers) 
					as users GROUP BY room_id
				) as unums LEFT JOIN Places USING (room_id) WHERE (password='') AND (user_number < 4) AND (position IS NULL) GROUP BY room_id;
			END IF;
		END IF;
	END IF;
END