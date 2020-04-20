SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspHRAccJCCoValwPhaseGrp]
/************************************************************************
* CREATED:	mh 4/28/2005    
* MODIFIED:    
*
* Purpose of Stored Procedure
*
*	Validate JC Company in HR Accident and return Phase Group.
*    
* Notes about Stored Procedure
* 
*
*	@jcco - JC Company to be validated
*	@phasegrp - Phase group associated with the JC Company
*
*
* returns 0 if successfull 
* returns 1 and error msg if failed
*
*************************************************************************/

    (@jcco bCompany = null, @phasegrp bGroup = null output, @msg varchar(80) = '' output)

as
set nocount on

    declare @rcode int

    select @rcode = 0

	if @jcco is null
	begin
		select @msg = 'Missing JC Company.', @rcode = 1
		goto bspexit
	end

	exec @rcode = bspJCCompanyVal @jcco, @msg output

	if @rcode = 0
		--Get the phase group
		exec @rcode = bspJCPhaseGrpGet @jcco, @phasegrp output, @msg output

bspexit:

     return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHRAccJCCoValwPhaseGrp] TO [public]
GO
