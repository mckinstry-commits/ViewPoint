SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Huy Huynh
-- Create date: 8/1/11
-- Description:	Used in PMHotList query to return a Status for display in System Status Label.
-- =============================================
CREATE FUNCTION [dbo].[vfPMACOStatus]
(
	@PMCo bCompany, @Contract bContract, @Project bProject, @ACO bACO
)
RETURNS nvarchar(max)
AS
BEGIN

declare @Status nvarchar(max), @rcode int, @NotInterfacedCount smallint, @ReadyForAccounting bYN, @AssignedToCCO bYN, @ACOItemsExist bYN
select @rcode = 0, @NotInterfacedCount = 0, @AssignedToCCO = 'N', @ACOItemsExist = 'N'


--Get record count of non interfaced items for the ACO
select @NotInterfacedCount = count(1) 
from dbo.PMOI 
where PMCo = @PMCo and Project = @Project and ACO = @ACO and InterfacedDate is null

--Find out if ACO Items exist
if exists (select top 1 1 from dbo.PMOI where PMCo = @PMCo and Project = @Project and ACO = @ACO)
begin
	set @ACOItemsExist = 'Y'
end
	
--Get the ready for accounting flag	
select @ReadyForAccounting = ReadyForAcctg from dbo.PMOH where PMCo = @PMCo and Project = @Project and ACO = @ACO	

--Find out if ACO belongs to a Contract Change Order (CCO)
if exists (select top 1 1 from PMContractChangeOrderACO where PMCo = @PMCo and [Contract] = @Contract and Project = @Project and ACO = @ACO)
begin
	set @AssignedToCCO = 'Y'
end

	
--Set status based on above values	
if @ACOItemsExist = 'N'
begin
	set @Status = 'No Detail Records'
end
else if @NotInterfacedCount = 0
begin
	set @Status = 'Approved and Interfaced'
end	
else if @ReadyForAccounting = 'Y' and @AssignedToCCO = 'Y'
begin
	set @Status = 'Approved Contract Change Order'
end
else if @ReadyForAccounting = 'N' and @AssignedToCCO = 'Y'
begin
	set @Status = 'Pending Contract Change Order'
end
else if @ReadyForAccounting = 'Y'	
begin
	set @Status = 'Approved'
end
else if @ReadyForAccounting = 'N'	
begin
	set @Status = 'Not Approved'
end	
			
		
		return @Status
END

GO
GRANT EXECUTE ON  [dbo].[vfPMACOStatus] TO [public]
GO
