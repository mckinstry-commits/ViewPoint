SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspPRCrewTSCraftVal]
/************************************************************************
* CREATED:	mh 7/13/07    
* MODIFIED:    
*
* Purpose of Stored Procedure
*
*    Validate Craft and then return appropriate rates to Crew TS.
*    
*           
* Notes about Stored Procedure
* 
*
* returns 0 if successfull 
* returns 1 and error msg if failed
*
*************************************************************************/

	(@prco bCompany = 0, @craft bCraft, @class bClass, @empl bEmployee, @postdate bDate, @jcco bCompany, @job bJob,
	@crafttemplate int, @shift tinyint, @regrate bUnitCost output, @otrate bUnitCost output, 
	@dblrate bUnitCost output, @msg varchar(90) output)

	as

	set nocount on
   
	declare @rcode int, @regearncode bEDLCode, @otearncode bEDLCode, @dblearncode bEDLCode

	select @rcode = 0

	if @prco is null
	begin
		select @msg = 'Missing PR Company!', @rcode = 1
		goto vspexit
	end

	if @craft is null
	begin
		select @msg = 'Missing PR Craft!', @rcode = 1
		goto vspexit
	end

	select @msg=Description from PRCM where PRCo=@prco and Craft=@craft
	if @@rowcount = 0
	begin
		select @msg = 'Craft not on file!', @rcode = 1 	goto vspexit
	end

	if (@craft is not null and @class is not null) 
	begin

		if @crafttemplate is null
			select @crafttemplate = CraftTemplate from JCJM where JCCo=@jcco and Job=@job --read job template

		select @regearncode=CrewRegEC, @otearncode=CrewOTEC, @dblearncode=CrewDblEC 
		from PRCO where PRCo=@prco --read company earn codes

		exec @rcode = bspPRRateDefault @prco, @empl, @postdate, @craft, @class, @crafttemplate, @shift, --get regular pay rate
		@regearncode, @rate=@regrate output, @msg=@msg output
		if @rcode<>0 goto vspexit

		exec @rcode = bspPRRateDefault @prco, @empl, @postdate, @craft, @class, @crafttemplate, @shift, --get overtime pay rate
		@otearncode, @rate=@otrate output, @msg=@msg output
		if @rcode<>0 goto vspexit

		exec @rcode = bspPRRateDefault @prco, @empl, @postdate, @craft, @class, @crafttemplate, @shift, --get doubletime pay rate
		@dblearncode, @rate=@dblrate output, @msg=@msg output
		if @rcode<>0 goto vspexit

	end   

vspexit:

     return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPRCrewTSCraftVal] TO [public]
GO
