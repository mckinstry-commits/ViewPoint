SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspEMRevBdownCodeVal]
/******************************************************
* Created By:  bc  03/30/98
* Modified By: TV 02/11/04 - 23061 added isnulls
*		TJL 10/05/07 - Issue #125678, 6x Recode:  Return Breakdown Code Description
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
(@EMGroup bGroup, @RevBdownCode varchar(10), @codedesc bDesc output, @msg varchar(60) output)
as
set nocount on

declare @rcode int
select @rcode = 0

if @RevBdownCode is null
	begin
	select @msg = 'Missing Revenue breakdown code', @rcode = 1
	goto bspexit
	end

select @codedesc = Description, @msg = Description
from bEMRT
where EMGroup = @EMGroup and RevBdownCode = @RevBdownCode
if @@rowcount = 0
	begin
	select @msg = 'Revenue breakdown code not set up.', @rcode = 1
	goto bspexit
	end

bspexit:
if @rcode<>0 select @msg=isnull(@msg,'')	--+ char(13) + char(10) + '[bspEMRevBdownCodeVal]'
return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMRevBdownCodeVal] TO [public]
GO
