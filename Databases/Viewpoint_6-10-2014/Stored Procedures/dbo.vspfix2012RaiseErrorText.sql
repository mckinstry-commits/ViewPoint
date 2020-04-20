SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspfix2012RaiseErrorText]
(
	@in VARCHAR(MAX)
	,@out VARCHAR(MAX) OUTPUT
)
AS
BEGIN
	/*
	Author:		JayR
	Create date: 5/11/2012
	Description:	This is a helper function that takes SQL that has invalid Raiserror functionality and returns it fixed.
	Note:  We _assume_ someone isn't evil enought to spread the raiserror over multiple lines.
	
	Testing:
	DECLARE @out VARCHAR(max)
	DECLARE @in VARCHAR(MAX)
	SET @in = '  raiserror 1234 ''this is some stuff''  ' + CHAR(10)
	BEGIN TRY
	exec vspfix2012RaiseErrorText @in, @out OUT
	select @out
	END TRY
	BEGIN CATCH
		PRINT ERROR_MESSAGE()
	END CATCH
	*/

	DECLARE @start_error AS INTEGER
	DECLARE @end_error AS INTEGER
	DECLARE @ll AS VARCHAR(MAX)
	DECLARE @rest AS VARCHAR(MAX)
	DECLARE @rR AS VARCHAR(MAX)
	DECLARE @BIGNUM AS BIGINT
	DECLARE @needle AS VARCHAR(2000)
	DECLARE @loopCount AS INTEGER
	DECLARE @maxLoop AS INTEGER
	DECLARE @newRaiseError AS VARCHAR(2000)
	
	SET @loopCount = 0
	SET @BIGNUM = 99999999 --Used by substring to get all of the end of a string
	SET @maxLoop = 1000
	SET @rR = @in
		
	SET @ll = LOWER(@rR)
	
	-- A regular expression would be very very nice here.  I want \w
	SET @start_error = PATINDEX('%raiserror [0-9]%',@ll)
	IF(@start_error = 0)
		SET @start_error = PATINDEX('%raiserror  [0-9]%',@ll)
	IF(@start_error = 0)
		SET @start_error = PATINDEX('%raiserror   [0-9]%',@ll)	
	IF(@start_error = 0)
		SET @start_error = PATINDEX('%raiserror' + CHAR(9) + '[0-9]%',@ll)
	IF(@start_error = 0)
		SET @start_error = PATINDEX('%raiserror ' + CHAR(9) + '[0-9]%',@ll)
	IF(@start_error = 0)
		SET @start_error = PATINDEX('%raiserror' + CHAR(9) + ' [0-9]%',@ll)
	
	IF(@start_error = 0)
		RAISERROR('Could not find any invalid raiserrors to fix',11,-1)
		
	WHILE(@start_error > 0)
	BEGIN
		SET @loopCount = @loopCount + 1
		
		IF(@loopCount > @maxLoop)
			RAISERROR('We are either looping forever or the code has way too many raiserrors',11,-1)
			
		SET @rest = SUBSTRING(@rR,@start_error,@BIGNUM)	
		IF(@rest IS NULL OR LEN(@rest) < 12)
			RAISERROR('The rest of the string is too short or null. We are lost',11,-1)
	
		SELECT @end_error = MIN(col) 
		FROM 
			(
			SELECT CHARINDEX(CHAR(10),@rest) - 1 AS col 
			UNION 
			SELECT CHARINDEX(CHAR(13),@rest) - 1 AS col 
			UNION
			SELECT LEN(@rest) AS col
			) xx
		WHERE xx.col > 0
			
		IF(@end_error IS NULL)
			RAISERROR('Variable @end_error is null.  Could not find end of raiserror expression',11,-1)
			
		IF(@end_error < 12)
			RAISERROR('Variable @end_error is too short.  Could not find end of raiserror expression',11,-1)
	
		--PRINT 'Start needle'
		SET @needle = SUBSTRING(@rR,@start_error,@end_error) 	
		--PRINT 'Needle:' + @needle
		
		IF(LEN(@needle) <= 11) 
				RAISERROR('Searching for "Raiserror" to replace yet we found something invalid',11,-1)
	
		--Remove the raiserror from the string.
		SET @rest = LTRIM(SUBSTRING(@needle,10,@BIGNUM)) 
		SET @rest = REPLACE(@rest,CHAR(9),' ') --Repalce tab character
		SET @rest = LTRIM(@rest)
		
		--Remove the number from the string
		WHILE (PATINDEX('[0-9]%',@rest) = 1)
			SET @rest = SUBSTRING(@rest,2,@BIGNUM)
			
		SET @rest = RTRIM(LTRIM(@rest))
		--Remove a trailing ;
		IF(RIGHT(@rest,1) = ';')
			SET @rest = LEFT(@rest,LEN(@rest) - 1)
	
		--PRINT 'We have a rest of:' + @rest
		IF(LEN(@rest) < 2) 
			RAISERROR('When trying to rebuild the raiserror syntax a calculation was incorrect',11,-1)
		
		--PRINT 'Starting construction of newRaiseError:' + @rest	
		SET @newRaiseError = 'RAISERROR(' + @rest + ',11,-1) '
		--PRINT 'Building the new definition'
		SET @rR = REPLACE(@rR,@needle,@newRaiseError)
		
		SET @ll = LOWER(@rR)
	
		-- A regular expression would be very very nice here.  I want \w
		SET @start_error = PATINDEX('%raiserror [0-9]%',@ll)
		IF(@start_error = 0)
			SET @start_error = PATINDEX('%raiserror  [0-9]%',@ll)
		IF(@start_error = 0)
			SET @start_error = PATINDEX('%raiserror   [0-9]%',@ll)	
		IF(@start_error = 0)
			SET @start_error = PATINDEX('%raiserror' + CHAR(9) + '[0-9]%',@ll)
		IF(@start_error = 0)
			SET @start_error = PATINDEX('%raiserror ' + CHAR(9) + '[0-9]%',@ll)
		IF(@start_error = 0)
			SET @start_error = PATINDEX('%raiserror' + CHAR(9) + ' [0-9]%',@ll)
		--PRINT 'We are at the end of the loop with a start_error values of:' + CAST(@start_error AS VARCHAR(10))
	END
	
	--PRINT 'Returning:' + @rR
	SET @out = @rR
END
GO
GRANT EXECUTE ON  [dbo].[vspfix2012RaiseErrorText] TO [public]
GO
