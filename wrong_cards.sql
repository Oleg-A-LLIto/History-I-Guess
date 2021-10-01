CREATE PROCEDURE wrong_cards(uid INT, rid INT, secret_key CHAR(12))
BEGIN
	IF secret_key = 'oQCrE109mN.G' THEN
		SELECT
		   room_id,
		   position,
		   card,
		   date,
		   correct 
		FROM
		   User 
		   LEFT JOIN
		      (
		         SELECT
		            room_id,
		            user_id 
		         FROM
		            ActivePlayers 
		         UNION
		         SELECT
		            room_id,
		            user_id 
		         FROM
		            InactivePlayers
		      )
		      AS players using (user_id) 
		   JOIN
		      (
		         SELECT
		            yes.room_id,
		            card,
		            yes.position,
		            yes.date,
		            (
		               CASE
		                  WHEN
		                     no.card IS NULL 
		                  THEN
		                     'yes' 
		                  ELSE
		                     'no' 
		               END
		            )
		            AS correct 
		         FROM
		            (
		               SELECT DISTINCT
		                  t2.position,
		                  t2.room_id,
		                  t2.name AS card 
		               FROM
		                  Places 
		                  JOIN
		                     Cards AS c using (card_id) 
		                  JOIN
		                     CardTypes AS ct using (card_type) 
		                  JOIN
		                     (
		                        SELECT
		                           Max(position) AS max,
		                           Min(position) AS min,
		                           room_id 
		                        FROM
		                           Places 
		                        GROUP BY
		                           room_id
		                     )
		                     AS mm 
		                  JOIN
		                     (
		                        SELECT
		                           room_id,
		                           position,
		                           date,
		                           name 
		                        FROM
		                           Places 
		                           JOIN
		                              Cards using (card_id) 
		                           JOIN
		                              CardTypes using (card_type)
		                     )
		                     AS t2 
		                  JOIN
		                     (
		                        SELECT
		                           room_id,
		                           position,
		                           date,
		                           name 
		                        FROM
		                           Places 
		                           JOIN
		                              Cards using (card_id) 
		                           JOIN
		                              CardTypes using (card_type)
		                     )
		                     AS t3 
		               where
		                  (
		(( ct.date > t2.date && Places.position = t2.position - 1 && (ct.date < t3.date && t3.position = t2.position + 1 
		                     OR t2.position = max))) || ((t3.date < t2.date && t3.position = t2.position + 1 && (ct.date < t3.date && Places.position = t2.position - 1 
		                     OR t2.position = min)))
		                  )
		                  && (t2.position != 0) && (t2.room_id = Places.room_id && t2.room_id = t3.room_id && mm.room_id = t2.room_id) 
		            )
		            AS no 
		            RIGHT JOIN
		               (
		                  SELECT
		                     position,
		                     room_id,
		                     name AS card,
		                     date 
		                  FROM
		                     Places 
		                     JOIN
		                        Cards AS cr using (card_id) 
		                     JOIN
		                        CardTypes AS crt using (card_type)
		               )
		               AS yes using (card) 
		      )
		      AS crds using (room_id) 
		WHERE
			(user_id = uid) &&
			(room_id = rid)
		ORDER BY
		   room_id,
		   position;
	END IF;
END