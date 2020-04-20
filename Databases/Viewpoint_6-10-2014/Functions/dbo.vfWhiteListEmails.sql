SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[vfWhiteListEmails]
(@Parameter varchar(3002))
RETURNS varchar(3000)
AS
BEGIN 		
	SELECT @Parameter = ',' + @Parameter + ',';
	SELECT @Parameter = REPLACE(@Parameter, ';', ',');

	DECLARE @EmailAddress TABLE (Value VARCHAR(8000));

	WITH
	L0   AS(SELECT 1 AS C UNION ALL SELECT 1 AS O), -- 2 rows
	L1   AS(SELECT 1 AS C FROM L0 AS A CROSS JOIN L0 AS B), -- 4 rows
	L2   AS(SELECT 1 AS C FROM L1 AS A CROSS JOIN L1 AS B), -- 16 rows
	L3   AS(SELECT 1 AS C FROM L2 AS A CROSS JOIN L2 AS B), -- 256 rows
	L4   AS(SELECT 1 AS C FROM L3 AS A CROSS JOIN L3 AS B), -- 65,536 rows
	Nums AS(SELECT ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS N FROM L4)

	INSERT INTO @EmailAddress(Value) 
	SELECT LTRIM(RTRIM(SUBSTRING(@Parameter,N+1,CHARINDEX(',',@Parameter,N+1)-N-1)))
	FROM Nums
	WHERE N < LEN(@Parameter) AND SUBSTRING(@Parameter,N,1) = ','

	DECLARE @To VARCHAR(3000);
	SET @To = '';
	SELECT @To = @To + ',' + Value
	FROM @EmailAddress
	INNER JOIN dbo.vWhiteList ON [@EmailAddress].Value = vWhiteList.Email;

	SET @To = SUBSTRING(@To, 2, LEN(@To));
	RETURN @To;
END
GO
GRANT EXECUTE ON  [dbo].[vfWhiteListEmails] TO [public]
GO
