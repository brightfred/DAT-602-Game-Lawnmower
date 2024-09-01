DROP DATABASE IF EXISTS dat_602_game;
CREATE DATABASE dat_602_game;
USE dat_602_game;

-- Note: INT in MySQL does not need a defined width like INT(10) as it will be deprecated in the next version

DELIMITER //

CREATE PROCEDURE createAllTables()
BEGIN
    -- Drop and create the game table// stores all the game sessions, game type (single-player or multiplayer), start time, and end time of a game(end time is null when the game is still running).
    DROP TABLE IF EXISTS game;
    CREATE TABLE game (
        game_id INT AUTO_INCREMENT PRIMARY KEY,
        game_type VARCHAR(50) NOT NULL,
        start_time TIMESTAMP NOT NULL,
        end_time TIMESTAMP
    );

    -- Drop and create the map table
    DROP TABLE IF EXISTS map;
    CREATE TABLE map (
        map_id INT AUTO_INCREMENT PRIMARY KEY,
        game_id INT,
        FOREIGN KEY (game_id) REFERENCES game(game_id)
    );

    -- Drop and create the tile table// represents each tiles on the board linked to a specific map to define the game layout.
    DROP TABLE IF EXISTS tile;
    CREATE TABLE tile (
        tile_id INT AUTO_INCREMENT PRIMARY KEY,
        map_id INT,
        FOREIGN KEY (map_id) REFERENCES map(map_id)
    );

    -- Drop and create the tile_type table//  define the diffrent type of tiles available in the game and the effects on gameplay or player(score,+/- health,pattern can end game when all gone)).
    DROP TABLE IF EXISTS tile_type;
    CREATE TABLE tile_type (
        tile_type_id INT AUTO_INCREMENT PRIMARY KEY,
        `name` VARCHAR(50) NOT NULL,
        effect VARCHAR(50) NOT NULL,
        score_value INT NOT NULL
    );

    -- Drop and create the player table // store the player data ,the game they are playing, their position on the board,status(banned,offline,online,lock-out) and login info(username,password).
    DROP TABLE IF EXISTS player;
    CREATE TABLE player (
        player_id INT AUTO_INCREMENT PRIMARY KEY,
        game_id INT,
        tile_id INT,
        username VARCHAR(50) NOT NULL UNIQUE,
        player_password VARCHAR(255) NOT NULL,
        is_admin BOOLEAN NOT NULL DEFAULT FALSE,
        `status` VARCHAR(20) NOT NULL DEFAULT 'offline',
        healthpoint INT NOT NULL DEFAULT 3,
        FOREIGN KEY (game_id) REFERENCES game(game_id),
        FOREIGN KEY (tile_id) REFERENCES tile(tile_id)
    );

    -- Drop and create the score table // store the score of each player in each game session , their time and score .
    DROP TABLE IF EXISTS score;
    CREATE TABLE score (
        score_id INT AUTO_INCREMENT PRIMARY KEY,
        player_id INT,
        game_id INT,
        score_timestamp DATETIME NOT NULL,
        score_value INT NOT NULL,
        FOREIGN KEY (player_id) REFERENCES player(player_id),
        FOREIGN KEY (game_id) REFERENCES game(game_id)
    );

    -- Drop and create the log table // store the log info such as player login attempts and time to track the consecutive failed attempts(act as a counter and need to be reseted on successful login).
    DROP TABLE IF EXISTS log;
    CREATE TABLE log (
        log_id INT AUTO_INCREMENT PRIMARY KEY,
        player_id INT,
        login_attempt INT NOT NULL DEFAULT 0,
        login_timestamp DATETIME NOT NULL,
        FOREIGN KEY (player_id) REFERENCES player(player_id)
    );

    -- Drop and create the chat_session table // store the start and end times for each session.
    DROP TABLE IF EXISTS chat_session;
    CREATE TABLE chat_session (
        chat_id INT AUTO_INCREMENT PRIMARY KEY,
        session_start DATETIME NOT NULL,
        session_end DATETIME
    );

    -- Drop and create the player_chat table // to store all the messages sent by players and link each message to a player id and the chat session for communication during a game.
    DROP TABLE IF EXISTS player_chat;
    CREATE TABLE player_chat (
        player_id INT,
        chat_id INT,
        `timestamp` DATETIME NOT NULL,
        message VARCHAR(255) NOT NULL,
        PRIMARY KEY (player_id, chat_id, timestamp),
        FOREIGN KEY (player_id) REFERENCES player(player_id),
        FOREIGN KEY (chat_id) REFERENCES chat_session(chat_id)
    );

    -- Drop and create the tile_location table // to track the position(row,colum) of each tile on the game board,the type of tile .
	DROP TABLE IF EXISTS tile_location;
	CREATE TABLE tile_location (
		tile_id INT,
		tile_type_id INT,
		`row` INT NOT NULL,
		`column` INT NOT NULL,
		PRIMARY KEY (tile_id, tile_type_id), -- Composite Primary Key because of the joint many to many relationship
		FOREIGN KEY (tile_id) REFERENCES tile(tile_id),
		FOREIGN KEY (tile_type_id) REFERENCES tile_type(tile_type_id)
	);

    -- Drop and create the inventory table // to track the items collected by the players during the game, the player and the game session with it.
    DROP TABLE IF EXISTS inventory;
    CREATE TABLE inventory (
        inventory_id INT AUTO_INCREMENT PRIMARY KEY,
        player_id INT,
        game_id INT,
        quantity INT NOT NULL,
        FOREIGN KEY (player_id) REFERENCES player(player_id),
        FOREIGN KEY (game_id) REFERENCES game(game_id)
    );

    -- Drop and create the item table // to store the item and details that player can get during the game.
    DROP TABLE IF EXISTS item;
    CREATE TABLE item (
        item_id INT AUTO_INCREMENT PRIMARY KEY,
        inventory_id INT,
        tile_type_id INT,
        item_name VARCHAR(50) NOT NULL,
        item_description VARCHAR(100) NOT NULL,
        FOREIGN KEY (inventory_id) REFERENCES inventory(inventory_id),
        FOREIGN KEY (tile_type_id) REFERENCES tile_type(tile_type_id)
    );

END //

DELIMITER ;




-- Now the test data in a store procedure
DELIMITER //

CREATE PROCEDURE insertTestData()
BEGIN
    -- test data in the player table // players with usernames, if they are admin and their initial healthpoint.
    INSERT INTO player (username, player_password, is_admin, healthpoint, `status`)
    VALUES ('Toaddy', 'password123', FALSE, 3, 'online'),
           ('Fredd', 'password1234', TRUE, 3, 'online'),
           ('Hello', 'password12345', FALSE, 3, 'locked-out'),
           ('WhatAmI', 'password123456', FALSE, 3, 'banned');

    -- test data in the game table // create the initial game sessions info with game type.
    INSERT INTO game (game_type, start_time)
    VALUES ('single-player', NOW());
           

    -- test data in the map table // to linkthe map to a game session.
    INSERT INTO map (game_id) 
    VALUES (1);

    -- test data in the tile_type table // define all the tile type ,their effect and the score associated with this type of tile.
    -- (?does my heart have a score value if only remaining heart at the end of the game should be worth 5 point each?)
    INSERT INTO tile_type (`name`, effect, score_value)
    VALUES ('Pattern', 'When all mowed, end the game', 0),
           ('Rock', '-1 healht point', -5),
           ('Gnome', 'health point', -5),
           ('Heart', '+1 healht point', 5),
           ('Biggerblade', 'Increase the mowing area', 0);

    -- test data in the tile table // link the tiles with a specific map.(is this correct,need to check again?)
    INSERT INTO tile (map_id) 
    VALUES (1),
		   (1),
           (1),
           (1), 
           (1), 
		   (1), 
		   (1);
   

    -- test data in the tile_location table // place the tiles on the board with specific location to create the layout.
    INSERT INTO tile_location (tile_id, tile_type_id, `row`, `column`)
    VALUES (1, 1, 1, 1),  -- Pattern tile
           (2, 2, 1, 2),  -- Rock tile
           (3, 3, 2, 1),  -- Gnome tile
           (4, 4, 2, 2),  -- Heart tile
           (5, 5, 2, 3),  -- Bigger Blade tile
           (6, 1, 3, 1),  -- Pattern tile
           (7, 1, 3, 2);  -- Pattern tile

    -- test data in the inventory table // set the quantity of item in a specific player inventory.
    INSERT INTO inventory (player_id, game_id, quantity)
    VALUES (1, 1, 1),  -- Toaddy has 1 item
           (2, 1, 2);  -- Fredd has 2 items

    -- test data in the item table // put items collected by the players ,the effects in their inventory table.
    INSERT INTO item (inventory_id, tile_type_id, item_name, item_description)
    VALUES (1, 4, 'Heart', '+1 healht point'),  -- Toaddy item
           (2, 5, 'Biggerblade', 'increase the mowing area');  -- Fredd item
           

    -- test data in the score table // set some score stored in different game sessions.
    INSERT INTO score (player_id, game_id, score_timestamp, score_value)
    VALUES (1, 1, '2024-08-29 08:24:00', 42),  -- Toaddy score
           (2, 1, '2024-08-29 08:25:00', 36),  -- Fredd score
           (3, 1, '2024-08-29 08:26:00', 34),  -- Hello score
           (4, 1, '2024-08-29 08:27:00', 30);  -- WhatAmI score

    -- test data in the log table / the login attempts and timestamps test data for all situation(locked-out,banned and a regular successful login.
    INSERT INTO log (player_id, login_attempt, login_timestamp)
    VALUES (1, 1, '2024-08-29 08:28:00'),  -- Toaddy regular login attempt 
           (2, 2, '2024-08-29 08:29:00'),  -- Fredd login attempt #2
           (3, 1, '2024-08-29 08:30:00'),  -- Hello login attempt #1 
           (3, 2, '2024-08-29 08:31:00'),  -- Hello login attempt #2 
           (3, 3, '2024-08-29 08:32:00'),  -- Hello login attempt #3 
           (3, 4, '2024-08-29 08:33:00'),  -- Hello login attempt #4 
           (3, 5, '2024-08-29 08:34:00'),  -- Hello's login attempt #5 (get locked out)
           (4, 4, '2024-08-29 08:35:00');  -- WhatAmI's login attempt (player is banned)
           
           
    -- test data in the chat_session table: Creating a chat session for players.
    INSERT INTO chat_session (session_start)
    VALUES ('2024-08-29 08:24:00');

    -- test data in the player_chat table: Storing player chat messages in the session.
    INSERT INTO player_chat (player_id, chat_id, `timestamp`, message)
    VALUES (1, 1, '2024-08-29 08:37:00', 'Hello world'),
           (2, 1, '2024-08-29 08:36:00', 'Hi Toaddy!');
    
END //

DELIMITER ;

CALL createAllTables();
CALL insertTestData();
