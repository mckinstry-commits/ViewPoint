SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  proc [dbo].[vspPMPCOAutoItemFill]
/***********************************************************
* Created By:	GP	02/16/2011
* Modified By:	GP	04/04/2011 - limit sl records to exclude item type 3 and 4, and po to item type 1.
*				GP	07/20/2012 TK-16478 - Added join to JCJP and check for Contract
*				GP	07/23/2012 TK-16566 - Changed SL and PO joins to look at item tables
*
*****************************************************/
(@PMCo bCompany, @Project bJob, @ViewBy varchar(10), @Contract bContract, @msg varchar(255) output)
as
set nocount on
   
declare @rcode int, @SLCo bCompany 
select @rcode = 0

--------------
--VALIDATION--
--------------
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

if @ViewBy is null
begin
	select @msg = 'Missing View by.', @rcode = 1
	goto vspexit
end

------------   
--GET DATA--
------------
--get slco		
select @SLCo = APCo from dbo.PMCO where PMCo = @PMCo

if @ViewBy = 'SL' --vendor (SL)
begin
	select h.Vendor, a.Name, i.SL, i.SLItem, i.Phase, i.JCCType as [CostType], i.[Description], i.KeyID
	from dbo.SLIT i
	join dbo.SLHD h on h.SLCo = i.SLCo and h.SL = i.SL
	join dbo.APVM a on a.VendorGroup = h.VendorGroup and a.Vendor = h.Vendor
	join dbo.JCJP j on j.JCCo = i.JCCo and j.Job = i.Job and j.PhaseGroup = i.PhaseGroup and j.Phase = i.Phase
	where i.SLCo = @SLCo and i.Job = @Project and h.[Status] = 0 and i.ItemType not in (3,4) and j.[Contract] = @Contract
	order by h.Vendor, i.SL, i.SLItem, i.Phase, i.JCCType
end
else if @ViewBy = 'PO' --vendor (PO)
begin
	select h.Vendor, a.Name, i.PO, i.POItem, i.Phase, i.JCCType as [CostType], i.[Description], i.KeyID
	from dbo.POIT i
	join dbo.POHD h on h.POCo = i.POCo and h.PO = i.PO
	join dbo.APVM a on a.VendorGroup = h.VendorGroup and a.Vendor = h.Vendor
	join dbo.JCJP j on j.JCCo = i.JCCo and j.Job = i.Job and j.PhaseGroup = i.PhaseGroup and j.Phase = i.Phase
	where i.POCo = @SLCo and i.Job = @Project and h.[Status] = 0 and i.ItemType = 1  and j.[Contract] = @Contract
	order by h.Vendor, i.PO, i.POItem, i.Phase, i.JCCType
end
else if @ViewBy = 'PHASE' --phase 
begin
	select p.Phase, p.[Description] as [Phase Description], c.CostType, t.[Description], c.KeyID
	from dbo.JCJPPM p
	join dbo.PMCO co on co.PMCo = p.PMCo
	join dbo.JCCHPM c on c.JCCo = p.JCCo and c.Job = p.Job and c.PhaseGroup = p.PhaseGroup and c.Phase = p.Phase
	join dbo.JCCT t on t.PhaseGroup = c.PhaseGroup and t.CostType = c.CostType 
	where p.PMCo = @PMCo and p.Project = @Project and p.[Contract] = @Contract
	order by p.Phase, c.CostType
end


   
vspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMPCOAutoItemFill] TO [public]
GO
