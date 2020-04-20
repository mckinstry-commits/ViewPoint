SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[vfTriggerDetailsTableFromArray] 
/***********************************************************    
* CREATED : Narendra 29-11-2012  
*      
* Usage:    
*     Used by Company copy wizard to turn a list of comma delimited values into a table.
*	  Returns a table of Trigger details having Trigger Name and Corresponding Table Name.
* 
* Input params:    
* @tablesToCheck - comma delimited list of trigger names and table names separated by colon 
*				   e.g   btPMFMd:bPMFM,btAPCOi:bAPCO
*****************************************************/    
(	
	@Array AS varchar(MAX)
)
RETURNS @TempList table (
		TriggerNames varchar(150),
		TableNames varchar(150)
	)
AS
BEGIN

DECLARE @Value AS varchar(100), @Comma AS int, @Bracket AS int;
DECLARE @TriggerValue AS varchar(100), @TableValue AS varchar(100)

	WHILE @Array <>''
	BEGIN
		-- find next delimited entry & copy it to @Value
		SET @Bracket = CHARINDEX('[',@Array);
		IF @Bracket = 1
			BEGIN	-- if a bracketed item is next, use closing bracket to find end of item
				-- remove opening bracket and find closing bracket 
				SET @Array = Right(@Array, LEN(@Array) - 1);
				SET @Bracket = CHARINDEX(']',@Array);
				IF @Bracket = 0 -- no closing bracket, take everything to the end of @Array
					BEGIN
						SET @Value = CAST(@Array AS varchar(max));
						SET @Comma = 0;
					END
				ELSE
					BEGIN
						-- set value to chars before closing bracket
						SET @Value = CAST(Left(@Array, @Bracket -1) AS varchar(max));
						
						-- use comma to find start of next item, if any
						SET @Comma = CHARINDEX(',', @Array, @Bracket);
					END
			END
		ELSE
			BEGIN	-- next item is not bracketed, use comma to find end of item
				SET @Comma = CHARINDEX(',', @Array);
				IF @Comma > 0
				 BEGIN
					--If found, parse out the first value...
					SET @Value = CAST(Left(@Array, @Comma -1) AS varchar(max));
					SET @TriggerValue=CAST(Left(@Value, CHARINDEX(':', @Array) -1) AS varchar(max));
					SET @TableValue=CAST(Right(@Value, LEN(@Value) - CHARINDEX(':', @Value)) AS varchar(max));
				 END
				ELSE
				 BEGIN
					--At the end of the string, so get last value...
					SET @Value = CAST(@Array AS varchar(max));
					SET @TriggerValue=CAST(Left(@Value, CHARINDEX(':', @Array) -1) AS varchar(max));
					SET @TableValue=CAST(Right(@Value, LEN(@Value) - CHARINDEX(':', @Value)) AS varchar(max));
				 END	
			END
		
		
		-- Remove used part of @Array (through @Comma)
		IF @Comma > 0
			-- remove it from the array
			SET @Array = Right(@Array, LEN(@Array) - @Comma);
		ELSE
			-- done! no more comma remain
			SET @Array='';
				
		-- Move @Value into array
		INSERT INTO @TempList (TriggerNames,TableNames)  VALUES (@TriggerValue,@TableValue); --Use Appropriate conversion
	END  --WHILE @Array <> ''
	
	RETURN
END

GO
GRANT SELECT ON  [dbo].[vfTriggerDetailsTableFromArray] TO [public]
GO
