SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.vspPRUpdateJCEquipRevCheck    Script Date: 8 ******/
CREATE procedure [dbo].[vspPRUpdateJCEquipRevCheck]
/***********************************************************
* CREATED BY: TJl 08/05/09 - Issue #134501, Enable Equip Revenue List report only when JC Equip Rev records exist in bPRER
* MODIFIED By : 
*
*
* USAGE:
* Called from the Pay Period Update form after Validation has completed.  If JC Equip Revenue records DO NOT exist
* for the Pay Period, then the Equipment Revenue List remains disabled.
*
*
* INPUT PARAMETERS
*   @prco   		PR Company
*   @prgroup  		PR Group to validate
*   @prenddate		Pay Period Ending Date
*
* OUTPUT PARAMETERS
*   @errmsg      error message if error occurs
*
* RETURN VALUE
*   0		success - PRER records do exist for this Pay Period
*   1		error - Cannot determine
*	7		Conditional Success - No errors but PRER records do NOT exist for this Pay Period
*	
*****************************************************/
(@prco bCompany = null, @prgroup bGroup = null, @prenddate bDate = null, @errmsg varchar(255) = null output)
as

set nocount on

declare @rcode int

select @rcode = 0

if @prco is null
	begin
	select @errmsg = 'Missing PR Company.', @rcode = 1
	goto vspexit
	end
if @prgroup is null
	begin
	select @errmsg = 'Missing PR Group.', @rcode = 1
	goto vspexit
	end
if @prenddate is null
	begin
	select @errmsg = 'Missing PR Pay Period Ending Date.', @rcode = 1
	goto vspexit
	end

/* Check for JC Equip Revenue records for this Pay Period */
if not exists(select top 1 1 from bPRER with (nolock) where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate)
	begin
	select @rcode = 7
	end
	
vspexit:

return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspPRUpdateJCEquipRevCheck] TO [public]
GO
