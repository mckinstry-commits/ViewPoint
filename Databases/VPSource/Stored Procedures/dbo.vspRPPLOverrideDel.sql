SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE     procedure [dbo].[vspRPPLOverrideDel]
/******************************************
* Created: TRL  10/27/2006
* Modified: GG 04/10/07 - cleanup
*
* Removes an 'overridden' Report Parameter Lookup.  Will only delete
* the vRPRLc entry if a standard one exists for the report and parameter in vRPPL. 
*
* Custom report parameter lookups (w/o standard vRPPL entry) are removed via the delete 
* trigger on RPPLShared. 
*
* Inputs:
*	@reportid		Report ID#
*	@parametername	Parameter name
*	@lookup			Lookup
*
* Output:
*	@msg		Error message
*
* Return code:
*	0 = success, 1 = error
*
*********************************************/
	(@reportid int = null, @parametername varchar(30) = null, @lookup varchar(30) = null,
	 @msg varchar(256) output)
as

set nocount on
declare @rcode int

select @rcode = 0

--make sure Report Parameter Lookup is an override, not custom
if exists(select top 1 1 from dbo.vRPPL (nolock) 
			where ReportID = @reportid and ParameterName = @parametername and Lookup = @lookup)
	begin
	delete dbo.vRPPLc where ReportID = @reportid and ParameterName = @parametername and Lookup = @lookup
	end

vspexit:
	return @rcode





GO
GRANT EXECUTE ON  [dbo].[vspRPPLOverrideDel] TO [public]
GO
