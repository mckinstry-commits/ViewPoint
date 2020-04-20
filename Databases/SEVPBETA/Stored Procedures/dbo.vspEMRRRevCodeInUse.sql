SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspEMRRRevCodeInUse    Script Date: ******/
CREATE proc [dbo].[vspEMRRRevCodeInUse]
   
/******************************************************
* Created By:  TJL  11/02/06 - Issue #27926:  6x Rewrite
* Modified By:	GP	9/30/08 - 129979, commented out validation for EMGroup and RevCode. Also
*								added isnull's to checks below.
*				
* Usage:
*	If RevCode is in use by EMRevRateEquip for this Category/RevCode or
*	if RevCode is in use by EMRevRateCatgyTemp for this Category/RevCode then
*	give warning to user in form to avoid btEMRRd trigger error.
*
*
* Input Parameters
*	EMCo		Need company to retreive Allow posting override flag
* 	EMGroup		EM group for this company
*	Category	Category
*	RevCode		Revenue code to validate
*
* Output Parameters
*	@errmsg		The RevCode description.  Error message when appropriate.
*
*
* Return Value
*  0	success
*  1	failure
***************************************************/
   
(@emco bCompany, @emgroup bGroup = null, @category bCat = null, @revcode bRevCode = null,
@errmsg varchar(255) output)
   
as
set nocount on

declare @rcode int
select @rcode = 0

if @emco is null
	begin
	select @errmsg = 'Missing EM Company.', @rcode = 1
	goto vspexit
	end
if @category is null
	begin
	select @errmsg = 'Missing Category.', @rcode = 1
	goto vspexit
	end
----if @emgroup is null
----	begin
----	select @errmsg = 'Missing EM Group.', @rcode = 1
----	goto vspexit
----	end
----if @revcode is null
----	begin
----	select @errmsg = 'Missing Revenue Code.', @rcode = 1
----	goto vspexit
----	end

/* Make sure that this Revenue Code is not being used in the Rates By Equipment table
   for any piece of Equipment setup to use this Category.*/
if exists(select 1
	from bEMRH h with (nolock)
	join bEMEM e with (nolock) on e.EMCo = h.EMCo and e.Equipment = h.Equipment
	where h.EMCo = @emco and h.EMGroup = isnull(@emgroup, h.EMGroup) 
		and h.RevCode = isnull(@revcode, h.RevCode) and e.Category = @category)
		begin
   		select @errmsg = 'Category/Revenue Code combination exists in Rates by Equipment.', @rcode = 1
   		goto vspexit
   		end
   
/* make sure that no revenue codes exist in relation to this category in the template tables before deletion */
if exists(select 1
	from bEMTC tc
	where tc.EMCo = @emco and tc.EMGroup = isnull(@emgroup, tc.EMGroup) 
		and tc.Category = isnull(@category, tc.Category) and tc.RevCode = isnull(@revcode, tc.RevCode))
		begin
		select @errmsg = 'Category/Revenue Code combination exists in Rates by Revenue Template Category.', @rcode = 1
		goto vspexit
		end	
   
vspexit:
if @rcode <> 0 select @errmsg = isnull(@errmsg,'')
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMRRRevCodeInUse] TO [public]
GO
