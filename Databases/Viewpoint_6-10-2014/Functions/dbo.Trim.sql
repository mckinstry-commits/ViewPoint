SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/************************************************************************
* CREATED:	 
* MODIFIED:	AR 12/20/2010 - fixing the nvarchar so it is a MAX instead of no length
*
* Purpose:

* returns 1 and error msg if failed
*
*************************************************************************/
CREATE FUNCTION [dbo].[Trim] ( @string nvarchar(max) )
RETURNS nvarchar(max)
AS 
BEGIN 
    SELECT  @string = LTRIM(RTRIM(@string))
    RETURN @string
  
  
END

GO
