SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/***********************************************************
* CREATED BY:	GP	12/19/2011 - TK-11049
* MODIFIED BY:	GP	4/27/2012 - TK-14560 Added join to PMOI to return approved status, removed check for ACO in where clause
*				GP	5/2/2011 - TK-14635 Changed select to look at PMOL to get Notes column
*				
* USAGE:
* Used in PM Subcontract CO and Purchase Order CO to
* return dataset for list view of available PMSL and PMMF
* records to add to each form.
*
* INPUT PARAMETERS
*   PMCo   
*	Project
*	SL
*	PO
*
* OUTPUT PARAMETERS
*   @msg      Description of Department if found.
*
* RETURN VALUE
*   0         Success
*   1         Failure
*****************************************************/ 
CREATE PROC [dbo].[vspPMSubPOCOGetPCOList]
(@PMCo bCompany, @Project bContract, @SL varchar(30) = NULL, @PO varchar(30) = NULL, @msg varchar(255) output)
as
set nocount on

declare @rcode int
set @rcode = 0


--Validate
if @PMCo is null
begin
	select @msg = 'Missing PM Company.', @rcode = 1
	goto vspexit
end

if @Project is null
begin
	select @msg = 'Missing Project.', @rcode = 1
	goto vspexit
end

--Get Subcontract and Material Detail
if @SL is not null
begin
	select sl.Project, case when p.ACO is null then 'Not Approved' else 'Approved' end as [Status], p.ACO, p.ACOItem, 
		sl.PCOType as [PCO Type], sl.PCO, sl.PCOItem as [PCO Item], 
		sl.SLItemDescription as [Description], sl.Phase, sl.CostType as [Cost Type], sl.Units, sl.UM, 
		sl.UnitCost as [Unit Cost], sl.Amount, p.Notes, sl.Vendor, sl.SL, sl.SLItem as [SL Item], sl.KeyID
	from dbo.PMSL sl
	left join dbo.PMOL p on p.PMCo = sl.PMCo and p.Project = sl.Project and p.PCOType = sl.PCOType and p.PCO = sl.PCO and p.PCOItem = sl.PCOItem and p.Subcontract = sl.SL
	where sl.PMCo = @PMCo and sl.Project = @Project and sl.SL = @SL and sl.PCO is not null and sl.SubCO is null 
end
else if @PO is not null
begin
	select mf.Project, case when p.ACO is null then 'Not Approved' else 'Approved' end as [Status], p.ACO, p.ACOItem, 
		mf.PCOType as [PCO Type], mf.PCO, mf.PCOItem as [PCO Item], 
		mf.MaterialCode as [Material], mf.MtlDescription as [Description], mf.Phase, mf.CostType as [Cost Type], mf.Units, mf.UM, 
		mf.UnitCost as [Unit Cost], mf.Amount, p.Notes, mf.Vendor, mf.PO, mf.POItem as [PO Item], mf.KeyID
	from dbo.PMMF mf
	left join dbo.PMOL p on p.PMCo = mf.PMCo and p.Project = mf.Project and p.PCOType = mf.PCOType and p.PCO = mf.PCO and p.PCOItem = mf.PCOItem and p.PO = mf.PO
	where mf.PMCo = @PMCo and mf.Project = @Project and mf.PO = @PO and mf.PCO is not null and mf.POCONum is null
end

	
	
vspexit:
	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspPMSubPOCOGetPCOList] TO [public]
GO
