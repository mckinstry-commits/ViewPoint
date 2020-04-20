--DROP FUNCTION mfnGetWIPRevenue
IF EXISTS ( SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE='FUNCTION' AND ROUTINE_SCHEMA='dbo' AND ROUTINE_NAME='mfnFirstOfMonth')
BEGIN
	PRINT 'DROP FUNCTION mfnFirstOfMonth'
	DROP FUNCTION dbo.mfnFirstOfMonth
END
go

--CREATE FUNCTION mfnFirstOfMonth
PRINT 'CREATE FUNCTION mfnFirstOfMonth'
go

--create FUNCTION mfnFirstOfMonth
CREATE  FUNCTION [dbo].[mfnFirstOfMonth] (@date datetime)  
RETURNS SMALLDATETIME AS  

begin

IF @date IS NULL
	SELECT @date=GETDATE()
	
select @date = cast(convert(varchar(10),@date,101) as datetime)
declare @retdate SMALLDATETIME
SELECT @retdate=CAST(CAST(DATEPART(MONTH,@date) AS VARCHAR(4)) + '/1/' + CAST(DATEPART(year,@date) AS VARCHAR(4)) AS SMALLDATETIME)

return @retdate
end
GO