SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   proc [dbo].[bspEMWOExists]
/********************************************************
* CREATED BY: 	JM 9/7/99
* MODIFIED BY: TV 02/11/04 - 23061 added isnulls 
*			  TRL 11/14/08 Issue 131082 changed WO formatting to vspEMFormatWO from bfJustifyStringToDatatype
*
* USAGE:
* 	Returns whether a WorkOrder exists for an EMCo.
*
* INPUT PARAMETERS:
*	EM Company
*   WorkOrder to check
* OUTPUT PARAMETERS:
*	Error Message, if one
*
* RETURN VALUE:
* 	0	WO exists
*   1   WO doesnt exist
*	2 	Failure
   *********************************************************/
(@emco bCompany, @wo bWO, @errmsg varchar(60) output)

as
   
set nocount on
   
declare @rcode int
   
select @rcode = 0
   
/* Verify required parameters passed. */
if @emco is null
begin
   	select @errmsg = 'Missing EM Company#!', @rcode = 2
	goto bspexit
end

if IsNull(@wo,'')=''
begin
	select @errmsg = 'Missing WO!', @rcode = 2
    goto bspexit
end

/*Issue 131082*/
exec @rcode = dbo.vspEMFormatWO @wo output, @errmsg output
If @rcode = 1
begin
    goto bspexit
end

/* See if @wo exists in bEMWH. */
if exists(select * from dbo.EMWH with(nolock) where WorkOrder = @wo and EMCo = @emco)
	begin
	   	select @rcode = 1
	end
else
	begin
       select @rcode = 0
   end

bspexit:
-- 	if @rcode=2 select @errmsg=isnull(@errmsg,'')	--+ '-[bspEMWOExists]'
return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMWOExists] TO [public]
GO
