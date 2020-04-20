--USE [Viewpoint]
--GO

--/****** Object:  StoredProcedure [dbo].[mspSendLoggedOnUserList]    Script Date: 11/03/2014 06:20:50 ******/
--IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mckLoggedOnUserHsitory]') AND type in (N'U'))
--PRINT 'DROP TABLE [dbo].[mckLoggedOnUserHsitory]'
--DROP table [dbo].[mckLoggedOnUserHsitory]
--GO

--PRINT 'CREATE TABLE mckLoggedOnUserHsitory'
--GO

--CREATE TABLE mckLoggedOnUserHsitory
--(
--	RunDate				DATETIME		NOT NULL
--,	LoginName 			varchar(50)		NOT NULL
--,	HostName 			varchar(50)		NULL
--,	MostRecentBatch		DATETIME		NOT NULL
--,	MostRecentLogOn		DATETIME		NOT NULL
--,	UserName			VARCHAR(100)	NULL
--,	UserPhone			varchar(30)		NULL
--,	UserEmail			varchar(30)		NULL
--)
--go

--GRANT SELECT ON mckLoggedOnUserHsitory TO PUBLIC
--go


/****** Object:  StoredProcedure [dbo].[mspSendLoggedOnUserList]    Script Date: 11/03/2014 06:20:50 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mspSendLoggedOnUserList2]') AND type in (N'P', N'PC'))
PRINT 'DROP PROCEDURE [dbo].[mspSendLoggedOnUserList2]'
DROP PROCEDURE [dbo].[mspSendLoggedOnUserList2]
GO

PRINT 'CREATE PROCEDURE [dbo].[mspSendLoggedOnUserList2]'
go

CREATE PROCEDURE [dbo].[mspSendLoggedOnUserList2]
(
	@EmailTo	VARCHAR(1000)	= 'sarahc@McKinstry.com;c-davidmcc@mckinstry.com;geng@mckinstry.com'
,	@EmailCc	VARCHAR(1000)	= 'billo@mckinstry.com;erics@mckinstry.com'
)
as

DECLARE @rundate DATETIME
DECLARE @curcount int
DECLARE @sql VARCHAR(1000)
DECLARE @fn	 VARCHAR(100)
DECLARE @MsgBody	 VARCHAR(2000)

SELECT @rundate=GETDATE()


IF EXISTS ( SELECT 1 FROM mckLoggedOnUserHsitory WHERE RunDate=@rundate)
BEGIN
	DELETE mckLoggedOnUserHsitory WHERE RunDate=@rundate
END

INSERT mckLoggedOnUserHsitory
(
	RunDate
,	LoginName
,	HostName
,	MostRecentBatch
,	MostRecentLogOn
,	UserName
,	UserPhone
,	UserEmail
)
SELECT CAST(CONVERT(VARCHAR(20),@rundate,120) AS DATETIME), tbl.loginname,tbl.hostname, tbl.most_recent_batch, tbl.most_recent_login, tbl.FullName, tbl.Phone,tbl.EMail
FROM  (SELECT  cast(m.loginame as char(20)) as loginname
            ,  cast(m.hostname as char(20)) as hostname
            ,  convert(char(20),m.last_batch,120 ) AS most_recent_batch
            ,  convert(char(20),m.login_time,120 ) AS most_recent_login
            ,  cast(u.FullName as char(40)) as FullName
            ,  cast(coalesce(u.Phone,'''') as char(20)) as Phone
            ,  cast(u.EMail as char(40)) as EMail
            ,  Row_number() OVER (PARTITION BY [hostname], [loginame] ORDER BY [loginame]) AS RowNum
     FROM   master.dbo.sysprocesses m
            LEFT OUTER JOIN Viewpoint.dbo.DDUP u
              ON m.loginame = u.VPUserName
     WHERE  program_name = 'ViewpointClient' AND loginame <> 'viewpointcs'
     ) AS tbl
WHERE  RowNum = 1
ORDER  BY most_recent_login ASC

SELECT @curcount = @@rowcount
--SELECT @MsgBody='<HTML><HEAD><TITLE>Viewpoint Logged On User Summary</TITLE></HEAD><BODY>'
SELECT @MsgBody='<b>' + CAST(@curcount AS VARCHAR(10)) + '</b> users logged into Viewpoint<br/><br/>'
SELECT @MsgBody=@MsgBody + '<i><FONT SIZE=''-2''>' + @@SERVERNAME + '.' + DB_NAME() + '</FONT></i><br/><br/>'

IF @@servername IN ('MCKSQL01\VIEWPOINT','MCKSQL02\VIEWPOINT','SPKSQL01\VIEWPOINT')
begin
	SELECT @MsgBody=@MsgBody + '<a href=''file:\\mckviewpoint\Viewpoint Repository\Reports\Custom\ProductionLoggedOnUserHistory.xlsx''>Logged On User Summary</a>'
end
--SELECT @MsgBody='</BODY></HTML>'


SELECT @fn=REPLACE(@@SERVERNAME,'\','_') + '_' + DB_NAME() + '_' + REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR(30),GETDATE(),120),'-',''),':',''),' ','') + '.txt'

SELECT @sql=
'select
	convert(char(20),RunDate,113)
,	cast(LoginName as char(20))
,	cast(HostName as char(20))
,	convert(char(20),MostRecentBatch,113)
,	convert(char(20),MostRecentLogOn,113)
,	cast(UserName as char(40))
,	cast(coalesce(UserPhone,'') as char(20))
,	cast(coalesce(UserEmail,'') as char(40))
FROM
	mckLoggedOnUserHsitory
WHERE
	CONVERT(VARCHAR(20),RunDate,120)=''' + CONVERT(VARCHAR(20),@rundate,120) + '''
ORDER BY
	MostRecentBatch'


--SELECT *
--FROM  (SELECT  cast(m.loginame as char(20)) as loginname
--            ,  cast(m.hostname as char(20)) as hostname
--            ,  convert(char(20),m.last_batch,120 ) AS most_recent_batch
--            ,  convert(char(20),m.login_time,120 ) AS most_recent_login
--            ,  cast(u.FullName as char(40)) as FullName
--            ,  cast(coalesce(u.Phone,'''') as char(20)) as Phone
--            ,  cast(u.EMail as char(40)) as EMail
--            ,  Row_number() OVER (PARTITION BY [hostname], [loginame] ORDER BY [loginame]) AS RowNum
--     FROM   master.dbo.sysprocesses m
--            LEFT OUTER JOIN Viewpoint.dbo.DDUP u
--              ON m.loginame = u.VPUserName
--     WHERE  program_name = ' + '''ViewpointClient''' + ' AND loginame <> ' + '''viewpointcs''' + ' ) AS tbl
--WHERE  RowNum = 1
--ORDER  BY most_recent_login ASC'


--PRINT @fn
--PRINT @sql

EXEC msdb.dbo.sp_send_dbmail
    @profile_name = 'Viewpoint',
    @recipients = @EmailTo,
    @copy_recipients = @EmailCc,
    --@recipients = 'billo@mckinstry.com',
    @execute_query_database='Viewpoint',
    @query = @sql ,
    @query_attachment_filename=@fn,
    @query_result_header=0,
    --@query_result_width =750,
    @query_result_separator=' ',
    @query_result_no_padding =1,
    @subject = 'Viewpoint Logged On Users Summary',
    @body = @MsgBody,
    @body_format='HTML',
    @attach_query_result_as_file = 1 ;
    

select
	convert(char(20),RunDate,113)
,	cast(LoginName as char(20))
,	cast(HostName as char(20))
,	convert(char(20),MostRecentBatch,113)
,	convert(char(20),MostRecentLogOn,113)
,	cast(UserName as char(40))
,	cast(coalesce(UserPhone,'') as char(20))
,	cast(coalesce(UserEmail,'') as char(40))
FROM
	mckLoggedOnUserHsitory
WHERE
	CONVERT(VARCHAR(20),RunDate,120)=CONVERT(VARCHAR(20),@rundate,120)
ORDER BY
	MostRecentBatch
	
GO

/****** Object:  StoredProcedure [dbo].[mspSendLoggedOnUserList]    Script Date: 11/03/2014 06:20:50 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mvwLoggedOnUserHsitory]') AND type in (N'V'))
PRINT 'DROP VIEW [dbo].[mvwLoggedOnUserHsitory]'
DROP view [dbo].[mvwLoggedOnUserHsitory]
GO

PRINT 'CREATE VIEW mvwLoggedOnUserHsitory'
GO

CREATE VIEW mvwLoggedOnUserHsitory
AS
SELECT
	YEAR(h.RunDate) AS RunYear
,	DATEPART(qq,h.RunDate) AS RunQuarter	
,	MONTH(h.RunDate) AS RunMonth
,	DAY(h.RunDate) AS RunDay
,	CASE DATEPART(dw,h.RunDate) 
		WHEN 1 THEN 'Sun'
		WHEN 2 THEN 'Mon'
		WHEN 3 THEN 'Tue'
		WHEN 4 THEN 'Wed'
		WHEN 5 THEN 'Thu'
		WHEN 6 THEN 'Fri'
		WHEN 7 THEN 'Sat'
		ELSE 'Unk'
	END AS RunDayOfWeek
,	DATEPART(hh,h.RunDate) AS RunHour
,	CAST(CONVERT(VARCHAR(10),h.RunDate, 101) AS DATE) AS RunDate
,	h.RunDate AS RunDateTime
,	h.LoginName 			
,	h.HostName 	
,	CASE
		WHEN h.HostName	LIKE 'SERDW%' THEN 'AppGW'
		ELSE 'Desktop'
	END AS ConnectMethod
,	h.MostRecentBatch		
,	h.MostRecentLogOn		
,	h.UserName	
,	h.UserPhone			
,	h.UserEmail			
FROM
	mckLoggedOnUserHsitory h 
go

GRANT SELECT ON mvwLoggedOnUserHsitory TO PUBLIC
go


--mspSendLoggedOnUserList2
--	@EmailTo	= NULL --'sarahc@McKinstry.com;c-davidmcc@mckinstry.com;geng@mckinstry.com'
--,	@EmailCc	= 'billo@mckinstry.com'


--SELECT * FROM mvwLoggedOnUserHsitory	
	
	
	
	/* JOIN 
	DDUP u ON
		h.LoginName=u.VPUserName LEFT OUTER JOIN
	dbo.PREHFullName p ON
		u.PRCo=p.PRCo
	AND u.Employee=p.Employee
*/
	

		
	