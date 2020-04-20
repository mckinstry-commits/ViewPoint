SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspEMCatVal    Script Date: 8/28/99 9:32:40 AM ******/
CREATE proc [dbo].[bspEMCatVal]
   
/******************************************************
* Created By:  ae  5/10/99
* Modified By: TV 02/11/04 - 23061 added isnulls
*
* Usage:
* Validates Category from EMCM.
*
*
* Input Parameters

*	EMCo		Need company to validate the Category
* 	Category
*
* Output Parameters
*	JobFlag
*	@msg	  Error message.
* Return Value
*  0	success
*  1	failure
***************************************************/
   
(@emco bCompany = null, @Category bDept = null, @msg varchar(60) output)
   
as
set nocount on

declare @rcode int
select @rcode = 0
select @msg = ''
   
if @emco is null
	begin
	select @msg= 'Missing Company.', @rcode = 1
	goto bspexit
	end
   
if @Category is null
	begin
	select @msg= 'Missing Category', @rcode = 1
	goto bspexit
	end
   
select @msg= Description
from EMCM with (nolock)
where EMCo = @emco and Category = @Category
if @@rowcount = 0
	begin
	select @msg = 'Category is not set up.', @rcode = 1
	goto bspexit
	end

bspexit:
if @rcode <> 0 select @msg = isnull(@msg,'')	--+ char(13) + char(10) + '[bspEMCatVal]'
return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMCatVal] TO [public]
GO
