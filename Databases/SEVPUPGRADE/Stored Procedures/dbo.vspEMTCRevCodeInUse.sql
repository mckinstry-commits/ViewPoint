SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspEMTCRevCodeInUse    Script Date: ******/
CREATE proc [dbo].[vspEMTCRevCodeInUse]
   
/******************************************************
* Created By:  TJL  11/02/06 - Issue #27972:  6x Rewrite
* Modified By: 
*				
* Usage:
*	If RevCode is in use by EMRevRateEquipTemp for this Category/RevCode then
*	give warning to user in form to avoid btEMTCd trigger error.
*
*
* Input Parameters
*	EMCo		Need company to retrieve Allow posting override flag
* 	EMGroup		EM group for this company
*	RevTemplate	Revenue Template
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
   
(@emco bCompany, @emgroup bGroup, @revtemplate varchar(10), @category bCat, @revcode bRevCode,
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
----if @emgroup is null
----	begin
----	select @errmsg = 'Missing EM Group.', @rcode = 1
----	goto vspexit
----	end
if @revtemplate is null
	begin
	select @errmsg = 'Missing Revenue Template.', @rcode = 1
	goto vspexit
	end
if @category is null
	begin
	select @errmsg = 'Missing Category.', @rcode = 1
	goto vspexit
	end
if @revcode is null
	begin
	select @errmsg = 'Missing Revenue Code.', @rcode = 1
	goto vspexit
	end

/* Make sure that this Revenue Code is not being used in the Rates By Equipment Template table
   for any piece of Equipment setup to use this Category. */
if exists(select 1
	from bEMTE h with (nolock)
	join bEMEM e with (nolock) on e.EMCo = h.EMCo and e.Equipment = h.Equipment
	where h.EMCo = @emco and h.EMGroup = @emgroup and h.RevTemplate = @revtemplate and h.RevCode = @revcode and e.Category = @category)
		begin
   		select @errmsg = 'Template/Category/Revenue Code combination exists in Rates by Equipment template.', @rcode = 1
   		goto vspexit
   		end
   
vspexit:
if @rcode <> 0 select @errmsg = isnull(@errmsg,'')
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMTCRevCodeInUse] TO [public]
GO
