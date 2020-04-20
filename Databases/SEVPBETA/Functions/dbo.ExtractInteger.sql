SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[ExtractInteger](@String VARCHAR(2000))
RETURNS VARCHAR(1000)
AS
BEGIN
DECLARE @Count INT
DECLARE @IntNumbers VARCHAR(1000)
SET @Count = 0
SET @IntNumbers = ''

WHILE @Count <= LEN(@String)
BEGIN
IF SUBSTRING(@String,@Count,1) >= '0'
AND SUBSTRING(@String,@Count,1) <= '9'
BEGIN
SET @IntNumbers = @IntNumbers + SUBSTRING(@String,@Count,1)
END
SET @Count = @Count + 1
END

RETURN @IntNumbers
END
GO
