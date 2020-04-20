SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspJBCheckRateContraintJBER]
   
/****************************************************************************
* CREATED BY:	TJL 02/16/09 - Issue #132267, Trigger error when index not unique
* MODIFIED By : TJL 09/23/09 - Issue #135541, Updating Rate only generates unwanted duplicate constraint error	
*
*
* USAGE: This procedure is called from StdBeforeRecUpdate and StdBeforeRecAdd in Job Billing
*		Override Rate forms.  If the nonclustered index is not unique, user will be warned and 
*		record will not be saved before reaching the Table constraint error.
*
*
*  INPUT PARAMETERS
*
* OUTPUT PARAMETERS
*   	@msg      error message if error occurs
* RETURN VALUE
*   	0         success
*   	1         Failure
****************************************************************************/
(@jbco bCompany, @template varchar(10) = null, @emco bCompany = null, @category varchar(10) = null,
	@byequipYN bYN = null, @equip bEquip = null, @byrevcodeYN bYN = null, @revcode bRevCode = null, 
	@seq int, @msg varchar(255) output)

as
set nocount on
   
declare @rcode int

select @rcode = 0

if exists(select 1
	from bJBER with (nolock)
	where JBCo = @jbco and Template = @template and EMCo = @emco and EquipCategory = @category 
		and RestrictByEquip = @byequipYN and isnull(Equipment, '') = isnull(@equip, '')
		and RestrictByRevCode = @byrevcodeYN and isnull(RevCode, '')= isnull(@revcode, '')
		and isnull(Seq, 0) <> isnull(@seq, 0))
	begin
	select @msg = 'Duplicate restrictions for this Template, EM Company, and Category are not allowed.  Record will not be saved.', @rcode = 1
	goto vspexit
	end

vspexit:
   
return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspJBCheckRateContraintJBER] TO [public]
GO
