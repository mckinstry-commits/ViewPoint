USE Viewpoint
GO

If EXISTS ( Select * From INFORMATION_SCHEMA.ROUTINES Where ROUTINE_NAME='MCKspVPUserCreationProcess' and ROUTINE_SCHEMA='dbo' and ROUTINE_TYPE='PROCEDURE' )
Begin
	Print 'DROP PROCEDURE dbo.MCKspVPUserCreationProcess'
	DROP PROCEDURE dbo.MCKspVPUserCreationProcess
End
GO

Print 'CREATE PROCEDURE dbo.MCKspVPUserCreationProcess'
GO


CREATE PROCEDURE [dbo].[MCKspVPUserCreationProcess]
( @co bCompany,
  @Rbatchid bBatchID ,
  @Count INT OUTPUT  ) AS
/*
	Purpose:		Create users w/ security permissions based on roles
	Created by:		Arun Thomas
	Modified by:	Leo Gurdian
	---------------------------
    Modified	| Change
	-----------	  --------------------------------  	
	4/24/2017	  VT changed to -> VVT , SL changed to -> AP , HD no longer used
	8/11/2017	  Company security moved into roles. No longer determined by UI selection. UI company now only sets user default company.	
	10/2/2017	  BW- Removed Co 90 from all groups. In group 201, removed 'SL' and changed 'VT' to 'VVT'. Removed groups for 'HD'
*/
BEGIN
       --User profile
	   --Non PR
        BEGIN

		--create missing DDUP records
		INSERT vDDUP 
		(
			VPUserName,	FullName, EMail,DefaultCompany
		,	SendViaSmtp
		,	EnterAsTab
		,	ToolTipHelp
		,	ExtendControls
		,	SmartCursor
		,	SavePrinterSettings
		,	AltGridRowColors
		,	SaveLastUsedParameters
		,   ShowRates
		)

		SELECT 'MCKINSTRY\'+ UserName, Name, Email, @co
		,	'Y'	--SendViaSmtp
		,	'Y'	--EnterAsTab
		,	'Y' --ToolTipHelp
		,	'Y'	--ExtendControls
		,	'Y'	--SmartCursor
		,	'Y'	--SavePrinterSettings
		,	'Y'	--AltGridRowColors
		,	'Y'	--SaveLastUsedParameters
		,   'N' --Show rates only applicable to PR role
		 FROM  MCKVPUserCreation
		 WHERE BatchNum = @Rbatchid 
		 --AND Role != 'PR' 
		 AND 'MCKINSTRY\' + UserName NOT IN
		(	SELECT DISTINCT [VPUserName] FROM vDDUP )

		END

		--update DDUP records in batch for PR show rates flag
		UPDATE p SET p.ShowRates = CASE WHEN c.Role = 'PR' THEN 'Y' ELSE 'N' END, p.DeactivatedDate = NULL, p.DefaultCompany = @co
		FROM dbo.DDUP p
		JOIN dbo.MCKVPUserCreation c ON p.VPUserName = 'MCKINSTRY\' + c.UserName
		WHERE c.BatchNum = @Rbatchid

		--Delete all security groups from DDSU for users in batch
		DELETE FROM dbo.DDSU WHERE VPUserName IN (SELECT 'MCKINSTRY\' + UserName FROM MCKVPUserCreation WHERE BatchNum = @Rbatchid)

	   --User profile
	   -- PR
		--BEGIN

		--INSERT vDDUP 
		--(
		--	VPUserName,	FullName, EMail,DefaultCompany
		--,	SendViaSmtp
		--,	EnterAsTab
		--,	ToolTipHelp
		--,	ExtendControls
		--,	SmartCursor
		--,	SavePrinterSettings
		--,	AltGridRowColors
		--,	SaveLastUsedParameters
		--,   ShowRates
		--)

		--SELECT 'MCKINSTRY\'+ UserName, Name, Email, @co
		--,	'Y'	--SendViaSmtp
		--,	'Y'	--EnterAsTab
		--,	'Y' --ToolTipHelp
		--,	'Y'	--ExtendControls
		--,	'Y'	--SmartCursor
		--,	'Y'	--SavePrinterSettings
		--,	'Y'	--AltGridRowColors
		--,	'Y'	--SaveLastUsedParameters
		--,   'Y' --Show rates only applicable to PR role
		-- FROM  MCKVPUserCreation WHERE BatchNum = @Rbatchid AND Role = 'PR'
		-- AND	'MCKINSTRY\' + UserName NOT IN
		--(	SELECT DISTINCT [VPUserName] FROM vDDUP )

		--END


		----Reassign all security for all users in batch
        -- Base security group
		BEGIN
		INSERT DDSU
		(SecurityGroup, VPUserName) 
		(SELECT 2,'MCKINSTRY\'+ y.UserName  FROM MCKVPUserCreation y WHERE y.BatchNum = @Rbatchid 
		AND NOT EXISTS ( SELECT 1 FROM DDSU x WHERE x.SecurityGroup = 2 AND x.VPUserName = 'MCKINSTRY\'+ y.UserName))
		 
		 INSERT DDSU
		(SecurityGroup, VPUserName) 
		(SELECT 4,'MCKINSTRY\'+ y.UserName  FROM MCKVPUserCreation y WHERE y.BatchNum = @Rbatchid 
		AND NOT EXISTS ( SELECT 1 FROM DDSU x WHERE x.SecurityGroup = 4 AND x.VPUserName = 'MCKINSTRY\'+ y.UserName))

		 INSERT DDSU
		(SecurityGroup, VPUserName) 
		(SELECT 10001,'MCKINSTRY\'+ y.UserName  FROM MCKVPUserCreation y WHERE y.BatchNum = @Rbatchid 
		AND NOT EXISTS ( SELECT 1 FROM DDSU x WHERE x.SecurityGroup = 10001 AND x.VPUserName = 'MCKINSTRY\'+ y.UserName))
		 
		 INSERT DDSU
		(SecurityGroup, VPUserName) 
		(SELECT 10020,'MCKINSTRY\'+ y.UserName  FROM MCKVPUserCreation y WHERE y.BatchNum = @Rbatchid 
		AND NOT EXISTS ( SELECT 1 FROM DDSU x WHERE x.SecurityGroup = 10020 AND x.VPUserName = 'MCKINSTRY\'+ y.UserName))

		  Insert DDSU
		(SecurityGroup, VPUserName) 
		(select 10004,'MCKINSTRY\'+ y.UserName  from MCKVPUserCreation y where y.BatchNum = @Rbatchid and y.Role in ('GL')
		and not exists ( select 1 from DDSU x where x.SecurityGroup = 10004 and x.VPUserName = 'MCKINSTRY\'+ y.UserName))
		 
		  Insert DDSU
		(SecurityGroup, VPUserName) 
		(select 10060,'MCKINSTRY\'+ y.UserName  from MCKVPUserCreation y where y.BatchNum = @Rbatchid and y.Role in ('AP', 'PR', 'PO')
		and not exists ( select 1 from DDSU x where x.SecurityGroup = 10060 and x.VPUserName = 'MCKINSTRY\'+ y.UserName))
		 
		--  INSERT DDSU
		--(SecurityGroup, VPUserName) 
		--(SELECT 10090,'MCKINSTRY\'+ y.UserName  FROM MCKVPUserCreation y WHERE y.BatchNum = @Rbatchid AND y.Role IN ('AR', 'AP', 'GL')
		--AND NOT EXISTS ( SELECT 1 FROM DDSU x WHERE x.SecurityGroup = 10090 AND x.VPUserName = 'MCKINSTRY\'+ y.UserName))
		 
		--  INSERT DDSU
		--(SecurityGroup, VPUserName) 
		--(SELECT 10000,'MCKINSTRY\'+ y.UserName  FROM MCKVPUserCreation y WHERE y.BatchNum = @Rbatchid AND y.Co = 1
		--AND NOT EXISTS ( SELECT 1 FROM DDSU x WHERE x.SecurityGroup = 10000 AND x.VPUserName = 'MCKINSTRY\'+ y.UserName))
		 
		--  Insert DDSU
		--(SecurityGroup, VPUserName) 
		--(select 10000,'MCKINSTRY\'+ y.UserName  from MCKVPUserCreation y where y.BatchNum = @Rbatchid and y.Co = 20
		--and not exists ( select 1 from DDSU x where x.SecurityGroup = 10020 and x.VPUserName = 'MCKINSTRY\'+ y.UserName))
		 
		--  INSERT DDSU
		--(SecurityGroup, VPUserName) 
		--(SELECT 10090,'MCKINSTRY\'+ y.UserName  FROM MCKVPUserCreation y WHERE y.BatchNum = @Rbatchid AND y.Co = 90
		--AND NOT EXISTS ( SELECT 1 FROM DDSU x WHERE x.SecurityGroup = 10090 AND x.VPUserName = 'MCKINSTRY\'+ y.UserName))
		 

		 END

		 --Special security group
		 Begin
		 --PM
		  Insert DDSU
		(SecurityGroup, VPUserName) 
		(select 201,'MCKINSTRY\'+ y.UserName  from MCKVPUserCreation y where y.BatchNum = @Rbatchid and y.Role in ('PM','AR','AP','SM','PO','VVT','GL')
		and not exists ( select 1 from DDSU x where x.SecurityGroup = 201 and x.VPUserName = 'MCKINSTRY\'+ y.UserName))

		 --AP
		  Insert DDSU
		(SecurityGroup, VPUserName) 
		(select 11,'MCKINSTRY\'+ y.UserName  from MCKVPUserCreation y where y.BatchNum = @Rbatchid and y.Role in ('AP')
		and not exists ( select 1 from DDSU x where x.SecurityGroup = 11 and x.VPUserName = 'MCKINSTRY\'+ y.UserName))
		
		  Insert DDSU
		(SecurityGroup, VPUserName) 
		(select 14,'MCKINSTRY\'+ y.UserName  from MCKVPUserCreation y where y.BatchNum = @Rbatchid and y.Role in ('AP')
		and not exists ( select 1 from DDSU x where x.SecurityGroup = 14 and x.VPUserName = 'MCKINSTRY\'+ y.UserName))

		Insert DDSU
		(SecurityGroup, VPUserName) 
		(select 240,'MCKINSTRY\'+ y.UserName  from MCKVPUserCreation y where y.BatchNum = @Rbatchid and y.Role in ('AP')
		and not exists ( select 1 from DDSU x where x.SecurityGroup = 240 and x.VPUserName = 'MCKINSTRY\'+ y.UserName))

		Insert DDSU
		(SecurityGroup, VPUserName) 
		(select 241,'MCKINSTRY\'+ y.UserName  from MCKVPUserCreation y where y.BatchNum = @Rbatchid and y.Role in ('AP')
		and not exists ( select 1 from DDSU x where x.SecurityGroup = 241 and x.VPUserName = 'MCKINSTRY\'+ y.UserName))

		Insert DDSU
		(SecurityGroup, VPUserName) 
		(select 301,'MCKINSTRY\'+ y.UserName  from MCKVPUserCreation y where y.BatchNum = @Rbatchid and y.Role in ('AP')
		and not exists ( select 1 from DDSU x where x.SecurityGroup = 301 and x.VPUserName = 'MCKINSTRY\'+ y.UserName))

		--AR
		-- Insert DDSU
		--(SecurityGroup, VPUserName) 
		--(select 20,'MCKINSTRY\'+ y.UserName  from MCKVPUserCreation y where y.BatchNum = @Rbatchid and y.Role in ('AR')
		--and not exists ( select 1 from DDSU x where x.SecurityGroup = 20 and x.VPUserName = 'MCKINSTRY\'+ y.UserName))

		 Insert DDSU
		(SecurityGroup, VPUserName) 
		(select 21,'MCKINSTRY\'+ y.UserName  from MCKVPUserCreation y where y.BatchNum = @Rbatchid and y.Role in ('AR')
		and not exists ( select 1 from DDSU x where x.SecurityGroup = 21 and x.VPUserName = 'MCKINSTRY\'+ y.UserName))

		 Insert DDSU
		(SecurityGroup, VPUserName) 
		(select 25,'MCKINSTRY\'+ y.UserName  from MCKVPUserCreation y where y.BatchNum = @Rbatchid and y.Role in ('AR')
		and not exists ( select 1 from DDSU x where x.SecurityGroup = 25 and x.VPUserName = 'MCKINSTRY\'+ y.UserName))

		 Insert DDSU
		(SecurityGroup, VPUserName) 
		(select 28,'MCKINSTRY\'+ y.UserName  from MCKVPUserCreation y where y.BatchNum = @Rbatchid and y.Role in ('AR')
		and not exists ( select 1 from DDSU x where x.SecurityGroup = 28 and x.VPUserName = 'MCKINSTRY\'+ y.UserName))

		Insert DDSU
		(SecurityGroup, VPUserName) 
		(select 30,'MCKINSTRY\'+ y.UserName  from MCKVPUserCreation y where y.BatchNum = @Rbatchid and y.Role in ('AR')
		and not exists ( select 1 from DDSU x where x.SecurityGroup = 30 and x.VPUserName = 'MCKINSTRY\'+ y.UserName))

		--GL
		Insert DDSU
		(SecurityGroup, VPUserName) 
		(select 401,'MCKINSTRY\'+ y.UserName  from MCKVPUserCreation y where y.BatchNum = @Rbatchid and y.Role in ('AR','GL')
		and not exists ( select 1 from DDSU x where x.SecurityGroup = 401 and x.VPUserName = 'MCKINSTRY\'+ y.UserName))

		Insert DDSU
		(SecurityGroup, VPUserName) 
		(select 410,'MCKINSTRY\'+ y.UserName  from MCKVPUserCreation y where y.BatchNum = @Rbatchid and y.Role in ('AR', 'GL', 'PR')
		and not exists ( select 1 from DDSU x where x.SecurityGroup = 410 and x.VPUserName = 'MCKINSTRY\'+ y.UserName))

		Insert DDSU
		(SecurityGroup, VPUserName) 
		(select 403,'MCKINSTRY\'+ y.UserName  from MCKVPUserCreation y where y.BatchNum = @Rbatchid and y.Role in ('GL')
		and not exists ( select 1 from DDSU x where x.SecurityGroup = 403 and x.VPUserName = 'MCKINSTRY\'+ y.UserName))
		
		--PR
		Insert DDSU
		(SecurityGroup, VPUserName) 
		(select 111,'MCKINSTRY\'+ y.UserName  from MCKVPUserCreation y where y.BatchNum = @Rbatchid and y.Role in ('PR')
		and not exists ( select 1 from DDSU x where x.SecurityGroup = 111 and x.VPUserName = 'MCKINSTRY\'+ y.UserName))

		Insert DDSU
		(SecurityGroup, VPUserName) 
		(select 113,'MCKINSTRY\'+ y.UserName  from MCKVPUserCreation y where y.BatchNum = @Rbatchid and y.Role in ('PR')
		and not exists ( select 1 from DDSU x where x.SecurityGroup = 113 and x.VPUserName = 'MCKINSTRY\'+ y.UserName))

		Insert DDSU
		(SecurityGroup, VPUserName) 
		(select 130,'MCKINSTRY\'+ y.UserName  from MCKVPUserCreation y where y.BatchNum = @Rbatchid and y.Role in ('PR')
		and not exists ( select 1 from DDSU x where x.SecurityGroup = 130 and x.VPUserName = 'MCKINSTRY\'+ y.UserName))

		Insert DDSU
		(SecurityGroup, VPUserName) 
		(select 2001,'MCKINSTRY\'+ y.UserName  from MCKVPUserCreation y where y.BatchNum = @Rbatchid and y.Role in ('PR')
		and not exists ( select 1 from DDSU x where x.SecurityGroup = 2001 and x.VPUserName = 'MCKINSTRY\'+ y.UserName))

		-- SM
		Insert DDSU
		(SecurityGroup, VPUserName) 
		(select 204,'MCKINSTRY\'+ y.UserName  from MCKVPUserCreation y where y.BatchNum = @Rbatchid and y.Role in ('SM')
		and not exists ( select 1 from DDSU x where x.SecurityGroup = 204 and x.VPUserName = 'MCKINSTRY\'+ y.UserName))

		Insert DDSU
		(SecurityGroup, VPUserName) 
		(select 271,'MCKINSTRY\'+ y.UserName  from MCKVPUserCreation y where y.BatchNum = @Rbatchid and y.Role in ('SM')
		and not exists ( select 1 from DDSU x where x.SecurityGroup = 271 and x.VPUserName = 'MCKINSTRY\'+ y.UserName))

		Insert DDSU
		(SecurityGroup, VPUserName) 
		(select 272,'MCKINSTRY\'+ y.UserName  from MCKVPUserCreation y where y.BatchNum = @Rbatchid and y.Role in ('SM')
		and not exists ( select 1 from DDSU x where x.SecurityGroup = 272 and x.VPUserName = 'MCKINSTRY\'+ y.UserName))


		--PO

		Insert DDSU
		(SecurityGroup, VPUserName) 
		(select 231,'MCKINSTRY\'+ y.UserName  from MCKVPUserCreation y where y.BatchNum = @Rbatchid and y.Role in ('PO')
		and not exists ( select 1 from DDSU x where x.SecurityGroup = 231 and x.VPUserName = 'MCKINSTRY\'+ y.UserName))


		Insert DDSU
		(SecurityGroup, VPUserName) 
		(select 233,'MCKINSTRY\'+ y.UserName  from MCKVPUserCreation y where y.BatchNum = @Rbatchid and y.Role in ('PO')
		and not exists ( select 1 from DDSU x where x.SecurityGroup = 233 and x.VPUserName = 'MCKINSTRY\'+ y.UserName))

		--VVT
		Insert DDSU
		(SecurityGroup, VPUserName) 
		(select 410,'MCKINSTRY\'+ y.UserName  from MCKVPUserCreation y where y.BatchNum = @Rbatchid and y.Role in ('VVT')
		and not exists ( select 1 from DDSU x where x.SecurityGroup = 410 and x.VPUserName = 'MCKINSTRY\'+ y.UserName))

		Insert DDSU
		(SecurityGroup, VPUserName) 
		(select 701,'MCKINSTRY\'+ y.UserName  from MCKVPUserCreation y where y.BatchNum = @Rbatchid and y.Role in ('VVT')
		and not exists ( select 1 from DDSU x where x.SecurityGroup = 701 and x.VPUserName = 'MCKINSTRY\'+ y.UserName))

		Insert DDSU
		(SecurityGroup, VPUserName) 
		(select 711,'MCKINSTRY\'+ y.UserName  from MCKVPUserCreation y where y.BatchNum = @Rbatchid and y.Role in ('VVT')
		and not exists ( select 1 from DDSU x where x.SecurityGroup = 711 and x.VPUserName = 'MCKINSTRY\'+ y.UserName))

		--HD
		--Insert DDSU
		--(SecurityGroup, VPUserName) 
		--(select 510,'MCKINSTRY\'+ y.UserName  from MCKVPUserCreation y where y.BatchNum = @Rbatchid and y.Role in ('HD')
		--and not exists ( select 1 from DDSU x where x.SecurityGroup = 510 and x.VPUserName = 'MCKINSTRY\'+ y.UserName))

		--INSERT DDSU
		--(SecurityGroup, VPUserName) 
		--(SELECT 1020,'MCKINSTRY\'+ y.UserName  FROM MCKVPUserCreation y WHERE y.BatchNum = @Rbatchid AND y.Role IN ('HD')
		--AND NOT EXISTS ( SELECT 1 FROM DDSU x WHERE x.SecurityGroup = 1020 AND x.VPUserName = 'MCKINSTRY\'+ y.UserName))

		END

		Begin
		Select @Count = Count(*) from  MCKVPUserCreation where BatchNum = @Rbatchid 
		END

--email the results
			DECLARE @tableHTML  NVARCHAR(MAX), @subject NVARCHAR(100)
	DECLARE @msg VARCHAR(2000)

	DECLARE @body1  NVARCHAR(MAX)
	

	
	BEGIN
		
		
		BEGIN
			
			SELECT @subject = N'Viewpoint user creation records' 

			SELECT 
@msg = '<html><head><title>Viewpoint user creation Processing Message</title></head><body>'
+             '<p>Note- If there is no records to be processed, there will not be a list.<br/>'
+             '<br/><br/></p>'
+             '<hr/><br/><font size="-2" color="silver"><i>'  
+             @@SERVERNAME + '.' + DB_NAME() + ' [' + suser_sname() + ' @ ' + CONVERT(VARCHAR(20),GETDATE(),100) + '] '
+             '</i></font><br/><br/></body></html>'  

			SET @tableHTML = 
				N'<H3>' + @subject + N'</H3>' +
				N'<H4>' + @msg + N'</H4>' +
				N'<font size="-2">' +
				N'<table border="1">' +
				N'<tr bgcolor=silver>' +
				N'<th>Co</th>' +
				N'<th>Role</th>' +
				N'<th>User Name</th>' +
				N'<th>Name</th>' +
				N'<th>Email</th>' +
				N'<th>Requested By</th>' +
				 N'</tr>' +
				CAST 
				( 
					( 
						SELECT
							td = COALESCE(@co,' '), '' -- BW changed from a.Co
						,	td = COALESCE(a.Role,' '), ''
						,	td = COALESCE(a.UserName,' '), ''
						,	td = COALESCE(a.Name,' '), ''
						,	td = COALESCE(a.Email,' '), ''
						,	td = COALESCE(a.RequestedBy,' '), ''
						FROM  MCKVPUserCreation a WHERE a.BatchNum = @Rbatchid 
					
						ORDER BY 2	
						FOR XML PATH('tr'), TYPE 
					) AS NVARCHAR(MAX) 
				) + N'</table>' + N'<br/><br/>'

				SELECT @body1 = ISNULL(@tableHTML,@msg)

				EXEC msdb.dbo.sp_send_dbmail 
					@profile_name = 'Viewpoint',
					@recipients =  'ArunT@mckinstry.com;HowardS@mckinstry.com;TheresaP@mckinstry.com'--'VPUserCreation@McKinstry.com'
					,@blind_copy_recipients = 'BenWi@mckinstry.com'
					,@subject = @subject,
					@body = @body1,
					@body_format = 'HTML'
			

		END
		END

END



GO


Grant EXECUTE ON dbo.MCKspVPUserCreationProcess TO [MCKINSTRY\Viewpoint Users]