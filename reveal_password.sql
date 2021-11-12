CREATE PROCEDURE reveal_password(name VARCHAR(16), pass VARCHAR(32), room_name VARCHAR(16))
COMMENT "reveal_password(username, password, room_name): look up this rooms password (for admins)"
BEGIN
	IF name NOT IN (SELECT username FROM User) THEN
		SELECT "Wrong username" AS Error;
	ELSE
		IF pass NOT IN (SELECT password FROM User WHERE (username = name)) THEN
			SELECT "Wrong password" AS Error;
		ELSE
			IF room_name NOT IN (SELECT Room.name FROM Room) THEN 
				SELECT "This room does not exist" AS Error;
			ELSE
				IF (SELECT user_id FROM User WHERE (username = name)) NOT IN (SELECT creators_id FROM Room WHERE (Room.name = room_name)) THEN
					SELECT "Only room administrators can see the password" AS Error;
				ELSE
					SELECT (CASE WHEN Room.password = '' THEN "Your room is not protected by a password" ELSE Room.password END) AS message FROM Room WHERE (Room.name = room_name);
				END IF;
			END IF;
		END IF;
	END IF;
END