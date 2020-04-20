USE master


SET NOCOUNT ON

DECLARE @Sid TABLE (name VARCHAR(255), sid1 VARBINARY(255), sid2 VARBINARY(255))

DECLARE @passwords TABLE (name VARCHAR(255), password1 NVARCHAR(255), password2 NVARCHAR(255))

INSERT INTO @Sid
        ( name, sid1)
SELECT name,sid
FROM sys.syslogins
--WHERE name IN ('MCKINSTRY\viewpointsvc', 'viewpointcs', 'vcspublic')

INSERT INTO @passwords(name, password1)
SELECT name,password
FROM sys.syslogins


:connect MCKSQL02\VIEWPOINT
IF EXISTS(
SELECT * FROM @Sid
WHERE name NOT IN(SELECT name FROM sys.syslogins))
	PRINT 'Missing MCKSQL02 Login'

IF EXISTS(
SELECT * FROM sys.syslogins
WHERE name NOT IN (SELECT name FROM @Sid))
	PRINT 'Missing MCKSQL01 Login'


INSERT INTO @Sid
        ( name, sid1, sid2 )
SELECT l.name, NULL, sid
FROM sys.syslogins l
	LEFT JOIN @Sid s ON s.name = l.name
WHERE s.name IS NULL

UPDATE s
SET sid2 = l.sid
FROM @Sid s 
	JOIN sys.syslogins l ON s.name = l.name

UPDATE p 
SET p.password2 = l.password
FROM @passwords p
	JOIN sys.syslogins l ON l.name = p.name

--SELECT s.name,s.sid1, l.sid FROM sys.syslogins l
--	JOIN @Sid s ON s.name = l.name
--WHERE sid1<>sid
----WHERE s.name IN ('MCKINSTRY\viewpointsvc', 'viewpointcs', 'vcspublic')

--SELECT * FROM @Sid

:connect SPKSQL01\VIEWPOINT

IF EXISTS(SELECT * FROM @Sid
WHERE name NOT IN(SELECT name FROM sys.syslogins))
	PRINT 'Missing SPKSQL01 Login'


IF EXISTS(SELECT * FROM sys.syslogins
WHERE name NOT IN (SELECT name FROM @Sid))
	PRINT 'Missing Login ON MCKSQL01 and MCKSQL02'


SELECT s.name, s.sid1 AS [MCKSQL01 SID], s.sid2 AS [MCKSQL02 SID], l.sid AS [SPKSQL01 SID], p.password1 AS [MCKSQL01 PW], p.password2 AS [MCKSQL02 PW], l.password AS [SPKSQL01 PW]
FROM @Sid s
	LEFT JOIN sys.syslogins l ON s.name = l.name
	LEFT JOIN @passwords p ON p.name = s.name
WHERE (sid1 <> sid2) OR (sid2<>l.sid) OR (l.sid<> sid1) OR (p.password1 <> p.password2) OR (p.password1 <> l.password) OR (p.password2<>l.password)


--SELECT p.name--, p.password1, p.password2, l.password
--FROM @passwords p
--	LEFT JOIN sys.syslogins l ON l.name = p.name
----WHERE p.name IN ('vcspublic','viewpointcs')
--WHERE (p.password1 <> p.password2) OR (p.password1 <> l.password) OR (p.password2<>l.password)