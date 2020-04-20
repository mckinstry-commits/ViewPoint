SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  Proc [dbo].[vspDMCreateLinkedServer]
/*
	Created by: Aaron Lang and Jonathan Paullin 02/04/2010
	
	Description: This script will add a linked server to the database it is being run from.
*/
(@linkedserver NVARCHAR(128), @returnmessage varchar(512) = '' output)
as

--Check if linked server exists
DECLARE @statusval INT, @viewpointdatabase VARCHAR(30), @returncode int;
SELECT @viewpointdatabase = DB_NAME(), @returncode = 0 

IF @linkedserver != @viewpointdatabase and NOT EXISTS(SELECT * FROM sys.servers WHERE name = @linkedserver)
BEGIN
	-- Add the linked server if it does not exist
	EXEC master.dbo.sp_addlinkedserver @server = @linkedserver, @srvproduct=N'SQL Server'

	-- Make sure the add worked 
	BEGIN TRY
		EXEC @statusval = sp_testlinkedserver @linkedserver;
	END TRY
	BEGIN CATCH
		SET @statusval = SIGN(@@ERROR);
	END CATCH;

	IF @statusval <> 0
	BEGIN
		SELECT @returnmessage = 'Unable to connect to linked server.', @returncode = 1; 
		goto vspExit
	END

	-- Make Viewpoint trustworthy	
	exec('ALTER DATABASE ' + @viewpointdatabase + ' SET TRUSTWORTHY ON')

	-- Setup the linked server to be self mapping
	EXEC sp_addlinkedsrvlogin @linkedserver, 'true'

	-- Ensure that self mapping is running (returns a 1 for success)
	DECLARE @selfmapping int
	SELECT @selfmapping = L.uses_self_credential
						  from sys.linked_logins as L
						  join sys.servers as S on L.server_id = S.server_id and S.name = @linkedserver	
								
	IF @selfmapping != 1	
	BEGIN
		SELECT @returnmessage = 'Self mapping is not running.', @returncode = 1; 
		goto vspExit
	END
		
END     

vspExit:
	return @returncode


GO
GRANT EXECUTE ON  [dbo].[vspDMCreateLinkedServer] TO [public]
GO
