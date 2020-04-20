SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   proc [dbo].[vspEMRevBdownCodeVal]
/******************************************************
* Created By:  bc  03/30/98
* 				TV 02/11/04 - 23061 added isnulls
*				TV 10/18/05 - Moved to 6X
*	
* Usage:
* Validates Revenue breakdown code from EMRT.
* an error is returned by any of the following conditions
* no Bdown code passed, no Bdown code in EMRT
*
* Input Parameters
* 	EMGroup		EM group for this company
*	RevBdownCode	Code assigned to the cost code
*
* Output Parameters
*	@msg	The RevBdownCode description.  Error message when appropriate.
* Return Value
*  0	success
*  1	failure
***************************************************/
(@EMGroup bGroup, @RevBdownCode varchar(10), @msg varchar(60) output)
as
set nocount on

	declare @rcode int
	select @rcode = 0

if @RevBdownCode is null
	begin
	select @msg = 'Missing Revenue breakdown code', @rcode = 1
	goto bspexit
	end

select @msg = Description
	from bEMRT
	where EMGroup = @EMGroup and RevBdownCode = @RevBdownCode

if @@rowcount = 0
	begin
	select @msg = 'Revenue breakdown code not set up.', @rcode = 1
	goto bspexit
	end

bspexit:
	if @rcode<>0 select @msg=isnull(@msg,'')	
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMRevBdownCodeVal] TO [public]
GO
