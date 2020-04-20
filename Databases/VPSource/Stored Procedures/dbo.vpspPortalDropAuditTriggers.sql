SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE  PROCEDURE [dbo].[vpspPortalDropAuditTriggers]

AS
   
DECLARE @name varchar(1000), @opencursor tinyint, @id int

SET NOCOUNT ON

SELECT 'Removing Audit trigger for all the Portal Tables (startig with "p") in ' + DB_NAME()

--Create cursor to loop through all Viewpoint Portal Tables
DECLARE PortalTableName CURSOR FOR
	SELECT id, name
	FROM sysobjects WHERE type = 'U' AND user_name(uid)= 'dbo' AND name LIKE 'p%'
	ORDER BY name

	--Open the table name cursor
	OPEN PortalTableName
	SELECT @opencursor = 1

--Loop through all tables in cursor
vpspLoop:
	FETCH NEXT FROM PortalTableName INTO @id, @name

	IF @@fetch_status <> 0 GOTO vpspEnd

	EXEC vpspPortalDropAuditTrigger @name
	
	SELECT 'Remove Audit Trigger for ' + @name

	GOTO vpspLoop

vpspEnd:   --Finished with the Portal Tables
   SELECT 'Audit Triggers removed.'
   CLOSE PortalTableName
   DEALLOCATE PortalTableName
   SELECT @opencursor = 0

vpspEXIT:
   IF @opencursor = 1
       BEGIN
       CLOSE PortalTableName
       DEALLOCATE PortalTableName
       END


RETURN




GO
GRANT EXECUTE ON  [dbo].[vpspPortalDropAuditTriggers] TO [VCSPortal]
GO
