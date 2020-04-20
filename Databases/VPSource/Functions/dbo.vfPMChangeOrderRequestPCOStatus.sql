SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Huy Huynh
-- Create date: 8/1/11
-- Description:	Used in PMHotList query to return a Status for display in System Status Label.
-- =============================================
CREATE FUNCTION [dbo].[vfPMChangeOrderRequestPCOStatus]
(
	@PMCo bCompany, @Contract bContract, @ID smallint
)
RETURNS nvarchar(max)
AS
BEGIN

declare @Status varchar(20), @rcode int, @RecordCount smallint, @ApprovedCount smallint
select @rcode = 0, @RecordCount = 0, @ApprovedCount = 0


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

--Get record counts
select @RecordCount = count(distinct(l.KeyID))
from dbo.PMChangeOrderRequestPCO a
join dbo.PMOL l on l.PMCo=a.PMCo and l.Project=a.Project and l.PCOType=a.PCOType and l.PCO=a.PCO
where a.PMCo = @PMCo and a.[Contract] = @Contract and a.COR = @ID

select @ApprovedCount = count(distinct(l.KeyID))
from dbo.PMChangeOrderRequestPCO a
join dbo.PMOL l on l.PMCo=a.PMCo and l.Project=a.Project and l.PCOType=a.PCOType and l.PCO=a.PCO
where a.PMCo = @PMCo and a.[Contract] = @Contract and a.COR = @ID and l.ACO is not null
	
--Compare counts to set status
if @RecordCount = 0
begin
	set @Status = 'No PCOs'
end
else if @RecordCount = @ApprovedCount
begin
	set @Status = 'Approved'
end	
else if @ApprovedCount <> 0 and @RecordCount > @ApprovedCount
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
GRANT EXECUTE ON  [dbo].[vfPMChangeOrderRequestPCOStatus] TO [public]
GO
