SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspJCJMValForSM]
/***********************************************************
* CREATED BY:	GP 1/17/2012 - TK-11525
* MODIFIED BY:	GP 1/24/2012 - TK-11894 Added customer from JCCM as output param
*
* USAGE:
*	Used to validate JC Job from SM and 
*	return Job Status, Project Manager and Shipping Address.
*
* INPUT PARAMETERS
*	JCCo		JC Company to validate 
*	Job			Job to validate
*
* OUTPUT PARAMETERS
*	@JobDesc	Returns a description of the job
*	@msg		Error message if error occurs otherwise Description of Job
*
* RETURN VALUE
*	0			Success
*   1			 Failure
*****************************************************/ 
(	@JCCo bCompany, @Job bJob, 
	@JobDesc bItemDesc output, @JobStatus bStatus output, @ProjectManager int output,
	@ShipAddress varchar(60) output, @ShipCity varchar(30) output, @ShipState varchar(4) output,
	@ShipZipCode bZip output, @ShipCountry char(2) output, @ShipAddress2 varchar(60) output, 
	@Phone bPhone output, @Customer bCustomer output,
	@msg varchar(60) output)

as
set nocount on  
   
declare @rcode int


if @JCCo is null
begin
	select @msg = 'Missing JC Company.', @rcode = 1
	goto vspexit
end

if @Job is null
begin
	select @msg = 'Missing Job.', @rcode = 1
	goto vspexit
end


--Get values from Job Master
select @msg = JCJM.[Description], @JobStatus = JCJM.JobStatus, @ProjectManager = JCJM.ProjectMgr,
	@ShipAddress = JCJM.ShipAddress, @ShipCity = JCJM.ShipCity, @ShipState = JCJM.ShipState, @ShipZipCode = JCJM.ShipZip, 
	@ShipCountry = JCJM.ShipCountry, @ShipAddress2 = JCJM.ShipAddress2, @Phone = JCJM.JobPhone,
	@Customer = JCCM.Customer
from dbo.JCJM
left join dbo.JCCM on JCCM.JCCo = JCJM.JCCo and JCCM.[Contract] = JCJM.[Contract]
where JCJM.JCCo = @JCCo and JCJM.Job = @Job 

if @@rowcount = 0
begin
	select @msg = 'Job not on file.', @rcode = 1
	goto vspexit
end
   	

   
vspexit:
	select @JobDesc = @msg
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCJMValForSM] TO [public]
GO
