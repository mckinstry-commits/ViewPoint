SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  FUNCTION [dbo].[fnMcKWeekEnding] (@date datetime)  
RETURNS datetime AS  

/*************************************************************************************!
*   Procedure:  fnWeekEnding 
*   Database:   infocentre
*   Date:       March 2006
*   Author:		Bill O
*   Description: Gets McKinstry week ending date - Sunday
!**************************************************************************************/

begin

select @date = cast(convert(varchar(10),@date,101) as datetime)
declare @retdate datetime

declare @dow int
select @dow = datepart(dw,@date)

if @dow <> 1
begin
	select @dow = 7 - (@dow-1)
	select @retdate = dateadd(day,@dow,@date)
end
else
	select @retdate =  @date

return @retdate
end

GO
