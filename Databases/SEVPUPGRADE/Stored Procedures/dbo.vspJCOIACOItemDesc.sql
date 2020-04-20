SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspJCOIACOItemDesc]
/*************************************
 * Created By:	CHS 1/29/2009
 *
 * called from JCOI to return ACO Item key description.
 *
 * Pass:
 * JCCo			JC Company
 * Job			JC Job
 * ACO			JC ACO
 * ACOItem		JC ACO Item
 *
 * Success returns:
 *	0 and Description from JCOI
 *
 * Error returns:
 * 
 *	1 and error message
 **************************************/
(@jcco bCompany, @job bJob, @aco bACO, @acoitem bACOItem, @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0, @msg = ''

-- -- -- get description from JCOI
if isnull(@acoitem,'') <> ''
	begin
	select @msg = Description
	from JCOI with (nolock) 
	where JCCo=@jcco and Job=@job and ACO=@aco and ACOItem=@acoitem
	end

bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCOIACOItemDesc] TO [public]
GO
