SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspDDDeleteFormReports]
/********************************
* Created: GG 09/19/06  
* Modified:	
*
* Called from Form Properties to remove a custom linked Report
* from a specific Form.
*
* Input:
*	@form			current Form name
*	@rerportid		Report ID# to remove
*
* Output:
*	@errmsg		error message
*	
* Return code:
*	0 = success, 1 = failure
*
*********************************/
(@form varchar(30) = null, @reportid int = null, @errmsg varchar(255) output)
as
	
set nocount on
	
declare @rcode int
	
select @rcode = 0

if @form is null or @reportid is null 
	begin
	select @errmsg = 'Missing parameter values, cannot delete linked Report!', @rcode = 1
	goto vspexit
	end

-- check standard linked Reports
if exists(select top 1 1 from dbo.vRPFR (nolock)
			where Form = @form and ReportID = @reportid)
	begin
	select @errmsg = convert(varchar,@reportid) + ' is a standard Report and can not be deleted.', @rcode = 1
	goto vspexit
	end

-- remove any custom Report defaults and header record
delete vRPFDc where Form = @form and ReportID = @reportid

delete vRPFRc where Form = @form and ReportID = @reportid

vspexit:
	return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspDDDeleteFormReports] TO [public]
GO
