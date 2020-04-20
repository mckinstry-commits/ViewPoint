SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspEMWOMassUpdateMechanicNameGet]

/***********************************************************
* CREATED BY: TRL 02/06/09 Issue 129069
*
* Usage: Used to get Employee for Mechanic Validation for WO Item Grid
*
* Input params:
*	@prco		PR company
*	@empl		Employee sort name or number
*	@activeopt	Controls validation based on Active flag
*			'Y' = must be an active
*			'N' = must be inactive
*			'X' = can be any value
*
* Output params:
*	@emplout	Employee number
*	@msg		Employee Name or error message
*
* Return code:
*	0 = success, 1 = failure
************************************************************/
(@prco bCompany ,@empl bEmployee ,@activeopt varchar(1), @emplname varchar(120) output,
@errmsg varchar(255) output)
   
as

set nocount on

declare @rcode int, @active bYN
   
select @rcode = 0

/* check required input params */
if @empl is null
begin
	select @errmsg = 'Missing Employee.', @rcode = 1
	goto vspexit
end

if IsNull(@activeopt,'') = ''
begin
	select @errmsg = 'Missing Active option for Employee validation.', @rcode = 1
	goto vspexit
end

select @emplname= IsNull(LastName,'') +  ', ' + IsNull(FirstName,'')+ ' '+IsNull(MidName,''), @active=ActiveYN
from dbo.PREHName
where PRCo=@prco and Employee= @empl
if @@rowcount = 0
begin
	select @errmsg = 'Not a valid Employee.', @rcode = 1
   	goto vspexit
end
   
if @activeopt <> 'X' and @active <> @activeopt
begin
	if @activeopt = 'Y' 
	begin
		select @errmsg = 'Must be an active Employee.', @rcode = 1
	end
	if @activeopt = 'N' 
	begin 
		select @errmsg = 'Must be an inactive Employee.', @rcode = 1
	end
	goto vspexit
end

vspexit:
   
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMWOMassUpdateMechanicNameGet] TO [public]
GO
