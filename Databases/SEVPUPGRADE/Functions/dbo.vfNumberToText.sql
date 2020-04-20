SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Mike Brewer
-- Create date: 4/22/09
-- Description:	This function helps to convers number into word equivilant
-- Issue #131608 
-- =============================================

CREATE Function [dbo].[vfNumberToText] (@SingleNumber varchar(1))
Returns varchar(5)
as 
Begin
Return
case @SingleNumber
when '0' then 'Zero'
when '1' then 'One'
when '2' then 'Two'
when '3' then 'Three'
when '4' then 'Four'
when '5' then 'Five'
when '6' then 'Six'
when '7' then 'Seven'
when '8' then 'Eight'
when '9' then 'Nine'
end
End


GO
GRANT EXECUTE ON  [dbo].[vfNumberToText] TO [public]
GO
