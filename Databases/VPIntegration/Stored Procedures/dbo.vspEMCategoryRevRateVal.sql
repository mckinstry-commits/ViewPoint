SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[vspEMCategoryRevRateVal]

  /*************************************
  * CREATED BY:		GP 01/14/2010 - 135755
  * Modified By:	
  *
  *		Validates Revenue Rate on EM Categories - Revenue Rates tab.
  *		Must ensure that Rate is not changed if more than 1 Revenue Breakdown Code
  *		exists in EM Revenue Rates By Category.
  *
  *		Input Parameters:
  *			EMCo
  *			EMGroup
  *			Category
  *			RevCode
  *  
  *		Output Parameters:
  *			rcode - 0 Success
  *					1 Failure
  *			msg - Return Message
  *		
  **************************************/
	(@EMCo bCompany = null, @EMGroup bGroup = null, @Category bCat = null, @RevCode bRevCode = null, 
	@RevBdownCodeCount int = null output, @RevBdownCodeTotal float = null output, @msg varchar(256) output)
	as
	set nocount on

	declare @rcode int
	select @rcode = 0, @RevBdownCodeCount = 0, @RevBdownCodeTotal = 0

	--Get Count and Total
	select @RevBdownCodeCount = count(RevBdownCode), @RevBdownCodeTotal = sum(Rate)
	from dbo.EMBG with (nolock) 
	where EMCo=@EMCo and EMGroup=@EMGroup and Category=@Category and RevCode=@RevCode


	vspexit:
   		return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspEMCategoryRevRateVal] TO [public]
GO
