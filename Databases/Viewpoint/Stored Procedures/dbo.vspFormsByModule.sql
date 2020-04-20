SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[vspFormsByModule]

(
	@ModuleList varchar(500)
)
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @TempList table
	(
		Module CHAR(2)
	)

	DECLARE @Mod varchar(10), @Pos int

	SET @ModuleList = LTRIM(RTRIM(@ModuleList))+ ','
	SET @Pos = CHARINDEX(',', @ModuleList, 1)

	IF REPLACE(@ModuleList, ',', '') <> ''
	BEGIN
		WHILE @Pos > 0
		BEGIN
			SET @Mod = LTRIM(RTRIM(LEFT(@ModuleList, @Pos - 1)))
			IF @Mod <> ''
			BEGIN
				INSERT INTO @TempList (Module) VALUES (CAST(@Mod AS CHAR(2))) --Use Appropriate conversion
			END
			SET @ModuleList = RIGHT(@ModuleList, LEN(@ModuleList) - @Pos)
			SET @Pos = CHARINDEX(',', @ModuleList, 1)

		END
	END	

	SELECT o.Form
	FROM 	dbo.DDFH AS o
		JOIN 
		@TempList t
		ON o.Mod = t.Module
		
END

GO
GRANT EXECUTE ON  [dbo].[vspFormsByModule] TO [public]
GO
