SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE proc [dbo].[vspPMPCOSUnassignedSubCOFill]
/*****************************************
* Created By:	TRL	03/16/2011
* Modified By:	GF 03/25/2011 TK-03354
*				GF 06/15/2011 TK-06131
*				GF 02/15/2012 TK-12263 #145805 change joins and where clause for available PMSL detail
*				GP 07/25/2012 TK-16592 removed check for ACO in where clause
*
******************************************/
(@PMCo bCompany = NULL,@Project bProject = NULL, @PCO bPCO = NULL, 
 @PCOType bPCOType = NULL, @errmsg varchar(255) output)

as
set nocount on
   
declare @rcode int, @SLCo bCompany 

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

---- get slco		
select @SLCo = APCo from dbo.PMCO where PMCo = @PMCo

select o.Vendor, a.Name, o.Subcontract as [SL], o.POSLItem as [SL Item], o.Phase,
		o.CostType as [Cost Type], s.SLItemDescription as [Description],o.PCOItem,
		o.KeyID as [PCOItem KeyID],s.KeyID as [SLItem KeyID]
from dbo.PMOL o
join dbo.APVM a on o.VendorGroup = a.VendorGroup and o.Vendor = a.Vendor
join dbo.PMSL s on o.PMCo = s.PMCo and o.Project = s.Project 
	and o.PhaseGroup = s.PhaseGroup and o.Phase = s.Phase and o.CostType = s.CostType
	and o.PCO = s.PCO and o.PCOType = s.PCOType and o.PCOItem = s.PCOItem
	and o.VendorGroup = s.VendorGroup and o.Vendor = s.Vendor
	and o.Subcontract = s.SL and o.POSLItem = s.SLItem
----BEG TK-12263
join dbo.SLHD h ON s.SLCo = h.SLCo AND s.SL = h.SL 
	--on s.PMCo = h.JCCo and s.Project = h.Job 
	--and s.SLCo = h.SLCo and s.SL = h.SL 
	--and s.VendorGroup = h.VendorGroup and s.Vendor = h.Vendor
--join dbo.PMCO c on o.PMCo = c.PMCo NOT NEEDED
----END TK-12263
where o.PMCo = @PMCo
	AND o.Project = @Project
	AND o.PCOType = @PCOType
	AND o.PCO = @PCO
	AND s.SLCo=@SLCo 
	and IsNull(o.Subcontract,'') <> ''
	AND o.POSLItem is not NULL
	AND o.Vendor is not null  
	AND o.SubCO is NULL
	--TK-03354 not already assigned to subco and must exist in SLIT (i.e. interfaced)
	AND s.SubCO IS NULL
	AND s.SLItemType In (1,2)
	----TK-06131
	AND h.Approved = 'Y'
	----TK-12263
	AND s.InterfaceDate IS NULL


order by o.Vendor, o.Subcontract, o.POSLItem, o.Phase, o.CostType,s.SLItemDescription, s.KeyID
If @@rowcount = 0 
begin
	select @errmsg = 'No change detail exists from which to create a SubCO.', @rcode = 1
	goto vspexit
end

   
vspexit:
   	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspPMPCOSUnassignedSubCOFill] TO [public]
GO
