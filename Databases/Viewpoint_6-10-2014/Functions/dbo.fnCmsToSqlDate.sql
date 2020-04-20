SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[fnCmsToSqlDate] (@cmsdate  decimal(8,0))  
RETURNS datetime
AS  
BEGIN 

declare @retStrDate char(10)

if @cmsdate >= 19010101 and @cmsdate < 99991232 and @cmsdate <> 404040404
begin

declare @strDate char(8)


declare @year char(4)
declare @month char(2)
declare @day char(2)

select @strDate = cast(@cmsdate as char(8))
select @year = substring(@strDate,1,4)
select @month = substring(@strDate,5,2)
select @day = substring(@strDate,7,2)

select @retStrDate = @month + '/' + @day + '/' + @year

end

else
	select @retStrDate = null

return cast(@retStrDate as datetime)
end

GO
