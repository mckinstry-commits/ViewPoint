SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspJBCheckRateContraintJBLR]
   
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
(@jbco bCompany, @template varchar(10) = null, @category varchar(20) = null,
	@byearntypeYN bYN = null, @earntype bEarnType = null, @byfactorYN bYN = null, @factor bRate = null,
	@byshiftYN bYN = null, @shift tinyint = null, @seq int, @msg varchar(255) output)

as
set nocount on
   
declare @rcode int

select @rcode = 0

if exists(select 1
	from bJBLR with (nolock)
	where JBCo = @jbco and Template = @template and LaborCategory = @category 
		and RestrictByEarn = @byearntypeYN and isnull(EarnType, -32768) = isnull(@earntype, -32768) 
		and RestrictByFactor = @byfactorYN and isnull(Factor, -99.999999) = isnull(@factor, -99.999999) 
		and RestrictByShift = @byshiftYN and isnull(Shift, 255) = isnull(@shift, 255)
		and isnull(Seq, 0) <> isnull(@seq, 0))
	begin
	select @msg = 'Duplicate restrictions for this Template and Category are not allowed.  Record will not be saved.', @rcode = 1
	goto vspexit
	end

vspexit:
   
return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspJBCheckRateContraintJBLR] TO [public]
GO
