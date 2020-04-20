SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[fnSqlToCmsDate] (@sqldate  datetime)  
RETURNS decimal(8,0)
AS  
BEGIN 

declare @retStrDate decimal(8,0)

select @retStrDate = cast(convert(varchar(8),@sqldate,112) as decimal(8,0))

return @retStrDate
END

GO
