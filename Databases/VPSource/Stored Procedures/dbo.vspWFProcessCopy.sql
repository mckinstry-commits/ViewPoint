SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE  proc [dbo].[vspWFProcessCopy]
/***********************************************************
* CREATED BY:	GP - 2/29/2012
* MODIFIED BY:	NH - 3/06/2012 - procedure was copying incorrect data as part of steps
*				JG - 3/09/2012 - TK-13110 - Removed Actions from HQApprovalProcessStep.
*				JG - 3/09/2012 - TK-13121 - Added ApproverOptional flag.
*				JG - 3/13/2012 - TK-00000 - Removed requirement of DocType
*				GF - 06/11/2012 TK-15205 removed unused columns
*				
* USAGE:
* Used in WF Process Copy.
*
* INPUT PARAMETERS
*   KeyID - KeyID of record to copy data from   
*   Process - new Process value
*	Description - new Process Description value
*	Type - new Process Type value
*
* OUTPUT PARAMETERS
*	NewRecordKeyID - KeyID of newly created record
*   msg
*
* RETURN VALUE
*   0         Success
*   1         Failure
*****************************************************/ 

(@KeyID bigint, @Process varchar(20), @Description bItemDesc, @DocType varchar(10), @OptionApprovalSteps bYN, 
@NewRecordKeyID bigint output, @msg varchar(255) output)
as
set nocount on

declare @rcode int
set @rcode = 0

--VALIDATION
if @KeyID is null
begin
	select @msg = 'Missing parent record KeyID.', @rcode = 1
	return @rcode
end

if @Process is null
begin
	select @msg = 'Missing Process.', @rcode = 1
	return @rcode
end

if exists (select 1 from dbo.vWFProcess where Process = @Process)
begin
	select @msg = 'The record you are copying to already exists.', @rcode = 1
	return @rcode
end

--COPY
insert dbo.vWFProcess (Process, DocType, [Description], Active, DaysPerStep, DaysToRemind, Notes)
select @Process, @DocType, @Description, Active, DaysPerStep, DaysToRemind, Notes
from dbo.vWFProcess
where KeyID = @KeyID

--Get KeyID from inserted record
set @NewRecordKeyID = SCOPE_IDENTITY()

-- NH - changed fourth select column from s.[Type] to s.ApproverType
--Insert option records
if @OptionApprovalSteps = 'Y'
BEGIN
	----TK-15205
	insert dbo.vWFProcessStep (Process, Seq, ApproverType, UserName, [Role], Step, ApprovalLimit,
		ApproverOptional, Notes)
	select @Process, s.Seq, s.ApproverType, s.UserName, s.[Role], s.Step, s.ApprovalLimit,
		s. ApproverOptional, s.Notes
	from dbo.vWFProcess p
	join dbo.vWFProcessStep s on s.Process = p.Process
	where p.KeyID = @KeyID
end

GO
GRANT EXECUTE ON  [dbo].[vspWFProcessCopy] TO [public]
GO
