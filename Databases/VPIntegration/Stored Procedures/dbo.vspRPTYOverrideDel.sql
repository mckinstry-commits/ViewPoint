SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspRPTYOverrideDel]
/******************************************
* Created: TRL  10/27/2006
* Modified: GG 04/10/07 - cleanup
*
* Removes an 'overridden' Report Type entry.  Will only delete
* the vRPTYc entry if a standard one exists for the report in vRPTY. 
*
* Custom report types (w/o standard vRPTY entry) are removed via the delete 
* trigger on RPTYShared. 
*
* Inputs:
*	@reporttype		Report Type
*
* Output:
*	@msg		Error message
*
* Return code:
*	0 = success, 1 = error
*
*********************************************/
	(@reporttype varchar(10) = null, @msg varchar(256) output)
as

set nocount on
declare @rcode int

select @rcode = 0

--make sure Report Type is an override, not custom
if exists(select top 1 1 from dbo.vRPTY (nolock) where ReportType = @reporttype)
	begin
	delete dbo.vRPTYc where ReportType = @reporttype
	end

vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspRPTYOverrideDel] TO [public]
GO
