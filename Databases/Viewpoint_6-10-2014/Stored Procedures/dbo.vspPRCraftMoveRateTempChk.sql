SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[vspPRCraftMoveRateTempChk]
	/******************************************************
	* CREATED BY:	MH 4/25/08 - Issue 121500 
	* MODIFIED By: 
	*
	* Usage:	
	*	
	*	Called by bspPRCraftRatesMove.  Checks to see if 
	*	Craft used in a template and if so returns a successconditional (7)
	*	code along with a message warning users to review rates
	*	in the templates.
	*
	* Input params:
	*
	*	@prco bCompany
	*	@craft bCraft	
	*	
	*
	* Output params:
	*	@msg		Code description or error message
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
   
   	(@prco bCompany, @craft bCraft, @msg varchar(75) output)
	as 
	set nocount on
	declare @rcode int
   	
	select @rcode = 0

	if exists(select 1 from PRCT (nolock) where PRCo = @prco and Craft = @craft)
	begin
		select @msg = 'Templates exist for this craft - please review rates in PR Craft Templates', @rcode = 7
	end
 
	vspexit:

	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPRCraftMoveRateTempChk] TO [public]
GO
