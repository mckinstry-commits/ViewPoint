SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE function [dbo].[vfJCJobClosedWarning]
	(@jcco bCompany = null, @value varchar(10) = null, @ContractOrJob varchar(1) = 'J')
returns varchar(20)
/***********************************************************
* CREATED BY:	GF 01/13/2008
* MODIFIED BY:
*
*
* USAGE:
* Returns JC Closed Job Status string
*
* INPUT PARAMETERS:
* JC Company
* Value					(Job or Contract)
* Contract or Job Flag	('C', 'J')
*
* OUTPUT PARAMETERS:
* Job status string
*	
*
*****************************************************/
as
begin

declare @status_label varchar(20), @status tinyint

select @status_label = ''

if @jcco is null or @value is null goto exitfunction

if @ContractOrJob = 'C'
	begin
	---- get status from JCCM
	select @status=ContractStatus
	from JCCM with (nolock) where JCCo=@jcco and Contract=@value
	if @@rowcount = 0 select @status = 1
	end

if @ContractOrJob = 'J'
	begin
	---- get status from JCJM
	select @status=JobStatus
	from JCJM with (nolock) where JCCo=@jcco and Job=@value
	if @@rowcount = 0 select @status = 1
	end

---- set the closed status label
if @status = 2
	begin
	select @status_label = 'Soft-Closed'
	end
if @status = 3
	begin
	select @status_label = 'Hard-Closed'
	end


exitfunction:
  			
return @status_label
end

GO
GRANT EXECUTE ON  [dbo].[vfJCJobClosedWarning] TO [public]
GO
