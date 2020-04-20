SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspIMFormatDate]
/***********************************************************
* CREATED BY:   CC 08/07/2008
* MODIFIED BY:  CC 09/22/2008 - Issue #129864 Handle cases where Month and Year are passed in with or without a date seperator.
*              AJW 06/10/2010 - Issue #140070 Handle DDMMYYYY & DDMMYY format
*				GF 10/04/2010 - issue #141031 added code to strip time off temporary date
*
* Usage: Used by Imports to format a date from a specified format to specified format
*	
*
* Input params:
*	@DateValue
*	@SourceFormat
*	@DateSeperator
*	@DestinationFormat
*	@ConvertToMonthFormat
*
* Output params:
*	@ReturnDate
*
* Return code:
*
*	
************************************************************/
@DateValue VARCHAR(30) = NULL,
@SourceFormat VARCHAR(10) = NULL,
@DateSeperator VARCHAR(2) = '/',
@DestinationFormat VARCHAR(10) = NULL,
@ConvertToMonthFormat bYN = 'N',
@ReturnDate VARCHAR(30) OUTPUT

AS

SET NOCOUNT ON

SET @SourceFormat = UPPER(@SourceFormat)

DECLARE @ShortFormat VARCHAR(10)
SELECT @ShortFormat = @SourceFormat 

SET @ShortFormat = REPLACE(@ShortFormat, 'MM', 'M')
SET @ShortFormat = REPLACE(@ShortFormat, '01', 'D')
SET @ShortFormat = REPLACE(@ShortFormat, '1', 'D')
SET @ShortFormat = REPLACE(@ShortFormat, 'DD', 'D')
SET @ShortFormat = REPLACE(@ShortFormat, 'YYYY', 'Y')
SET @ShortFormat = REPLACE(@ShortFormat, 'YYY', 'Y')
SET @ShortFormat = REPLACE(@ShortFormat, 'YY', 'Y')
SET @ShortFormat = REPLACE(@ShortFormat, @DateSeperator, '')

SET @DateSeperator = '/'

--check for date value with no date seperator
IF CHARINDEX(@DateSeperator, @DateValue) = 0
	BEGIN
	    --issue 140070 support DDMMYYYY format
       if LEN(@DateValue) = 8 
         	BEGIN
				SELECT @DateValue = 
					CASE @ShortFormat 
						WHEN 'MDY' THEN LEFT(@DateValue,2) + @DateSeperator + RIGHT(LEFT(@DateValue,4),2) + @DateSeperator + RIGHT(@DateValue,4)
						WHEN 'DMY' THEN LEFT(@DateValue,2) + @DateSeperator + RIGHT(LEFT(@DateValue,4),2) + @DateSeperator + RIGHT(@DateValue,4)
						WHEN 'YMD' THEN LEFT(@DateValue,4) + @DateSeperator + LEFT(RIGHT(@DateValue,4),2) + @DateSeperator + RIGHT(@DateValue,2) 
						WHEN 'YDM' THEN LEFT(@DateValue,4) + @DateSeperator + LEFT(RIGHT(@DateValue,4),2) + @DateSeperator + RIGHT(@DateValue,2)
						WHEN 'MYD' THEN LEFT(@DateValue,2) + @DateSeperator + LEFT(RIGHT(@DateValue,6),4) + @DateSeperator + RIGHT(@DateValue,2)
						WHEN 'DYM' THEN LEFT(@DateValue,2) + @DateSeperator + RIGHT(LEFT(@DateValue,6),4) + @DateSeperator + RIGHT(@DateValue,2)
					END
			END
			
		IF LEN(@DateValue) = 4
			BEGIN
				SELECT @DateValue = 
					CASE @ShortFormat 
						WHEN 'MDY' THEN LEFT(@DateValue,2) + @DateSeperator + '01' + @DateSeperator + RIGHT(@DateValue,2)
						WHEN 'DMY' THEN '01' + @DateSeperator + LEFT(@DateValue,2) + @DateSeperator + RIGHT(@DateValue,2)
						WHEN 'YMD' THEN LEFT(@DateValue,2) + @DateSeperator + RIGHT(@DateValue,2) + @DateSeperator + '01' 
						WHEN 'YDM' THEN LEFT(@DateValue,2) + @DateSeperator + '01' + @DateSeperator + RIGHT(@DateValue,2)
						WHEN 'MYD' THEN LEFT(@DateValue,2) + @DateSeperator + RIGHT(@DateValue,2) + @DateSeperator + '01' 
						WHEN 'DYM' THEN '01' + @DateSeperator + LEFT(@DateValue,2) + @DateSeperator + RIGHT(@DateValue,2)
					END
			END
		IF LEN(@DateValue) = 5
			BEGIN
				SELECT @DateValue = 
					CASE @ShortFormat 
						WHEN 'MDY' THEN LEFT(@DateValue,1) + @DateSeperator + '01' + @DateSeperator + RIGHT(@DateValue,4)
						WHEN 'DMY' THEN '01' + @DateSeperator + LEFT(@DateValue,1) + @DateSeperator + RIGHT(@DateValue,4)
						WHEN 'YMD' THEN LEFT(@DateValue,4) + @DateSeperator + RIGHT(@DateValue,1) + @DateSeperator + '01' 
						WHEN 'YDM' THEN LEFT(@DateValue,4) + @DateSeperator + '01' + @DateSeperator + RIGHT(@DateValue,1)
						WHEN 'MYD' THEN LEFT(@DateValue,1) + @DateSeperator + RIGHT(@DateValue,4) + @DateSeperator + '01' 
						WHEN 'DYM' THEN '01' + @DateSeperator + LEFT(@DateValue,4) + @DateSeperator + RIGHT(@DateValue,1)
					END
			END
		--issue 140070 differ from MMYYYY from DDMMYY formats
		IF LEN(@DateValue) = 6 and charindex('D',@SourceFormat)=0
			BEGIN
				SELECT @DateValue = 
					CASE @ShortFormat 
						WHEN 'MDY' THEN LEFT(@DateValue,2) + @DateSeperator + '01' + @DateSeperator + RIGHT(@DateValue,4)
						WHEN 'DMY' THEN '01' + @DateSeperator + LEFT(@DateValue,2) + @DateSeperator + RIGHT(@DateValue,4)
						WHEN 'YMD' THEN LEFT(@DateValue,4) + @DateSeperator + RIGHT(@DateValue,2) + @DateSeperator + '01' 
						WHEN 'YDM' THEN LEFT(@DateValue,4) + @DateSeperator + '01' + @DateSeperator + RIGHT(@DateValue,2)
						WHEN 'MYD' THEN LEFT(@DateValue,2) + @DateSeperator + RIGHT(@DateValue,4) + @DateSeperator + '01' 
						WHEN 'DYM' THEN '01' + @DateSeperator + LEFT(@DateValue,4) + @DateSeperator + RIGHT(@DateValue,2)
					END
			END
		--issue 140070 DDMMYY
		IF LEN(@DateValue) = 6 and charindex('D',@SourceFormat)<>0
			BEGIN
			    --all formats are the same
				SELECT @DateValue = LEFT(@DateValue,2) + @DateSeperator + RIGHT(LEFT(@DateValue,4),2) + @DateSeperator + RIGHT(@DateValue,2)
			END
	END
	

--Check for values with only 1 date seperator
IF CHARINDEX(@DateSeperator, @DateValue, CHARINDEX(@DateSeperator, @DateValue) + 1) = 0
	BEGIN
		SELECT @DateValue = 
			CASE @ShortFormat 
				WHEN 'MDY' THEN REPLACE(@DateValue, @DateSeperator, @DateSeperator + '01' + @DateSeperator)
				WHEN 'DMY' THEN '01' + @DateSeperator + @DateValue
				WHEN 'YMD' THEN @DateValue + @DateSeperator + '01' 
				WHEN 'YDM' THEN REPLACE(@DateValue, @DateSeperator, @DateSeperator + '01' + @DateSeperator)
				WHEN 'MYD' THEN @DateValue + @DateSeperator + '01' 
				WHEN 'DYM' THEN '01' + @DateSeperator + @DateValue
			END
	END
	


SET DATEFORMAT @ShortFormat;

DECLARE @TemporaryDate DATETIME


SET @TemporaryDate = CAST(@DateValue AS DATETIME)

----#141031
SET @TemporaryDate = DATEADD(d, DATEDIFF(d,0, @TemporaryDate), 0)

SET DATEFORMAT 'mdy';

DECLARE @TextReturnDate VARCHAR(30)
SET @TextReturnDate = CONVERT(VARCHAR(30), @TemporaryDate, 1)

IF @ConvertToMonthFormat = 'Y'
	BEGIN
		SET @TextReturnDate = LEFT(@TextReturnDate, 2) + @DateSeperator + '01' + @DateSeperator + RIGHT(@TextReturnDate, 2)
		SET @TemporaryDate = CAST(@TextReturnDate AS DATETIME)
	END

SET @DestinationFormat = UPPER(@DestinationFormat)

SELECT @ShortFormat = @DestinationFormat

SET @ShortFormat = REPLACE(@ShortFormat, 'MM', 'M')
SET @ShortFormat = REPLACE(@ShortFormat, 'DD', 'D')
SET @ShortFormat = REPLACE(@ShortFormat, 'YYYY', 'Y')
SET @ShortFormat = REPLACE(@ShortFormat, @DateSeperator, '')

SELECT @TextReturnDate =
	CASE @ShortFormat 
		WHEN 'MDY' THEN CONVERT(VARCHAR(30), @TemporaryDate, 1)
		WHEN 'DMY' THEN CONVERT(VARCHAR(30), @TemporaryDate, 3)
		WHEN 'YMD' THEN CONVERT(VARCHAR(30), @TemporaryDate, 11)
		WHEN 'YDM' THEN RIGHT(@TextReturnDate, 2) + @DateSeperator + SUBSTRING(@TextReturnDate, 3, 2) + @DateSeperator +  LEFT(@TextReturnDate, 2) 
		WHEN 'MYD' THEN LEFT(@TextReturnDate, 2) + @DateSeperator + RIGHT(@TextReturnDate, 4) + @DateSeperator + SUBSTRING(@TextReturnDate, 3, 2)  
		WHEN 'DYM' THEN SUBSTRING(@TextReturnDate, 3, 2) + @DateSeperator + RIGHT(@TextReturnDate, 2) + @DateSeperator +  LEFT(@TextReturnDate, 2)
	END

SET @ReturnDate = @TextReturnDate



GO
GRANT EXECUTE ON  [dbo].[vspIMFormatDate] TO [public]
GO
