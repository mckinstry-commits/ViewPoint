SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****************************************************************************/
CREATE  proc [dbo].[vspJCAllocationDepartments]
/****************************************************************************
 * Created By:	DANF 01/25/2007
 * Modified By:	
 *
 *
 *
 * USAGE:
 * Used to populate Allocation Department List
 *
 * INPUT PARAMETERS:
 * JC Company
 *
 * OUTPUT PARAMETERS:
 *
 *
 * RETURN VALUE:
 * 	0 	    Success
 *	1 & message Failure
 *
 *****************************************************************************/
(@jcco bCompany = null, @alloccode tinyint = null, @exists bYN = null)
as
set nocount on

declare @rcode int

select @rcode = 0

IF @exists = 'N'
	begin
	select JCDM.Department as 'Department', JCDM.Description as 'Description'
	--, case isnull(JCAD.Department,'') when '' then 'N' else 'Y' end as 'Exists'
	from JCDM JCDM with (nolock) 
	left join JCAD with (nolock)
	on JCDM.JCCo = JCAD.JCCo and JCDM.Department = JCAD.Department and JCAD.AllocCode = @alloccode
	where JCDM.JCCo = @jcco and isnull(JCAD.Department,'') <> ''
	end
else
	begin
	select JCDM.Department as 'Department', JCDM.Description as 'Description'
	--, case isnull(JCAD.Department,'') when '' then 'N' else 'Y' end as 'Exists'
	from JCDM JCDM with (nolock) 
	left join JCAD with (nolock)
	on JCDM.JCCo = JCAD.JCCo and JCDM.Department = JCAD.Department and JCAD.AllocCode = @alloccode
	where JCDM.JCCo = @jcco and isnull(JCAD.Department,'') = ''
	end

bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCAllocationDepartments] TO [public]
GO
