SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE  proc [dbo].[vspPMPCOAutoItemCreate]
   /***********************************************************
    * Created By:	GP	02/17/2011
    * Modified By:	GP	03/09/2011 V1# B-03081 - added default PCO Item user option
    *				GP	06/22/2011 TK-06248 Changed PMOL insert to use Purchase Units/UnitCost/UM columns
    *				GP	06/23/2011 TK-06420 Added normal UM/UnitCost/Units fields back into PMOL insert
    *				GP	08/19/2011 TK-07800 Added ability to add same phase/ct PMOL records to new PCOItems
    *				GP  08/29/2011 TK-07982 Added @HeaderDesc to PMOI inserts
    *				GP	10/27/2011 TK-09452 Removed error when PCO Item does not previously exist, allows create of new PCO Item
    *				GP	10/28/2011 TK-09439 Added VendorGroup to PMOL insert by Phase
    *				JG	01/03/2012 TK-11377 Added logic to set the FixedAmountYN flag when ImpactContract is 'N'
    *				GP	01/06/2012 TK-11602 Check prefill contract item checkbox before inserting contract item into bPMOI
    *				GF  02/10/2012 TK-12465 issue #145746 use JCCH.UM for PMOL.UM NOT JCCI.UM
    *				GF  02/26/2012 TK-12845 beginning status for item
    *				GP	06/11/2012 TK-15641 Unit cost now grabs CurUnitCost instead of OrigUnitCost
    *				TL   02/15/2013 Task 40720.  Add parameter @createnewposlitem and added code to get and update new PO/SL Items
	*              STO   05/21/2013 TFS 50164. PO/SL Item -- not populating correctly. Removed JCCI PMOI restriction in where 
	*                               clause for SL/PO items added isnull check on select for assoc inserts.  
    *
    *****************************************************/
   (@PMCo bCompany, @Project bJob, @PCOType bDocType, @PCO bPCO, @KeyIDString varchar(max) = null, 
   @ViewBy varchar(10), @ImpactBudget char(1), @ImpactSL char(1), @ImpactPO char(1), @ImpactContract char(1),
   @DefaultPCOItem bPCOItem, @PrefillContractItem bYN,  @CreateNewPOSLItem bYN, @msg varchar(255) output)
   as
   set nocount on
   
declare @rcode int, @currentKeyID varchar(10), @PCOItem bPCOItem, @PCOItemMask varchar(30), @PCOItemLen smallint,
	@Status bStatus, @dummy varchar(30), @NextPCOItem varchar(30), @lastitem bPCOItem,	@UseDefaultPCOItem char(1), @HeaderDesc bItemDesc,
     @NextPOSLItem smallint, @POSL varchar(30)
	
select @rcode = 0, @UseDefaultPCOItem = 'N'

----TK-11377
DECLARE @FixedAmountYN bYN
SET @FixedAmountYN = CASE WHEN @ImpactContract = 'Y' THEN 'N' ELSE 'Y' END

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

if @PCOType is null
begin
	select @msg = 'Missing PCO Type.', @rcode = 1
	goto vspexit
end

if @PCO is null
begin
	select @msg = 'Missing PCO.', @rcode = 1
	goto vspexit
end

if @KeyIDString is null
begin
	select @msg = 'Missing selected items for create.', @rcode = 1
	goto vspexit
end

--check if PCO Item is provided from the form
if ltrim(rtrim(isnull(@DefaultPCOItem, ''))) <> ''		set @UseDefaultPCOItem = 'Y'


----------------   
--CREATE ITEMS--
----------------
--get header status
select @Status = [Status], @HeaderDesc = [Description] 
from dbo.PMOP 
where PMCo = @PMCo and Project = @Project and PCOType = @PCOType and PCO = @PCO

----TK-12845
---- if null, get begin status
IF @Status IS NULL
	BEGIN
	---- for PCO category
	select Top 1 @Status = Status
	FROM dbo.PMSC WHERE DocCat = 'PCO' AND CodeType = 'B'
	IF @@ROWCOUNT = 0
		BEGIN
		---- company begin status
		SELECT @Status = c.BeginStatus
		FROM dbo.PMCO c
		WHERE PMCo = @PMCo
		IF @@ROWCOUNT = 0 OR ISNULL(@Status,'') = ''
			BEGIN
			---- first beginning status
   			SELECT TOP 1 @Status = s.Status
   			FROM dbo.PMSC s
   			WHERE s.CodeType = 'B'
			END
		END
	END


--get PCOItem mask
select @PCOItemMask = InputMask, @PCOItemLen = InputLength from DDDTShared where Datatype = 'bPCOItem'
if isnull(@PCOItemMask,'') = ''		select @PCOItemMask = 'L'
if isnull(@PCOItemLen,'') = ''		select @PCOItemLen = '10'
if @PCOItemMask in ('R','L')	set @PCOItemMask = cast(@PCOItemLen as varchar(5)) + @PCOItemMask + 'N'

while @KeyIDString is not null
begin
	--get next keyid
	if charindex(char(44), @KeyIDString) <> 0
	begin
		select @currentKeyID = substring(@KeyIDString, 1, charindex(char(44), @KeyIDString) - 1)
	end	
	else
	begin
		select @currentKeyID = @KeyIDString	
	end	
	--remove current keyid from keystring
	select @KeyIDString = substring(@KeyIDString, len(@currentKeyID) + 2, (len(@KeyIDString) - len(@currentKeyID) + 1))
		
		
	--clear params
	select @NextPCOItem = null, @dummy = null, @lastitem = null, @PCOItem = null
	
	--use default pco item OR get next PCO Item
	if @UseDefaultPCOItem = 'Y'
	begin
		set @NextPCOItem = @DefaultPCOItem
	end
	else
	begin
		select @NextPCOItem = cast(isnull(max(PCOItem),0) as numeric) + 1 
		from dbo.PMOI with (nolock) 
		where PMCo = @PMCo and Project = @Project and PCOType = @PCOType and PCO = @PCO
			and substring(ltrim(PCOItem),1,1) not in ('+', '-') and isnumeric(PCOItem) = 1		
	end
	--set item if null & cast as string
	if @NextPCOItem = null		set @NextPCOItem = 1
	set @dummy = cast(@NextPCOItem as varchar(10))
	--format new PCOItem
	exec @rcode = dbo.bspHQFormatMultiPart @dummy, @PCOItemMask, @PCOItem output


	if @ViewBy = 'SL'
	begin
		--find if item already exists with same contract and contract item
		select top 1 @lastitem = oi.PCOItem, @POSL=sl.SL
		from dbo.PMOI oi
		join dbo.SLIT sl on sl.KeyID = @currentKeyID
		join dbo.JCJP jp on jp.JCCo = sl.JCCo and jp.Job = sl.Job and jp.PhaseGroup = sl.PhaseGroup and jp.Phase = sl.Phase
		join dbo.JCCI ci on ci.JCCo = jp.JCCo and ci.[Contract] = jp.[Contract] and ci.Item = jp.Item
		where oi.PMCo = @PMCo and oi.Project = @Project and oi.PCOType = @PCOType and oi.PCO = @PCO
		
		select @NextPOSLItem = null
		If @CreateNewPOSLItem = 'Y' 
		begin
				exec dbo.vspPMGetNextSLPOMOItem @PMCo,@ViewBy,@POSL,@NextPOSLItem output
		end

		-- TFS 50164
		If @NextPOSLItem = 0 set @NextPOSLItem = 1

		--if found and no default, set pco item
		if @lastitem is not null and @UseDefaultPCOItem = 'N'	set @PCOItem = @lastitem
		
		--check if phase/ct exists in PMOL for this item already, if so, try next item and check before insert
		if exists (select top 1 1 from dbo.PMOL ol
			join dbo.SLIT sl on sl.PhaseGroup = ol.PhaseGroup and sl.Phase = ol.Phase and sl.JCCType = ol.CostType
			where ol.PMCo = @PMCo and ol.Project = @Project and ol.PCOType = @PCOType and ol.PCO = @PCO and ol.PCOItem = @PCOItem and sl.KeyID = @currentKeyID)
		begin
			--get next pco item
			select @NextPCOItem = cast(isnull(max(PCOItem),0) as numeric) + 1 
			from dbo.PMOI with (nolock) 
			where PMCo = @PMCo and Project = @Project and PCOType = @PCOType and PCO = @PCO
				and substring(ltrim(PCOItem),1,1) not in ('+', '-') and isnumeric(PCOItem) = 1	
			--set item if null & cast as string
			if @NextPCOItem is null		set @NextPCOItem = 1
			set @dummy = cast(@NextPCOItem as varchar(10))		
			--clear PCO value & format new PCOItem
			select @PCOItem = null
			exec @rcode = dbo.bspHQFormatMultiPart @dummy, @PCOItemMask, @PCOItem output				
		end
	
		--insert item record
		----TK-11377 Added FixedAmountYN
		insert dbo.bPMOI (PMCo, Project, PCOType, PCO, PCOItem, [Contract], ContractItem, Units, UM, UnitPrice, [Status], [Description], FixedAmountYN, FixedAmount) 
		select @PMCo, @Project, @PCOType, @PCO, @PCOItem, jp.[Contract], case when @PrefillContractItem = 'Y' then jp.Item else null end, 
			0, isnull(ci.UM,'LS'), isnull(ci.UnitPrice,0), @Status, @HeaderDesc, @FixedAmountYN, 0
		from dbo.SLIT sl 
		join dbo.JCJP jp on jp.JCCo = sl.JCCo and jp.Job = sl.Job and jp.PhaseGroup = sl.PhaseGroup and jp.Phase = sl.Phase
		left join dbo.JCCI ci on ci.JCCo = jp.JCCo and ci.[Contract] = jp.[Contract] and ci.Item = jp.Item
		where sl.KeyID = @currentKeyID 
			and not exists (select top 1 1 from dbo.PMOI oi where oi.PMCo = @PMCo and oi.Project = @Project and oi.PCOType = @PCOType and oi.PCO = @PCO and oi.PCOItem = @PCOItem)
				
		--insert phase record TK-12465
		INSERT dbo.bPMOL (PMCo, Project, PCOType, PCO, PCOItem, PhaseGroup, Phase, CostType, PurchaseUnits,
					PurchaseUM, PurchaseUnitCost, Subcontract, POSLItem, VendorGroup, Vendor, UnitHours,
					ECM, SendYN, UM, UnitCost, EstUnits)
		SELECT @PMCo, @Project, @PCOType, @PCO, @PCOItem, sl.PhaseGroup, sl.Phase, sl.JCCType, 0,
					ISNULL(sl.UM,'LS'), isnull(sl.CurUnitCost,0), sl.SL, ISNULL(@NextPOSLItem,sl.SLItem), hd.VendorGroup, hd.Vendor, 0,
					'E', 'Y', ISNULL(ch.UM,'LS'), 0, 0
		FROM dbo.SLIT sl
		JOIN dbo.JCCH ch on ch.JCCo = sl.JCCo and ch.Job = sl.Job and ch.PhaseGroup = sl.PhaseGroup and ch.Phase = sl.Phase AND ch.CostType=sl.JCCType
		JOIN dbo.JCJP jp on jp.JCCo = sl.JCCo and jp.Job = sl.Job and jp.PhaseGroup = sl.PhaseGroup and jp.Phase = sl.Phase
		JOIN dbo.JCCI ci on ci.JCCo = jp.JCCo and ci.[Contract] = jp.[Contract] and ci.Item = jp.Item
		JOIN dbo.SLHD hd on hd.SLCo = sl.SLCo and hd.SL = sl.SL
		WHERE sl.KeyID = @currentKeyID
		AND NOT EXISTS(select 1 from dbo.PMOL ol where ol.PMCo = @PMCo and ol.Project = @Project 
						and ol.PCOType = @PCOType and ol.PCO = @PCO and ol.PCOItem = @PCOItem 
						and ol.PhaseGroup = sl.PhaseGroup and ol.Phase = sl.Phase 
						and ol.CostType = sl.JCCType)
												
								
	END
	else if @ViewBy = 'PO'
	begin	
		--find if item already exists with same contract and contract item
		select top 1 @lastitem = oi.PCOItem, @POSL=po.PO 
		from dbo.PMOI oi
		join dbo.POIT po on po.KeyID = @currentKeyID
		join dbo.JCJP jp on jp.JCCo = po.JCCo and jp.Job = po.Job and jp.PhaseGroup = po.PhaseGroup and jp.Phase = po.Phase
		join dbo.JCCI ci on ci.JCCo = jp.JCCo and ci.[Contract] = jp.[Contract] and ci.Item = jp.Item
		where oi.PMCo = @PMCo and oi.Project = @Project and oi.PCOType = @PCOType and oi.PCO = @PCO
		
		select @NextPOSLItem = null
		If @CreateNewPOSLItem = 'Y' 
		begin
				exec dbo.vspPMGetNextSLPOMOItem @PMCo,@ViewBy,@POSL,@NextPOSLItem output
		end

		-- TFS 50164
		If @NextPOSLItem = 0 set @NextPOSLItem = 1

		--if found and no default, set pco item
		if @lastitem is not null and @UseDefaultPCOItem = 'N'	set @PCOItem = @lastitem
		
		--check if phase/ct exists in PMOL for this item already, if so, try next item and check before insert
		if exists (select top 1 1 from dbo.PMOL ol
			join dbo.POIT po on po.PhaseGroup = ol.PhaseGroup and po.Phase = ol.Phase and po.JCCType = ol.CostType
			where ol.PMCo = @PMCo and ol.Project = @Project and ol.PCOType = @PCOType and ol.PCO = @PCO and ol.PCOItem = @PCOItem and po.KeyID = @currentKeyID)
		begin
			--get next pco item
			select @NextPCOItem = cast(isnull(max(PCOItem),0) as numeric) + 1 
			from dbo.PMOI with (nolock) 
			where PMCo = @PMCo and Project = @Project and PCOType = @PCOType and PCO = @PCO
				and substring(ltrim(PCOItem),1,1) not in ('+', '-') and isnumeric(PCOItem) = 1	
			--set item if null & cast as string
			if @NextPCOItem is null		set @NextPCOItem = 1
			set @dummy = cast(@NextPCOItem as varchar(10))		
			--clear PCO value & format new PCOItem
			select @PCOItem = null
			exec @rcode = dbo.bspHQFormatMultiPart @dummy, @PCOItemMask, @PCOItem output				
		end		
	
		--insert item record
		----TK-11377 Added FixedAmountYN
		insert dbo.bPMOI (PMCo, Project, PCOType, PCO, PCOItem, [Contract], ContractItem, Units, UM, UnitPrice, [Status], [Description], FixedAmountYN, FixedAmount)
		select @PMCo, @Project, @PCOType, @PCO, @PCOItem, jp.[Contract], case when @PrefillContractItem = 'Y' then jp.Item else null end, 
			0, isnull(ci.UM,'LS'), isnull(ci.UnitPrice,0), @Status, @HeaderDesc, @FixedAmountYN, 0
		from dbo.POIT po 
		join dbo.JCJP jp on jp.JCCo = po.JCCo and jp.Job = po.Job and jp.PhaseGroup = po.PhaseGroup and jp.Phase = po.Phase
		left join dbo.JCCI ci on ci.JCCo = jp.JCCo and ci.[Contract] = jp.[Contract] and ci.Item = jp.Item
		where po.KeyID = @currentKeyID
			and not exists (select top 1 1 from dbo.PMOI oi where oi.PMCo = @PMCo and oi.Project = @Project and oi.PCOType = @PCOType and oi.PCO = @PCO and oi.PCOItem = @PCOItem)
		
		--insert phase record TK-12465
		INSERT dbo.bPMOL (PMCo, Project, PCOType, PCO, PCOItem, PhaseGroup, Phase, CostType, PurchaseUnits,
						PurchaseUM, PurchaseUnitCost, PO, POSLItem, VendorGroup, Vendor, UnitHours,
						ECM, SendYN, UM, UnitCost, EstUnits)
		SELECT @PMCo, @Project, @PCOType, @PCO, @PCOItem, po.PhaseGroup, po.Phase, po.JCCType, 0,
						ISNULL(po.UM,'LS'), isnull(po.CurUnitCost,0), po.PO, ISNULL(@NextPOSLItem,po.POItem), hd.VendorGroup, hd.Vendor, 0,
						'E', 'Y', ISNULL(ch.UM,'LS'), 0 , 0
		FROM dbo.POIT po
		JOIN dbo.JCCH ch on ch.JCCo = po.JCCo and ch.Job = po.Job and ch.PhaseGroup = po.PhaseGroup and ch.Phase = po.Phase AND ch.CostType=po.JCCType
		JOIN dbo.JCJP jp on jp.JCCo = po.JCCo and jp.Job = po.Job and jp.PhaseGroup = po.PhaseGroup and jp.Phase = po.Phase
		JOIN dbo.JCCI ci on ci.JCCo = jp.JCCo and ci.[Contract] = jp.[Contract] and ci.Item = jp.Item
		JOIN dbo.POHD hd on hd.POCo = po.POCo and hd.PO = po.PO
		WHERE po.KeyID = @currentKeyID
		AND NOT EXISTS(SELECT 1 FROM dbo.PMOL ol WHERE ol.PMCo = @PMCo and ol.Project = @Project
					and ol.PCOType = @PCOType and ol.PCO = @PCO and ol.PCOItem = @PCOItem
					and ol.PhaseGroup = po.PhaseGroup and ol.Phase = po.Phase and ol.CostType = po.JCCType)
	end
	else if @ViewBy = 'PHASE'
	begin
		--find if item already exists with same contract and contract item
		select top 1 @lastitem = oi.PCOItem
		from dbo.PMOI oi
		join dbo.JCCH ct on ct.KeyID = @currentKeyID
		join dbo.JCJP jp on jp.JCCo = ct.JCCo and jp.Job = ct.Job and jp.PhaseGroup = ct.PhaseGroup and jp.Phase = ct.Phase 
		join dbo.JCCI ci on ci.JCCo = jp.JCCo and ci.[Contract] = jp.[Contract] and ci.Item = jp.Item
		where oi.PMCo = @PMCo and oi.Project = @Project and oi.PCOType = @PCOType and oi.PCO = @PCO and oi.[Contract] = ci.[Contract] and oi.ContractItem = ci.Item
		
		--if found and no default, set pco item
		if @lastitem is not null and @UseDefaultPCOItem = 'N'	set @PCOItem = @lastitem
		
		--check if phase/ct exists in PMOL for this item already, if so, try next item and check before insert
		if exists (select top 1 1 from dbo.PMOL ol
			join dbo.JCCH ct on ct.PhaseGroup = ol.PhaseGroup and ct.Phase = ol.Phase and ct.CostType = ol.CostType
			where ol.PMCo = @PMCo and ol.Project = @Project and ol.PCOType = @PCOType and ol.PCO = @PCO and ol.PCOItem = @PCOItem and ct.KeyID = @currentKeyID)
		begin
			--get next pco item
			select @NextPCOItem = cast(isnull(max(PCOItem),0) as numeric) + 1 
			from dbo.PMOI with (nolock) 
			where PMCo = @PMCo and Project = @Project and PCOType = @PCOType and PCO = @PCO
				and substring(ltrim(PCOItem),1,1) not in ('+', '-') and isnumeric(PCOItem) = 1	
			--set item if null & cast as string
			if @NextPCOItem is null		set @NextPCOItem = 1
			set @dummy = cast(@NextPCOItem as varchar(10))		
			--clear PCO value & format new PCOItem
			select @PCOItem = null
			exec @rcode = dbo.bspHQFormatMultiPart @dummy, @PCOItemMask, @PCOItem output				
		end		
	
		--insert item
		----TK-11377 Added FixedAmountYN
		insert dbo.bPMOI (PMCo, Project, PCOType, PCO, PCOItem, [Contract], ContractItem, Units, UM, UnitPrice, [Status], [Description], FixedAmountYN, FixedAmount)
		select @PMCo, @Project, @PCOType, @PCO, @PCOItem, jp.[Contract], case when @PrefillContractItem = 'Y' then jp.Item else null end, 
			0, ci.UM, isnull(ci.UnitPrice,0), @Status, @HeaderDesc, @FixedAmountYN, 0
		from dbo.JCCH ct
		join dbo.JCJP jp on jp.JCCo = ct.JCCo and jp.Job = ct.Job and jp.PhaseGroup = ct.PhaseGroup and jp.Phase = ct.Phase 
		join dbo.JCCI ci on ci.JCCo = jp.JCCo and ci.[Contract] = jp.[Contract] and ci.Item = jp.Item		
		where ct.KeyID = @currentKeyID
			and not exists (select top 1 1 from dbo.PMOI oi where oi.PMCo = @PMCo and oi.Project = @Project and oi.PCOType = @PCOType and oi.PCO = @PCO and oi.PCOItem = @PCOItem)
		
		--insert phase record TK-12465
		insert dbo.bPMOL (PMCo, Project, PCOType, PCO, PCOItem, PhaseGroup, Phase, CostType, PurchaseUnits,
					PurchaseUM, PurchaseUnitCost, UnitHours, ECM, SendYN, UM, UnitCost, EstUnits, VendorGroup)
		select @PMCo, @Project, @PCOType, @PCO, @PCOItem, ct.PhaseGroup, ct.Phase, ct.CostType, 0,
					ISNULL(ct.UM,'LS'), ISNULL(ci.UnitPrice,0), 0, 'E', 'Y', ISNULL(ct.UM,'LS'), 0, 0, hq.VendorGroup
		from dbo.JCCH ct
		join dbo.JCJP jp on jp.JCCo = ct.JCCo and jp.Job = ct.Job and jp.PhaseGroup = ct.PhaseGroup and jp.Phase = ct.Phase 
		join dbo.JCCI ci on ci.JCCo = jp.JCCo and ci.[Contract] = jp.[Contract] and ci.Item = jp.Item
		join dbo.PMCO pm on pm.PMCo = @PMCo
		join dbo.HQCO hq on	hq.HQCo = pm.APCo		
		where ct.KeyID = @currentKeyID
		and not exists (select 1 from dbo.PMOL ol where ol.PMCo = @PMCo and ol.Project = @Project
						and ol.PCOType = @PCOType and ol.PCO = @PCO and ol.PCOItem = @PCOItem 
						and ol.PhaseGroup = ct.PhaseGroup and ol.Phase = ct.Phase and ol.CostType = ct.CostType)	
	end
	
	--get the final value
	if charindex(char(44), @KeyIDString) = 0	
		set @KeyIDString = @KeyIDString + char(44)
	--set string to null if no values left
	if len(@KeyIDString) < 2		
		set @KeyIDString = null
end


   
vspexit:
   	return @rcode




GO
GRANT EXECUTE ON  [dbo].[vspPMPCOAutoItemCreate] TO [public]
GO
