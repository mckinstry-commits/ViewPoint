SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/**********************************************/
CREATE proc [dbo].[vspHQGetRFMetaValueClause]
/*************************************
* Created By:   Gartht 04/5/2011 - TK-03252
* Modified By:
*
*
*
* Creates Metedata Value Header string for automated response fields.
*
*
* Pass:
*	TemplateName
*	Header String
*	Column String
*
* Success returns:
*	0 and HeaderString
*
* Error returns:
*	1 and error message
**************************************/
(@templatename varchar(40), @columnstring varchar(8000) output, @msg varchar(255) OUTPUT)
AS
SET NOCOUNT ON
  
DECLARE @rcode INT,
	    @delimeter varchar(3),
		@start int, @end int,
		@equalPos int, @spacePos int,
		@col varchar(50),
		@join varchar(255),	
		@alias varchar(2)
			
SELECT @rcode = 0

SELECT @columnstring = ''

IF @templatename IS NULL
BEGIN
	SELECT @msg = 'Missing Template Name', @rcode = 1
	GOTO vspexit
END
	
IF NOT EXISTS (SELECT TOP 1 1 FROM HQWD WHERE TemplateName = @templatename and AutoResponse = 'Y')
BEGIN
	GOTO vspexit
END	

  DECLARE @DocObjects TABLE 
		(  
		   TemplateName varchar(40),
		   DocObject varchar(30), 
	       ObjectTable varchar(30), 
		   Alias varchar(2), 
		   JoinClause varchar(255), 
		   JoinOrder int
		)
	
  INSERT INTO @DocObjects 
  exec dbo.vspHQGetResponseWOCatalog @templatename, @msg output
   
  WHILE (SELECT Count(*) from @DocObjects) > 0
  BEGIN
					
		SELECT TOP 1 @join=o.JoinClause, @alias=o.Alias 
		FROM @DocObjects o ORDER BY JoinOrder
		
		WHILE(LEN(@join) > 0)
		BEGIN
			
			SET @delimeter = @alias + '.'

			SET @start = PATINDEX('%' + @delimeter + '%', @join)		
			IF (@start > 0)
			BEGIN
				
				-- Parse pattern for space and equal sign
				SET @spacePos = CHARINDEX(' ', @join, @start)
				SET @equalPos = CHARINDEX('=', @join, @start)
				
				-- If no space found, set position to end of string
				If(@spacePos = 0)
					set @spacePos = LEN(@join) + 1
					
				-- If equals found before space then set end position to equal index
				if  @equalPos < @spacePos AND @equalPos != 0
					set @end = @equalPos
				-- Otherwise set to space position
				else
					set @end = @spacePos
					
				-- Grab column name for meta information
				SET @col = SUBSTRING(@join, @start, @end - @start)
				
				-- Build column meta value select string		 
				SET @columnstring = @columnstring + ', ' + @col + ' as meta_' + Replace(@col,'.','_')
				
				-- Consume the processed join string
				SET @join = SUBSTRING(@join, @end, LEN(@join) - @end + 1)
			END
			ELSE
			BEGIN
				SET @join = ''
			END
		END
		
		DELETE FROM @DocObjects WHERE Alias = @alias 
  END
  
  vspexit:
  
      if @rcode<>0 select @msg=isnull(@msg,'')
      return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspHQGetRFMetaValueClause] TO [public]
GO
