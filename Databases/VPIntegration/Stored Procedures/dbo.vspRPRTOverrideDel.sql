SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspRPRTOverrideDel]
/******************************************
* Created: TRL  10/27/2006
* Modified: GG 04/10/07 - cleanup
*
* Removes an 'overridden' Report Title entry.  Will only delete
* the vRPRTc entry if a standard one exists for the report in vRPRT. 
*
* Custom report parameters (w/o standard vRPRT entry) are removed via the delete 
* trigger on RPRTShared. 
*
* Inputs:
*	@reportid		Report ID
*
* Output:
*	@msg		Error message
*
* Return code:
*	0 = success, 1 = error
*
*********************************************/
	(@reportid int = null, @msg varchar(256) output)
as

set nocount on
declare @rcode int

select @rcode = 0

--make sure Report Title is an override, not custom
if exists(select top 1 1 from dbo.vRPRT (nolock) where ReportID = @reportid)
	begin
	delete dbo.vRPRTc where ReportID = @reportid
	end

vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspRPRTOverrideDel] TO [public]
GO
