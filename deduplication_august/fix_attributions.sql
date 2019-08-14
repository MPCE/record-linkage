DELETE FROM edition_author WHERE edition_code = 'bk0001848' AND author = 'id2702';

UPDATE edition_author
SET author = CONCAT('id00', SUBSTRING(author,3,4))
WHERE CHAR_LENGTH(author) = 6;

-- Executed 7/8/2019 - success