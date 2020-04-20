SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		EN/CS
-- Create date: 12/06/2012
-- Description:	This function takes an input string and returns
--				string after removing non numeric characters
--  
-- =============================================

CREATE Function [dbo].[vfStripNonNumerics] (@InputString varchar(255))

RETURNS varchar(255)

AS
 
BEGIN
  DECLARE @Pos INT
  SET @Pos = PATINDEX('%[^0-9]%', @InputString)
  WHILE @Pos > 0
   BEGIN
    SET @InputString = STUFF(@InputString, @Pos, 1, '')
    SET @Pos = PATINDEX('%[^0-9]%', @InputString)
   END
  RETURN @InputString
END

GO
GRANT EXECUTE ON  [dbo].[vfStripNonNumerics] TO [public]
GO
