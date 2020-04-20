SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		AL, dbo.vfTAbleFromArray
-- Create date: 6/1/2007
-- Description:	Turns a list of comma delineated values into a table
-- =============================================

CREATE FUNCTION [dbo].[vfCoTableFromArray] 
(	
	-- Add the parameters for the function here
	@Array AS VARCHAR(8000)
)
RETURNS @TempList TABLE (
		Company SMALLINT 
	)
AS
BEGIN

Declare @Co as SMALLINT, @Value as VARCHAR(100),@Comma AS CHAR(2)


	

WHILE @Array <>''
BEGIN
SET @Comma = CharIndex(',', @Array)
    IF @Comma > 0
        BEGIN
        --If found, parse out the first value…
            SET @Value = Cast(Left(@Array, @Comma -1) AS SMALLINT)
        --..and remove it from the array
            SET @Array = Right(@Array, Len(@Array) - @Comma)
        END
    ELSE
        BEGIN
        --At the end of the string, so get last value...
            SET @Value = Cast(@Array AS SMALLINT)
        --...and set @Array to an empty string.
            SET @Array=''
        END
--Do what you want with the value here
	BEGIN
		INSERT INTO @TempList (Company)  VALUES (@Value) --Use Appropriate conversion
	END
END
 --WHILE @Array <> ''
RETURN

End

GO
GRANT SELECT ON  [dbo].[vfCoTableFromArray] TO [public]
GO
