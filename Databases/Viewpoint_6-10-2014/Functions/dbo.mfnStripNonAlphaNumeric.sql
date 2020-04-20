SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[mfnStripNonAlphaNumeric] ( @stringValue VARCHAR(256) )
RETURNS VARCHAR(256)
	WITH SCHEMABINDING
BEGIN
	IF @stringValue IS NULL
	BEGIN
		RETURN NULL
	END
	
	DECLARE @newStringValue VARCHAR(256)
	DECLARE @place INT
	DECLARE @stringLength INT
	DECLARE @charValue INT
	
	SET @newStringValue = ''
	SET @stringLength = LEN(@stringValue)
	SET @place = 1
	
	WHILE @place <= @stringLength 
		BEGIN
			SET @charValue = ASCII(SUBSTRING(@stringValue, @place, 1))
			
			--Lower case letters range from 97-122 (decimal). 
			--Upper case letters range from 65-90 (decimal)
			--The numbers 0-9 range from 48-57 (decimal). 
			
			IF (@charValue BETWEEN 48 AND 57) OR (@charValue BETWEEN 64 AND 90) OR (@charValue BETWEEN 97 AND 122)
			BEGIN	
				SET @newStringValue = @newStringValue + CHAR(@charValue)
			END
			
			SET @place = @place + 1
		END
	IF LEN(@newStringValue) = 0 
	BEGIN
		RETURN NULL
	END
	
	RETURN @newStringValue
END

GO
