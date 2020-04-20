SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspJCJMValForCOR]
/***********************************************************
* CREATED BY:	GP 03/15/2011 - V1# B-02920
* MODIFIED By:	
*
* USAGE:
* Validates JC Job
* and checks that it is on the correct
* contract in PM Change Order Request.
*
* INPUT PARAMETERS
*   JCCo   JC Co to validate against 
*   Job    Job to validate
*	Contract
*
* OUTPUT PARAMETERS                    
*   @msg      error message if error occurs otherwise Description of Job
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/ 
(@JCCo bCompany, @Job bJob, @Contract bContract, @msg varchar(60) output)
as
set nocount on

declare @rcode int, @ContractForJob bContract, @JobStatus bStatus
select @rcode = 0
   
   
--VALIDATION--   
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

if @Contract is null
begin
	select @msg = 'Missing Contract.', @rcode = 1
	goto vspexit
end


--CHECK JOB/CONTRACT--
exec @rcode = dbo.vspJCJMVal @JCCo, @Job, @ContractForJob output, null, @JobStatus output, @msg output
     
if @rcode = 1	goto vspexit     
     
if @Contract <> @ContractForJob
begin
	select @msg = 'Project: ' + @Job + ' is assigned to Contract: ' + @ContractForJob + '.', @rcode = 1
	goto vspexit
end     
  
if @JobStatus not in (0,1)
begin
	select @msg = 'Project status must be Pending or Open.', @rcode = 1
	goto vspexit
end    
 
   
   
vspexit:
	return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspJCJMValForCOR] TO [public]
GO
