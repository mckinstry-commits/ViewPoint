SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspEMWOValNoAlphas    Script Date: 3/11/2002 11:10:13 AM ******/
CREATE    proc [dbo].[bspEMWOValNoAlphas]
/***********************************************************
* CREATED BY: JM 3/8/02
*				TV 02/11/04 - 23061 added isnulls 
*				TRL 11/20/08 - Issue 131028 Added code strip spaces for
*				for work orders with a 4RN3RN format "2004 15"
*
* USAGE:
* 	Does not allow alphas, allows WO no on file in EMWH
*
* 	Error returned if any of the following occurs:
* 		No EMCo passed
*		No WorkOrder passed
*		Alphas found in WorkOrder
*
* INPUT PARAMETERS:
*	EMCo   		EMCo to validate against
* 	WorkOrder 	WorkOrder to validate
*
* OUTPUT PARAMETERS:
*	@msg      		Error message if error occurs, otherwise
*
* RETURN VALUE:
*	0		success
*	1		Failure
*****************************************************/
(@emco bCompany = null, @workorder bWO = null,@msg varchar(255) output)
    
as

set nocount on
    
declare @rcode int, @NumLeadingZeros tinyint,@NumLeadingSpaces tinyint,@newwoSave bWO,@verifywo bWO, @x tinyint
select @rcode = 0
    
if @emco is null
begin
	select @msg = 'Missing EM Company!', @rcode = 1
    goto bspexit
end
if IsNull(@workorder,'')=''
begin
	select @msg = 'Missing Work Order!', @rcode = 1
    goto bspexit
end
    
/*Store the number of leading zeros in @newwo since incrementing process
in loop will wipe them out and they need to be added back to the front of 
the string after the increment. 
Strip out any leading spaces from R justification. 
For WO values '      12' or 00000012 or '2004 11 or ' 12  9*/
select @NumLeadingZeros = 0, @NumLeadingSpaces = 0
while substring(@workorder,@NumLeadingSpaces+1,1) = ' '
	select @NumLeadingSpaces = @NumLeadingSpaces + 1	
	select @newwoSave = @workorder, @workorder = substring(@workorder,@NumLeadingSpaces+1,len(@workorder))
	while substring(@workorder,@NumLeadingZeros+1,1) = '0'
	select @NumLeadingZeros = @NumLeadingZeros + 1	
	/*Replace internal spaces with 0, need to calc next wo number
	bWO input mask 4RN3RN and input length 7; 2004 11 to 2004011*/
	select @workorder = Replace(@newwoSave,' ',0)

if dbo.bfIsCompletelyNumeric(ltrim(@workorder)) = 0
begin
	select @msg = 'Work Order cannot contain alpha characters!', @rcode = 1
    goto bspexit
end
   
bspexit:
if @rcode<>0 select @msg=isnull(@msg,'')	--+ char(13) + char(10) + '[bspEMWOValNoAlphas]'

return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMWOValNoAlphas] TO [public]
GO
