SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Huy Huynh
-- Create date: 8/1/11
-- Description:	Used in PMHotList query to return a Status for display in System Status Label.
-- =============================================
CREATE FUNCTION [dbo].[vfPMContractChangeOrderACOStatus]
(
	@PMCo bCompany, @Contract bContract, @ID smallint
)
RETURNS nvarchar(max)
AS
BEGIN

declare @Status varchar(20), @rcode int, @ACOCount smallint, @ApprovedACOCount smallint
select @rcode = 0, @ACOCount = 0, @ApprovedACOCount = 0


--Validate
if @PMCo is null
begin
	return NULL
end

if @Contract is null
begin
	return NULL
end

if @ID is null
begin
	return NULL
end


--Get record count of ACO Headers
select @ACOCount = count(distinct(h.KeyID))
from dbo.PMContractChangeOrderACO a
join dbo.PMOH h on h.PMCo=a.PMCo and h.Project=a.Project and h.ACO=a.ACO
where a.PMCo = @PMCo and a.[Contract] = @Contract and a.ID = @ID

--Get record count of ACO Headers (ReadyForAcctg=Y)
select @ApprovedACOCount = count(distinct(h.KeyID))
from dbo.PMContractChangeOrderACO a
join dbo.PMOH h on h.PMCo=a.PMCo and h.Project=a.Project and h.ACO=a.ACO
where a.PMCo = @PMCo and a.[Contract] = @Contract and a.ID = @ID and h.ReadyForAcctg = 'Y'

		
--Compare counts to set status
if @ACOCount = 0
begin
	set @Status = 'No ACOs'
end
else if @ACOCount = @ApprovedACOCount
begin
	set @Status = 'Approved'
end	
else if @ACOCount <> @ApprovedACOCount and @ApprovedACOCount <> 0
begin
	set @Status = 'Partially Approved'
end
else
begin
	set @Status = 'Not Approved'
end


return @Status

END
GO
GRANT EXECUTE ON  [dbo].[vfPMContractChangeOrderACOStatus] TO [public]
GO
