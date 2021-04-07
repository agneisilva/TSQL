SELECT o.name
 FROM syscomments AS c
 INNER JOIN sysobjects AS o
 ON c.id = o.id
 WHERE c.text LIKE '%[objectname]%';
