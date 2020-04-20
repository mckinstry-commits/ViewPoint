SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- =============================================
-- Author:		AL, dbo.vfTAbleFromArray
-- Modified: CC - 2/25/2008 -- changed casts to varchar(max) to overcome implicit cast limitation of 30 characters
-- Modified: JD - 10/06/2009 -- allowed bracked names containing commas in the input list: "[name, with a comma],name without comma,[other name]"
--                              NOTE: brackets are stripped from output array
-- Create date: 6/1/2007
-- Description:	Turns a list of comma delineated values into a table
-- =============================================

CREATE FUNCTION [dbo].[vfTableFromArray] 
(	
	-- Add the parameters for the function here
	@Array AS VARCHAR(MAX)
)
RETURNS @TempList TABLE (
		Names VARCHAR(150)
	)
AS
BEGIN

	Declare @Value as VARCHAR(100), @Comma AS INT, @Bracket AS INT;


	WHILE @Array <>''
	BEGIN
		-- find next delimited entry & copy it to @Value
		SET @Bracket = CharIndex('[',@Array);
		IF @Bracket = 1
			BEGIN	-- if a bracketed item is next, use closing bracket to find end of item
				-- remove opening bracket and find closing bracket 
				SET @Array = Right(@Array, Len(@Array) - 1);
				SET @Bracket = CharIndex(']',@Array);
				IF @Bracket = 0 -- no closing bracket, take everything to the end of @Array
					BEGIN
						SET @Value = Cast(@Array AS varchar(max));
						SET @Comma = 0;
					END
				ELSE
					BEGIN
						-- set value to chars before closing bracket
						SET @Value = Cast(Left(@Array, @Bracket -1) AS varchar(max));
						
						-- use comma to find start of next item, if any
						SET @Comma = CharIndex(',', @Array, @Bracket);
					END
			END
		ELSE
			BEGIN	-- next item is not bracketed, use comma to find end of item
				SET @Comma = CharIndex(',', @Array);
				IF @Comma > 0
					--If found, parse out the first value…
					SET @Value = Cast(Left(@Array, @Comma -1) AS varchar(max));
				ELSE
					--At the end of the string, so get last value...
					SET @Value = Cast(@Array AS varchar(max));
			END
		
		
		-- Remove used part of @Array (through @Comma)
		IF @Comma > 0
			-- remove it from the array
			SET @Array = Right(@Array, Len(@Array) - @Comma);
		ELSE
			-- done! no more commas remain
			SET @Array='';
				
		-- Move @Value into array
		INSERT INTO @TempList (Names)  VALUES (@Value); --Use Appropriate conversion
	END  --WHILE @Array <> ''
	RETURN
END

GO
GRANT SELECT ON  [dbo].[vfTableFromArray] TO [public]
GO
