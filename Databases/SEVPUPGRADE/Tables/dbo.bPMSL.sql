CREATE TABLE [dbo].[bPMSL]
(
[PMCo] [dbo].[bCompany] NOT NULL,
[Project] [dbo].[bJob] NOT NULL,
[Seq] [int] NOT NULL,
[RecordType] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPMSL_RecordType] DEFAULT ('O'),
[PCOType] [dbo].[bDocType] NULL,
[PCO] [dbo].[bPCO] NULL,
[PCOItem] [dbo].[bPCOItem] NULL,
[ACO] [dbo].[bACO] NULL,
[ACOItem] [dbo].[bACOItem] NULL,
[Line] [tinyint] NULL,
[PhaseGroup] [dbo].[bGroup] NULL,
[Phase] [dbo].[bPhase] NULL,
[CostType] [dbo].[bJCCType] NULL,
[VendorGroup] [dbo].[bGroup] NULL,
[Vendor] [dbo].[bVendor] NULL,
[SLCo] [dbo].[bCompany] NOT NULL,
[SL] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[SLItem] [dbo].[bItem] NULL,
[SLItemDescription] [dbo].[bItemDesc] NULL,
[SLItemType] [tinyint] NULL,
[SLAddon] [tinyint] NULL,
[SLAddonPct] [dbo].[bPct] NULL,
[Units] [dbo].[bUnits] NOT NULL,
[UM] [dbo].[bUM] NOT NULL,
[UnitCost] [dbo].[bUnitCost] NOT NULL,
[Amount] [dbo].[bDollar] NOT NULL,
[SubCO] [smallint] NULL,
[WCRetgPct] [dbo].[bPct] NULL,
[SMRetgPct] [dbo].[bPct] NULL,
[Supplier] [dbo].[bVendor] NULL,
[InterfaceDate] [dbo].[bDate] NULL,
[SendFlag] [dbo].[bYN] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[SLMth] [dbo].[bMonth] NULL,
[SLTrans] [dbo].[bTrans] NULL,
[IntFlag] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[TaxType] [tinyint] NULL,
[TaxCode] [dbo].[bTaxCode] NULL,
[TaxGroup] [dbo].[bGroup] NULL,
[udSource] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[udConv] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[udSLContractNo] [varchar] (15) COLLATE Latin1_General_BIN NULL,
[udCMSItem] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[udCGCTable] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[udCGCTableID] [decimal] (12, 0) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/****** Object:  Trigger dbo.btPMSLd    Script Date: 09/05/2006 ******/
CREATE trigger [dbo].[btPMSLd] on [dbo].[bPMSL] for DELETE as
/*--------------------------------------------------------------
 * Created By:	GF 01/15/2007 6.x HQMA auditing
 * Modified By:	GF 11/02/2010 - issue #141957 record association
 *				GF 03/26/2011 - TK-03289
 *				DAN SO 04/21/2011 - TK-04287 - removing SCO information from PMOL
 *				GF 06/22/2011 - D-02339 use view not tables for links
 *				DAN SO 01/09/2012 - TK-11562 - clear out Subcontract and POSLItem
 *				DAN SO 01/16/2012 - TK-11562 - backed out changes
 *				JayR 03/26/2012 TK-00000 Cleanup unused variables
 * Delete trigger for bPMSL
 *
 *
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on



---- delete subcontract association if only no others detail exists for ACO
---- record side ACO
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN dbo.vPMSubcontractCO h ON h.SLCo=d.SLCo AND h.SL=d.SL AND h.SubCO=d.SubCO
INNER JOIN dbo.bPMOH c ON c.PMCo=d.PMCo AND c.Project=d.Project AND c.ACO=d.ACO
INNER JOIN dbo.vPMRelateRecord a ON a.RecTableName='PMSubcontractCO' AND a.RECID=h.KeyID AND a.LinkTableName='PMOH' AND a.LINKID=c.KeyID
WHERE d.ACO IS NOT NULL AND d.SubCO IS NOT NULL
AND NOT EXISTS(SELECT 1 FROM dbo.bPMSL x WHERE x.PMCo=d.PMCo AND x.Project=d.Project AND x.ACO=d.ACO AND x.SubCO=d.SubCO)
---- link side aCO
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN dbo.vPMSubcontractCO h ON h.SLCo=d.SLCo AND h.SL=d.SL AND h.SubCO=d.SubCO
INNER JOIN dbo.bPMOH c ON c.PMCo=d.PMCo AND c.Project=d.Project AND c.ACO=d.ACO
INNER JOIN dbo.vPMRelateRecord a ON a.RecTableName='PMOH' AND a.RECID=c.KeyID AND a.LinkTableName='PMSubcontractCO' AND a.LINKID=h.KeyID
WHERE d.ACO IS NOT NULL AND d.SubCO IS NOT NULL
AND NOT EXISTS(SELECT 1 FROM dbo.bPMSL x WHERE x.PMCo=d.PMCo AND x.Project=d.Project AND x.ACO=d.ACO AND x.SubCO=d.SubCO)

---- delete subcontract association if only no others detail exists for ACO
---- record side
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN dbo.bSLHD h ON h.SLCo=d.SLCo AND h.SL=d.SL
INNER JOIN dbo.bPMOH c ON c.PMCo=d.PMCo AND c.Project=d.Project AND c.ACO=d.ACO
INNER JOIN dbo.vPMRelateRecord a ON a.RecTableName='PMOH' AND a.RECID=c.KeyID AND a.LinkTableName='SLHD' AND a.LINKID=h.KeyID
WHERE d.SL IS NOT NULL AND d.ACO IS NOT NULL
AND NOT EXISTS(SELECT 1 FROM dbo.bPMSL x WHERE x.PMCo=d.PMCo AND x.Project=d.Project AND x.ACO=d.ACO AND x.SL=d.SL)
---- link side
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN dbo.bSLHD h ON h.SLCo=d.SLCo AND h.SL=d.SL
INNER JOIN dbo.bPMOH c ON c.PMCo=d.PMCo AND c.Project=d.Project AND c.ACO=d.ACO
INNER JOIN dbo.vPMRelateRecord a ON a.RecTableName='SLHD' AND a.RECID=h.KeyID AND a.LinkTableName='PMOH' AND a.LINKID=c.KeyID
WHERE d.SL IS NOT NULL AND d.ACO IS NOT NULL
AND NOT EXISTS(SELECT 1 FROM dbo.bPMSL x WHERE x.PMCo=d.PMCo AND x.Project=d.Project AND x.ACO=d.ACO AND x.SL=d.SL)


---- delete subcontract association if only no others detail exists for ACO
---- record side PCO
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN dbo.vPMSubcontractCO h ON h.SLCo=d.SLCo AND h.SL=d.SL AND h.SubCO=d.SubCO
INNER JOIN dbo.bPMOP c ON c.PMCo=d.PMCo AND c.Project=d.Project AND c.PCOType=d.PCOType AND c.PCO=d.PCO
INNER JOIN dbo.vPMRelateRecord a ON a.RecTableName='PMSubcontractCO' AND a.RECID=h.KeyID AND a.LinkTableName='PMOP' AND a.LINKID=c.KeyID
WHERE d.PCO IS NOT NULL AND d.SubCO IS NOT NULL
AND NOT EXISTS(SELECT 1 FROM dbo.bPMSL x WHERE x.PMCo=d.PMCo AND x.Project=d.Project AND x.PCOType=d.PCOType AND x.PCO=d.PCO AND x.SubCO=d.SubCO)
---- link side PCO
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN inserted i ON i.KeyID=d.KeyID
INNER JOIN dbo.vPMSubcontractCO h ON h.SLCo=d.SLCo AND h.SL=d.SL AND h.SubCO=d.SubCO
INNER JOIN dbo.bPMOP c ON c.PMCo=d.PMCo AND c.Project=d.Project AND c.PCOType=d.PCOType AND c.PCO=d.PCO
INNER JOIN dbo.vPMRelateRecord a ON a.RecTableName='PMOP' AND a.RECID=c.KeyID AND a.LinkTableName='PMSubcontractCO' AND a.LINKID=h.KeyID
WHERE d.PCO IS NOT NULL AND d.SubCO IS NOT NULL
AND NOT EXISTS(SELECT 1 FROM dbo.bPMSL x WHERE x.PMCo=d.PMCo AND x.Project=d.Project AND x.PCOType=d.PCOType AND x.PCO=d.PCO AND x.SubCO=d.SubCO)

---- delete subcontract association if only no others detail exists for PCO
---- record side
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN dbo.bSLHD h ON h.SLCo=d.SLCo AND h.SL=d.SL
INNER JOIN dbo.bPMOP c ON c.PMCo=d.PMCo AND c.Project=d.Project AND c.PCOType=d.PCOType AND c.PCO=d.PCO
INNER JOIN dbo.vPMRelateRecord a ON a.RecTableName='PMOP' AND a.RECID=c.KeyID AND a.LinkTableName='SLHD' AND a.LINKID=h.KeyID
WHERE d.SL IS NOT NULL AND d.PCO IS NOT NULL
AND NOT EXISTS(SELECT 1 FROM dbo.bPMSL x WHERE x.PMCo=d.PMCo
			AND x.Project=d.Project AND x.PCOType=d.PCOType AND x.PCO=d.PCO AND x.SL=d.SL)
---- link side
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN dbo.bSLHD h ON h.SLCo=d.SLCo AND h.SL=d.SL
INNER JOIN dbo.bPMOP c ON c.PMCo=d.PMCo AND c.Project=d.Project AND c.PCOType=d.PCOType AND c.PCO=d.PCO
INNER JOIN dbo.vPMRelateRecord a ON a.RecTableName='SLHD' AND a.RECID=h.KeyID AND a.LinkTableName='PMOP' AND a.LINKID=c.KeyID
WHERE d.SL IS NOT NULL AND d.PCO IS NOT NULL
AND NOT EXISTS(SELECT 1 FROM dbo.PMSL x WHERE x.PMCo=d.PMCo
			AND x.Project=d.Project AND x.PCOType=d.PCOType AND x.PCO=d.PCO AND x.SL=d.SL)






--------------
-- TK-04287 --
--------------
UPDATE	ol
   SET	SubCO = NULL,
		SubCOSeq = NULL,
		Subcontract = NULL,
		POSLItem = NULL
  FROM	dbo.bPMOL ol
  JOIN	deleted d ON ol.PMCo=d.PMCo AND ol.Project=d.Project
   AND	ol.Phase=d.Phase AND ol.CostType=d.CostType
 WHERE	ol.SubCO = d.SubCO
   AND	ol.SubCOSeq = d.Seq



-- Audit inserts
insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bPMSL','PMCo: ' + isnull(convert(char(3),d.PMCo), '') + ' Project: ' + isnull(d.Project,'')
		+ ' Seq: ' + isnull(convert(varchar(10),d.Seq),'') + ' Phase: ' + isnull(d.Phase,'')
		+ ' CostType: ' + isnull(convert(varchar(3),d.CostType),''), d.PMCo, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
from deleted d join bPMCO c on c.PMCo = d.PMCo
where d.PMCo = c.PMCo and c.AuditPMSL = 'Y'


RETURN 






GO

GO

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPMSLi    Script Date: 8/28/99 9:38:24 AM ******/
CREATE  trigger [dbo].[btPMSLi] on [dbo].[bPMSL] for INSERT as
/*--------------------------------------------------------------
* Insert trigger for PMSL
* Created By:	LM 12/22/97  
* Modified By: GF 05/03/2000
*              GF 05/30/2001 - added validation for units <> 0 and UM='LS'
*              DANF 09/06/02 - 17738 Added Phase Group to bspJCADDCOSTTYPE
*				GF 10/09/2002 - changed dbl quotes to single quotes
*				GF 09/10/2003 - issue #22398 - added check for duplicate SL item with different
*								phase/costtype/um combination
*				GF 01/15/2007 - 6.x HQMA auditing
*				GF 03/13/2008 - issue #127436 changed logic to add project firm contact to use bPMSS info if possible
*				GF 07/24/2008 - issue #129065 need to check PMOL for existance by pending or approved not both
*				GF 09/19/2008 - issue #129811 subcontract tax
*				GF 03/12/2010 - issue #138547 - SLHD.Vendor must match PMSL.Vendor when SL assigned.
*				GF 06/28/2010 - issue #135813 SL expanded to 30 characters
*				GF 11/02/2010 - issue #141957 record association
*				GF 11/05/2010 - issue #141031 change to use date function.
*				GF 11/19/2010 - issue #141715 use pm company subcontract option for PMOL units and costs
*				GF 02/21/2011 - B-02385 create PMSubcontractCO record when adding SubCO to PMSL
*				GF 03/02/2011 - TK-01846 use impact budget and sub types when adding to PMOL
*				GF 03/26/2011 - TK-03289 SUBCO
*				GF 05/11/2011 - TK-05178 TK-05205
*				GF 06/20/2011 - TK-06121
*				GF 06/22/2011 - D-02339 use view not tables for links
*				GF 11/02/2011 TK-09613 do not allow subco for different jobs
*				JayR 03/27/2012 TK-00000 Change to use FKs and table constraints for some of the validation
*				GF 05/17/2012 TK-13889 if SubCO is assigned to an ACO, approve the SCO
*				GF 06/20/2012 TK-15931 cleanup, check PMOL for match and sync purchase values if found.
*				GF 07/03/2012 TK-16127 only approve SCO from an ACO and SCO does not exist
*				GF 11/09/2012 TK-18033 SL Claim Enhancement. Changed to Use ApprovalRequired
*				AW 03/15/2013 TFS 43659 - support new check box for creating a new SL
*
*--------------------------------------------------------------*/
declare @numrows int, @errmsg varchar(255), @validcnt int, @validcnt2 int, @validcnt3 int,
		@rcode int,
   		@pmco bCompany, @project bJob, @seq int, @phasegroup bGroup, @phase bPhase, 
   		@costtype bJCCType, @pmslum bUM, @um bUM, @slco bCompany, @vendorgroup bGroup, 
   		@vendor bVendor, @sl VARCHAR(30), @slcompgroup varchar(10), @description bItemDesc,
   		@recordtype char(1), 
   		@pcotype bPCOType, @pco bDocument, @pcoitem bPCOItem, @aco bDocument, @acoitem bACOItem, 
   		@units bUnits, @unitcost bUnitCost, @estcost bDollar, @sendyn bYN, 
   		@unithours bHrs, @esthours bHrs, @hourcost bUnitCost, @phaseum bUM, @retcode int, 
   		@retmsg varchar(150), @origdate bDate, @slitemdescription bItemDesc, @slitem bItem,
		@sendtofirm bVendor, @sendtocontact bEmployee, @slhd_vendor bVendor,
		@subItemPhase bPhase, @subItemCostType bJCCType, @subItemUM bUM,
		@SLID BIGINT, @ACOID BIGINT, @PCOID BIGINT, @slct1option TINYINT,
		----TK-01846 B-02385
		@SubCO SMALLINT	, @SubCO_Status VARCHAR(6), @BudgetType CHAR(1), @SubType CHAR(1),
		@PurchaseAmt bDollar, @PurchaseUnits bUnits, @PurchaseUM bUM, @PurchaseUnitCost bUnitCost,
		----TK-09613
		@SCO_JCCo bCompany, @SCO_Job bJob

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

---- Get current date 141031
set @origdate = dbo.vfDateOnly()

---- if assigned to a SL the VendorGroup/Vendor must match SL
-- There is a conflicting index so I did not switch this one to FKs for validation
SELECT @validcnt = COUNT(*) FROM inserted i LEFT JOIN dbo.bSLHD h ON
		h.SLCo=i.SLCo AND h.SL=i.SL AND h.VendorGroup=i.VendorGroup
		AND h.Vendor=i.Vendor WHERE i.SL IS NOT NULL
SELECT @validcnt2 = COUNT(*) FROM inserted i WHERE i.SL IS NULL
if @validcnt + @validcnt2 <> @numrows
	BEGIN
	SELECT @errmsg = 'Vendor is Invalid for Subcontract'
	goto error
	END



if @numrows = 1
	begin
   	select @pmco=PMCo, @project=Project, @seq=Seq
	from inserted
	end
else
	begin
   	---- use a cursor to process each inserted row
   	declare bPMSL_insert cursor LOCAL FAST_FORWARD for select PMCo, Project, Seq
   	from inserted
   
   	open bPMSL_insert
   
	fetch next from bPMSL_insert into @pmco, @project, @seq
	if @@fetch_status <> 0
		begin
   		select @errmsg = 'Cursor error'
   		goto error
   		end
	end


insert_check:
---- get inserted data
select @phasegroup=PhaseGroup, @phase=Phase, @costtype=CostType, @pmslum=UM, @slco=SLCo, 
   		@vendorgroup=VendorGroup, @vendor=Vendor, @sl=SL, @slitem=SLItem, @slitemdescription=SLItemDescription, 
   		@recordtype=RecordType, @pcotype=PCOType, @pco=PCO, @pcoitem=PCOItem, @aco=ACO, @acoitem=ACOItem, 
   		@units=Units, @unitcost=UnitCost, @estcost=Amount, @sendyn=SendFlag,
   		----B-02385
   		@SubCO = SubCO
from inserted where PMCo=@pmco and Project=@project and Seq=@seq

---- get compliance group from JCJM
select @slcompgroup = SLCompGroup from bJCJM with (nolock) where JCCo = @pmco and Job = @project

---- check if SL and SubCO not null that company and job are same
----TK-09613
IF @sl IS NOT NULL AND @SubCO IS NOT NULL
	BEGIN
	---- verify same JCCo and Job
	SET @SCO_JCCo = NULL
	SET @SCO_Job = NULL
	SELECT @SCO_JCCo = PMCo, @SCO_Job = Project
	FROM dbo.vPMSubcontractCO WHERE SLCo=@slco AND SL=@sl AND SubCO=@SubCO
	IF @@ROWCOUNT <> 0
		BEGIN
		IF @SCO_JCCo <> @pmco
   			BEGIN
   			SELECT @errmsg = 'Invalid SubCO, assigned to a different Company.'
   			GOTO error
   			END
		--IF @SCO_Job <> @project
  -- 			BEGIN
  -- 			SELECT @errmsg = 'Invalid SubCO, assigned to a different Job.'
  -- 			GOTO error
  -- 			END
   		END
	END
	
---- get beginning status for SubCO from PMSC B-02385
SET @SubCO_Status = NULL
select Top 1 @SubCO_Status = Status
FROM dbo.bPMSC WHERE DocCat = 'SUBCO' AND CodeType = 'B'
----TK-05205
IF @@ROWCOUNT = 0
	BEGIN
	SELECT @SubCO_Status = BeginStatus
	FROM dbo.bPMCO WHERE PMCo=@pmco
	END
	
---- glet sl cost type option #141715
SET @slct1option = 2
select @slct1option=SLCT1Option
from dbo.bPMCO with (nolock) where PMCo=@pmco
IF ISNULL(@slct1option,0) = 0 SET @slct1option = 2

--- validate pending change order
if @recordtype = 'C'
   	begin
   	if isnull(@pcotype,'') <> ''
   		begin
   		if not exists(select top 1 1 from bPMOI where PMCo=@pmco and Project=@project
   					and PCOType=@pcotype and PCO=@pco and PCOItem=@pcoitem)
   			begin
   			select @errmsg = 'PCO is invalid: PCOType: ' + isnull(@pcotype,'') + ' PCO: ' + isnull(@pco,'') + ' PCOItem: ' + isnull(@pcoitem,'') + ' !'
   			goto error
   			end
   		end

   	---- validate approved change order
   	if isnull(@aco,'') <> ''
   		begin
   		if not exists(select top 1 1 from bPMOI where PMCo=@pmco and Project=@project
   					and ACO=@aco and ACOItem=@acoitem)
   			begin
   			select @errmsg = 'ACO is invalid: ACO: ' + isnull(@aco,'') + ' ACOItem: ' + isnull(@acoitem,'') + ' !'
   			goto error
   			end
   		end
   	end


if @phase is not null
   	begin
   	---- validate standard phase - if it doesnt exist in JCJP try to add it
   	exec @rcode = dbo.bspJCADDPHASE @pmco, @project, @phasegroup, @phase, 'Y', null, @errmsg output
   	if @rcode<>0
   		begin
   		select @errmsg = @errmsg + ' - Error adding phase to job phases.'
   		GoTo error
   		End

   	---- validate Cost Type - if JCCH doesnt exist try to add it
   	exec @rcode = dbo.bspJCADDCOSTTYPE @jcco=@pmco, @job=@project, @phasegroup=@phasegroup, @phase=@phase,
    	                @costtype=@costtype, @um=@pmslum, @override= 'P', @msg=@errmsg output
   	if @rcode<>0
   		begin
   		select @errmsg = @errmsg + ' - Error adding cost type to JCCH.'
   		GoTo error
   		End
   	End


---- check for duplicate with different assigned phase/costtype/um combination
if @recordtype = 'O' and @sl is not null
   	begin
   	-- check for duplicate item record with different phase/costtype/um combination
   	if exists(select 1 from dbo.bPMSL with (nolock) where PMCo=@pmco and Project=@project and SLCo=@slco
   		and Vendor=@vendor and SL=@sl and SLItem=@slitem and Seq<>@seq and InterfaceDate is null
   		and RecordType='O' and (Phase<>@phase or CostType<>@costtype or UM<>@pmslum))
   		begin
   		select @errmsg = 'SL: ' + isnull(@sl,'') + ' SLItem: ' + convert(varchar(8),isnull(@slitem,0)) 
   					+ ' - Multiple records set up for same item with different Phase/CostType/UM combination.'
   	    goto error
   	    end
   	end

if @recordtype = 'C' and @sl is not null
   	begin
   	---- check for duplicate item record with different phase/costtype/um combination
   	if exists(select 1 from dbo.bPMSL with (nolock) where PMCo=@pmco and Project=@project and SLCo=@slco
   		and Vendor=@vendor and SL=@sl and SLItem=@slitem and Seq<>@seq and InterfaceDate is null
   		and RecordType='C' and (Phase<>@phase or CostType<>@costtype or UM<>@pmslum))
   		begin
   		select @errmsg = 'SL: ' + isnull(@sl,'') + ' SLItem: ' + convert(varchar(8),isnull(@slitem,0)) 
   					+ ' - Multiple records set up for same item with different Phase/CostType/UM combination.'
   	    goto error
   	    END
   	---- #138547
	---- get vendor from SLHD if SL exists. compare to PMSL vendor if one assigned. Must match
	select @slhd_vendor = Vendor from dbo.bSLHD h with (nolock) where h.SLCo=@slco and h.SL=@sl
	if @@rowcount <> 0
		BEGIN
		if isnull(@slhd_vendor,'') <> isnull(@vendor,'')
			BEGIN
			select @errmsg = 'SL: ' + isnull(@sl,'') + ' Vendor: ' + convert(varchar(10),isnull(@slhd_vendor,0)) 
   					+ ' does not match subcontract detail vendor: ' + convert(varchar(10),isnull(@vendor,0)) + '.'
   			goto error
			END
		END
   	end
   	---- #138547

---- Validate SL/insert SL
if @sl is not null
   	begin
	---- check SLIT for item, if found phase/costtype must exist
   	select @subItemPhase = Phase, @subItemCostType = JCCType, @subItemUM = UM
   	from dbo.bSLIT where SLCo=@slco and SL=@sl and SLItem=@slitem
   	if @@rowcount <> 0
   		begin
   		if @subItemPhase <> @phase or @subItemCostType <> @costtype or @subItemUM <> @pmslum
   			begin
			select @errmsg = 'SL: ' + isnull(@sl,'') + ' SLItem: ' + convert(varchar(8),isnull(@slitem,0)) 
   					+ ' - Multiple records set up for same item with different Phase/CostType/UM combination.'
			goto error
			END
		end
		
   	if not exists (select top 1 1 from dbo.bSLHD with (nolock) where SLCo=@slco and SL=@sl)
   		begin
   		----select @description = substring(@slitemdescription,1,30)
   		insert bSLHD (SLCo, SL, JCCo, Job, Description, VendorGroup, Vendor, Status, PayTerms, 
   				CompGroup, Purge, Approved, OrigDate
				----TK-18033
				,ApprovalRequired)
   		select @slco, @sl, @pmco, @project, @slitemdescription, @vendorgroup, @vendor, 3, m.PayTerms, 
   				@slcompgroup, 'N', 'N', @origdate
				----TK-18033
				,'N'
   		from bAPVM m with (nolock) where m.VendorGroup=@vendorgroup and m.Vendor=@vendor
   		if @@rowcount <> 1
   			begin
   			select @errmsg = ' Cannot insert into SLHD '
   			goto error
   			end
   		end

	---- insert SendTo info in bPMSS if needed
	if not exists(select 1 from dbo.bPMSS with (nolock) where PMCo=@pmco and Project=@project
					and SLCo=@slco and SL=@sl)
		begin
		exec @retcode = bspPMSSInitialize @pmco, @project, @slco, @sl, @retmsg output
		end

	---- insert Project Firm if needed check bPMSS to see if we have a send to firm and contact
	select @sendtofirm=SendToFirm, @sendtocontact=SendToContact
	from dbo.bPMSS with (nolock) where PMCo=@pmco and Project=@project and SLCo=@slco and SL=@sl
	and SendToFirm is not null and SendToContact is not null
	if @@rowcount <> 0
		begin
		if not exists(select 1 from dbo.bPMPF with (nolock) where PMCo=@pmco and Project=@project
				and FirmNumber=@sendtofirm and ContactCode=@sendtocontact)
			begin
			exec @retcode = bspPMPFirmContactDistAdd @pmco, @project, @vendorgroup, @sendtofirm, @sendtocontact, @retmsg output
			end
		end
	else
		begin
		if not exists(select 1 from dbo.bPMPF with (nolock) where PMCo=@pmco and Project=@project
					and VendorGroup=@vendorgroup and FirmNumber=@vendor)
			begin
			exec @retcode = bspPMSLFirmContactInit @pmco, @project, @vendorgroup, @vendor, @retmsg output
			end
		end
	end

---- Add a record to change order detail if this is a change order and not already in PMOL
----TK-01846
if @recordtype='C' AND @slct1option <> 1
   	begin
	if isnull(@pcotype,'') <> '' and isnull(@pco,'') <> ''
		BEGIN
		----TK-01846
		SELECT @BudgetType=BudgetType, @SubType=SubType
		FROM dbo.bPMOP where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco 
		
		---- check the pending detail for phase and cost type
   		if not exists (select top 1 1 from dbo.bPMOL where PMCo=@pmco 
   					and Project=@project and PCOType=@pcotype and PCO=@pco and PCOItem=@pcoitem
   					and PhaseGroup=@phasegroup and Phase=@phase and CostType=@costtype)
   			begin
   			SET @unithours = 0
   			SET	@esthours = 0
   			SET @hourcost = 0
   			select @phaseum=UM 
   			from dbo.bJCCH
   			where JCCo=@pmco 
   				and Job=@project 
   				and PhaseGroup=@phasegroup
   				and Phase=@phase 
   				and CostType=@costtype
   			---- if no JCCH record found use PMSL um
   			IF @@ROWCOUNT = 0 SET @phaseum = @pmslum
   			
   			---- set purchase values if PCO set up for subcontract impact type TK-05178
   			IF @SubType = 'Y'
   				BEGIN
   				SET @PurchaseUM = @pmslum
   				SET @PurchaseUnits = @units
   				SET @PurchaseUnitCost = @unitcost
				SET @PurchaseAmt = @estcost
				END
			ELSE
				BEGIN
				SET @PurchaseUM = NULL
   				SET @PurchaseUnits = 0
   				SET @PurchaseUnitCost = 0
				SET @PurchaseAmt = 0
				END
				
   			---- TK-06039
   			---- if the JCCH um <> PMSL UM then zero out estimate values
			if @phaseum <> @pmslum
   				 begin
   				 select @units=0, @unitcost=0
   				 END
   			
   			----#141715
			if @slct1option = 3
				begin
				SET @units = 0
				SET @unitcost=0
				SET @estcost = 0
				END

			---- TK-01846 we need to check the PCO impact types to set what we actual update to PMOL
			IF @BudgetType = 'N'
				BEGIN
				SET @units = 0
				SET @unitcost=0
				SET @estcost = 0
				END
				

   			---- insert change order detail record TK-01846
   			insert bPMOL (PMCo, Project, PCOType, PCO, PCOItem, ACO, ACOItem, PhaseGroup, Phase, CostType,
   						  EstUnits, UM, UnitHours, EstHours, HourCost, UnitCost, ECM, EstCost, SendYN,
   						  VendorGroup, Vendor, Subcontract, POSLItem, SubCO, SubCOSeq,
   						  PurchaseUnits, PurchaseUM, PurchaseUnitCost, PurchaseAmt)
   			values (@pmco, @project, @pcotype, @pco, @pcoitem, @aco, @acoitem, @phasegroup,
   					@phase, @costtype, @units, @phaseum, @unithours, @esthours, @hourcost, 
   					@unitcost, 'E', @estcost, @sendyn, @vendorgroup,
   					CASE WHEN @SubType = 'Y' THEN @vendor ELSE NULL END,
   					CASE WHEN @SubType = 'Y' THEN @sl ELSE NULL END,
   					CASE WHEN @SubType = 'Y' THEN @slitem ELSE NULL END,
   					CASE WHEN @SubType = 'Y' AND @SubCO IS NOT NULL THEN @SubCO ELSE NULL END,
   					CASE WHEN @SubType = 'Y' AND @SubCO IS NOT NULL THEN @seq ELSE NULL END,
   					----TK-06121
   					CASE WHEN @SubType = 'Y' THEN @PurchaseUnits ELSE 0 END,
   					CASE WHEN @SubType = 'Y' THEN @PurchaseUM ELSE NULL END,
   					CASE WHEN @SubType = 'Y' THEN @PurchaseUnitCost ELSE 0 END,
   					CASE WHEN @SubType = 'Y' THEN @PurchaseAmt ELSE 0 END
   					)
   			end
		end
	else
		begin
		---- check the approved detail for phase and cost type
   		if not exists (select top 1 1 from dbo.bPMOL with (nolock) where PMCo=@pmco 
   						and Project=@project and ACO=@aco and ACOItem=@acoitem 
   						and PhaseGroup=@phasegroup and Phase=@phase and CostType=@costtype)
   			BEGIN
   			
   			----TK-01846
			SET @BudgetType='Y'
			SET @SubType='Y'
			---- if the ACO is from the PCO then check bPMOP for Type flags TK-01846
			IF @pco IS NOT NULL
				BEGIN
				SELECT @BudgetType=BudgetType, @SubType=SubType
				FROM dbo.bPMOP where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco 
				END
			
			---- set estimate cost
   			SET @unithours = 0
   			SET @esthours = 0
   			SET @hourcost = 0
   			select @phaseum=UM 
   			from dbo.bJCCH 
   			where JCCo=@pmco 
   				and Job=@project 
   				and PhaseGroup=@phasegroup 
   				and Phase=@phase 
   				and CostType=@costtype
   			---- if no JCCH record found use PMSL um
   			IF @@ROWCOUNT = 0 SET @phaseum = @pmslum
   			
   			---- set purchase values if PCO set up for subcontract impact type TK-05178
   			IF @SubType = 'Y'
   				BEGIN
   				SET @PurchaseUM = @pmslum
   				SET @PurchaseUnits = @units
   				SET @PurchaseUnitCost = @unitcost
				SET @PurchaseAmt = @estcost
				END
			ELSE
				BEGIN
				SET @PurchaseUM = NULL
   				SET @PurchaseUnits = 0
   				SET @PurchaseUnitCost = 0
				SET @PurchaseAmt = 0
				END
				
   			---- TK-06039
   			---- if the JCCH um <> PMSL UM then zero out estimate values
			if @phaseum <> @pmslum
   				 begin
   				 select @units=0, @unitcost=0
   				 END
   			
   			----#141715
			if @slct1option = 3
				begin
				SET @units = 0
				SET @unitcost=0
				SET @estcost = 0
				END
   			
			---- TK-01846 we need to check the PCO impact types to set what we actual update to PMOL
			IF @BudgetType = 'N'
				BEGIN
				SET @units = 0
				SET @unitcost=0
				SET @estcost = 0
				END
				
   			---- insert change order detail record TK-01846
   			insert bPMOL (PMCo, Project, PCOType, PCO, PCOItem, ACO, ACOItem, PhaseGroup, Phase, CostType,
   						  EstUnits, UM, UnitHours, EstHours, HourCost, UnitCost, ECM, EstCost, SendYN,
   						  VendorGroup, Vendor, Subcontract, POSLItem, SubCO, SubCOSeq,
   						  PurchaseUnits, PurchaseUM, PurchaseUnitCost, PurchaseAmt)
   			values (@pmco, @project, @pcotype, @pco, @pcoitem, @aco, @acoitem, @phasegroup,
   					@phase, @costtype, @units, @phaseum, @unithours, @esthours, @hourcost, 
   					@unitcost, 'E', @estcost, @sendyn, @vendorgroup,
   					CASE WHEN @SubType = 'Y' THEN @vendor ELSE NULL END,
   					CASE WHEN @SubType = 'Y' THEN @sl ELSE NULL END,
   					CASE WHEN @SubType = 'Y' THEN @slitem ELSE NULL END,
   					CASE WHEN @SubType = 'Y' THEN @SubCO ELSE NULL END,
   					CASE WHEN @SubType = 'Y' THEN @seq ELSE NULL END,
   					----TK-06121
   					CASE WHEN @SubType = 'Y' THEN @PurchaseUnits ELSE 0 END,
   					CASE WHEN @SubType = 'Y' THEN @PurchaseUM ELSE NULL END,
   					CASE WHEN @SubType = 'Y' THEN @PurchaseUnitCost ELSE 0 END,
   					CASE WHEN @SubType = 'Y' THEN @PurchaseAmt ELSE 0 END
   					)
   			end
		end
   	end


---- assigned to a subcontract: #141957
---- TK-03289 create subcontract change order if needed
IF @sl IS NOT NULL AND @SubCO IS NOT NULL
	BEGIN
	IF NOT EXISTS(SELECT 1 FROM dbo.vPMSubcontractCO WHERE SLCo=@slco AND SL=@sl AND SubCO=@SubCO)
		BEGIN
		INSERT INTO dbo.vPMSubcontractCO (PMCo, Project, SubCO, Description, Status, Date, SLCo, SL, ReadyForAcctg)
		VALUES (@pmco, @project, @SubCO, @slitemdescription, @SubCO_Status, dbo.vfDateOnly(), @slco, @sl, 'N')
		----TK-16127 moved approve to here so only happens when a new SCO
		----TK-13889 if the SCO is being assigned from an ACO, then we need to approve the SCO
		IF ISNULL(@aco,'') <> ''
			BEGIN
			DECLARE @SCOKeyID BIGINT
			SELECT @SCOKeyID = KeyID
			FROM dbo.vPMSubcontractCO
			WHERE SLCo = @slco
				AND SL = @sl
				AND SubCO = @SubCO
			IF @@ROWCOUNT = 1
				BEGIN
				EXEC @retcode = dbo.vspPMSubcontractCOApproveSCOs @SCOKeyID, 'Y', NULL, @retmsg OUTPUT
				END
			END
		END
	END



---- TK-15931 Backfill values to PMOL if we find a match. There must be only one PMSL record.
IF @recordtype = 'C'
	BEGIN
	---- update subcontract values to PMOL
	UPDATE dbo.bPMOL
			SET SubCO				= @SubCO
			  , SubCOSeq			= CASE WHEN @SubCO IS NOT NULL THEN @seq ELSE NULL END
			  , PurchaseUnits		= @units
			  , PurchaseUM			= @pmslum
			  , PurchaseUnitCost	= @unitcost
			  , PurchaseAmt			= @estcost
			  , Subcontract			= @sl
			  , POSLItem			= @slitem
			  , Vendor				= @vendor
			  , VendorGroup			= @vendorgroup
	WHERE PMCo = @pmco
		AND Project = @project
		AND Phase = @phase
		AND CostType = @costtype
		AND ISNULL(PCOType,'') = ISNULL(@pcotype,'')
		AND ISNULL(PCO,'') = ISNULL(@pco,'')
		AND ISNULL(PCOItem,'') = ISNULL(@pcoitem,'')
		AND ISNULL(ACO,'') = ISNULL(@aco,'')
		AND ISNULL(ACOItem,'') = ISNULL(@acoitem,'')
		AND NOT EXISTS(SELECT 1 FROM dbo.PMSL s WHERE s.PMCo=@pmco AND s.Project = @project
				AND Phase = @phase
				AND CostType = @costtype
				AND (PCO IS NOT NULL OR ACO IS NOT NULL)
				AND ISNULL(PCOType,'') = ISNULL(@pcotype,'')
				AND ISNULL(PCO,'') = ISNULL(@pco,'')
				AND ISNULL(PCOItem,'') = ISNULL(@pcoitem,'')
				AND ISNULL(ACO,'') = ISNULL(@aco,'')
				AND ISNULL(ACOItem,'') = ISNULL(@acoitem,'')
				AND Seq <> @seq)	
	END



next_PMSL_record:
if @numrows > 1
   	begin
       fetch next from bPMSL_insert into @pmco, @project, @seq
   	if @@fetch_status = 0
   		goto insert_check
   	else
   		begin
   		close bPMSL_insert
   		deallocate bPMSL_insert
   		end
   	end


---- update the Record Type field based on whether or not there is a
---- change order associated with this sl
---- original record type
UPDATE dbo.bPMSL SET RecordType = 'O'
FROM inserted i INNER JOIN dbo.bPMSL p ON p.KeyID=i.KeyID
WHERE i.RecordType = 'C' AND i.ACO IS NULL AND i.PCO IS NULL
---- change record type
UPDATE dbo.bPMSL SET RecordType = 'C'
FROM inserted i INNER JOIN dbo.bPMSL p ON p.KeyID=i.KeyID
WHERE i.RecordType = 'O' AND (i.ACO IS NOT NULL or i.PCO IS NOT NULL)

---- insert vPMRelateRecord for various links PCO/ACO/SUBCO/SLHD TK-03289
---- PCO and SubCO
INSERT INTO dbo.vPMRelateRecord(RecTableName, RECID, LinkTableName, LINKID)
SELECT 'PMSubcontractCO', a.KeyID, 'PMOP', b.KeyID
FROM inserted i
INNER JOIN dbo.vPMSubcontractCO a ON a.SLCo=i.SLCo AND a.SL=i.SL AND a.SubCO=i.SubCO
INNER JOIN dbo.bPMOP b ON b.PMCo=i.PMCo AND b.Project=i.Project AND b.PCOType=i.PCOType AND b.PCO=i.PCO
WHERE i.SubCO IS NOT NULL AND i.PCO IS NOT NULL AND i.SL IS NOT NULL
AND NOT EXISTS(SELECT 1 FROM dbo.vPMRelateRecord c WHERE c.RecTableName='PMSubcontractCO' AND c.RECID=a.KeyID
				AND c.LinkTableName='PMOP' AND c.LINKID=b.KeyID)
AND NOT EXISTS(SELECT 1 FROM dbo.vPMRelateRecord d WHERE d.RecTableName='PMOP' AND d.RECID=b.KeyID
				AND d.LinkTableName='PMSubcontractCO' AND d.LINKID=a.KeyID)

---- ACO and SubCO
INSERT INTO dbo.vPMRelateRecord(RecTableName, RECID, LinkTableName, LINKID)
SELECT 'PMSubcontractCO', a.KeyID, 'PMOH', b.KeyID
FROM inserted i
INNER JOIN dbo.vPMSubcontractCO a ON a.SLCo=i.SLCo AND a.SL=i.SL AND a.SubCO=i.SubCO
INNER JOIN dbo.bPMOH b ON b.PMCo=i.PMCo AND b.Project=i.Project AND b.ACO=i.ACO
WHERE i.SubCO IS NOT NULL AND i.ACO IS NOT NULL AND i.SL IS NOT NULL
AND NOT EXISTS(SELECT 1 FROM dbo.vPMRelateRecord c WHERE c.RecTableName='PMSubcontractCO' AND c.RECID=a.KeyID
				AND c.LinkTableName='PMOH' AND c.LINKID=b.KeyID)
AND NOT EXISTS(SELECT 1 FROM dbo.vPMRelateRecord d WHERE d.RecTableName='PMOH' AND d.RECID=b.KeyID
				AND d.LinkTableName='PMSubcontractCO' AND d.LINKID=a.KeyID)

---- PCO and SL
INSERT INTO dbo.vPMRelateRecord(RecTableName, RECID, LinkTableName, LINKID)
SELECT 'PMOP', a.KeyID, 'SLHD', b.KeyID
FROM inserted i
INNER JOIN dbo.bPMOP a ON a.PMCo=i.PMCo AND a.Project=i.Project AND a.PCOType=i.PCOType AND a.PCO=i.PCO
INNER JOIN dbo.bSLHD b ON b.SLCo=i.SLCo AND b.SL=i.SL
WHERE i.SL IS NOT NULL AND i.PCO IS NOT NULL
AND NOT EXISTS(SELECT 1 FROM dbo.vPMRelateRecord c WHERE c.RecTableName='PMOP' AND c.RECID=a.KeyID
				AND c.LinkTableName='SLHD' AND c.LINKID=b.KeyID)
AND NOT EXISTS(SELECT 1 FROM dbo.vPMRelateRecord d WHERE d.RecTableName='SLHD' AND d.RECID=b.KeyID
				AND d.LinkTableName='PMOP' AND d.LINKID=a.KeyID)

---- ACO and SL
INSERT INTO dbo.vPMRelateRecord(RecTableName, RECID, LinkTableName, LINKID)
SELECT 'PMOH', a.KeyID, 'SLHD', b.KeyID
FROM inserted i
INNER JOIN dbo.bPMOH a ON a.PMCo=i.PMCo AND a.Project=i.Project AND a.ACO=i.ACO
INNER JOIN dbo.bSLHD b ON b.SLCo=i.SLCo AND b.SL=i.SL
WHERE i.SL IS NOT NULL AND i.ACO IS NOT NULL
AND NOT EXISTS(SELECT 1 FROM dbo.vPMRelateRecord c WHERE c.RecTableName='PMOH' AND c.RECID=a.KeyID
				AND c.LinkTableName='SLHD' AND c.LINKID=b.KeyID)
AND NOT EXISTS(SELECT 1 FROM dbo.vPMRelateRecord d WHERE d.RecTableName='SLHD' AND d.RECID=b.KeyID
				AND d.LinkTableName='PMOH' AND d.LINKID=a.KeyID)



-- Audit inserts
insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bPMSL','PMCo: ' + isnull(convert(char(3),i.PMCo), '') + ' Project: ' + isnull(i.Project,'')
		+ ' Seq: ' + isnull(convert(varchar(10),i.Seq),'') + ' Phase: ' + isnull(i.Phase,'')
		+ ' CostType: ' + isnull(convert(varchar(3),i.CostType),''), i.PMCo, 'A', NULL, NULL, NULL, getdate(), SUSER_SNAME()
from inserted i join bPMCO c on c.PMCo = i.PMCo
where i.PMCo = c.PMCo and c.AuditPMSL = 'Y'


return


error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot insert into PMSL'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction





GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




/****** Object:  Trigger dbo.btPMSLu    Script Date: 8/28/99 9:38:25 AM ******/
CREATE trigger [dbo].[btPMSLu] on [dbo].[bPMSL] for UPDATE as
/*--------------------------------------------------------------
* Update trigger for PMSL
* Created By:	LM 12/24/97
* Modified By:	GF 05/03/2000
*                  GF 05/30/2001 - added validation for units <> 0 and UM='LS'
*                  DANF 09/06/02 - 17738 Added Phase Group to bspJCADDCOSTTYPE
*					GF 09/23/2003 - issue #22398 - check for different phase/cost-type/um combinations
*					GF 01/15/2003 - issue #20976 - update AppChangeOrder in SLCD when approving PCO
*					GF 01/15/2007 - 6.x HQMA auditing
*					GF 03/13/2008 - issue #127436 changed logic to add project firm contact to use bPMSS info if possible
*					GF 09/19/2008 - issue #129811 subcontract tax
*					GF 03/12/2010 - issue #138547 - SLHD.Vendor must match PMSL.Vendor when SL assigned.
*					GF 06/28/2010 - issue #135813 SL expanded to 30 characters
*					GF 11/02/2010 - issue #141957 record association
*					GF 11/05/2010 - issue #141031 change to use date function.
*					GF 02/21/2011 - B-02385 create PMSubcontractCO record when adding SubCO to PMSL
*					GP 02/24/2011 - fixed bug caused by B-02385 above, forgot to add @SubCO to 2nd cursor fetch
*					GF 04/08/2011 - TK-03289
*					GF 05/06/2011 - TK-04933
*					GF 05/11/2011 - TK-05178 TK-05205 TK-05756
*					GF 06/21/2011 - TK-05811
*					GF 06/22/2011 - D-02339 use view not tables for links
*					GF 11/02/2011 TK-09613 do not allow subco to different JCCo or Job.
*					GF 03/06/2012 TK-12996 #146016 Sync changes between PCO Item detail and SubCO
*					GF 03/26/2012 TK-13577 #146151 missed update vendor group with sync
*					JayR 03/27/2012 TK-00000 Switch to using FKs and table constraints for validation
*					GF 05/17/2012 TK-13889 if SubCO is assigned to an ACO, approve the SCO
*					GF 05/30/2012 TK-15264 missing @IntFlag in fetch next
*					GF 06/20/2012 TK-15931 cleanup update to PMOL 
*					GF 07/03/2012 TK-16127 only approve SCO from an ACO and SCO does not exist
*					GF 11/09/2012 TK-18033 SL Claim Enhancement. Changed to Use ApprovalRequired
*
*--------------------------------------------------------------*/
declare @numrows int, @errmsg varchar(255), @rcode int, @validcnt int, @validcnt2 int,
		@pmco bCompany, @project bJob, @seq int, @phasegroup bGroup, @phase bPhase, 
   		@costtype bJCCType, @pmslum bUM, @slco bCompany, @vendorgroup bGroup,
		@vendor bVendor, @sl VARCHAR(30), @SLCompGroup varchar(10), @description bItemDesc,
   		@retcode int, @retmsg varchar(150), @origdate bDate, @slitemdescription bItemDesc,
   		@recordtype varchar(1), @slitem bItem, @opencursor tinyint, @sendtofirm bVendor,
   		@sendtocontact bEmployee, @ACOItem varchar(10), @slhd_vendor bVendor,
		@subItemPhase bPhase, @subItemCostType bJCCType, @subItemUM bUM, @SLID BIGINT,
		@ACOID BIGINT, @PCOID BIGINT, @PCO bPCO, @ACO bPCO, @PCOType bDocType, @KeyID BIGINT,
		----B-02385 TK-03289 TK-04933
		@SubCO SMALLINT	, @SubCO_Status VARCHAR(6), @PCOItem VARCHAR(10), @slitemtype TINYINT,
		@OldACO VARCHAR(10), @OldACOItem VARCHAR(10), @OldPCOType bDocType, @OldPCO VARCHAR(10),
		@OldPCOItem VARCHAR(10), @OldSubCO SMALLINT, @OldSL VARCHAR(30), @OldSLItem SMALLINT,
		----TK-09613
		@SCO_JCCo bCompany, @SCO_Job bJob,
		----TK-12996 
		@Units bUnits, @Amount bDollar, @UnitCost bUnitCost
		----TK-13889
		,@IntFlag CHAR(1)
		
select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

SET @opencursor = 0
SET @rcode = 0
SET @origdate = dbo.vfDateOnly()

---- check for changes to PMCo
if update(PMCo)
	begin
	select @errmsg = 'Cannot change PMCo'
	goto error
	end

---- check for changes to Seq
if update(Seq)
	begin
	select @errmsg = 'Cannot change Seq'
	goto error
	end

---- if assigned to a SL the VendorGroup/Vendor must match SL
-- I have left this in because there is a conflicting index
SELECT @validcnt = COUNT(*) FROM inserted i LEFT JOIN dbo.bSLHD h ON
		h.SLCo=i.SLCo AND h.SL=i.SL AND h.VendorGroup=i.VendorGroup
		AND h.Vendor=i.Vendor WHERE i.SL IS NOT NULL
SELECT @validcnt2 = COUNT(*) FROM inserted i WHERE i.SL IS NULL
if @validcnt + @validcnt2 <> @numrows
	BEGIN
	SELECT @errmsg = 'Vendor is Invalid for Subcontract'
	goto error
	END


---- update the Record Type field based on whether or not there is a
---- change order associated with this sl TK-05178
if update(ACO) or update(PCO)
   	BEGIN
	---- original record type
	UPDATE dbo.bPMSL SET RecordType = 'O'
	FROM inserted i INNER JOIN dbo.bPMSL p ON p.KeyID=i.KeyID
	WHERE i.RecordType = 'C' AND i.ACO IS NULL AND i.PCO IS NULL
	---- change record type
	UPDATE dbo.bPMSL SET RecordType = 'C'
	FROM inserted i INNER JOIN dbo.bPMSL p ON p.KeyID=i.KeyID
	WHERE i.RecordType = 'O' AND (i.ACO IS NOT NULL or i.PCO IS NOT NULL)
	END


if @numrows = 1
	begin
   	select @pmco=i.PMCo, @project=i.Project, @seq=i.Seq, @phasegroup=i.PhaseGroup, @phase=i.Phase,
			@costtype=i.CostType, @pmslum=i.UM, @slco=i.SLCo, @vendorgroup=i.VendorGroup,
			@vendor=i.Vendor, @sl=i.SL, @slitem=i.SLItem, @slitemdescription=i.SLItemDescription,
			@recordtype=i.RecordType, @ACOItem=i.ACOItem, @ACO=i.ACO, @PCOType=i.PCOType,
			@PCO=i.PCO, @PCOItem=i.PCOItem, @KeyID=i.KeyID,
			----TK-12996
			@Units = i.Units, @Amount = i.Amount, @UnitCost = i.UnitCost,
			----B-02385 TK-03289 TK-04933
			@SubCO = i.SubCO, @PCOItem = i.PCOItem, @slitemtype = i.SLItemType,
			---- old info
			@OldSubCO = d.SubCO, @OldACO = d.ACO, @OldACOItem = d.ACOItem, @OldPCOType = d.PCOType,
			@OldPCO = d.PCO, @OldPCOItem = d.PCOItem, @OldSL = d.SL, @OldSLItem = d.SLItem
			----TK-13889
			,@IntFlag = i.IntFlag

	from inserted i
	join deleted d on d.KeyID = i.KeyID
	end
else
	begin
   	---- use a cursor to process each inserted row
   	declare bPMSL_insert cursor LOCAL FAST_FORWARD
   	for select i.PMCo, i.Project, i.Seq, i.PhaseGroup, i.Phase, i.CostType, i.UM,
   			i.SLCo, i.VendorGroup, i.Vendor, i.SL, i.SLItem, i.SLItemDescription, i.RecordType,
			i.ACOItem, i.ACO, i.PCOType, i.PCO, i.KeyID,
			----TK-12996
			i.Units, i.Amount, i.UnitCost,
			----B-02385 TK-03289 TK-04933
			i.SubCO, i.PCOItem, i.SLItemType,
			---- old info
			d.SubCO,  d.ACO, d.ACOItem, d.PCOType, d.PCO, d.PCOItem, d.SL, d.SLItem
			----TK-13889
			,i.IntFlag	
			
   	from inserted i
	join deleted d on d.KeyID = i.KeyID
   
   	open bPMSL_insert
   	set @opencursor = 1
   
	fetch next from bPMSL_insert into @pmco, @project, @seq, @phasegroup, @phase, @costtype, @pmslum,
			@slco, @vendorgroup, @vendor, @sl, @slitem, @slitemdescription, @recordtype,
			@ACOItem, @ACO, @PCOType, @PCO, @KeyID,
			----TK-12996
			@Units, @Amount, @UnitCost,
			----b-02385 TK-03289 TK-04933
			@SubCO, @PCOItem, @slitemtype,
			---- old info
			@OldSubCO, @OldACO, @OldACOItem, @OldPCOType, @OldPCO, @OldPCOItem, @OldSL, @OldSLItem
			----TK-15264
			,@IntFlag

	if @@fetch_status <> 0
		begin
   		select @errmsg = 'Cursor error'
   		goto error
   		end
	end


insert_check:
---- gete Comp group from JCJM
select @SLCompGroup = SLCompGroup from dbo.bJCJM with (nolock) where JCCo=@pmco and Job=@project


---- check if SL and SubCO not null that company and job are same
----TK-09613
IF UPDATE(SubCO) AND ISNULL(@SubCO,0) <> ISNULL(@OldSubCO,0)
	BEGIN
	IF @sl IS NOT NULL AND @SubCO IS NOT NULL
		BEGIN
		---- verify same JCCo and Job
		SET @SCO_JCCo = NULL
		SET @SCO_Job = NULL
		SELECT @SCO_JCCo = PMCo, @SCO_Job = Project
		FROM dbo.vPMSubcontractCO WHERE SLCo=@slco AND SL=@sl AND SubCO=@SubCO
		IF @@ROWCOUNT <> 0
			BEGIN
			IF @SCO_JCCo <> @pmco
   				BEGIN
   				SELECT @errmsg = 'Invalid SubCO, assigned to a different Company.'
   				GOTO error
   				END
			--IF @SCO_Job <> @project
   --				BEGIN
   --				SELECT @errmsg = 'Invalid SubCO, assigned to a different Job.'
   --				GOTO error
   --				END
   			END
		END
	END

---- get beginning status for SubCO from PMSC B-02385
SET @SubCO_Status = NULL
select Top 1 @SubCO_Status = Status
FROM dbo.bPMSC WHERE DocCat = 'SUBCO' AND CodeType = 'B'
----TK-05205
IF @@ROWCOUNT = 0
	BEGIN
	SELECT @SubCO_Status = BeginStatus
	FROM dbo.bPMCO WHERE PMCo=@pmco
	END
	
---- check for duplicate with different assigned phase/costtype/um combination
if @recordtype = 'O' and @sl is not null
   	begin
   	---- check for duplicate item record with different phase/costtype/um combination
   	if exists(select 1 from dbo.bPMSL with (nolock) where PMCo=@pmco and Project=@project and SLCo=@slco
   		and Vendor=@vendor and SL=@sl and SLItem=@slitem and Seq<>@seq and InterfaceDate is null
   		and RecordType='O' and (Phase<>@phase or CostType<>@costtype or UM<>@pmslum))
   		begin
   		select @errmsg = 'SL: ' + isnull(@sl,'') + ' SLItem: ' + convert(varchar(8),isnull(@slitem,0)) 
   					+ ' - Multiple records set up for same item with different Phase/CostType/UM combination.'
   	    goto error
   	    end
   	end

if @recordtype = 'C' and @sl is not null
   	begin
   	---- check for duplicate item record with different phase/costtype/um combination
   	if exists(select 1 from dbo.bPMSL with (nolock) where PMCo=@pmco and Project=@project and SLCo=@slco
   		and Vendor=@vendor and SL=@sl and SLItem=@slitem and Seq<>@seq and InterfaceDate is null
   		and RecordType='C' and (Phase<>@phase or CostType<>@costtype or UM<>@pmslum))
   		begin
   		select @errmsg = 'SL: ' + isnull(@sl,'') + ' SLItem: ' + convert(varchar(8),isnull(@slitem,0)) 
   					+ ' - Multiple records set up for same item with different Phase/CostType/UM combination.'
   	    goto error
   	    end
   	---- #138547
	---- get vendor from SLHD if SL exists. compare to PMSL vendor if one assigned. Must match
	select @slhd_vendor = Vendor from dbo.bSLHD h with (nolock) where h.SLCo=@slco and h.SL=@sl
	if @@rowcount <> 0
		BEGIN
		if isnull(@slhd_vendor,'') <> isnull(@vendor,'')
			BEGIN
			select @errmsg = 'SL: ' + isnull(@sl,'') + ' Vendor: ' + convert(varchar(10),isnull(@slhd_vendor,0)) 
   					+ ' does not match subcontract detail vendor: ' + convert(varchar(10),isnull(@vendor,0)) + '.'
   			goto error
			END
		END
	---- #138547
   	end


----Validate SL/insert SL
if update(SL) and @sl is not null
   	begin
   	if not exists (select 1 from dbo.bSLHD where SLCo=@slco and SL=@sl)
   		begin
   		----select @description = substring(@slitemdescription,1,30)
   		insert dbo.bSLHD (SLCo, SL, JCCo, Job, Description, VendorGroup, Vendor, Status, PayTerms, 
   				CompGroup, Purge, Approved, OrigDate
				----TK-18033
				,ApprovalRequired)
   		select @slco, @sl, @pmco, @project, @slitemdescription, @vendorgroup, @vendor, 3, m.PayTerms, 
   				@SLCompGroup,'N', 'N', @origdate
				----TK-18033
				,'N'
   		from dbo.bAPVM m with (nolock) where m.VendorGroup=@vendorgroup and m.Vendor=@vendor
   		if @@rowcount <> 1
   			begin
   			select @errmsg = ' Cannot insert into SLHD '
   			goto error
   			end
   		end
	end


if @sl is not null
	begin
   	---- check SLIT for item, if found phase/costtype must exist
   	select @subItemPhase = Phase, @subItemCostType = JCCType, @subItemUM = UM
   	from dbo.bSLIT where SLCo=@slco and SL=@sl and SLItem=@slitem
   	if @@rowcount <> 0
   		begin
   		if @subItemPhase <> @phase or @subItemCostType <> @costtype or @subItemUM <> @pmslum
   			begin
			select @errmsg = 'SL: ' + isnull(@sl,'') + ' SLItem: ' + convert(varchar(8),isnull(@slitem,0)) 
   					+ ' - Multiple records set up for same item with different Phase/CostType/UM combination.'
			goto error
			END
		end
	
	---- insert SendTo info in bPMSS if needed
	if not exists(select 1 from dbo.bPMSS with (nolock) where PMCo=@pmco and Project=@project
					and SLCo=@slco and SL=@sl)
		begin
		exec @retcode = bspPMSSInitialize @pmco, @project, @slco, @sl, @retmsg output
		end

	---- insert Project Firm if needed check bPMSS to see if we have a send to firm and contact
	select @sendtofirm=SendToFirm, @sendtocontact=SendToContact
	from dbo.bPMSS with (nolock) where PMCo=@pmco and Project=@project and SLCo=@slco and SL=@sl
	and SendToFirm is not null and SendToContact is not null
	if @@rowcount <> 0
		begin
		if not exists(select 1 from dbo.bPMPF with (nolock) where PMCo=@pmco and Project=@project
				and FirmNumber=@sendtofirm and ContactCode=@sendtocontact)
			begin
			exec @retcode = bspPMPFirmContactDistAdd @pmco, @project, @vendorgroup, @sendtofirm, @sendtocontact, @retmsg output
			end
		end
	else
		begin
		if not exists(select 1 from dbo.bPMPF with (nolock) where PMCo=@pmco and Project=@project
					and VendorGroup=@vendorgroup and FirmNumber=@vendor)
			begin
			exec @retcode = bspPMSLFirmContactInit @pmco, @project, @vendorgroup, @vendor, @retmsg output
			end
		end
	end



---- B-02385
IF @sl IS NOT NULL AND @slitemtype IN (1,2,4)
	BEGIN
	IF @SubCO IS NOT NULL
		BEGIN
		---- insert row for SUBCO when not exists
		IF NOT EXISTS(SELECT 1 FROM dbo.vPMSubcontractCO WHERE SLCo=@slco AND SL=@sl AND SubCO=@SubCO)
			BEGIN
			----TK-07041
			INSERT INTO dbo.vPMSubcontractCO (PMCo, Project, SubCO, Description, Status, Date, SLCo, SL, ReadyForAcctg)
			VALUES (@pmco, @project, @SubCO, @slitemdescription, @SubCO_Status, dbo.vfDateOnly(), @slco, @sl, 'N')
			----TK-16127 only approve when adding new SCO from an ACO
			----TK-13889 if the SCO is being assigned from an ACO, then we need to approve the SCO
			----we only want to do this is there already was an ACO assigned and the subco changed
			IF ISNULL(@OldSubCO,-1) <> @SubCO AND ISNULL(@IntFlag,'N') <> 'C' AND ISNULL(@ACO,'') <> ''
				BEGIN
				DECLARE @SCOKeyID BIGINT
				SELECT @SCOKeyID = KeyID
				FROM dbo.vPMSubcontractCO
				WHERE SLCo = @slco
					AND SL = @sl
					AND SubCO = @SubCO
				IF @@ROWCOUNT = 1
					BEGIN
					EXEC @retcode = dbo.vspPMSubcontractCOApproveSCOs @SCOKeyID, 'Y', NULL, @retmsg OUTPUT
					END
				END
			END
		END
	END



---- TK-12966 TK-15931 CLEAN UP
---- Backfill values to PMOL if we find a match. There must be only one PMSL record.
---- update subcontract values to PMOL
IF @recordtype = 'C'
	BEGIN
	UPDATE dbo.bPMOL
			SET SubCO				= @SubCO
			  , SubCOSeq			= CASE WHEN @SubCO IS NOT NULL THEN @seq ELSE NULL END
			  , PurchaseUnits		= @Units
			  , PurchaseUM			= @pmslum
			  , PurchaseUnitCost	= @UnitCost
			  , PurchaseAmt			= @Amount
			  , Subcontract			= @sl
			  , POSLItem			= @slitem
			  , Vendor				= @vendor
			  ----TK-13577
			  , VendorGroup			= @vendorgroup
	WHERE PMCo = @pmco
		AND Project = @project
		AND Phase = @phase
		AND CostType = @costtype
		AND ISNULL(PCOType,'') = ISNULL(@PCOType,'')
		AND ISNULL(PCO,'') = ISNULL(@PCO,'')
		AND ISNULL(PCOItem,'') = ISNULL(@PCOItem,'')
		AND ISNULL(ACO,'') = ISNULL(@ACO,'')
		AND ISNULL(ACOItem,'') = ISNULL(@ACOItem,'')
		AND NOT EXISTS(SELECT 1 FROM dbo.PMSL s WHERE s.PMCo=@pmco AND s.Project = @project
					AND Phase = @phase
					AND CostType = @costtype
					AND (PCO IS NOT NULL OR ACO IS NOT NULL)
					AND ISNULL(PCOType,'') = ISNULL(@PCOType,'')
					AND ISNULL(PCO,'') = ISNULL(@PCO,'')
					AND ISNULL(PCOItem,'') = ISNULL(@PCOItem,'')
					AND ISNULL(ACO,'') = ISNULL(@ACO,'')
					AND ISNULL(ACOItem,'') = ISNULL(@ACOItem,'')
					AND Seq <> @seq)
	END
			

next_PMSL_record:
if @numrows > 1
	begin
	fetch next from bPMSL_insert into @pmco, @project, @seq, @phasegroup, @phase, @costtype, @pmslum,
			@slco, @vendorgroup, @vendor, @sl, @slitem, @slitemdescription, @recordtype,
			@ACOItem, @ACO, @PCOType, @PCO, @KeyID,
			----TK-12996
			@Units, @Amount, @UnitCost,
			----b-02385 TK-03289 TK-04933
			@SubCO, @PCOItem, @slitemtype,
			---- old info
			@OldSubCO, @OldACO, @OldACOItem, @OldPCOType, @OldPCO, @OldPCOItem, @OldSL, @OldSLItem
			----TK-13889
			,@IntFlag
			

   	if @@fetch_status = 0
		begin
   		goto insert_check
		end
   	else
   		begin
   		close bPMSL_insert
   		deallocate bPMSL_insert
   		set @opencursor = 0
   		end
   	end

---- update AppChangeOrder in SLCD when PCO subct detail is approved.
if update(ACO)
   	begin
   	update bSLCD set AppChangeOrder = i.ACO
   	from inserted i join dbo.bSLCD s on s.SLCo=i.SLCo and s.Mth=i.SLMth and s.SLTrans=i.SLTrans
   	where i.SLMth is not null and i.SLTrans is not null and i.PCO is not null 
   	and i.InterfaceDate is not null and i.ACO is not null and i.SendFlag = 'Y'
   	AND s.AppChangeOrder <> i.ACO
   	end



---- manage PM related records - may be inserting PCO/ACO-SL or PCO/ACO-SUBCO
---- could also be changing from one related record to another in which case we need to remove
---- the old related link and add a new related link. TK-03289
---- if subcontract has changed we need to delete old related record if only one
---- record side ACO
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN inserted i ON i.KeyID=d.KeyID
INNER JOIN dbo.bSLHD h ON h.SLCo=d.SLCo AND h.SL=d.SL
INNER JOIN dbo.bPMOH c ON c.PMCo=d.PMCo AND c.Project=d.Project AND c.ACO=d.ACO
INNER JOIN dbo.vPMRelateRecord a ON a.RecTableName='PMOH' AND a.RECID=c.KeyID AND a.LinkTableName='SLHD' AND a.LINKID=h.KeyID
WHERE d.SL IS NOT NULL AND d.ACO IS NOT NULL
AND NOT EXISTS(SELECT 1 FROM dbo.bPMSL x WHERE x.PMCo=d.PMCo AND x.Project=d.Project AND x.ACO=d.ACO AND x.SL=d.SL)
---- link side ACO
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN inserted i ON i.KeyID=d.KeyID
INNER JOIN dbo.bSLHD h ON h.SLCo=d.SLCo AND h.SL=d.SL
INNER JOIN dbo.bPMOH c ON c.PMCo=d.PMCo AND c.Project=d.Project AND c.ACO=d.ACO
INNER JOIN dbo.vPMRelateRecord a ON a.RecTableName='SLHD' AND a.RECID=h.KeyID AND a.LinkTableName='PMOH' AND a.LINKID=c.KeyID
WHERE d.SL IS NOT NULL AND d.ACO IS NOT NULL
AND NOT EXISTS(SELECT 1 FROM dbo.bPMSL x WHERE x.PMCo=d.PMCo AND x.Project=d.Project AND x.ACO=d.ACO AND x.SL=d.SL)	

---- if subcontract has changed we need to delete old related record if only one
---- record side PCO
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN inserted i ON i.KeyID=d.KeyID
INNER JOIN dbo.bSLHD h ON h.SLCo=d.SLCo AND h.SL=d.SL
INNER JOIN dbo.bPMOP c ON c.PMCo=d.PMCo AND c.Project=d.Project AND c.PCOType=d.PCOType AND c.PCO=d.PCO
INNER JOIN dbo.vPMRelateRecord a ON a.RecTableName='PMOP' AND a.RECID=c.KeyID AND a.LinkTableName='SLHD' AND a.LINKID=h.KeyID
WHERE d.SL IS NOT NULL AND d.PCO IS NOT NULL
AND NOT EXISTS(SELECT 1 FROM dbo.bPMSL x WHERE x.PMCo=d.PMCo AND x.Project=d.Project AND x.PCOType=d.PCOType AND x.PCO=d.PCO AND x.SL=d.SL)
---- link side PCO
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN inserted i ON i.KeyID=d.KeyID
INNER JOIN dbo.bSLHD h ON h.SLCo=d.SLCo AND h.SL=d.SL
INNER JOIN dbo.bPMOP c ON c.PMCo=d.PMCo AND c.Project=d.Project AND c.PCOType=d.PCOType AND c.PCO=d.PCO
INNER JOIN dbo.vPMRelateRecord a ON a.RecTableName='SLHD' AND a.RECID=h.KeyID AND a.LinkTableName='PMOP' AND a.LINKID=c.KeyID
WHERE d.SL IS NOT NULL AND d.PCO IS NOT NULL
AND NOT EXISTS(SELECT 1 FROM dbo.bPMSL x WHERE x.PMCo=d.PMCo AND x.Project=d.Project AND x.PCOType=d.PCOType AND x.PCO=d.PCO AND x.SL=d.SL)


---- if subcontract change order has changed we need to delete
---- old related record if only one subco associated to PCO
---- record side PCO TK-05811
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN inserted i ON i.KeyID=d.KeyID
INNER JOIN dbo.vPMSubcontractCO h ON h.SLCo=d.SLCo AND h.SL=d.SL AND h.SubCO=d.SubCO
INNER JOIN dbo.bPMOP c ON c.PMCo=d.PMCo AND c.Project=d.Project AND c.PCOType=d.PCOType AND c.PCO=d.PCO
INNER JOIN dbo.vPMRelateRecord a ON a.RecTableName='PMSubcontractCO' AND a.RECID=h.KeyID AND a.LinkTableName='PMOP' AND a.LINKID=c.KeyID
WHERE d.PCO IS NOT NULL AND d.SubCO IS NOT NULL
AND NOT EXISTS(SELECT 1 FROM dbo.bPMSL x WHERE x.PMCo=d.PMCo AND x.Project=d.Project AND x.PCOType=d.PCOType AND x.PCO=d.PCO AND x.SubCO=d.SubCO)
---- link side PCO
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN inserted i ON i.KeyID=d.KeyID
INNER JOIN dbo.vPMSubcontractCO h ON h.SLCo=d.SLCo AND h.SL=d.SL AND h.SubCO=d.SubCO
INNER JOIN dbo.bPMOP c ON c.PMCo=d.PMCo AND c.Project=d.Project AND c.PCOType=d.PCOType AND c.PCO=d.PCO
INNER JOIN dbo.vPMRelateRecord a ON a.RecTableName='PMOP' AND a.RECID=c.KeyID AND a.LinkTableName='PMSubcontractCO' AND a.LINKID=h.KeyID
WHERE d.PCO IS NOT NULL AND d.SubCO IS NOT NULL
AND NOT EXISTS(SELECT 1 FROM dbo.bPMSL x WHERE x.PMCo=d.PMCo AND x.Project=d.Project AND x.PCOType=d.PCOType AND x.PCO=d.PCO AND x.SubCO=d.SubCO)

---- record side ACO
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN inserted i ON i.KeyID=d.KeyID
INNER JOIN dbo.vPMSubcontractCO h ON h.SLCo=d.SLCo AND h.SL=d.SL AND h.SubCO=d.SubCO
INNER JOIN dbo.bPMOH c ON c.PMCo=d.PMCo AND c.Project=d.Project AND c.ACO=d.ACO
INNER JOIN dbo.vPMRelateRecord a ON a.RecTableName='PMSubcontractCO' AND a.RECID=h.KeyID AND a.LinkTableName='PMOH' AND a.LINKID=c.KeyID
WHERE d.ACO IS NOT NULL AND d.SubCO IS NOT NULL
AND NOT EXISTS(SELECT 1 FROM dbo.bPMSL x WHERE x.PMCo=d.PMCo AND x.Project=d.Project AND x.ACO=d.ACO AND x.SubCO=d.SubCO)
---- link side ACO
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN inserted i ON i.KeyID=d.KeyID
INNER JOIN dbo.vPMSubcontractCO h ON h.SLCo=d.SLCo AND h.SL=d.SL AND h.SubCO=d.SubCO
INNER JOIN dbo.bPMOH c ON c.PMCo=d.PMCo AND c.Project=d.Project AND c.ACO=d.ACO
INNER JOIN dbo.vPMRelateRecord a ON a.RecTableName='PMOH' AND a.RECID=c.KeyID AND a.LinkTableName='PMSubcontractCO' AND a.LINKID=h.KeyID
WHERE d.ACO IS NOT NULL AND d.SubCO IS NOT NULL
AND NOT EXISTS(SELECT 1 FROM dbo.bPMSL x WHERE x.PMCo=d.PMCo AND x.Project=d.Project AND x.ACO=d.ACO AND x.SubCO=d.SubCO)




---- insert vPMRelateRecord for various links PCO/ACO/SUBCO/SLHD TK-03289
---- PCO and SubCO TK-05756 TK-05811
INSERT INTO dbo.vPMRelateRecord(RecTableName, RECID, LinkTableName, LINKID)
SELECT DISTINCT 'PMSubcontractCO', a.KeyID, 'PMOP', b.KeyID
FROM inserted i
INNER JOIN deleted x ON x.KeyID=i.KeyID
INNER JOIN dbo.vPMSubcontractCO a ON a.SLCo=i.SLCo AND a.SL=i.SL AND a.SubCO=i.SubCO
INNER JOIN dbo.bPMOP b ON b.PMCo=i.PMCo AND b.Project=i.Project AND b.PCOType=i.PCOType AND b.PCO=i.PCO
WHERE i.SubCO IS NOT NULL AND i.PCO IS NOT NULL
AND NOT EXISTS(SELECT 1 FROM dbo.vPMRelateRecord c WHERE c.RecTableName='PMSubcontractCO' AND c.RECID=a.KeyID
				AND c.LinkTableName='PMOP' AND c.LINKID=b.KeyID)
AND NOT EXISTS(SELECT 1 FROM dbo.vPMRelateRecord d WHERE d.RecTableName='PMOP' AND d.RECID=b.KeyID
				AND d.LinkTableName='PMSubcontractCO' AND d.LINKID=a.KeyID)

---- ACO and SubCO TK-05756 TK-05811
INSERT INTO dbo.vPMRelateRecord(RecTableName, RECID, LinkTableName, LINKID)
SELECT DISTINCT 'PMSubcontractCO', a.KeyID, 'PMOH', b.KeyID
FROM inserted i
INNER JOIN deleted x ON x.KeyID=i.KeyID
INNER JOIN dbo.vPMSubcontractCO a ON a.SLCo=i.SLCo AND a.SL=i.SL AND a.SubCO=i.SubCO
INNER JOIN dbo.bPMOH b ON b.PMCo=i.PMCo AND b.Project=i.Project AND b.ACO=i.ACO
WHERE i.SubCO IS NOT NULL AND i.ACO IS NOT NULL
AND NOT EXISTS(SELECT 1 FROM dbo.vPMRelateRecord c WHERE c.RecTableName='PMSubcontractCO' AND c.RECID=a.KeyID
				AND c.LinkTableName='PMOH' AND c.LINKID=b.KeyID)
AND NOT EXISTS(SELECT 1 FROM dbo.vPMRelateRecord d WHERE d.RecTableName='PMOH' AND d.RECID=b.KeyID
				AND d.LinkTableName='PMSubcontractCO' AND d.LINKID=a.KeyID)

---- PCO and SL
INSERT INTO dbo.vPMRelateRecord(RecTableName, RECID, LinkTableName, LINKID)
SELECT DISTINCT 'PMOP', a.KeyID, 'SLHD', b.KeyID
FROM inserted i
--INNER JOIN deleted x ON x.KeyID=i.KeyID
INNER JOIN dbo.bPMOP a ON a.PMCo=i.PMCo AND a.Project=i.Project AND a.PCOType=i.PCOType AND a.PCO=i.PCO
INNER JOIN dbo.bSLHD b ON b.SLCo=i.SLCo AND b.SL=i.SL
WHERE i.SL IS NOT NULL AND i.PCO IS NOT NULL ----AND ISNULL(x.SL,'') <> ISNULL(i.SL,'')
AND NOT EXISTS(SELECT 1 FROM dbo.vPMRelateRecord c WHERE c.RecTableName='PMOP' AND c.RECID=a.KeyID
				AND c.LinkTableName='SLHD' AND c.LINKID=b.KeyID)
AND NOT EXISTS(SELECT 1 FROM dbo.vPMRelateRecord d WHERE d.RecTableName='SLHD' AND d.RECID=b.KeyID
				AND d.LinkTableName='PMOP' AND d.LINKID=a.KeyID)

---- ACO and SL
INSERT INTO dbo.vPMRelateRecord(RecTableName, RECID, LinkTableName, LINKID)
SELECT DISTINCT 'PMOH', a.KeyID, 'SLHD', b.KeyID
FROM inserted i
--INNER JOIN deleted x ON x.KeyID=i.KeyID
INNER JOIN dbo.bPMOH a ON a.PMCo=i.PMCo AND a.Project=i.Project AND a.ACO=i.ACO
INNER JOIN dbo.bSLHD b ON b.SLCo=i.SLCo AND b.SL=i.SL
WHERE i.SL IS NOT NULL AND i.ACO IS NOT NULL ----AND ISNULL(x.SL,'') <> ISNULL(i.SL,'')
AND NOT EXISTS(SELECT 1 FROM dbo.vPMRelateRecord c WHERE c.RecTableName='PMOH' AND c.RECID=a.KeyID
				AND c.LinkTableName='SLHD' AND c.LINKID=b.KeyID)
AND NOT EXISTS(SELECT 1 FROM dbo.vPMRelateRecord d WHERE d.RecTableName='bSLHD' AND d.RECID=b.KeyID
				AND d.LinkTableName='PMOH' AND d.LINKID=a.KeyID)






---- HQMA inserts
if not exists(select top 1 1 from inserted i join bPMCO c with (nolock) on i.PMCo=c.PMCo and c.AuditPMSL='Y')
	begin
  	goto trigger_end
	end

if update(SL)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMSL','PMCo: ' + isnull(convert(char(3),i.PMCo), '') + ' Project: ' + isnull(i.Project,'')
		+ ' Seq: ' + isnull(convert(varchar(10),i.Seq),'') + ' Phase: ' + isnull(i.Phase,'')
		+ ' CostType: ' + isnull(convert(varchar(3),i.CostType),''), i.PMCo, 'C',
		'SL', d.SL, i.SL, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.Seq=i.Seq
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.SL,'') <> isnull(i.SL,'') and c.AuditPMSL='Y'
	end
if update(SLItem)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMSL','PMCo: ' + isnull(convert(char(3),i.PMCo), '') + ' Project: ' + isnull(i.Project,'')
		+ ' Seq: ' + isnull(convert(varchar(10),i.Seq),'') + ' Phase: ' + isnull(i.Phase,'')
		+ ' CostType: ' + isnull(convert(varchar(3),i.CostType),''), i.PMCo, 'C',
		'SLItem', convert(varchar(6),d.SLItem), convert(varchar(6),i.SLItem), getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.Seq=i.Seq
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.SLItem,'') <> isnull(i.SLItem,'') and c.AuditPMSL='Y'
	end
if update(SLItemDescription)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMSL','PMCo: ' + isnull(convert(char(3),i.PMCo), '') + ' Project: ' + isnull(i.Project,'')
		+ ' Seq: ' + isnull(convert(varchar(10),i.Seq),'') + ' Phase: ' + isnull(i.Phase,'')
		+ ' CostType: ' + isnull(convert(varchar(3),i.CostType),''), i.PMCo, 'C',
		'SLItemDescription', d.SLItemDescription, i.SLItemDescription, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.Seq=i.Seq
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.SLItemDescription,'') <> isnull(i.SLItemDescription,'') and c.AuditPMSL='Y'
	end
if update(SLItemType)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMSL','PMCo: ' + isnull(convert(char(3),i.PMCo), '') + ' Project: ' + isnull(i.Project,'')
		+ ' Seq: ' + isnull(convert(varchar(10),i.Seq),'') + ' Phase: ' + isnull(i.Phase,'')
		+ ' CostType: ' + isnull(convert(varchar(3),i.CostType),''), i.PMCo, 'C',
		'SLItemType', convert(varchar(1),d.SLItemType), convert(varchar(1),i.SLItemType), getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.Seq=i.Seq
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.SLItemType,'') <> isnull(i.SLItemType,'') and c.AuditPMSL='Y'
	end
if update(SLAddon)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMSL','PMCo: ' + isnull(convert(char(3),i.PMCo), '') + ' Project: ' + isnull(i.Project,'')
		+ ' Seq: ' + isnull(convert(varchar(10),i.Seq),'') + ' Phase: ' + isnull(i.Phase,'')
		+ ' CostType: ' + isnull(convert(varchar(3),i.CostType),''), i.PMCo, 'C',
		'SLAddon', convert(varchar(6),d.SLAddon), convert(varchar(6),i.SLAddon), getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.Seq=i.Seq
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.SLAddon,'') <> isnull(i.SLAddon,'') and c.AuditPMSL='Y'
	end
if update(SLAddonPct)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMSL','PMCo: ' + isnull(convert(char(3),i.PMCo), '') + ' Project: ' + isnull(i.Project,'')
		+ ' Seq: ' + isnull(convert(varchar(10),i.Seq),'') + ' Phase: ' + isnull(i.Phase,'')
		+ ' CostType: ' + isnull(convert(varchar(3),i.CostType),''), i.PMCo, 'C',
		'SLAddonPct', convert(varchar(15),d.SLAddonPct), convert(varchar(15),i.SLAddonPct), getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.Seq=i.Seq
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(convert(varchar(15),d.SLAddonPct),'') <> isnull(convert(varchar(15),i.SLAddonPct),'') and c.AuditPMSL='Y'
	end
if update(WCRetgPct)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMSL','PMCo: ' + isnull(convert(char(3),i.PMCo), '') + ' Project: ' + isnull(i.Project,'')
		+ ' Seq: ' + isnull(convert(varchar(10),i.Seq),'') + ' Phase: ' + isnull(i.Phase,'')
		+ ' CostType: ' + isnull(convert(varchar(3),i.CostType),''), i.PMCo, 'C',
		'WCRetgPct', convert(varchar(15),d.WCRetgPct), convert(varchar(15),i.WCRetgPct), getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.Seq=i.Seq
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(convert(varchar(15),d.WCRetgPct),'') <> isnull(convert(varchar(15),i.WCRetgPct),'') and c.AuditPMSL='Y'
	end
if update(SMRetgPct)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMSL','PMCo: ' + isnull(convert(char(3),i.PMCo), '') + ' Project: ' + isnull(i.Project,'')
		+ ' Seq: ' + isnull(convert(varchar(10),i.Seq),'') + ' Phase: ' + isnull(i.Phase,'')
		+ ' CostType: ' + isnull(convert(varchar(3),i.CostType),''), i.PMCo, 'C',
		'SMRetgPct', convert(varchar(15),d.SMRetgPct), convert(varchar(15),i.SMRetgPct), getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.Seq=i.Seq
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(convert(varchar(15),d.SMRetgPct),'') <> isnull(convert(varchar(15),i.SMRetgPct),'') and c.AuditPMSL='Y'
	end
if update(Vendor)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMSL','PMCo: ' + isnull(convert(char(3),i.PMCo), '') + ' Project: ' + isnull(i.Project,'')
		+ ' Seq: ' + isnull(convert(varchar(10),i.Seq),'') + ' Phase: ' + isnull(i.Phase,'')
		+ ' CostType: ' + isnull(convert(varchar(3),i.CostType),''), i.PMCo, 'C',
		'Vendor', convert(varchar(10),d.Vendor), convert(varchar(10),i.Vendor), getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.Seq=i.Seq
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.Vendor,'') <> isnull(i.Vendor,'') and c.AuditPMSL='Y'
	end
if update(Supplier)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMSL','PMCo: ' + isnull(convert(char(3),i.PMCo), '') + ' Project: ' + isnull(i.Project,'')
		+ ' Seq: ' + isnull(convert(varchar(10),i.Seq),'') + ' Phase: ' + isnull(i.Phase,'')
		+ ' CostType: ' + isnull(convert(varchar(3),i.CostType),''), i.PMCo, 'C',
		'Supplier', convert(varchar(10),d.Supplier), convert(varchar(10),i.Supplier), getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.Seq=i.Seq
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.Supplier,'') <> isnull(i.Supplier,'') and c.AuditPMSL='Y'
	end
if update(SubCO)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMSL','PMCo: ' + isnull(convert(char(3),i.PMCo), '') + ' Project: ' + isnull(i.Project,'')
		+ ' Seq: ' + isnull(convert(varchar(10),i.Seq),'') + ' Phase: ' + isnull(i.Phase,'')
		+ ' CostType: ' + isnull(convert(varchar(3),i.CostType),''), i.PMCo, 'C',
		'SubCO', convert(varchar(10),d.SubCO), convert(varchar(10),i.SubCO), getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.Seq=i.Seq
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.SubCO,'') <> isnull(i.SubCO,'') and c.AuditPMSL='Y'
	end
if update(UM)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMSL','PMCo: ' + isnull(convert(char(3),i.PMCo), '') + ' Project: ' + isnull(i.Project,'')
		+ ' Seq: ' + isnull(convert(varchar(10),i.Seq),'') + ' Phase: ' + isnull(i.Phase,'')
		+ ' CostType: ' + isnull(convert(varchar(3),i.CostType),''), i.PMCo, 'C',
		'UM', d.UM, i.UM, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.Seq=i.Seq
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.UM,'') <> isnull(i.UM,'') and c.AuditPMSL='Y'
	end
if update(SendFlag)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMSL','PMCo: ' + isnull(convert(char(3),i.PMCo), '') + ' Project: ' + isnull(i.Project,'')
		+ ' Seq: ' + isnull(convert(varchar(10),i.Seq),'') + ' Phase: ' + isnull(i.Phase,'')
		+ ' CostType: ' + isnull(convert(varchar(3),i.CostType),''), i.PMCo, 'C',
		'SendFlag', d.SendFlag, i.SendFlag, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.Seq=i.Seq
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.SendFlag,'') <> isnull(i.SendFlag,'') and c.AuditPMSL='Y'
	end
if update(Units)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMSL','PMCo: ' + isnull(convert(char(3),i.PMCo), '') + ' Project: ' + isnull(i.Project,'')
		+ ' Seq: ' + isnull(convert(varchar(10),i.Seq),'') + ' Phase: ' + isnull(i.Phase,'')
		+ ' CostType: ' + isnull(convert(varchar(3),i.CostType),''), i.PMCo, 'C',
		'Units', convert(varchar(20),d.Units), convert(varchar(20),i.Units), getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.Seq=i.Seq
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(convert(varchar(20),d.Units),'') <> isnull(convert(varchar(20),i.Units),'') and c.AuditPMSL='Y'
	end
if update(UnitCost)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMSL','PMCo: ' + isnull(convert(char(3),i.PMCo), '') + ' Project: ' + isnull(i.Project,'')
		+ ' Seq: ' + isnull(convert(varchar(10),i.Seq),'') + ' Phase: ' + isnull(i.Phase,'')
		+ ' CostType: ' + isnull(convert(varchar(3),i.CostType),''), i.PMCo, 'C',
		'UnitCost', convert(varchar(20),d.UnitCost), convert(varchar(20),i.UnitCost), getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.Seq=i.Seq
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(convert(varchar(20),d.UnitCost),'') <> isnull(convert(varchar(20),i.UnitCost),'') and c.AuditPMSL='Y'
	end
if update(Amount)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMSL','PMCo: ' + isnull(convert(char(3),i.PMCo), '') + ' Project: ' + isnull(i.Project,'')
		+ ' Seq: ' + isnull(convert(varchar(10),i.Seq),'') + ' Phase: ' + isnull(i.Phase,'')
		+ ' CostType: ' + isnull(convert(varchar(3),i.CostType),''), i.PMCo, 'C',
		'Amount', convert(varchar(20),d.Amount), convert(varchar(20),i.Amount), getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.Seq=i.Seq
	join bPMCO c ON i.PMCo=c.PMCo
	where c.AuditPMSL='Y' and isnull(convert(varchar(20),d.Amount),'') <> isnull(convert(varchar(20),i.Amount),'')
	end
if update(TaxType)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMSL','PMCo: ' + isnull(convert(char(3),i.PMCo), '') + ' Project: ' + isnull(i.Project,'')
		+ ' Seq: ' + isnull(convert(varchar(10),i.Seq),'') + ' Phase: ' + isnull(i.Phase,'')
		+ ' CostType: ' + isnull(convert(varchar(3),i.CostType),''), i.PMCo, 'C',
		'TaxType', convert(varchar(3),d.TaxType), convert(varchar(3),i.TaxType), getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.Seq=i.Seq
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.TaxType,'') <> isnull(i.TaxType,'') and c.AuditPMSL='Y'
	end
if update(TaxCode)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMSL','PMCo: ' + isnull(convert(char(3),i.PMCo), '') + ' Project: ' + isnull(i.Project,'')
		+ ' Seq: ' + isnull(convert(varchar(10),i.Seq),'') + ' Phase: ' + isnull(i.Phase,'')
		+ ' CostType: ' + isnull(convert(varchar(3),i.CostType),''), i.PMCo, 'C',
		'TaxCode', d.TaxCode, i.TaxCode, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.Seq=i.Seq
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.TaxCode,'') <> isnull(i.TaxCode,'') and c.AuditPMSL='Y'
	end


trigger_end:

return


error:
	if @opencursor = 1
   		begin
   		close bPMSL_insert
   		deallocate bPMSL_insert
   		set @opencursor = 0
   		end
   
   	select @errmsg = isnull(@errmsg,'') + ' - cannot update PMSL'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   












GO
ALTER TABLE [dbo].[bPMSL] WITH NOCHECK ADD CONSTRAINT [CK_bPMSL_SL] CHECK (([SL] IS NULL OR [SLItem] IS NOT NULL))
GO
ALTER TABLE [dbo].[bPMSL] WITH NOCHECK ADD CONSTRAINT [CK_bPMSL_SLItemType] CHECK (([SLItemType] IS NULL OR ([SLItemType]=(4) OR [SLItemType]=(3) OR [SLItemType]=(2) OR [SLItemType]=(1))))
GO
ALTER TABLE [dbo].[bPMSL] ADD CONSTRAINT [CK_bPMSL_SubCO] CHECK (([SubCO]>=(0)))
GO
ALTER TABLE [dbo].[bPMSL] WITH NOCHECK ADD CONSTRAINT [CK_bPMSL_TaxType] CHECK (([TaxType] IS NULL AND [TaxCode] IS NULL OR [TaxType] IS NOT NULL AND [TaxCode] IS NOT NULL))
GO
ALTER TABLE [dbo].[bPMSL] WITH NOCHECK ADD CONSTRAINT [CK_bPMSL_UM] CHECK (([UM]<>'LS' OR [Units]=(0)))
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPMSL] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPMSL] ON [dbo].[bPMSL] ([PMCo], [Project], [Seq]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ciPMSLAP] ON [dbo].[bPMSL] ([PMCo], [Project], [Vendor], [udSLContractNo], [udCMSItem], [udCGCTable]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_bPMSL_SLCo] ON [dbo].[bPMSL] ([SLCo], [SL], [SLItem]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bPMSL] WITH NOCHECK ADD CONSTRAINT [FK_bPMSL_bJCJM] FOREIGN KEY ([PMCo], [Project]) REFERENCES [dbo].[bJCJM] ([JCCo], [Job])
GO
ALTER TABLE [dbo].[bPMSL] WITH NOCHECK ADD CONSTRAINT [FK_bPMSL_bSLAD] FOREIGN KEY ([SLCo], [SLAddon]) REFERENCES [dbo].[bSLAD] ([SLCo], [Addon])
GO
ALTER TABLE [dbo].[bPMSL] WITH NOCHECK ADD CONSTRAINT [FK_bPMSL_bHQTX] FOREIGN KEY ([TaxGroup], [TaxCode]) REFERENCES [dbo].[bHQTX] ([TaxGroup], [TaxCode])
GO
ALTER TABLE [dbo].[bPMSL] WITH NOCHECK ADD CONSTRAINT [FK_bPMSL_bAPVM] FOREIGN KEY ([VendorGroup], [Vendor]) REFERENCES [dbo].[bAPVM] ([VendorGroup], [Vendor])
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPMSL].[UnitCost]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPMSL].[SendFlag]'
GO
