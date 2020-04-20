SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspPMContractChangeOrderACOAddPCOs]
/***********************************************************
* CREATED BY:	GP	04/12/2011
* MODIFIED BY:	GP	05/16/2011 - Added RecordAdded column to insert and rewrote insert
*				GP/GPT 06/06/2011 - TK-05795 Fixed PurchaseChange amount
*				GP/GPT 06/06/2011 - TK-05837 Fixed EstimatedChange and ContractChange amount totals. 
*				TRL 07/27/2011 - TK-07036  Added code to delete ACO Item record when it has 0 or Estimate, Purchase and Contract Amount
*				GP 11/18/2011 - TK-09987 Fixed duplicate PCO record insert
*				
* USAGE:
* Used in PM Contract Change Orders - ACO tab to add related
* PCO records
*
* INPUT PARAMETERS
*   PMCo   
*	Project
*	ACO
*
* OUTPUT PARAMETERS
*   @msg      Description of Department if found.
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/ 

(@PMCo bCompany, @Project bProject, @ACO bACO, @Contract bContract, @ID smallint, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @Seq int
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

if @ACO is null
begin
	select @msg = 'Missing ACO.', @rcode = 1
	goto vspexit
end

if exists (select top 1 1 from dbo.PMContractChangeOrderACO 
			where PMCo = @PMCo and [Contract] = @Contract   and ID = @ID and Project = @Project 
			and EstimateChange = 0 and PurchaseChange=0 and ContractChange=0 and PCO is null)
begin
	delete from dbo.vPMContractChangeOrderACO 
	where PMCo = @PMCo and [Contract] = @Contract   and ID = @ID and Project = @Project 
		and EstimateChange = 0 and PurchaseChange=0 and ContractChange=0 and PCO is null
end

--Get next Seq
select @Seq = isnull(max(Seq),0) 
from dbo.PMContractChangeOrderACO 
where PMCo = @PMCo and [Contract] = @Contract and ID = @ID;

--CTE used to sum up PMMF and PMSL amounts by PCOType and PCO
with ACO_CTE (PMCo, [Contract], ID, Project, ACO, PCOType, PCO, ACOItemPhaseCost, ACOItemCommitTotal, ACOItemRevTotal, DateAdded)
as
(
	--Returns all material and subcontract detail amounts for the PCO
	select @PMCo, @Contract, @ID, @Project, @ACO, Amt.PCOType, Amt.PCO, 
		Amt.ACOItemPhaseCost, isnull(sum(Amt.PMSLAmount) + sum(Amt.PMMFAmount), 0), Amt.ACOItemRevTotal, dbo.vfDateOnly()
	from
	(
	select distinct i.PCOType, i.PCO, [ACOItemPhaseCost]= sum(t.ACOItemPhaseCost), [PMSLAmount]=0, [PMMFAmount]=m.Amount, [ACOItemRevTotal]=sum(t.ACOItemRevTotal)
	from dbo.PMOI i  
	join dbo.PMOIACOTotals t on t.PMCo=i.PMCo and t.Project=i.Project and t.ACO=i.ACO and t.ACOItem=i.ACOItem
	left join dbo.PMMF m on m.PMCo=i.PMCo and m.Project=i.Project and m.ACO=i.ACO and m.PCO=i.PCO
	where i.PMCo = @PMCo and i.Project = @Project and i.ACO = @ACO and i.PCO is not null
	group by i.PCOType,i.PCO,m.Amount
	union
	select distinct i.PCOType, i.PCO, 0, [PMSLAmount]=l.Amount,[PMMFAmount]=0, 0
	from dbo.bPMOI i
	join dbo.PMOIACOTotals t on t.PMCo=i.PMCo and t.Project=i.Project and t.ACO=i.ACO and t.ACOItem=i.ACOItem
	left join dbo.PMSL l on l.PMCo=i.PMCo and l.Project=i.Project and l.ACO=i.ACO and l.PCO=i.PCO
	where i.PMCo = @PMCo and i.Project = @Project and i.ACO = @ACO and i.PCO is not null
	group by i.PCOType,i.PCO,l.Amount
	)
	Amt
	group by Amt.PCOType, Amt.PCO, Amt.ACOItemPhaseCost, Amt.ACOItemRevTotal	
)

----Insert related ACO records grouped by PCOType/PCO
insert dbo.vPMContractChangeOrderACO (PMCo, [Contract], ID, Project, ACO, Seq, 
	PCOType, PCO, EstimateChange, PurchaseChange, ContractChange, RecordAdded)	
select c.PMCo, c.[Contract], c.ID, c.Project, c.ACO, row_number() over(order by a.PMCo, a.[Contract], a.ID) + @Seq, 
	c.PCOType, c.PCO, sum(c.ACOItemPhaseCost), sum(c.ACOItemCommitTotal), sum(c.ACOItemRevTotal), c.DateAdded 
from ACO_CTE c
left join dbo.PMContractChangeOrderACO a on a.PMCo=@PMCo and a.[Contract]=@Contract and a.ID=@ID 
	 and a.PCOType=c.PCO and a.PCO=c.PCO
group by c.PMCo, c.[Contract], c.ID, c.Project, c.ACO, c.PCOType, c.PCO, c.DateAdded, a.PMCo, a.[Contract], a.ID


	
	
vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMContractChangeOrderACOAddPCOs] TO [public]
GO
