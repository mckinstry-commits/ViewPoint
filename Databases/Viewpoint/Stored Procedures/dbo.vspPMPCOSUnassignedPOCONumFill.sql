SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE proc [dbo].[vspPMPCOSUnassignedPOCONumFill]
/*****************************************
* Created By:	TRL	04/15/2011 TK-04279
* Modified By:	GF 06/15/2011 TK-06131
*				GP 06/21/2011 TK-15940 Changed join to POHD to not use Job, removed join to PMCO
*				GP 07/25/2012 TK-16592 removed check for ACO in where clause
*
******************************************/
(@PMCo bCompany = NULL,@Project bProject = NULL, @PCO bPCO = NULL, 
 @PCOType bPCOType = NULL, @errmsg varchar(255) output)

as
set nocount on
   
declare @rcode int, @POCo bCompany 

select @rcode = 0

if @PMCo is null
begin
	select @errmsg = 'Missing PM Company.', @rcode = 1
	goto vspexit
end

if @Project is null
begin
	select @errmsg = 'Missing Project.', @rcode = 1
	goto vspexit
end

if @PCOType is null
begin
	select @errmsg = 'Missing PCO Type.', @rcode = 1
	goto vspexit
end

if @PCO is null
begin
	select @errmsg = 'Missing PCO.', @rcode = 1
	goto vspexit
end

---- get POCO	
select @POCo = APCo from dbo.PMCO where PMCo = @PMCo

select o.Vendor, a.Name, o.PO, o.POSLItem as [PO Item], o.Phase, o.CostType as [Cost Type],m.MaterialCode,
m.MtlDescription as [Description],m.VendMatId as [Vendor Matl Id],
m.UM, m.Units,m.ECM,m.Amount,o.PCOItem, o.KeyID as [PCOItem KeyID],m.KeyID as [POItem KeyID]
from dbo.PMOL o
join dbo.APVM a on o.VendorGroup = a.VendorGroup and o.Vendor = a.Vendor
join dbo.PMMF m on o.PMCo = m.PMCo and o.Project = m.Project 
	and o.PhaseGroup = m.PhaseGroup and o.Phase = m.Phase and o.CostType = m.CostType
	and o.PCO = m.PCO and o.PCOType = m.PCOType and o.PCOItem = m.PCOItem
	and o.VendorGroup = m.VendorGroup and o.Vendor = m.Vendor
	and o.PO = m.PO and o.POSLItem = m.POItem
join dbo.POHD h on h.POCo = m.POCo and h.PO = m.PO
where o.PMCo = @PMCo and o.Project = @Project and o.PCOType = @PCOType  and o.PCO = @PCO and m.POCo=@POCo 
and IsNull(o.PO,'') <> '' and o.POSLItem is not null and o.Vendor is not null  
and o.POCONum is null 
and m.MaterialOption = 'P'
----TK-06131
AND h.Approved = 'Y'
-- not already assigned to PO CO Num and must exist in PMMF (i.e. interfaced)
--AND m.POCONum IS NULL and m.POMth is null

order by o.Vendor, o.PO, o.POSLItem, o.Phase, o.CostType,m.MaterialCode,m.MtlDescription, m.KeyID
If @@rowcount = 0 
begin
	select @errmsg = 'No change detail exists from which to create a PO CO Number.', @rcode = 1
	goto vspexit
end

   
vspexit:
   	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspPMPCOSUnassignedPOCONumFill] TO [public]
GO
