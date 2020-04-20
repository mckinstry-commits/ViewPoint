--DROP FUNCTION mfnSplitCsvParam
IF EXISTS ( SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE='FUNCTION' AND ROUTINE_SCHEMA='dbo' AND ROUTINE_NAME='mfnSplitCsvParam')
BEGIN
	PRINT 'DROP FUNCTION mfnSplitCsvParam'
	DROP FUNCTION dbo.mfnSplitCsvParam
END
go

PRINT 'CREATE FUNCTION mfnSplitCsvParam'
go

--create FUNCTION mfnSplitCsvParam
create FUNCTION dbo.mfnSplitCsvParam
(
	@csvParam	VARCHAR(500)
)
RETURNS
@ParsedList table
(
	Val CHAR(1)
)
AS
BEGIN
	DECLARE @char CHAR(1), @Pos INT

	SET @csvParam = LTRIM(RTRIM(@csvParam))+ ','
	SET @Pos = CHARINDEX(',', @csvParam, 1)

	IF REPLACE(@csvParam, ',', '') <> ''
	BEGIN
		WHILE @Pos > 0
		BEGIN
			SET @char = LTRIM(RTRIM(LEFT(@csvParam, @Pos - 1)))
			IF @char <> ''
			BEGIN
				INSERT INTO @ParsedList (Val) 
				VALUES (@char)
			END
			SET @csvParam = RIGHT(@csvParam, LEN(@csvParam) - @Pos)
			SET @Pos = CHARINDEX(',', @csvParam, 1)

		END
	END	
	RETURN
END
GO

--Test Script
--SELECT * from dbo.mfnSplitCsvParam(null)
--SELECT * from dbo.mfnSplitCsvParam('')
--SELECT * from dbo.mfnSplitCsvParam(',,,')
--SELECT * from dbo.mfnSplitCsvParam('N')
--SELECT * from dbo.mfnSplitCsvParam('M,A,C')
--SELECT * from dbo.mfnSplitCsvParam(',,M,,A,,,C,,,')
--SELECT * from dbo.mfnSplitCsvParam('MAC')