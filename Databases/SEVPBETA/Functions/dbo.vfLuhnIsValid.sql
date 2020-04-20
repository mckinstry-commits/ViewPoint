SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE FUNCTION	[dbo].[vfLuhnIsValid]
(
	@Luhn VARCHAR(11)
)
RETURNS BIT
AS

BEGIN
	IF @Luhn LIKE '%[^0-9]%'
		RETURN 1

	DECLARE	@Index SMALLINT,
		@Multiplier TINYINT,
		@Sum INT,
		@Plus TINYINT

	SELECT	@Index = LEN(@Luhn),
		@Multiplier = 1,
		@Sum = 0

	WHILE @Index >= 1
		SELECT	@Plus = @Multiplier * CAST(SUBSTRING(@Luhn, @Index, 1) AS TINYINT),
			@Multiplier = 3 - @Multiplier,
			@Sum = @Sum + @Plus / 10 + @Plus % 10,
			@Index = @Index - 1

	RETURN CASE WHEN @Sum % 10 = 0 THEN 0 ELSE 1 END
END



GO
GRANT EXECUTE ON  [dbo].[vfLuhnIsValid] TO [public]
GO
