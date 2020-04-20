SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

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
