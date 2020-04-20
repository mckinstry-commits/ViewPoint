SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****************************************************************************/
CREATE  proc [dbo].[vspJCAllocationDepartmentsAdd]
/****************************************************************************
 * Created By:	DANF 01/25/2007
 * Modified By:	
 *
 *
 *
 * USAGE:
 * Used to Add Deaprtment to the Allocation Department List
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
(@jcco bCompany = null, @alloccode tinyint = null, @department varchar(10) = null, @exists bYN = null)
as
set nocount on

declare @rcode int

select @rcode = 0

INSERT INTO JCAD (JCCo, AllocCode, Department)
VALUES ( @jcco, @alloccode, @department);

bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCAllocationDepartmentsAdd] TO [public]
GO
