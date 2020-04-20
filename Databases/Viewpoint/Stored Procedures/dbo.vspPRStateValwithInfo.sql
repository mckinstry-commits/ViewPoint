SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspPRStateValwithInfo]
/************************************************************************
* CREATED:	mh 2/8/08     
*			EN 3/7/08 - #127081  in declare statements change State declarations to varchar(4)
* MODIFIED:    
*
* Purpose of Stored Procedure
*
*   Expanded version of PRStateVal.  Retieves Local and Dl Code 
*	info for use as captions in PRUnemplEmpl
*           
* Notes about Stored Procedure
*
* returns 0 if successfull 
* returns 1 and error msg if failed
*
*************************************************************************/

    (@prco bCompany = 0, @state varchar(4) = null, @localdesc1 varchar(20) output, 
	@localdesc2 varchar(20) output, @localdesc3 varchar(20) output, 
	@dlcodedesc1 varchar(20) output, @dlcodedesc2 varchar(20) output, @msg varchar(255) = '' output)

as
set nocount on

    declare @rcode int

    select @rcode = 0

	if @prco is null
	begin
		select @msg = 'Missing PR Company.', @rcode = 1
		goto vspexit
	end

	if @state is null
	begin
		select @msg = 'Missing State.', @rcode = 1
		goto vspexit
	end

	--validate state
	exec @rcode = bspPRStateVal @prco, @state, @msg output

	if @rcode = 0
	begin
		--we have a valid PR State set up in PRSI
		exec @rcode = bspPRUELocalCodeGet @prco, @state, @localdesc1 output, @localdesc2 output, @localdesc3 output, @msg output
		if @rcode = 0 
		begin
			exec @rcode = bspPRUEDLCodeGet @prco, @state, @dlcodedesc1 output, @dlcodedesc2 output, @msg output
		end
	end

vspexit:

     return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPRStateValwithInfo] TO [public]
GO
