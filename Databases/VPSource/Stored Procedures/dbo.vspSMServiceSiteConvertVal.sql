SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspSMServiceSiteConvertVal]
/***********************************************************
* CREATED BY:	GP	1/20/2012 - TK11894
* MODIFIED BY:	Chris G 7/25/12 - D-05523 - Allow revert to Job if WOs are only Job specific
*				
* USAGE:
* Used in SM Service Site before converting to check
* if a site has work orders posted for it before allowing
* conversion. Also returns the previous job value if the
* user wishes to revert.
*
* INPUT PARAMETERS
*   SMServiceSiteID		Primary key for vSMServiceSite   
*
* OUTPUT PARAMETERS
*	@WorkOrderExists	bYN to identify that work orders were found for this site
*	@JCCo				JC Company previously used on a site
*	@Job 				Job previously used on a site
*   @msg				Error message if found
*
* RETURN VALUE
*   0		Success
*   1		Failure
*****************************************************/ 

(@SMServiceSiteID int, @WorkOrderExists bYN output, @JCCo bCompany = null output, @Job bJob = null output, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @SMCo bCompany, @ServiceSite varchar(20)
select @rcode = 0, @WorkOrderExists = 'N'


--Validate
if @SMServiceSiteID is null
begin
	select @msg = 'Missing SMServiceSiteID.', @rcode = 1
	goto vspexit
end

--Get additional info from service site table
select @SMCo = SMCo, @ServiceSite = ServiceSite, @JCCo = JCCo, @Job = Job
from dbo.vSMServiceSite
where SMServiceSiteID = @SMServiceSiteID

--Check for existing work orders
if exists (select 1 from dbo.vSMWorkOrder where SMCo = @SMCo and ServiceSite = @ServiceSite and Job is null)
begin
	select @msg = 'Customer work orders exist for this site.', @WorkOrderExists = 'Y', @rcode = 1
	goto vspexit
end
	
	
	
vspexit:
	return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspSMServiceSiteConvertVal] TO [public]
GO
