SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [dbo].[vspUDVersionUpdate] 
/************************************************
* Created: Chris G 08/10/12
* 
* Modified: 
* 
* Updates the version of a UD Table or Standard View with UD fields. 
************************************************/
   (@tablename varchar(128)) AS
   
	IF @tablename IS Not NULL
	BEGIN
		IF NOT EXISTS(SELECT 1 FROM UDVersion WHERE TableName = @tablename)
			BEGIN
				INSERT INTO UDVersion (TableName, [Version]) VALUES (@tablename, 1)
			END				
		ELSE
			BEGIN
				UPDATE UDVersion SET [Version] = [Version] + 1 WHERE TableName = @tablename
			END	
	END


GO
GRANT EXECUTE ON  [dbo].[vspUDVersionUpdate] TO [public]
GO
