SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		AW
-- Create date: 09/27/2013
-- Description:	This function takes an input string and returns
--				string after removing non alpha-numeric characters
--  
-- =============================================

CREATE Function [dbo].[vfStripNonAlphaNumerics] (@InputString varchar(255))

RETURNS varchar(255)

AS
 
BEGIN
  DECLARE @Pos INT
  SET @Pos = PATINDEX('%[^0-9A-Za-z]%', @InputString)
  WHILE @Pos > 0
   BEGIN
    SET @InputString = STUFF(@InputString, @Pos, 1, '')
    SET @Pos = PATINDEX('%[^0-9A-Za-z]%', @InputString)
   END
  RETURN @InputString
END

GO
GRANT EXECUTE ON  [dbo].[vfStripNonAlphaNumerics] TO [public]
GO
