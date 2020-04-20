SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		<Jay Riddle>
-- Create date: <03.13.2013>
-- Description:	< This function quotes server names nicely >
-- 
-- =============================================
CREATE FUNCTION [dbo].[vfFormatServerName] (@ServerName VARCHAR(100))

RETURNS VARCHAR(100)

AS
BEGIN

	DECLARE @NewName VARCHAR(100);
	SET @NewName = ISNULL(@ServerName,'');

		IF @NewName <> '' AND LEFT(@NewName,1) <> '['
		BEGIN
			SET @NewName = QUOTENAME(@NewName);
		END
	
		IF @NewName <> '' AND RIGHT(@NewName,1) <> '.'
		BEGIN
			SET @NewName = @NewName + '.';
		END

	RETURN @NewName
END

GO
GRANT EXECUTE ON  [dbo].[vfFormatServerName] TO [public]
GO
