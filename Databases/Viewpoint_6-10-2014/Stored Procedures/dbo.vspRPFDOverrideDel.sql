SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  procedure [dbo].[vspRPFDOverrideDel]
/******************************************
* Created: TRL  10/27/2006
* Modified: GG 04/06/07 - cleanup
*
* Removes an 'overridden' Form Report Parameter assignmment.  Will only delete
* the vRPFDc entry if a standard one exists for the form, report, and parameter in vRPFD. 
*
* Custom form report parameters (w/o standard vRPFD entry) are removed via the delete 
* trigger on RPFDShared. 
*
* Inputs:
*	@form			Form name
*	@reportid		Report ID#
*	@parametername	Parameter name
*
* Output:
*	@msg		Error message
*
* Return code:
*	0 = success, 1 = error
*
*********************************************/
(@form varchar(30) = null, @reportid int = 0 , @parametername varchar(30) = null, @msg varchar(256) output)

as

set nocount on
declare @rcode int

select @rcode = 0

--make sure Form/Report/Parameter is an override, not custom
if exists(select top 1 1 from dbo.vRPFD (nolock) where Form = @form and ReportID = @reportid
			and ParameterName = @parametername)
	begin
	delete dbo.vRPFDc where Form = @form and ReportID = @reportid and ParameterName = @parametername
	end

vspexit:
	return @rcode







GO
GRANT EXECUTE ON  [dbo].[vspRPFDOverrideDel] TO [public]
GO
