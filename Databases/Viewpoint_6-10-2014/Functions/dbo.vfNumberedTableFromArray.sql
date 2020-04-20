SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- =============================================
-- Author:		AL, dbo.vfTAbleFromArray
-- Modified:	CC - 2/25/2008 -- changed casts to varchar(max) to overcome implicit cast limitation of 30 characters
--				CC - 5/8/2009  -- created new function to include position number to match with other lists (note: one based)
-- Create date: 5/8/2009 
-- Description:	Turns a list of comma delimited values into a table
-- =============================================

CREATE FUNCTION [dbo].[vfNumberedTableFromArray] 
(	
	@Array AS VARCHAR(MAX)
)
RETURNS @TempList TABLE (
		Names VARCHAR(150),
		ItemNumber int
	)
AS
BEGIN

	DECLARE	  @Co AS SMALLINT
			, @Value AS VARCHAR(150)
			, @Comma AS CHAR(2)
			, @Counter AS int

	SET @Counter = 1

	WHILE @Array <>''
	BEGIN
		SET @Comma = CharIndex(',', @Array)
		IF @Comma > 0
			BEGIN
			--If found, parse out the first value…
				SET @Value = CAST(LEFT(@Array, @Comma -1) AS VARCHAR(MAX));
			--..and remove it from the array
				SET @Array = RIGHT(@Array, LEN(@Array) - @Comma);
			END
		ELSE
			BEGIN
			--At the end of the string, so get last value...
				SET @Value = CAST(@Array AS VARCHAR(MAX));
			--...and set @Array to an empty string.
				SET @Array='';
			END
		BEGIN
			INSERT INTO @TempList (Names, ItemNumber)  VALUES (@Value, @Counter);
			SELECT @Counter = @Counter + 1;
		END
	END
	 
	RETURN

END

GO
GRANT SELECT ON  [dbo].[vfNumberedTableFromArray] TO [public]
GO
