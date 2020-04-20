SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[vspPRCraftMasterVal]
	/******************************************************
	* CREATED BY:	mh 4/10/2008 
	* MODIFIED By: 
	*
	* Usage:
	*
	*		Validates Craft using bspPRCraftVal and returns
	*		a count of Templates being used by the Craft.
	*	
	*
	* Input params:
	*	
	*		@prco, @craft	
	*
	* Output params:
	*
	*		@templatecount	count of templates using this Craft.
	*		@msg		Code description or error message
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
   
   	@prco bCompany, @craft bCraft, @templatecount int output, @msg varchar(90) output

	as 
	set nocount on
	declare @rcode int
   	
	select @rcode = 0, @templatecount = 0

	exec @rcode = bspPRCraftVal @prco, @craft, @msg output

	if @rcode = 0
	begin
		select @templatecount = count(t.Craft) from PRCM m join PRCT t on 
		m.PRCo = t.PRCo and m.Craft = t.Craft
		where m.PRCo = @prco and m.Craft = @craft
	end
	 
	vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPRCraftMasterVal] TO [public]
GO
