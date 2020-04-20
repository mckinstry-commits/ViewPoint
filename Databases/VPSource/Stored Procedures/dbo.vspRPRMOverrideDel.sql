SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE procedure [dbo].[vspRPRMOverrideDel]
/******************************************
* Created: TRL  10/27/2006
* Modified: GG 04/10/07 - cleanup
*
* Removes an 'overridden' Module Report assignments.  Will only delete
* the vRPRMc entry if a standard one exists for the module and report in vRPRM. 
*
* Custom module reports (w/o standard vRPRM entry) are removed via the delete 
* trigger on RPRMShared. 
*
* Inputs:
*	@mod		Module
*	@reportid	Report ID
*
* Output:
*	@msg		Error message
*
* Return code:
*	0 = success, 1 = error
*
*********************************************/
	(@mod varchar(2) = null, @reportid int = 0, @msg varchar(256) output)

as

set nocount on
declare @rcode int

select @rcode = 0

--make sure Module Report is an override, not custom
if exists(select top 1 1 from dbo.vRPRM (nolock) where Mod = @mod and ReportID = @reportid)
	begin
	delete dbo.vRPRMc where Mod = @mod and ReportID = @reportid
	end

vspexit:
	return @rcode



GO
GRANT EXECUTE ON  [dbo].[vspRPRMOverrideDel] TO [public]
GO
