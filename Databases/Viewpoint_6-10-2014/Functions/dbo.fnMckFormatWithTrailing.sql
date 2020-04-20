SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[fnMckFormatWithTrailing]
(
      @sourceString varchar(100)
,     @padChar          CHAR(1)
,     @len              int   
)
RETURNS varchar(100)
AS
BEGIN

DECLARE @ret VARCHAR(100)
SELECT @ret=@sourceString + REPLICATE(@padChar,@len-LEN(@sourceString)) 

RETURN @ret
END
      
GO
