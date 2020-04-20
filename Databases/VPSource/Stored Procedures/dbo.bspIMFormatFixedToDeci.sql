SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[bspIMFormatFixedToDeci]
	/************************************************************************
	* CREATED:  MH    
	* MODIFIED: CC - 3/19/2008  Issue #122980 - Add large field support.
				CC - 02/03/2009 Issue #130094 - Removed unnecessary conversions to varchar(max), and unnecessary select statements
	*
	* Purpose of Stored Procedure
	*
	* Take a number and insert a decimal at the postion indicated by the decipos 
	* parameter    
	*    
	* Notes about Stored Procedure
	*
	* returns 0 if successfull 
	* returns 1 and error msg if failed
	*
	*************************************************************************/
   
   (@inputvalue VARCHAR(MAX), @decipos int, @formattedval VARCHAR(MAX) OUTPUT, @msg VARCHAR(80) = '' OUTPUT)
   AS
   BEGIN
		SET NOCOUNT ON
	   
		DECLARE	 @rcode int
	   
		SELECT @rcode = 0

		IF @inputvalue IS NULL
		   BEGIN
			   SELECT @msg = 'Missing Input Value!', @rcode = 1
			   GOTO bspexit
		   END

		IF @decipos IS NULL
		   SET @decipos = 0

		IF LEN(@inputvalue) < @decipos
			BEGIN
				SET @formattedval = @inputvalue
				GOTO bspexit
			END
		  
		SET @formattedval = (SUBSTRING(@inputvalue, 1, LEN(@inputvalue) - @decipos)) + '.' + RIGHT(@inputvalue, @decipos)
		  
		bspexit:
		RETURN @rcode
	END


GO
GRANT EXECUTE ON  [dbo].[bspIMFormatFixedToDeci] TO [public]
GO
