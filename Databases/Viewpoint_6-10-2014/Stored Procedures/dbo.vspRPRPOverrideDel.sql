SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspRPRPOverrideDel]
/******************************************
* Created: TRL  10/27/2006
* Modified: GG 04/10/07 - cleanup
*
* Removes an 'overridden' Report Parameter.  Will only delete
* the vRPRPc entry if a standard one exists for the report and parameter in vRPRP. 
*
* Custom report parameters (w/o standard vRPRP entry) are removed via the delete 
* trigger on RPRPShared. 
*
* Inputs:
*	@reportid		Report ID
*	@parametername	Parameter Name
*
* Output:
*	@msg		Error message
*
* Return code:
*	0 = success, 1 = error
*
*********************************************/
	(@reportid int = 0 , @parametername varchar(30) = null, @msg varchar(256) output)
as

set nocount on
declare @rcode int

select @rcode = 0

--make sure Report Parameter is an override, not custom
if exists(select top 1 1 from dbo.vRPRP (nolock)
			where ReportID = @reportid and ParameterName = @parametername)
	begin
	delete dbo.vRPRPc where ReportID = @reportid and ParameterName = @parametername
	end

vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspRPRPOverrideDel] TO [public]
GO
