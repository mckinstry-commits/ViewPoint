SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE  procedure [dbo].[vspRPFROverrideDel]
/******************************************
* Created: TRL  10/27/2006
* Modified: GG 04/06/07 - cleanup
*
* Removes an 'overridden' Form Report assignmment.  Will only delete
* the vRPFRc entry if a standard one exists for the form and report in vRPFR. 
*
* Custom form reports (w/o standard vRPFR entry) are removed via the delete 
* trigger on RPRFShared. 
*
* Inputs:
*	@form			Form name
*	@reportid		Report ID#
*
* Output:
*	@msg		Error message
*
* Return code:
*	0 = success, 1 = error
*
*********************************************/
(@form varchar(30) = null, @reportid int = 0 , @msg varchar(256) output)

as

set nocount on
declare @rcode int

select @rcode = 0

--make sure Form/Report is an override, not custom
if exists(select top 1 1 from dbo.vRPFR (nolock) where Form = @form and ReportID = @reportid)
	begin
	delete dbo.vRPFRc where Form = @form and ReportID = @reportid
	end

vspexit:
	return @rcode





GO
GRANT EXECUTE ON  [dbo].[vspRPFROverrideDel] TO [public]
GO
