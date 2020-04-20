SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION    [dbo].[vfGetVersion]  
/************************************************************************
* CREATED:	
* MODIFIED:	JayR 06/25/2012 - This funciton parses version numbers such as 9.5.33
*
*  Examples:
*     SELECT dbo.vfGetVersion('9.15.77',1)    -- should return 9
*     SELECT dbo.vfGetVersion('9.15.77',2)    -- should return 15
*     SELECT dbo.vfGetVersion('9.15.77',3)    -- should return 77
*
*************************************************************************/  
  (@version_in NVARCHAR(128), @level INT)  
RETURNS varchar(2000)
AS  
BEGIN  

	DECLARE @length INT
	DECLARE @ver NVARCHAR(128)
	
	SET @length = 0
	--SET @msg = @msg + 'Input was ' + ISNULL(@version_in,'null') + CAST(ISNULL(@level,-123) AS VARCHAR(10))
	
	IF(@level <= 0 OR @level > 5) RETURN 0
	
	IF(@version_in IS NULL) RETURN 0
	IF LTRIM(RTRIM(@version_in)) = '' RETURN 0
		
	SET @length = CHARINDEX('.',@version_in) - 1
	IF(@length <= 0)
	BEGIN
		SET @length = LEN(@version_in)	
	END
		
	IF(@level = 1)
		BEGIN
			SET @ver = SUBSTRING(@version_in,1,@length)
			IF ISNUMERIC(@ver) = 0 RETURN 0
			--RETURN CAST(@ver AS int)
			--RETURN @msg + ' Answer:' + CAST(@ver AS VARCHAR(10))
			RETURN CAST(@ver AS VARCHAR(10))
		END
	ELSE
		BEGIN
			RETURN dbo.[vfGetVersion](SUBSTRING(@version_in,@length+2,999),@level - 1)
		END
		
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vfGetVersion] TO [public]
GO
