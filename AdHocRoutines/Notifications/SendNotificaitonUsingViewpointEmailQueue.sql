--sp_helptext vspMailQueueInsert

use Viewpoint
go


declare	@myTo varchar(3000)
declare	@myCC varchar(3000)				-- = Null,
declare	@myBCC varchar(3000)				--= Null,
declare	@myFrom varchar(3000)				--= Null,
declare	@mySubject varchar(3000)			--,
declare	@myBody varchar(max)					--,
declare	@myAttempts int					--= Null,
declare	@myFailureDate datetime			--= Null,
declare	@myFailureReason varchar(3000)	--= Null,
declare	@mySource varchar(30)				--= null,
declare	@myAttachIDs varchar(max)			--= null,
declare	@myAttachFiles varchar(max)		--= null,
declare	@myCacheFolder varchar(max)		--= null,
declare	@myTokenID int					--= Null,
declare	@myVPUserName bVPUserName			--= NULL,
declare	@myIsHTML bYN						--= 'N'

select @myBody = 
	'<table border=1>'
+	'  <tr>'
+	'    <td colspan=2 bgcolor=#336699 align=center>'
+	'      <h2>Test Email</h2>'
+	'    </td>'
+	'  </tr>'
+	'  <tr>'
+	'    <td>'
+	'      <i>Server:</i>'
+	'    </td>'
+	'    <td>'
+	'      <b>' + @@SERVERNAME + '</b>'
+	'    </td>'
+	'  </tr>'
+	'  <tr>'
+	'    <td>'
+	'      <i>Database:</i>'
+	'    </td>'
+	'    <td>'
+	'      <b>' + db_name() + '</b>'
+	'    </td>'
+	'  </tr>'
+	'  <tr>'
+	'    <td>'
+	'      <i>User:</i>'
+	'    </td>'
+	'    <td>'
+	'      <b>' + suser_sname() + '</b> <i>(' + cast(@@SPID as varchar(20)) + ')</i>'
+	'    </td>'
+	'  </tr>'
+	'  <tr>'
+	'    <td colspan=2>'
+   '       <p>This is an example of an email that can be sent from Viewpoint using Viewpoint''s'
+   '       messaging queue technology (<i>[dbo].[vspMailQueueInsert]</i>).  This may be a better way'
+   '       of sending Viewpoint related messages as the results are recorded, retries are managed'
+   '       and monitoring can be achieved more easily (as opposed to SQL msdb.dbo.sp_db_sendmail.)<p>'
+   '       <p>Look for a follow up email with the code that generated this message.</p>'
+	'    </td>'
+	'  </tr>'
+	'  <tr>'
+	'    <td colspan=2 bgcolor=#336699 align=center>'
+	'      <font size=-2><i>' + cast(getdate() as varchar(50)) + '</i></font>'
+	'    </td>'
+	'  </tr>'
+	'</table>'

select
	@myTo = 'billo@mckinstry.com'																--,
--,	@myCC = 'arunt@mckinstry.com;howards@mckinstry.com;benwi@mckinstry.com'						-- = Null,
,	@myCC = null																				-- = Null,
,	@myBCC = null																				--= Null,
,	@myFrom = 'billo@mckinstry.com'																--= Null,
,	@mySubject ='Test email from Viewpoint using [dbo].[vspMailQueueInsert] from Development'	--,					--,
,	@myAttempts = null																			--= Null,
,	@myFailureDate =null																		--= Null,
,	@myFailureReason =null																		--= Null,
,	@mySource = 'McKCustom'																		--= null,
,	@myAttachIDs = null																			--= null,
,	@myAttachFiles = null																		--= null,
,	@myCacheFolder = null																		--= null,
,	@myTokenID = null																			--= Null,
,	@myVPUserName = suser_sname()																--= NULL,
,	@myIsHTML = 'Y'																				--= 'N'

exec [dbo].[vspMailQueueInsert]
	@To = @myTo
,	@CC = @myCC
,	@BCC = @myBCC
,	@From =	@myFrom
,	@Subject =	@mySubject
,	@Body = @myBody
,	@Attempts = @myAttempts
,	@FailureDate = @myFailureDate
,	@FailureReason = @myFailureReason
,	@Source = @mySource
,	@AttachIDs = @myAttachIDs
,	@AttachFiles =	@myAttachFiles
,	@CacheFolder = @myCacheFolder
,	@TokenID = @myTokenID
,	@VPUserName = @myVPUserName
,	@IsHTML =	@myIsHTML
go

--select * from vMailQueue
--select distinct Source from vMailQueueArchive order by SentDate desc