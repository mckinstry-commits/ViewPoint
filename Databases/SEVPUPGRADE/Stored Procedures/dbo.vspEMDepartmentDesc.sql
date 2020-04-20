SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspEMDepartmentDesc    Script Date: 05/03/2005 ******/
CREATE  proc [dbo].[vspEMDepartmentDesc]
/*************************************
 * Created By:	DANF 03/15/07
 * Modified By:
 *
 *
 * USAGE:
 * Called from EM Department to get key description for Department. 
 *
 *
 * INPUT PARAMETERS
 * @emco			EM Company
 * @department		EM Department
 * 
 *
 * Success returns:
 *	0 and Description from EMDM
 *
 * Error returns:
 *	1 and error message
 **************************************/
(@emco bCompany, @department bDept, @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0, @msg = ''

if isnull(@department,'') = ''
	begin
   	select @msg = 'Department cannot be null.', @rcode = 1
   	goto bspexit
	end

-- -- -- get department description
select @msg=Description
from EMDM with (nolock) 
where EMCo=@emco and Department=@department

bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMDepartmentDesc] TO [public]
GO
