SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE function [dbo].[vfJCCloseWarning]
(@batchmonth bMonth = null, @lstMthCost bMonth = null, @lstMthRevenue bMonth = null)
returns varchar(255)
/***********************************************************
* CREATED BY	: DANF
* MODIFIED BY	
*
* USAGE:
* 	Returns Warning for Contract Close process.
*
* INPUT PARAMETERS:
*	batch month, Last Cost Month, and last revenue Month.
*
* OUTPUT PARAMETERS:
*	Warning Message
*	
*
*****************************************************/
as
begin

declare @warning varchar(255)

set @warning = ''

         If @batchmonth < @lstMthRevenue 
			begin
			select @warning = 'Revenue postings in future months.  Unable to close.'
			goto exitfunction
			end

         If @batchmonth < @lstMthCost 
			begin
			select @warning = 'Cost postings in future months.  Unable to close.'
			goto exitfunction
			end

         If @batchmonth < @lstMthCost and @batchmonth < @lstMthRevenue
			begin
			select @warning = 'Cost and Revenue postings in future months.  Unable to close.'
			goto exitfunction
			end

exitfunction:
  			
return @warning
end

GO
GRANT EXECUTE ON  [dbo].[vfJCCloseWarning] TO [public]
GO
