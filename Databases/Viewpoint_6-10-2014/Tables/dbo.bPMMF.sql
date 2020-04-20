CREATE TABLE [dbo].[bPMMF]
(
[PMCo] [dbo].[bCompany] NOT NULL,
[Project] [dbo].[bJob] NOT NULL,
[Seq] [int] NOT NULL,
[RecordType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[PCOType] [dbo].[bDocType] NULL,
[PCO] [dbo].[bPCO] NULL,
[PCOItem] [dbo].[bPCOItem] NULL,
[ACO] [dbo].[bACO] NULL,
[ACOItem] [dbo].[bACOItem] NULL,
[MaterialGroup] [dbo].[bGroup] NULL,
[MaterialCode] [dbo].[bMatl] NULL,
[VendMatId] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[MtlDescription] [dbo].[bItemDesc] NULL,
[PhaseGroup] [dbo].[bGroup] NULL,
[Phase] [dbo].[bPhase] NULL,
[CostType] [dbo].[bJCCType] NULL,
[MaterialOption] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[VendorGroup] [dbo].[bGroup] NULL,
[Vendor] [dbo].[bVendor] NULL,
[POCo] [dbo].[bCompany] NULL,
[PO] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[POItem] [dbo].[bItem] NULL,
[RecvYN] [dbo].[bYN] NOT NULL,
[Location] [dbo].[bLoc] NULL,
[MO] [char] (10) COLLATE Latin1_General_BIN NULL,
[MOItem] [dbo].[bItem] NULL,
[UM] [dbo].[bUM] NOT NULL,
[Units] [dbo].[bUnits] NOT NULL,
[UnitCost] [dbo].[bUnitCost] NOT NULL CONSTRAINT [DF_bPMMF_UnitCost] DEFAULT ((0)),
[ECM] [dbo].[bECM] NULL,
[Amount] [dbo].[bDollar] NOT NULL,
[ReqDate] [dbo].[bDate] NULL,
[InterfaceDate] [dbo].[bDate] NULL,
[TaxGroup] [dbo].[bGroup] NULL,
[TaxCode] [dbo].[bTaxCode] NULL,
[TaxType] [tinyint] NULL,
[SendFlag] [dbo].[bYN] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[RequisitionNum] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[MSCo] [dbo].[bCompany] NULL,
[Quote] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[INCo] [dbo].[bCompany] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[RQLine] [dbo].[bItem] NULL,
[IntFlag] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[POTrans] [int] NULL,
[POMth] [dbo].[bMonth] NULL,
[Supplier] [dbo].[bVendor] NULL,
[POCONum] [smallint] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/****** Object:  Trigger dbo.btPMMFd ******/
CREATE trigger [dbo].[btPMMFd] on [dbo].[bPMMF] for DELETE as
/*--------------------------------------------------------------
 * Created By:	GF 01/15/2007 6.x HQMA auditing
 * Modified By:	GF 11/02/2010 - issue #141957 record association
 *				GF 04/06/2011 - TK-03857
 *				DAN SO 04/21/2011 - TK-04287 - removing PMPOCO information from PMOL
 *				GF 06/22/2011 - D-02339 use view not tables for links
 *				GF 02/14/2012 TK-12630 missed check to remove links for POCO's
 *				JayR 04/02/2012 TK-0000 Add drop to first part of script
 *
 * Delete trigger for bPMMF
 *
 *
 *--------------------------------------------------------------*/
declare @numrows int, @errmsg varchar(255), @validcnt int

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

---- delete purchase order association if only no others detail exists for ACO
---- record side
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN dbo.bPOHD h ON h.POCo=d.POCo AND h.PO=d.PO
INNER JOIN dbo.bPMOH c ON c.PMCo=d.PMCo AND c.Project=d.Project AND c.ACO=d.ACO
INNER JOIN dbo.vPMRelateRecord a ON a.RecTableName='PMOH' AND a.RECID=c.KeyID AND a.LinkTableName='POHD' AND a.LINKID=h.KeyID
WHERE d.PO IS NOT NULL AND d.ACO IS NOT NULL
AND NOT EXISTS(SELECT 1 FROM dbo.PMMF x WHERE x.PMCo=d.PMCo
			AND x.Project=d.Project AND x.ACO=d.ACO AND x.PO=d.PO)
---- link side
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN dbo.bPOHD h ON h.POCo=d.POCo AND h.PO=d.PO
INNER JOIN dbo.bPMOH c ON c.PMCo=d.PMCo AND c.Project=d.Project AND c.ACO=d.ACO
INNER JOIN dbo.vPMRelateRecord a ON a.RecTableName='POHD' AND a.RECID=h.KeyID AND a.LinkTableName='PMOH' AND a.LINKID=c.KeyID
WHERE d.PO IS NOT NULL AND d.ACO IS NOT NULL
AND NOT EXISTS(SELECT 1 FROM dbo.PMMF x WHERE x.PMCo=d.PMCo
			AND x.Project=d.Project AND x.PCOType=d.PCOType AND x.ACO=d.ACO AND x.PO=d.PO)

---- TK-12630 missed POCO related to ACO
---- delete POCO association if only no others detail exists for ACO
---- record side ACO
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN dbo.vPMPOCO h ON h.POCo=d.POCo AND h.PO=d.PO AND h.POCONum=d.POCONum
INNER JOIN dbo.bPMOH c ON c.PMCo=d.PMCo AND c.Project=d.Project AND c.ACO=d.ACO
INNER JOIN dbo.vPMRelateRecord a ON a.RecTableName='PMPOCO' AND a.RECID=h.KeyID AND a.LinkTableName='PMOH' AND a.LINKID=c.KeyID
WHERE d.ACO IS NOT NULL AND d.POCONum IS NOT NULL
AND NOT EXISTS(SELECT 1 FROM dbo.bPMMF x WHERE x.PMCo=d.PMCo AND x.Project=d.Project AND x.ACO=d.ACO AND x.POCONum=d.POCONum)
---- link side ACO
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN dbo.vPMPOCO h ON h.POCo=d.POCo AND h.PO=d.PO AND h.POCONum=d.POCONum
INNER JOIN dbo.bPMOH c ON c.PMCo=d.PMCo AND c.Project=d.Project AND c.ACO=d.ACO
INNER JOIN dbo.vPMRelateRecord a ON a.RecTableName='PMOH' AND a.RECID=c.KeyID AND a.LinkTableName='PMPOCO' AND a.LINKID=h.KeyID
WHERE d.ACO IS NOT NULL AND d.POCONum IS NOT NULL
AND NOT EXISTS(SELECT 1 FROM dbo.bPMMF x WHERE x.PMCo=d.PMCo AND x.Project=d.Project AND x.ACO=d.ACO AND x.POCONum=d.POCONum)

---- delete purchase order association if only no others detail exists for PCO
---- record side
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN dbo.bPOHD h ON h.POCo=d.POCo AND h.PO=d.PO
INNER JOIN dbo.bPMOP c ON c.PMCo=d.PMCo AND c.Project=d.Project AND c.PCOType=d.PCOType AND c.PCO=d.PCO
INNER JOIN dbo.vPMRelateRecord a ON a.RecTableName='PMOP' AND a.RECID=c.KeyID AND a.LinkTableName='POHD' AND a.LINKID=h.KeyID
WHERE d.PO IS NOT NULL AND d.PCO IS NOT NULL
AND NOT EXISTS(SELECT 1 FROM dbo.PMMF x WHERE x.PMCo=d.PMCo
			AND x.Project=d.Project AND x.PCOType=d.PCOType AND x.PCO=d.PCO AND x.PO=d.PO)
---- link side
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN dbo.bPOHD h ON h.POCo=d.POCo AND h.PO=d.PO
INNER JOIN dbo.bPMOP c ON c.PMCo=d.PMCo AND c.Project=d.Project AND c.PCOType=d.PCOType AND c.PCO=d.PCO
INNER JOIN dbo.vPMRelateRecord a ON a.RecTableName='PMOP' AND a.RECID=c.KeyID AND a.LinkTableName='POHD' AND a.LINKID=h.KeyID
WHERE d.PO IS NOT NULL AND d.PCO IS NOT NULL
AND NOT EXISTS(SELECT 1 FROM dbo.PMMF x WHERE x.PMCo=d.PMCo
			AND x.Project=d.Project AND x.PCOType=d.PCOType AND x.PCO=d.PCO AND x.PO=d.PO)

---- TK-12630 missed POCO related to ACO
---- delete subcontract association if only no others detail exists for ACO
---- record side PCO
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN dbo.vPMPOCO h ON h.POCo=d.POCo AND h.PO=d.PO AND h.POCONum=d.POCONum
INNER JOIN dbo.bPMOP c ON c.PMCo=d.PMCo AND c.Project=d.Project AND c.PCOType=d.PCOType AND c.PCO=d.PCO
INNER JOIN dbo.vPMRelateRecord a ON a.RecTableName='PMPOCO' AND a.RECID=h.KeyID AND a.LinkTableName='PMOP' AND a.LINKID=c.KeyID
WHERE d.PCO IS NOT NULL AND d.POCONum IS NOT NULL
AND NOT EXISTS(SELECT 1 FROM dbo.bPMMF x WHERE x.PMCo=d.PMCo AND x.Project=d.Project AND x.PCOType=d.PCOType AND x.PCO=d.PCO AND x.POCONum=d.POCONum)
---- link side PCO
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN inserted i ON i.KeyID=d.KeyID
INNER JOIN dbo.vPMPOCO h ON h.POCo=d.POCo AND h.PO=d.PO AND h.POCONum=d.POCONum
INNER JOIN dbo.bPMOP c ON c.PMCo=d.PMCo AND c.Project=d.Project AND c.PCOType=d.PCOType AND c.PCO=d.PCO
INNER JOIN dbo.vPMRelateRecord a ON a.RecTableName='PMOP' AND a.RECID=c.KeyID AND a.LinkTableName='PMPOCO' AND a.LINKID=h.KeyID
WHERE d.PCO IS NOT NULL AND d.POCONum IS NOT NULL
AND NOT EXISTS(SELECT 1 FROM dbo.bPMMF x WHERE x.PMCo=d.PMCo AND x.Project=d.Project AND x.PCOType=d.PCOType AND x.PCO=d.PCO AND x.POCONum=d.POCONum)




---- delete material order association if only no others detail exists for ACO
---- record side
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN dbo.bINMO h ON h.INCo=d.INCo AND h.MO=d.MO
INNER JOIN dbo.bPMOH c ON c.PMCo=d.PMCo AND c.Project=d.Project AND c.ACO=d.ACO
INNER JOIN dbo.vPMRelateRecord a ON a.RecTableName='PMOH' AND a.RECID=c.KeyID AND a.LinkTableName='INMO' AND a.LINKID=h.KeyID
WHERE d.MO IS NOT NULL AND d.ACO IS NOT NULL
AND NOT EXISTS(SELECT 1 FROM dbo.PMMF x WHERE x.PMCo=d.PMCo
			AND x.Project=d.Project AND x.ACO=d.ACO AND x.MO=d.MO)
---- link side
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN dbo.bINMO h ON h.INCo=d.INCo AND h.MO=d.MO
INNER JOIN dbo.bPMOH c ON c.PMCo=d.PMCo AND c.Project=d.Project AND c.ACO=d.ACO
INNER JOIN dbo.vPMRelateRecord a ON a.RecTableName='INMO' AND a.RECID=h.KeyID AND a.LinkTableName='PMOH' AND a.LINKID=c.KeyID
WHERE d.MO IS NOT NULL AND d.ACO IS NOT NULL
AND NOT EXISTS(SELECT 1 FROM dbo.PMMF x WHERE x.PMCo=d.PMCo
			AND x.Project=d.Project AND x.ACO=d.ACO AND x.MO=d.MO)


---- delete material order association if only no others detail exists for PCO
---- record side
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN dbo.bINMO h ON h.INCo=d.INCo AND h.MO=d.MO
INNER JOIN dbo.bPMOP c ON c.PMCo=d.PMCo AND c.Project=d.Project AND c.PCOType=d.PCOType AND c.PCO=d.PCO
INNER JOIN dbo.vPMRelateRecord a ON a.RecTableName='PMOP' AND a.RECID=c.KeyID AND a.LinkTableName='INMO' AND a.LINKID=h.KeyID
WHERE d.MO IS NOT NULL AND d.PCO IS NOT NULL
AND NOT EXISTS(SELECT 1 FROM dbo.PMMF x WHERE x.PMCo=d.PMCo
			AND x.Project=d.Project AND x.PCOType=d.PCOType AND x.PCO=d.PCO AND x.MO=d.MO)
---- link side
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN dbo.bINMO h ON h.INCo=d.INCo AND h.MO=d.MO
INNER JOIN dbo.bPMOP c ON c.PMCo=d.PMCo AND c.Project=d.Project AND c.PCOType=d.PCOType AND c.PCO=d.PCO
INNER JOIN dbo.vPMRelateRecord a ON a.RecTableName='INMO' AND a.RECID=h.KeyID AND a.LinkTableName='PMOP' AND a.LINKID=c.KeyID
WHERE d.MO IS NOT NULL AND d.PCO IS NOT NULL
AND NOT EXISTS(SELECT 1 FROM dbo.PMMF x WHERE x.PMCo=d.PMCo
			AND x.Project=d.Project AND x.PCOType=d.PCOType AND x.PCO=d.PCO AND x.MO=d.MO)






--------------
-- TK-04287 --
--------------
UPDATE	ol
   SET	POCONum = NULL, POCONumSeq = NULL
  FROM	dbo.bPMOL ol
  JOIN	deleted d ON ol.PMCo=d.PMCo AND ol.Project=d.Project
   AND	ol.Phase=d.Phase AND ol.CostType=d.CostType
 WHERE	ol.POCONum = d.POCONum
   AND	ol.POCONumSeq = d.Seq



---- Audit inserts
insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bPMMF','PMCo: ' + isnull(convert(char(3),d.PMCo), '') + ' Project: ' + isnull(d.Project,'')
		+ ' Seq: ' + isnull(convert(varchar(10),d.Seq),'')+ ' Phase: ' + isnull(d.Phase,'')
		+ ' CostType: ' + isnull(convert(varchar(3),d.CostType),''), d.PMCo, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
from deleted d join bPMCO c on c.PMCo = d.PMCo
where d.PMCo = c.PMCo and c.AuditPMMF = 'Y'


return


error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot delete PMMF'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction




GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*********************************************************/
CREATE trigger [dbo].[btPMMFi] on [dbo].[bPMMF] for INSERT as
/*--------------------------------------------------------------
 * Insert trigger for PMMF
 * Created By:	LM 12/22/97
 * Modified By:	GF 05/03/2000
 *                  GF 04/23/2001 - use Job Ship Data when inserting POHD
 *                  GF 05/30/2001 - added validation for units <> 0 and UM='LS'
 *					GF 01/22/2002 - added validation for units = 0, amount <> 0, and UM <> 'LS'
 *					GF 02/07/2002 - added insert for MSQH if type 'Q', also UM = 'LS' not allowed
 *					GF 02/14/2002 - added insert for INMO if type 'M', also UM = 'LS' not allowed
 *                  DANF 09/06/02 - 17738 added phase group to bspJCADDCOSTTYPE
 *					GF 10/09/2002 - Changed DBL quotes to single quotes.
 *					GF 08/29/2003 - issue #21541 - 2nd address line. Also performance improvement.
 *					GF 09/08/2003 - issue #      - verify tax type has tax code and vis-versa
 *					GWC  03/19/04 - added dbo. before all stored procedure calls
 *					GF 08/20/2004 - issue #25482 - change validation for material option to allow 'R' for requisitions
 *					GF 01/15/2007 - 6.x HQMA auditing
 *					DC 01/28/08 - Issue 121529 - Increase the PO change order line description to 60.
 *					GF 03/11/2008 - issue #127076 country for POHD and MSQH
 *				GF 07/24/2008 - issue #129065 need to check PMOL for existance by pending or approved not both
 *				GF 04/01/2009 - issue #129409 oil price escalation
 *				GF 11/21/2009 - issue #136679 exclude PO's without vendor
 *				GF 11/02/2010 - issue #141957 record association
 *				GF 11/05/2010 - issue #141031
 *				GF 11/19/2010 - issue #141715 use pm company subcontract option for PMOL units and costs
 *				AMR 01/17/11 - #142350, making case insensitive by removing unused vars and renaming same named variables
 *				GF 03/02/2011 - TK-01846 use impact budget and sub types when adding to PMOL
 *				GP 03/10/2011 - B-03081 changed validation of material to avoid errors in PMPCOItemDetail
 *				GF 04/08/2011 - TK-03857 TK-03569 TK-05205
 *				GF 06/21/2011 - TK-06121
 *				GF 06/22/2011 - D-02339 use view not tables for links
 *				GP 7/27/2011 - TK-07144 changed bPO to varchar(30)
 *				JayR 03/22/2012 Change to use FK and table constraints for validation
 *
 *--------------------------------------------------------------*/
--#142350 - renaming @poco and @po
declare @numrows int, @errmsg varchar(255), @validcnt int, @validcnt2 int, @rcode int,
   		@pmco bCompany, @project bJob, @seq int, @location bLoc, @MaterialGroup bGroup,
   		@MaterialOption char(1), @material bMatl, @PhaseGroup bGroup, @Phase bPhase,
   		@CostType bJCCType, @UM bUM, @POCo bCompany, @VendorGroup bGroup, @Vendor bVendor,
   		@PO varchar(30), @POCompGroup varchar(10), @Description bItemDesc,
		@recordtype char(1),
   		@pcotype bDocType, @pco bPCO, @pcoitem bPCOItem, @aco bACO, @acoitem bACOItem,
   		@Units bUnits, @UnitCost bUnitCost, @ECM bECM, @EstCost bDollar, @SendYN bYN,
   		@UnitHours bHrs, @EstHours bHrs, @HourCost bUnitCost, @PhaseUM bUM,
   		@retcode int, @retmsg varchar(150), @address varchar(60), @city varchar(30),
   		@state varchar(4), @zip bZip, @msco bCompany, @quote varchar(10), @validcnt1 int,
   		@msjcco bCompany, @msjob bJob, @datequoted bDate, @inco bCompany, @stocked bYN,
   		@pricetemplate smallint, @mo varchar(10), @address2 varchar(60), @shipcountry varchar(2),
   		@SubItemPhase bPhase, @SubItemCostType bJCCType, @SubItemUM bUM, @SubItemMatl bMatl,
   		@POItem smallint, @MOItem SMALLINT, @POID BIGINT, @MOID BIGINT, @ACOID BIGINT,
   		@PCOID BIGINT, @POCoIns TINYINT, @POIns VARCHAR(30), @mtct1option TINYINT,
		----TK-01846 TK-03569
		@BudgetType CHAR(1), @POType CHAR(1), @POCONum_Status VARCHAR(6), @POCONum SMALLINT ,
		@PurchaseAmt bDollar, @MaterialCode bMatl, @PurchaseUnits bUnits, @PurchaseUM bUM,
		@PurchaseUnitCost bUnitCost

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

select @datequoted = dbo.vfDateOnly()

---- no MaterialOption 'R' if PMCO.RQInUse = 'N'
select @validcnt = count(*) from inserted i join bPMCO c with (nolock) on i.PMCo=c.PMCo
where i.MaterialOption = 'R' and c.RQInUse = 'N'
if @validcnt <> 0
   	begin
   	select @errmsg = 'Invalid material option (R)equisition, not flagged as in use in PM Company!'
   	goto error
   	end

---- validate MS company for material option (Q)uote
select @validcnt = count(*) from inserted i where i.MaterialOption='Q'
select @validcnt1 = count(*) from bMSCO r with (nolock) JOIN inserted i ON i.MSCo=r.MSCo where i.MaterialOption='Q'
select @validcnt2 = count(*) from inserted i where i.MSCo is null and i.MaterialOption='Q'
if @validcnt <> @validcnt1 + @validcnt2
	begin
	select @errmsg = 'Invalid MS company '
	goto error
	end

---- validate IN company for material option (M)aterial Order
select @validcnt = count(*) from inserted i where i.MaterialOption='M'
select @validcnt1 = count(*) from bINCO r with (nolock) JOIN inserted i ON i.INCo=r.INCo where i.MaterialOption='M'
select @validcnt2 = count(*) from inserted i where i.INCo is null and i.MaterialOption='M'
if @validcnt <> @validcnt1 + @validcnt2
	begin
	select @errmsg = 'Invalid IN company '
	goto error
	end

---- begin process
if @numrows = 1
	begin
   	select @pmco=PMCo, @project=Project, @seq=Seq
   	from inserted
	end
else
   	begin
   	---- use a cursor to process each updated row
   	declare bPMMF_insert cursor LOCAL FAST_FORWARD
   	for select PMCo, Project, Seq
   	from inserted
   
   	open bPMMF_insert
   	
   	fetch next from bPMMF_insert into @pmco, @project, @seq
	if @@fetch_status <> 0
   		begin
   		select @errmsg = 'Cursor error'
   		goto error
   		end
   	end


insert_check:
---- get JCJM info
select @POCompGroup=POCompGroup, @address=ShipAddress, @city=ShipCity, @state=ShipState,
   	   @zip=ShipZip, @pricetemplate=PriceTemplate, @address2=ShipAddress2, @shipcountry=ShipCountry
from bJCJM WITH (NOLOCK) where JCCo = @pmco and Job = @project

select @PhaseGroup=PhaseGroup, @Phase=Phase, @CostType=CostType, @MaterialGroup=MaterialGroup,
   		@material=MaterialCode, @location=Location, @MaterialOption=MaterialOption, @UM=UM,
   		@POCo=POCo, @VendorGroup=VendorGroup, @Vendor=Vendor, @PO=PO, @Description=MtlDescription,
   		@recordtype=RecordType, @pcotype=PCOType, @pco=PCO, @pcoitem=PCOItem, @aco=ACO,
   		@acoitem=ACOItem, @Units=Units, @UnitCost=UnitCost, @ECM=ECM, @EstCost=Amount,
   		@SendYN=SendFlag, @msco=MSCo, @quote=Quote, @inco=INCo, @mo=MO, @POItem=POItem,
   		@MOItem=MOItem, @POCoIns=POCo, @POIns=PO, @POCONum=POCONum ----TK-03569
from inserted where PMCo=@pmco and Project=@project and Seq=@seq

---- glet sl cost type option #141715
SET @mtct1option = 2
select @mtct1option=MTCT1Option
from dbo.bPMCO with (nolock) where PMCo=@pmco
IF ISNULL(@mtct1option,0) = 0 SET @mtct1option = 2

---- validate pending change order
if @recordtype = 'C'
   	begin
   	if isnull(@pcotype,'') <> ''
   		begin
   		if not exists(select top 1 1 from bPMOI with (nolock) where PMCo=@pmco and Project=@project
   					and PCOType=@pcotype and PCO=@pco and PCOItem=@pcoitem)
   			begin
   			select @errmsg = 'PCO is invalid: PCOType: ' + isnull(@pcotype,'') + ' PCO: ' + isnull(@pco,'') + ' PCOItem: ' + isnull(@pcoitem,'') + ' !'
   			goto error
   			end
   		end

   	---- validate approved change order
   	if isnull(@aco,'') <> ''
   		begin
   		if not exists(select top 1 1 from bPMOI with (nolock) where PMCo=@pmco and Project=@project
   					and ACO=@aco and ACOItem=@acoitem)
   			begin
   			select @errmsg = 'ACO is invalid: ACO: ' + isnull(@aco,'') + ' ACOItem: ' + isnull(@acoitem,'') + ' !'
   			goto error
   			end
   		end
   	end

if @Phase is not null
   	begin
   	---- validate standard phase
   	exec @rcode = dbo.bspJCADDPHASE @pmco, @project, @PhaseGroup, @Phase, 'Y', null, @errmsg output
   	if @rcode <> 0 goto error
   	---- validate Cost Type - if JCCH doesnt exist try to add it
   	exec @rcode = dbo.bspJCADDCOSTTYPE @jcco=@pmco, @job=@project, @phasegroup=@PhaseGroup, @phase=@Phase, 
   					@costtype=@CostType,  @um=@UM, @override= 'P', @msg=@errmsg output
   	if @rcode <> 0 goto error
   	end

---- Validate PO/insert PO
if @MaterialOption = 'P' and @PO is not null
   	begin
   	---- #136679
   	if @Vendor is null
   		begin
   		select @errmsg = 'Missing Vendor for PO: ' + isnull(@PO,'') + '.'
   		goto error
   		end

	---- check POIT for item, if found phase/costtype must exist
   	select @SubItemPhase = Phase, @SubItemCostType = JCCType, @SubItemUM = UM, @SubItemMatl = Material
   	from dbo.bPOIT where POCo=@POCo and PO=@PO and POItem=@POItem
   	-- set @material to match POIT value to bypass error in PMPCOS Item Detail - B-03081
   	set @material = @SubItemMatl
   	if @@rowcount <> 0
   		begin
   		if @SubItemPhase <> @Phase or @SubItemCostType <> @CostType or @SubItemUM <> @UM or isnull(@SubItemMatl,'') <> isnull(@material,'')
   			begin
			select @errmsg = 'PO: ' + isnull(@PO,'') + ' POItem: ' + convert(varchar(8),isnull(@POItem,0)) 
   					+ ' - Multiple records set up for same item with different Phase/CostType/UM/Material combination.'
			goto error
			END
		end
		
   	if not exists (select top 1 1 from bPOHD WITH (NOLOCK) where POCo=@POCo and PO=@PO)
   		begin
   		insert bPOHD (POCo, PO, VendorGroup, Vendor, Description, OrderDate, Status, JCCo, Job,
				CompGroup, PayTerms, Address, City, State, Zip, Purge, Approved,
				Address2, Country)
   		select @POCo, @PO, @VendorGroup, @Vendor, @Description, dbo.vfDateOnly(), 3, @pmco,
				@project, @POCompGroup, m.PayTerms, @address, @city, @state, @zip, 'N', 'N',
				@address2, @shipcountry
   		from bAPVM m with (nolock) where m.VendorGroup=@VendorGroup and m.Vendor=@Vendor
   		if @@rowcount <> 1
   			begin
   			select @errmsg = ' Cannot insert into POHD '
   			goto error
   			end
   		END
   		
	---- TK-03569
	IF @POCONum IS NOT NULL
		BEGIN
		---- get beginning status for POCONum from PMSC TK-03569
		SET @POCONum_Status = NULL
		select Top 1 @POCONum_Status = Status
		FROM dbo.bPMSC WHERE DocCat = 'PURCHASECO' AND CodeType = 'B'
		----TK-05205
		IF @@ROWCOUNT = 0
			BEGIN
			SELECT @POCONum_Status = BeginStatus
			FROM dbo.bPMCO WHERE PMCo=@pmco
			END

		IF NOT EXISTS(SELECT 1 FROM dbo.vPMPOCO WHERE POCo=@POCo AND PO=@PO AND POCONum=@POCONum)
			BEGIN
			INSERT INTO dbo.vPMPOCO (PMCo, Project, POCo, PO, POCONum, Description, Status, Date)
			VALUES (@pmco, @project, @POCo, @PO, @POCONum, @Description, @POCONum_Status, dbo.vfDateOnly())
			END
		END
   		
   	END

---- initiate project firm for PO and MO where vendor is not null
if isnull(@Vendor,0) <> 0
   	begin
   	-- insert Project Firm if needed
   	select @validcnt=count(*) from bPMPF WITH (NOLOCK)
   	where PMCo=@pmco and Project=@project and VendorGroup=@VendorGroup and FirmNumber=@Vendor
   	if @validcnt = 0
   		begin
   		exec @retcode = dbo.bspPMSLFirmContactInit @pmco, @project, @VendorGroup, @Vendor, @retmsg output
   		end
   	end

---- validate material for types (M) and (Q)
if @MaterialOption in ('M','Q')
   	begin
   	-- validate material
   	select @stocked=Stocked from bHQMT WITH (NOLOCK) where MatlGroup=@MaterialGroup and Material=@material
   	if @@rowcount = 0
   		begin
   		select @errmsg = ' Material ' + isnull(@material,'') + ' is invalid '
   		goto error
   		end
   	if @stocked = 'N'
   		begin
   		select @errmsg = ' Material ' + isnull(@material,'') + ' is not a stocked material '
   		goto error
   		end
   	end

---- validate (M)aterial Order type
if @MaterialOption = 'M'
   	begin
   	if @inco is not null and @location is not null
   		begin
   		---- validate location
   		if not exists(select top 1 1 from bINLM WITH (NOLOCK) where INCo=@inco and Loc=@location)
   			begin
   			select @errmsg = ' Location ' + isnull(@location,'') + ' is Invalid '
   			goto error
   			end
   			
   		---- validate material at location
   		if not exists(select top 1 1 from bINMT WITH (NOLOCK) where INCo=@inco and Loc=@location
   							and MatlGroup=@MaterialGroup and Material=@material)
   			begin
   			select @errmsg = ' Material ' + isnull(@material,'') + ' is not valid for Location ' + isnull(@location,'') + ' '
   			goto error
   			end
   
   		---- validate MO - insert MO
   		if @mo is not null
   			begin
			---- check INMI for item, if found phase/costtype must exist
   			select @SubItemPhase = Phase, @SubItemCostType = JCCType, @SubItemUM = UM, @SubItemMatl = Material
   			from dbo.bINMI where INCo=@inco and MO=@mo and MOItem=@MOItem
   			if @@rowcount <> 0
   				begin
   				if @SubItemPhase <> @Phase or @SubItemCostType <> @CostType or @SubItemUM <> @UM or isnull(@SubItemMatl,'') <> isnull(@material,'')
   					begin
					select @errmsg = 'MO: ' + isnull(@mo,'') + ' MOItem: ' + convert(varchar(8),isnull(@MOItem,0)) 
   							+ ' - Multiple records set up for same item with different Phase/CostType/UM/Material combination.'
					goto error
					END
				end
   			
   			if not exists (select top 1 1 from bINMO WITH (NOLOCK) where INCo=@inco and MO=@mo)
   				begin
   				insert bINMO (INCo, MO, Description, JCCo, Job, OrderDate, Status, Purge, Approved)
   				select @inco, @mo, @Description, @pmco, @project, dbo.vfDateOnly(), 3, 'N', 'N'
   				if @@rowcount <> 1
   					begin
   					select @errmsg = ' Cannot insert into INMO '
   					goto error
   					end
   				end
   			end
   		end
   	end

---- validate (Q)uote type
if @MaterialOption = 'Q'
   	begin
   	if @msco is not null and @quote is not null
   		begin
   		---- validate location
   		if not exists (select top 1 1 from bINLM WITH (NOLOCK) where INCo=@msco and Loc=@location)
   			begin
           	select @errmsg =' Location ' + isnull(@location,'') + ' is Invalid '
           	goto error
   			end
   
   		---- check if quote set up for different jc company and job
   		select @msjcco=JCCo, @msjob=Job from bMSQH WITH (NOLOCK) where MSCo=@msco and Quote=@quote
   		if @@rowcount <> 0
   			begin
   			if isnull(@msjcco,0) <> @pmco or isnull(@msjob,'') <> @project
   				begin
                  	select @errmsg = ' Invalid quote - ' + isnull(@quote,'') + ' set up for different JCCO and Job'
                  	goto error
                  	end
   			end
   			
   		---- check for quote already assigned for MS company
   		if exists(select 1 from bMSQH WITH (NOLOCK) where MSCo=@msco and QuoteType='J' and JCCo=@pmco 
   						and Job=@project and Quote<>@quote)
   			begin
   			select @errmsg = 'Quote is already set up for JC company and Job in MS. Only one allowed.'
   			goto error
   			end
   			
   		---- verify Job price template is valid for MSCo
   		if isnull(@pricetemplate,0) <> 0
   			begin
   			select @validcnt=count(*) from bMSTH WITH (NOLOCK) where MSCo=@msco and PriceTemplate=@pricetemplate
   			if @validcnt = 0 select @pricetemplate = null
   			end
   
   		---- insert quote in MSQH
   		if not exists(select top 1 1 from bMSQH WITH (NOLOCK) where MSCo=@msco and Quote=@quote)
   			begin
   			insert into bMSQH(MSCo, Quote, QuoteType, JCCo, Job, Description, Contact, Phone, ShipAddress,
   						City, State, Zip, ShipAddress2, PriceTemplate, TaxGroup, TaxCode, HaulTaxOpt, Active,
   						QuotedBy, QuoteDate, SepInv, PurgeYN, Country, ApplyEscalators, BidIndexDate)
   			select @msco, @quote, 'J', @pmco, @project, j.Description, m.Name, j.JobPhone, j.ShipAddress,
   						j.ShipCity, j.ShipState, j.ShipZip, j.ShipAddress2, @pricetemplate, j.TaxGroup, j.TaxCode,
   						j.HaulTaxOpt, 'N', convert(varchar(30),suser_sname()), @datequoted,
						'N', 'N', j.ShipCountry, 'N', null
   			from bJCJM j with (nolock) left join bJCMP m with (nolock) on m.JCCo=j.JCCo and m.ProjectMgr=j.ProjectMgr
   			where j.JCCo=@pmco and j.Job=@project
   			if @@rowcount <> 1
   				begin
   				select @errmsg = 'Error inserting MS quote header'
   				goto error
   				end
   			end
   		end
   	end

---- Add a record to change order detail if this is a change order and not already in PMOL
----TK-01846
if @recordtype = 'C' AND @mtct1option <> 1
   	begin
	if isnull(@pcotype,'') <> '' and isnull(@pco,'') <> ''
		BEGIN
		----TK-01846
		SELECT @BudgetType=BudgetType, @POType=POType
		FROM dbo.bPMOP where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco 
		
		---- check the pending detail for phase and cost type
   		if not exists (select top 1 1 from bPMOL with (nolock) where PMCo=@pmco 
   					and Project=@project and PCOType=@pcotype and PCO=@pco and PCOItem=@pcoitem
   					and PhaseGroup=@PhaseGroup and Phase=@Phase and CostType=@CostType)
   			begin
   			SET @UnitHours=0
   			SET @EstHours=0
   			SET @HourCost=0
   			--- get phase cost type um
   			select @PhaseUM=UM 
   			from dbo.bJCCH
   			where JCCo=@pmco 
   				and Job=@project 
   				and PhaseGroup=@PhaseGroup 
   				and Phase=@Phase 
   				and CostType=@CostType
   			---- if no JCCH record found use PMSL um
   			IF @@ROWCOUNT = 0 SET @PhaseUM = @UM
   			
   			---- set purchase values if PCO set up for subcontract impact type TK-05178
   			IF @POType = 'Y'
   				BEGIN
   				SET @MaterialCode = @material
   				SET @PurchaseUM = @UM
   				SET @PurchaseUnits = @Units
   				SET @PurchaseUnitCost = @UnitCost
				SET @PurchaseAmt = @EstCost
				END
			ELSE
				BEGIN
				SET @PurchaseUM = NULL
   				SET @PurchaseUnits = 0
   				SET @PurchaseUnitCost = 0
				SET @PurchaseAmt = 0
				END
				
   			---- TK-06039
   			---- if the JCCH um <> PMMF UM then zero out estimate values
			if @PhaseUM <> @UM
   				 begin
   				 SET @Units = 0
   				 SET @UnitCost = 0
   				 END
   			
	      	----#141715
			if @mtct1option = 3
				begin
				SET @Units = 0
				SET @UnitCost=0
				SET @EstCost = 0
				END

			---- TK-01846 we need to check the PCO impact types to set what we actual update to PMOL
			IF @BudgetType = 'N'
				BEGIN
				SET @Units = 0
				SET @UnitCost=0
				SET @EstCost = 0
				END
				
   			---- insert change order detail record TK-01846 TK-06121
   			insert bPMOL (PMCo, Project, PCOType, PCO, PCOItem, ACO, ACOItem, PhaseGroup, Phase, CostType,
   					EstUnits, UM, UnitHours, EstHours, HourCost, UnitCost, ECM, EstCost,
   					SendYN, VendorGroup, Vendor, PO, POSLItem, POCONum, POCONumSeq,
   					MaterialCode, PurchaseUnits, PurchaseUM, PurchaseUnitCost, PurchaseAmt)
   			values (@pmco, @project, @pcotype, @pco, @pcoitem, @aco, @acoitem, @PhaseGroup, @Phase,
   					@CostType, @Units, @PhaseUM, @UnitHours, @EstHours, @HourCost, @UnitCost,
   					ISNULL(@ECM,'E'), @EstCost, @SendYN, @VendorGroup,
   					CASE WHEN @POType = 'Y' THEN @Vendor ELSE NULL END,
   					CASE WHEN @POType = 'Y' THEN @PO ELSE NULL END,
   					CASE WHEN @POType = 'Y' THEN @POItem ELSE NULL END,
   					CASE WHEN @POType = 'Y' AND @POCONum IS NOT NULL THEN @POCONum ELSE NULL END,
   					CASE WHEN @POType = 'Y' AND @POCONum IS NOT NULL THEN @seq ELSE NULL END,
   					----TK-06121
   					CASE WHEN @POType = 'Y' THEN @MaterialCode ELSE NULL END,
   					CASE WHEN @POType = 'Y' THEN @PurchaseUnits ELSE 0 END,
   					CASE WHEN @POType = 'Y' THEN @PurchaseUM ELSE NULL END,
   					CASE WHEN @POType = 'Y' THEN @PurchaseUnitCost ELSE 0 END,
   					CASE WHEN @POType = 'Y' THEN @PurchaseAmt ELSE 0 END
   					)
   			end
		END
	else
		BEGIN
		---- check the approved detail for phase and cost type
   		if not exists (select top 1 1 from bPMOL with (nolock) where PMCo=@pmco 
   						and Project=@project and ACO=@aco and ACOItem=@acoitem 
   						and PhaseGroup=@PhaseGroup and Phase=@Phase and CostType=@CostType)
   			BEGIN
   			----TK-01846
			SET @BudgetType='Y'
			SET @POType='Y'
			
			---- set estimate cost
   			SET @UnitHours=0
   			SET @EstHours=0
   			SET @HourCost=0
   			---- get cost type um
   			select @PhaseUM=UM
   			from dbo.bJCCH 
   			where JCCo=@pmco 
   				and Job=@project 
   				and PhaseGroup=@PhaseGroup 
   				and Phase=@Phase 
   				and CostType=@CostType
   			---- if no JCCH record found use PMSL um
   			IF @@ROWCOUNT = 0 SET @PhaseUM = @UM
   			
   			---- set purchase values if PCO set up for subcontract impact type TK-05178
   			IF @POType = 'Y'
   				BEGIN
   				SET @MaterialCode = @material
   				SET @PurchaseUM = @UM
   				SET @PurchaseUnits = @Units
   				SET @PurchaseUnitCost = @UnitCost
				SET @PurchaseAmt = @EstCost
				END
			ELSE
				BEGIN
				SET @PurchaseUM = NULL
   				SET @PurchaseUnits = 0
   				SET @PurchaseUnitCost = 0
				SET @PurchaseAmt = 0
				END
				
   			---- TK-06039
   			---- if the JCCH um <> PMMF UM then zero out estimate values
			if @PhaseUM <> @UM
   				 begin
   				 SET @Units = 0
   				 SET @UnitCost = 0
   				 END
   			
	      	----#141715
			if @mtct1option = 3
				begin
				SET @Units = 0
				SET @UnitCost=0
				SET @EstCost = 0
				END

			---- TK-01846 we need to check the PCO impact types to set what we actual update to PMOL
			IF @BudgetType = 'N'
				BEGIN
				SET @Units = 0
				SET @UnitCost=0
				SET @EstCost = 0
				END

   			---- insert change order detail record TK-01846 TK-06121
   			insert bPMOL (PMCo, Project, PCOType, PCO, PCOItem, ACO, ACOItem, PhaseGroup, Phase, CostType,
   					EstUnits, UM, UnitHours, EstHours, HourCost, UnitCost, ECM, EstCost,
   					SendYN, VendorGroup, Vendor, PO, POSLItem, POCONum, POCONumSeq,
   					MaterialCode, PurchaseUnits, PurchaseUM, PurchaseUnitCost, PurchaseAmt)
   			values (@pmco, @project, @pcotype, @pco, @pcoitem, @aco, @acoitem, @PhaseGroup, @Phase,
   					@CostType, @Units, @PhaseUM, @UnitHours, @EstHours, @HourCost, @UnitCost,
   					ISNULL(@ECM,'E'), @EstCost, @SendYN, @VendorGroup,
   					CASE WHEN @POType = 'Y' THEN @Vendor ELSE NULL END,
   					CASE WHEN @POType = 'Y' THEN @PO ELSE NULL END,
   					CASE WHEN @POType = 'Y' THEN @POItem ELSE NULL END,
   					CASE WHEN @POType = 'Y' AND @POCONum IS NOT NULL THEN @POCONum ELSE NULL END,
   					CASE WHEN @POType = 'Y' AND @POCONum IS NOT NULL THEN @seq ELSE NULL END,
   					----TK-06121
   					CASE WHEN @POType = 'Y' THEN @MaterialCode ELSE NULL END,
   					CASE WHEN @POType = 'Y' THEN @PurchaseUnits ELSE 0 END,
   					CASE WHEN @POType = 'Y' THEN @PurchaseUM ELSE NULL END,
   					CASE WHEN @POType = 'Y' THEN @PurchaseUnitCost ELSE 0 END,
   					CASE WHEN @POType = 'Y' THEN @PurchaseAmt ELSE 0 END
   					)
   			end
		end
   	end


-- finished with validation and updates (except HQ Audit)
Valid_Finished:
if @numrows > 1
   	begin
	fetch next from bPMMF_insert into @pmco, @project, @seq
	if @@fetch_status = 0
		begin
		goto insert_check
		end
	else
		begin
		close bPMMF_insert
		deallocate bPMMF_insert
		end
	end


---- insert vPMRelateRecord for various links PCO/ACO/POCONum/POHD TK-03569
---- PCO and POCONum
INSERT INTO dbo.vPMRelateRecord(RecTableName, RECID, LinkTableName, LINKID)
SELECT DISTINCT 'PMPOCO', a.KeyID, 'PMOP', b.KeyID
FROM inserted i
INNER JOIN dbo.vPMPOCO a ON a.POCo=i.POCo AND a.PO=i.PO AND a.POCONum=i.POCONum
INNER JOIN dbo.bPMOP b ON b.PMCo=i.PMCo AND b.Project=i.Project AND b.PCOType=i.PCOType AND b.PCO=i.PCO
WHERE i.POCONum IS NOT NULL AND i.PCO IS NOT NULL AND i.PO IS NOT NULL
AND NOT EXISTS(SELECT 1 FROM dbo.vPMRelateRecord c WHERE c.RecTableName='PMPOCO' AND c.RECID=a.KeyID
				AND c.LinkTableName='PMOP' AND c.LINKID=b.KeyID)
AND NOT EXISTS(SELECT 1 FROM dbo.vPMRelateRecord d WHERE d.RecTableName='PMOP' AND d.RECID=b.KeyID
				AND d.LinkTableName='PMPOCO' AND d.LINKID=a.KeyID)

---- ACO and POCONum
INSERT INTO dbo.vPMRelateRecord(RecTableName, RECID, LinkTableName, LINKID)
SELECT DISTINCT 'PMPOCO', a.KeyID, 'PMOH', b.KeyID
FROM inserted i
INNER JOIN dbo.vPMPOCO a ON a.POCo=i.POCo AND a.PO=i.PO AND a.POCONum=i.POCONum
INNER JOIN dbo.bPMOH b ON b.PMCo=i.PMCo AND b.Project=i.Project AND b.ACO=i.ACO
WHERE i.POCONum IS NOT NULL AND i.ACO IS NOT NULL AND i.PO IS NOT NULL
AND NOT EXISTS(SELECT 1 FROM dbo.vPMRelateRecord c WHERE c.RecTableName='PMPOCO' AND c.RECID=a.KeyID
				AND c.LinkTableName='PMOH' AND c.LINKID=b.KeyID)
AND NOT EXISTS(SELECT 1 FROM dbo.vPMRelateRecord d WHERE d.RecTableName='PMOH' AND d.RECID=b.KeyID
				AND d.LinkTableName='PMPOCO' AND d.LINKID=a.KeyID)

---- PCO and PO
INSERT INTO dbo.vPMRelateRecord(RecTableName, RECID, LinkTableName, LINKID)
SELECT DISTINCT 'PMOP', a.KeyID, 'POHD', b.KeyID
FROM inserted i
INNER JOIN dbo.bPMOP a ON a.PMCo=i.PMCo AND a.Project=i.Project AND a.PCOType=i.PCOType AND a.PCO=i.PCO
INNER JOIN dbo.bPOHD b ON b.POCo=i.POCo AND b.PO=i.PO
WHERE i.PO IS NOT NULL AND i.PCO IS NOT NULL
AND NOT EXISTS(SELECT 1 FROM dbo.vPMRelateRecord c WHERE c.RecTableName='PMOP' AND c.RECID=a.KeyID
				AND c.LinkTableName='POHD' AND c.LINKID=b.KeyID)
AND NOT EXISTS(SELECT 1 FROM dbo.vPMRelateRecord d WHERE d.RecTableName='POHD' AND d.RECID=b.KeyID
				AND d.LinkTableName='PMOP' AND d.LINKID=a.KeyID)

---- ACO and PO
INSERT INTO dbo.vPMRelateRecord(RecTableName, RECID, LinkTableName, LINKID)
SELECT DISTINCT 'PMOH', a.KeyID, 'POHD', b.KeyID
FROM inserted i
INNER JOIN dbo.bPMOH a ON a.PMCo=i.PMCo AND a.Project=i.Project AND a.ACO=i.ACO
INNER JOIN dbo.bPOHD b ON b.POCo=i.POCo AND b.PO=i.PO
WHERE i.PO IS NOT NULL AND i.ACO IS NOT NULL
AND NOT EXISTS(SELECT 1 FROM dbo.vPMRelateRecord c WHERE c.RecTableName='PMOH' AND c.RECID=a.KeyID
				AND c.LinkTableName='POHD' AND c.LINKID=b.KeyID)
AND NOT EXISTS(SELECT 1 FROM dbo.vPMRelateRecord d WHERE d.RecTableName='POHD' AND d.RECID=b.KeyID
				AND d.LinkTableName='PMOH' AND d.LINKID=a.KeyID)

---- PCO and MO
INSERT INTO dbo.vPMRelateRecord(RecTableName, RECID, LinkTableName, LINKID)
SELECT DISTINCT 'PMOP', a.KeyID, 'INMO', b.KeyID
FROM inserted i
INNER JOIN dbo.bPMOP a ON a.PMCo=i.PMCo AND a.Project=i.Project AND a.PCOType=i.PCOType AND a.PCO=i.PCO
INNER JOIN dbo.bINMO b ON b.INCo=i.INCo AND b.MO=i.MO
WHERE i.MO IS NOT NULL AND i.PCO IS NOT NULL
AND NOT EXISTS(SELECT 1 FROM dbo.vPMRelateRecord c WHERE c.RecTableName='PMOP' AND c.RECID=a.KeyID
				AND c.LinkTableName='INMO' AND c.LINKID=b.KeyID)
AND NOT EXISTS(SELECT 1 FROM dbo.vPMRelateRecord d WHERE d.RecTableName='INMO' AND d.RECID=b.KeyID
				AND d.LinkTableName='PMOP' AND d.LINKID=a.KeyID)

---- ACO and MO
INSERT INTO dbo.vPMRelateRecord(RecTableName, RECID, LinkTableName, LINKID)
SELECT DISTINCT 'PMOH', a.KeyID, 'INMO', b.KeyID
FROM inserted i
INNER JOIN dbo.bPMOH a ON a.PMCo=i.PMCo AND a.Project=i.Project AND a.ACO=i.ACO
INNER JOIN dbo.bINMO b ON b.INCo=i.INCo AND b.MO=i.MO
WHERE i.MO IS NOT NULL AND i.ACO IS NOT NULL
AND NOT EXISTS(SELECT 1 FROM dbo.vPMRelateRecord c WHERE c.RecTableName='PMOH' AND c.RECID=a.KeyID
				AND c.LinkTableName='INMO' AND c.LINKID=b.KeyID)
AND NOT EXISTS(SELECT 1 FROM dbo.vPMRelateRecord d WHERE d.RecTableName='INMO' AND d.RECID=b.KeyID
				AND d.LinkTableName='PMOH' AND d.LINKID=a.KeyID)




---- Audit inserts
insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bPMMF','PMCo: ' + isnull(convert(char(3),i.PMCo), '') + ' Project: ' + isnull(i.Project,'')
		+ ' Seq: ' + isnull(convert(varchar(10),i.Seq),'') + ' Phase: ' + isnull(i.Phase,'')
		+ ' CostType: ' + isnull(convert(varchar(3),i.CostType),''), i.PMCo, 'A', NULL, NULL, NULL, getdate(), SUSER_SNAME()
from inserted i join bPMCO c on c.PMCo = i.PMCo
where i.PMCo = c.PMCo and c.AuditPMMF = 'Y'
   
   
return


error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot insert into PMMF'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
  
 





GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*************************************************************/
CREATE  trigger [dbo].[btPMMFu] on [dbo].[bPMMF] for UPDATE as
/*--------------------------------------------------------------
* Update trigger for PMMF
* Created By:	LM 12/23/97
* Modified By:	GF 05/03/2000
*				GF 04/23/2001 - use job shipping data when inserting POHD
*				GF 05/30/2001 - added validation for units <> 0 and UM='LS'
*				GF 01/22/2002 - added validation for units = 0, amount <> 0, and UM <> 'LS'
*				GF 02/07/2002 - added insert for MSQH if type 'Q', also UM = 'LS' not allowed
*				GF 02/14/2002 - added insert for INMO if type 'M', also UM = 'LS' not allowed
*				DANF 09/06/02 - 17738 Added Phase Group to bspJCADDCOSTTYPE
*				GF 08/29/2003 - issue #21541 - 2nd address line. Also performance improvement.
*				GWC 03/19/04  - added dbo. before all stored procedure calls
*				GF 08/20/2004 - issue #25482 - added validation for material option 'R' - requisitions
*				GF 01/15/2007 - 6.x HQMA auditing
*				DC 01/28/2008 - Issue 121529 - Increase the PO change order line description to 60.
*				GF 03/11/2008 - issue #127076 country for POHD and MSQH
*				GF 04/01/2009 - issue #129409 oil price escalation
*				GF 11/21/2009 - issue #136679 exclude PO's without vendor
*				GF 11/02/2010 - issue #141957 record association
*				GF 11/05/2010 - issue #141031
*				GF 04/09/2011 - TK-03289 TK-03569
*				GF 05/06/2011 - TK-04933 TK-05205 TK-05756
*				GF 06/06/2011 - TK-05799 POCO-ACO-PCO link
*				GF 06/21/2011 - TK-05811 record linking
*				GF 06/22/2011 - D-02339 use view not tables for links
*				GP 7/27/2011 - TK-07144 changed bPO to varchar(30)
*				JayR 03/22/2012 Change to use FK and table constraints for validation
*
*
*--------------------------------------------------------------*/
declare @numrows int, @errmsg varchar(255), @validcnt int, @validcnt2 int, @rcode int,
		@pmco bCompany, @project bJob, @seq int, @location bLoc, @materialgroup bGroup,
		@materialoption char(1), @material bMatl, @phasegroup bGroup, @phase bPhase,
		@costtype bJCCType, @UM bUM, @POCo bCompany, @vendorgroup bGroup, @vendor bVendor,
		@PO varchar(30), @POCompGroup varchar(10), @Description bItemDesc, @RecordType char(1),
		@PCOType bPCOType, @PCO bPCO, @PCOItem bPCOItem, @ACO bACO, @ACOItem bACOItem,
		@Units bUnits, @UnitCost bUnitCost, @ECM bECM, @EstCost bDollar, @SendYN bYN,
		@UnitHours bHrs, @EstHours bHrs, @HourCost bUnitCost, @PhaseUM bUM,
		@retcode int, @retmsg varchar(150), @address varchar(60), @city varchar(30),
		@state varchar(4), @zip bZip, @msco bCompany, @quote varchar(10), @validcnt1 int,
		@msjcco bCompany, @msjob bJob, @datequoted bDate, @inco bCompany, @stocked bYN,
		@pricetemplate smallint, @mo varchar(10), @OldVendor bVendor, @address2 varchar(60),
		@opencursor int, @shipcountry varchar(2),
		@SubItemPhase bPhase, @SubItemCostType bJCCType, @SubItemUM bUM, @SubItemMatl bMatl,
		@POItem smallint, @MOItem SMALLINT, @POID BIGINT, @MOID BIGINT, @ACOID BIGINT,
		@PCOID BIGINT, @OldPCO bPCO, @OldACO bPCO, @OldPCOType bPCOType,
		@OldPOCo TINYINT, @OldPO VARCHAR(30), @OldINCo TINYINT, @OldMO VARCHAR(30),
		@OldMatlOption CHAR(1), @KeyID BIGINT,
		----TK-03569
		@POCONum SMALLINT, @OldPOCONum SMALLINT, @POCONum_Status VARCHAR(6),
		@OldPCOItem bPCOItem, @OldACOItem bACOItem

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

select @rcode = 0, @opencursor = 0, @datequoted = dbo.vfDateOnly()

---- check for changes to PMCo
if update(PMCo)
	begin
	select @errmsg = 'Cannot change PMCo'
	goto error
	end

---- check for changes to Project
if update(Project)
	begin
	select @errmsg = 'Cannot change Project'
	goto error
	end

---- check for changes to Seq
if update(Seq)
	begin
	select @errmsg = 'Cannot change Seq'
	goto error
	end

---- Validate Vendor
if update(Vendor)
   	begin
   	select @validcnt = count(*) from bAPVM r with (nolock)
   	JOIN inserted i ON i.VendorGroup = r.VendorGroup and i.Vendor = r.Vendor
   	select @validcnt2 = count(*) from inserted i where i.Vendor is null
   	if @validcnt + @validcnt2 <> @numrows
           begin
           select @errmsg = 'Vendor is Invalid '
           goto error
           end
   	end

---- validate MaterialOption in ('P','M','Q','R')
if update(MaterialOption)
   	begin
   	select @validcnt = count(*) from inserted i join bPMCO c with (nolock) on i.PMCo=c.PMCo
   	where i.MaterialOption = 'R' and c.RQInUse = 'N'
   	if @validcnt <> 0
   		begin
   		select @errmsg = 'Invalid material option (R)equisition, not flagged as in use in PM Company!'
   		goto error
   		end
   	end


---- validate MS company for material option (Q)uote
select @validcnt = count(*) from inserted i where i.MaterialOption='Q'
select @validcnt1 = count(*) from bMSCO r with (nolock) JOIN inserted i ON i.MSCo=r.MSCo where i.MaterialOption='Q'
select @validcnt2 = count(*) from inserted i where i.MSCo is null and i.MaterialOption='Q'
if @validcnt <> @validcnt1 + @validcnt2
   	begin
   	select @errmsg = 'Invalid MS company '
   	goto error
   	end

---- validate IN company for material option (M)aterial Order
select @validcnt = count(*) from inserted i where i.MaterialOption='M'
select @validcnt1 = count(*) from bINCO r with (nolock) JOIN inserted i ON i.INCo=r.INCo where i.MaterialOption='M'
select @validcnt2 = count(*) from inserted i where i.INCo is null and i.MaterialOption='M'
if @validcnt <> @validcnt1 + @validcnt2
	begin
	select @errmsg = 'Invalid IN company '
	goto error
	end

---- begin process
if @numrows = 1
	begin
   	select @pmco=PMCo, @project=Project, @seq=Seq, @KeyID=KeyID
   	from inserted
	end
else
   	begin
   	---- use a cursor to process each updated row
   	declare bPMMF_insert cursor LOCAL FAST_FORWARD
   	for select PMCo, Project, Seq, KeyID
   	from inserted
   
   	open bPMMF_insert
	select @opencursor = 1
   	
   	fetch next from bPMMF_insert into @pmco, @project, @seq, @KeyID
   	if @@fetch_status <> 0
   		begin
   		select @errmsg = 'Cursor error'
   		goto error
   		end
   	end


insert_check:
---- get JCJM info
select @POCompGroup=POCompGroup, @address=ShipAddress, @city=ShipCity, @state=ShipState,
   	   @zip=ShipZip, @pricetemplate=PriceTemplate, @address2=ShipAddress2, @shipcountry=ShipCountry
from bJCJM WITH (NOLOCK) where JCCo = @pmco and Job = @project

select @phasegroup=i.PhaseGroup, @phase=i.Phase, @costtype=i.CostType, @materialgroup=i.MaterialGroup,
   		   @material=i.MaterialCode, @location=i.Location, @materialoption=i.MaterialOption, @UM=i.UM,
   		   @POCo=i.POCo, @vendorgroup=i.VendorGroup, @vendor=i.Vendor, @PO=i.PO, @Description=i.MtlDescription,
   		   @RecordType=i.RecordType, @PCOType=i.PCOType, @PCO=i.PCO, @PCOItem=i.PCOItem, @ACO=i.ACO,
   		   @ACOItem=i.ACOItem, @Units=i.Units, @UnitCost=i.UnitCost, @ECM=i.ECM, @EstCost=i.Amount,
   		   @SendYN=i.SendFlag, @msco=i.MSCo, @quote=i.Quote, @inco=i.INCo, @mo=i.MO, @POItem=i.POItem,
		   @MOItem=i.MOItem, @OldMatlOption=d.MaterialOption, @OldPOCo=d.POCo, @OldPO=d.PO,
		   @OldINCo=d.INCo, @OldMO=d.MO, @OldPCOType=d.PCOType, @OldPCO=d.PCO, @OldACO=d.ACO,
		   ----TK-03569
		   @POCONum=i.POCONum, @OldPOCONum=d.POCONum, @OldPCOItem=d.PCOItem, @OldACOItem=d.ACOItem
FROM inserted i
INNER JOIN deleted d ON d.KeyID=i.KeyID
where i.KeyID=@KeyID
----PMCo=@pmco and Project=@project and Seq=@seq

----select @OldVendor=Vendor from deleted where PMCo=@pmco and Project=@project and Seq=@seq

---- get beginning status for POCONum from PMSC TK-03569
SET @POCONum_Status = NULL
select Top 1 @POCONum_Status = Status
FROM dbo.bPMSC WHERE DocCat = 'PURCHASECO' AND CodeType = 'B'
----TK-05205
IF @@ROWCOUNT = 0
	BEGIN
	SELECT @POCONum_Status = BeginStatus
	FROM dbo.bPMCO WHERE PMCo=@pmco
	END
				
if update(Phase)
   	begin
   	if @phase is not null
   		begin
   		---- validate standard phase - if it doesnt exist in JCJP try to add it
   		exec @rcode = dbo.bspJCADDPHASE @pmco, @project, @phasegroup, @phase, 'Y', null, @errmsg output
   		if @rcode <> 0 goto error
   		---- validate Cost Type - if JCCH doesnt exist try to add it
   		exec @rcode = dbo.bspJCADDCOSTTYPE @jcco=@pmco, @job=@project, @phasegroup=@phasegroup, @phase=@phase,
   	                	@costtype=@costtype, @um=@UM, @override= 'P', @msg=@errmsg output
   		if @rcode <> 0 goto error
   		end
   	end

---- Validate PO/insert PO
if Update(PO)
   	begin
   	if @materialoption = 'P' and @PO is not null
   		begin
		---- #136679
		if @vendor is null
			begin
			select @errmsg = 'Missing Vendor for PO: ' + isnull(@PO,'') + '.'
			goto error
			end
			
		---- check POIT for item, if found phase/costtype must exist
   		select @SubItemPhase = Phase, @SubItemCostType = JCCType, @SubItemUM = UM, @SubItemMatl = Material
   		from dbo.bPOIT where POCo=@POCo and PO=@PO and POItem=@POItem
   		if @@rowcount <> 0
   			begin
   			if @SubItemPhase <> @phase or @SubItemCostType <> @costtype or @SubItemUM <> @UM or isnull(@SubItemMatl,'') <> isnull(@material,'')
   				begin
				select @errmsg = 'PO: ' + isnull(@PO,'') + ' POItem: ' + convert(varchar(8),isnull(@POItem,0)) 
   						+ ' - Multiple records set up for same item with different Phase/CostType/UM/Material combination.'
				goto error
				END
			end
			
   		if not exists (select top 1 1 from bPOHD WITH (NOLOCK) where POCo=@POCo and PO=@PO)
   			begin
   			insert bPOHD (POCo, PO, VendorGroup, Vendor, Description, OrderDate, Status, JCCo, Job,
					CompGroup, PayTerms, Address, City, State, Zip, Purge, Approved,
					Address2) ----, Country)
   			select @POCo, @PO, @vendorgroup, @vendor, @Description, convert(varchar(11),getdate()), 3, @pmco,
					@project, @POCompGroup, m.PayTerms, @address, @city, @state, @zip, 'N', 'N',
					@address2 ----, @shipcountry
   			from bAPVM m with (nolock) where m.VendorGroup=@vendorgroup and m.Vendor=@vendor
   		    if @@rowcount <> 1
   				begin
   				select @errmsg = ' Cannot insert into POHD '
   				goto error
   				end
   			end
   		end
   	end


---- TK-03569
IF @PO IS NOT NULL
	BEGIN
	IF @POCONum IS NOT NULL
		BEGIN
		---- insert row for POCONum when not exists
		IF NOT EXISTS(SELECT 1 FROM dbo.vPMPOCO WHERE POCo=@POCo AND PO=@PO AND POCONum=@POCONum)
			BEGIN
			INSERT INTO dbo.vPMPOCO (PMCo, Project, POCo, PO, POCONum, Description, Status, Date)
			VALUES (@pmco, @project, @POCo, @PO, @POCONum, @Description, @POCONum_Status, dbo.vfDateOnly())
			END
			
		---- when approved need to assign the SubCO and SubCO to PMOL record TK-00000
		IF @OldACO IS NULL AND @ACO IS NOT NULL AND @PCO IS NOT NULL
			BEGIN
			UPDATE dbo.bPMOL SET POCONum=@POCONum, POCONumSeq=@seq
			WHERE PMCo=@pmco 
				AND Project=@project 
				AND PCOType=@PCOType 
				AND PCO=@PCO
				AND PCOItem=@PCOItem 
				AND Phase=@phase 
				AND CostType=@costtype
				AND PO=@PO
				AND POSLItem = @POItem
				AND ISNULL(POCONumSeq,-1) <> @seq
			END
			
		---- TK-04933
		---- if POCONum has changed for a change order record we may need to update PMOL
		---- and unassign old from the old record and assign to the new record
		IF @OldPOCONum IS NOT NULL AND @OldPOCONum <> @POCONum
			BEGIN
			---- update PMOL for change order and unassign Old POCONum
			IF @OldPCOItem IS NOT NULL OR @OldACOItem IS NOT NULL
				BEGIN
				UPDATE dbo.bPMOL SET POCONum = NULL, POCONumSeq = NULL
				WHERE PMCo = @pmco AND Project = @project
				AND Phase = @phase AND CostType=@costtype
				AND ISNULL(PCOType,'') = ISNULL(@OldPCOType,'')
				AND ISNULL(PCO,'') = ISNULL(@OldPCO,'')
				AND ISNULL(PCOItem,'') = ISNULL(@OldPCOItem,'')
				AND ISNULL(ACO,'') = ISNULL(@OldACO,'')
				AND ISNULL(ACOItem,'') = ISNULL(@OldACOItem,'')
				AND POCONum = @OldPOCONum
				AND POCONumSeq=@seq
				END
			END
			
		---- update PMOL for change order and assign POCONumSeq
		IF @PCOItem IS NOT NULL OR @ACOItem IS NOT NULL
			BEGIN
			UPDATE dbo.bPMOL SET POCONum = @POCONum, POCONumSeq = @seq
			WHERE PMCo = @pmco 
				AND Project = @project
				AND Phase = @phase 
				AND CostType = @costtype
				AND ISNULL(PCOType,'') = ISNULL(@PCOType,'')
				AND ISNULL(PCO,'') = ISNULL(@PCO,'')
				AND ISNULL(PCOItem,'') = ISNULL(@PCOItem,'')
				AND ISNULL(ACO,'') = ISNULL(@ACO,'')
				AND ISNULL(ACOItem,'') = ISNULL(@ACOItem,'')
				AND ISNULL(POCONum,-1) <> ISNULL(@POCONum,-1)
				AND PO = @PO
				AND POSLItem = @POItem
				AND ISNULL(POCONumSeq,-1) <> @seq
			END
		END
	
	---- TK-04933
	---- possible we are removing the POCONum from the detail record
	---- need to update PMOL and also remove the POCONum, POCONumSeq
	IF @OldPOCONum IS NOT NULL AND @POCONum IS NULL
		BEGIN
		IF @OldPCOItem IS NOT NULL OR @OldACOItem IS NOT NULL
			BEGIN
			UPDATE dbo.bPMOL SET POCONum = NULL, POCONumSeq = NULL
			WHERE PMCo = @pmco 
				AND Project = @project
				AND Phase = @phase 
				AND CostType=@costtype
				AND ISNULL(PCOType,'') = ISNULL(@OldPCOType,'')
				AND ISNULL(PCO,'') = ISNULL(@OldPCO,'')
				AND ISNULL(PCOItem,'') = ISNULL(@OldPCOItem,'')
				AND ISNULL(ACO,'') = ISNULL(@OldACO,'')
				AND ISNULL(ACOItem,'') = ISNULL(@OldACOItem,'')
				AND POCONum = @OldPOCONum
				AND POCONumSeq = @seq
			END
		END
		
	END ---- END PO IS NOT NULL
	

---- if vendor changed update bPOHD
if update(Vendor)
   	begin
   	if @materialoption = 'P' and isnull(@PO,'') <> ''
   		begin
   		if exists (select 1 from bPOHD WITH (NOLOCK) where POCo=@POCo and PO=@PO and Status=3)
   			begin
--   			if @OldVendor <> @vendor
--   				begin
   				update bPOHD set Vendor=@vendor where POCo=@POCo and PO=@PO
   				if @@rowcount <> 1
   					begin
   					select @errmsg = ' Cannot update POHD '
   					goto error
   					end
--   				end
   			end
   		end
   	end

---- initiate project firm for PO where vendor is not null
if isnull(@vendor,0) <> 0
   	begin
   	---- insert Project Firm if needed
   	select @validcnt=count(*) from bPMPF WITH (NOLOCK)
   	where PMCo=@pmco and Project=@project and VendorGroup=@vendorgroup and FirmNumber=@vendor
   	if @validcnt = 0
   		begin
   		exec @retcode = dbo.bspPMSLFirmContactInit @pmco, @project, @vendorgroup, @vendor, @retmsg output
   		end
   	end

---- validate material for types (M) and (Q)
if @materialoption in ('M','Q')
   	begin
   	---- validate material
   	select @stocked=Stocked from bHQMT WITH (NOLOCK) where MatlGroup=@materialgroup and Material=@material
   	if @@rowcount = 0
   		begin
   		select @errmsg = ' Material ' + isnull(@material,'') + ' is invalid '
   		goto error
   		end
   	if @stocked = 'N'
   		begin
   		select @errmsg = ' Material ' + isnull(@material,'') + ' is not a stocked material '
   		goto error
   		end
   	end

---- validate (M)aterial Order type
if @materialoption = 'M'
   	begin
   	if @inco is not null and @location is not null
   		begin
   		---- validate location
   		if not exists(select top 1 1 from bINLM WITH (NOLOCK) where INCo=@inco and Loc=@location)
   			begin
   			select @errmsg = ' Location ' + isnull(@location,'') + ' is Invalid '
   			goto error
   			end
   			
   		---- validate material at location
   		if not exists(select top 1 1 from bINMT WITH (NOLOCK) where INCo=@inco and Loc=@location
   							and MatlGroup=@materialgroup and Material=@material)
   			begin
   			select @errmsg = ' Material ' + isnull(@material,'') + ' is not valid for Location ' + isnull(@location,'') + ' '
   			goto error
   			end
   
   		---- validate MO - insert MO
   		if @mo is not null
           	begin
			---- check INMI for item, if found phase/costtype must exist
   			select @SubItemPhase = Phase, @SubItemCostType = JCCType, @SubItemUM = UM, @SubItemMatl = Material
   			from dbo.bINMI where INCo=@inco and MO=@mo and MOItem=@MOItem
   			if @@rowcount <> 0
   				begin
   				if @SubItemPhase <> @phase or @SubItemCostType <> @costtype or @SubItemUM <> @UM or isnull(@SubItemMatl,'') <> isnull(@material,'')
   					begin
					select @errmsg = 'MO: ' + isnull(@mo,'') + ' MOItem: ' + convert(varchar(8),isnull(@MOItem,0)) 
   							+ ' - Multiple records set up for same item with different Phase/CostType/UM/Material combination.'
					goto error
					END
				end
           	
   			if not exists (select top 1 1 from bINMO WITH (NOLOCK) where INCo=@inco and MO=@mo)
   				begin
   				insert bINMO (INCo, MO, Description, JCCo, Job, OrderDate, Status, Purge, Approved)
   				select @inco, @mo, @Description, @pmco, @project, convert(varchar(11),getdate()), 3, 'N', 'N'
   				if @@rowcount <> 1
   					begin
   					select @errmsg = ' Cannot insert into INMO '
   					goto error
   					end
   				end
   			end
   		end
   	end

---- validate quote
if @materialoption = 'Q'
   	begin
   	if @msco is not null and @quote is not null
   		begin
   		---- validate location
   		if not exists (select top 1 1 from bINLM WITH (NOLOCK) where INCo=@msco and Loc=@location)
   			begin
           	select @errmsg =' Location ' + isnull(@location,'') + ' is Invalid '
           	goto error
   			end
   
   		---- check if quote set up for different jc company and job
   		select @msjcco=JCCo, @msjob=Job from bMSQH WITH (NOLOCK) where MSCo=@msco and Quote=@quote
   		if @@rowcount <> 0
   			begin
   			if isnull(@msjcco,0) <> @pmco or isnull(@msjob,'') <> @project
   				begin
                  	select @errmsg = ' Invalid quote - ' + isnull(@quote,'') + ' set up for different JCCO and Job'
                  	goto error
                  	end
   			end
   			
   		---- check for quote already assigned for MS company
   		if exists(select 1 from bMSQH WITH (NOLOCK) where MSCo=@msco and QuoteType='J' and JCCo=@pmco and Job=@project and Quote<>@quote)
   			begin
   			select @errmsg = 'Quote is already set up for JC company and Job in MS. Only one allowed.'
   			goto error
   			end
   			
   		---- verify Job price template is valid for MSCo
   		if isnull(@pricetemplate,0) <> 0
   			begin
   			select @validcnt=count(*) from bMSTH WITH (NOLOCK) where MSCo=@msco and PriceTemplate=@pricetemplate
   			if @validcnt = 0 select @pricetemplate = null
   			end
   
   		---- insert quote in MSQH
   		if not exists(select top 1 1 from bMSQH WITH (NOLOCK) where MSCo=@msco and Quote=@quote)
   			begin
   			insert into bMSQH(MSCo, Quote, QuoteType, JCCo, Job, Description, Contact, Phone, ShipAddress,
   						City, State, Zip, ShipAddress2, PriceTemplate, TaxGroup, TaxCode, HaulTaxOpt, Active,
   						QuotedBy, QuoteDate, SepInv, PurgeYN, Country, ApplyEscalators, BidIndexDate)
   			select @msco, @quote, 'J', @pmco, @project, j.Description, m.Name, j.JobPhone, j.ShipAddress,
   						j.ShipCity, j.ShipState, j.ShipZip, j.ShipAddress2, @pricetemplate, j.TaxGroup, j.TaxCode,
   						j.HaulTaxOpt, 'N', convert(varchar(30),suser_sname()), @datequoted,
						'N', 'N', j.ShipCountry, 'N', null
   			from bJCJM j with (nolock) left join bJCMP m with (nolock) on m.JCCo=j.JCCo and m.ProjectMgr=j.ProjectMgr
   			where j.JCCo=@pmco and j.Job=@project
   			if @@rowcount <> 1
   				begin
   				select @errmsg = 'Error inserting MS quote header'
   				goto error
   				end
   			end
   		end
   	end


---- finished with validation and updates (except HQ Audit)
Valid_Finished:
if @numrows > 1
   	begin
	fetch next from bPMMF_insert into @pmco, @project, @seq, @KeyID
	if @@fetch_status = 0
		begin
		goto insert_check
		end
	else
		begin
		close bPMMF_insert
		deallocate bPMMF_insert
		select @opencursor = 0
		end
	end

---- TK-05811
---- manage PM related records - may be inserting PCO/ACO/POCONum/PO/MO
---- could also be changing from one related record to another in which case we need to remove
---- the old related link and add a new related link. TK-03289 TK-03569
---- if PO has changed we need to delete old related record if only one
---- record side ACO
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN inserted i ON i.KeyID=d.KeyID
INNER JOIN dbo.bPOHD h ON h.POCo=d.POCo AND h.PO=d.PO
INNER JOIN dbo.bPMOH c ON c.PMCo=d.PMCo AND c.Project=d.Project AND c.ACO=d.ACO
INNER JOIN dbo.vPMRelateRecord a ON a.RecTableName='PMOH' AND a.RECID=c.KeyID AND a.LinkTableName='POHD' AND a.LINKID=h.KeyID
WHERE d.PO IS NOT NULL AND d.ACO IS NOT NULL
AND NOT EXISTS(SELECT 1 FROM dbo.bPMMF x WHERE x.PMCo=d.PMCo AND x.Project=d.Project AND x.ACO=d.ACO AND x.PO=d.PO)
---- link side ACO
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN inserted i ON i.KeyID=d.KeyID
INNER JOIN dbo.bPOHD h ON h.POCo=d.POCo AND h.PO=d.PO
INNER JOIN dbo.bPMOH c ON c.PMCo=d.PMCo AND c.Project=d.Project AND c.ACO=d.ACO
INNER JOIN dbo.vPMRelateRecord a ON a.RecTableName='POHD' AND a.RECID=h.KeyID AND a.LinkTableName='PMOH' AND a.LINKID=c.KeyID
WHERE d.PO IS NOT NULL AND d.ACO IS NOT NULL
AND NOT EXISTS(SELECT 1 FROM dbo.bPMMF x WHERE x.PMCo=d.PMCo AND x.Project=d.Project AND x.ACO=d.ACO AND x.PO=d.PO)	

---- record side PCO
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN inserted i ON i.KeyID=d.KeyID
INNER JOIN dbo.bPOHD h ON h.POCo=d.POCo AND h.PO=d.PO
INNER JOIN dbo.bPMOP c ON c.PMCo=d.PMCo AND c.Project=d.Project AND c.PCOType=d.PCOType AND c.PCO=d.PCO
INNER JOIN dbo.vPMRelateRecord a ON a.RecTableName='PMOP' AND a.RECID=c.KeyID AND a.LinkTableName='POHD' AND a.LINKID=h.KeyID
WHERE d.PO IS NOT NULL AND d.PCO IS NOT NULL
AND NOT EXISTS(SELECT 1 FROM dbo.bPMMF x WHERE x.PMCo=d.PMCo AND x.Project=d.Project AND x.PCOType=d.PCOType AND x.PCO=d.PCO AND x.PO=d.PO)
---- link side PCO
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN inserted i ON i.KeyID=d.KeyID
INNER JOIN dbo.bPOHD h ON h.POCo=d.POCo AND h.PO=d.PO
INNER JOIN dbo.bPMOP c ON c.PMCo=d.PMCo AND c.Project=d.Project AND c.PCOType=d.PCOType AND c.PCO=d.PCO
INNER JOIN dbo.vPMRelateRecord a ON a.RecTableName='POHD' AND a.RECID=h.KeyID AND a.LinkTableName='PMOP' AND a.LINKID=c.KeyID
WHERE d.PO IS NOT NULL AND d.PCO IS NOT NULL
AND NOT EXISTS(SELECT 1 FROM dbo.bPMMF x WHERE x.PMCo=d.PMCo AND x.Project=d.Project AND x.PCOType=d.PCOType AND x.PCO=d.PCO AND x.PO=d.PO)	


---- if MO has changed we need to delete old related record if only one
---- record side ACO
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN inserted i ON i.KeyID=d.KeyID
INNER JOIN dbo.bINMO h ON h.INCo=d.INCo AND h.MO=d.MO
INNER JOIN dbo.bPMOH c ON c.PMCo=d.PMCo AND c.Project=d.Project AND c.ACO=d.ACO
INNER JOIN dbo.vPMRelateRecord a ON a.RecTableName='PMOH' AND a.RECID=c.KeyID AND a.LinkTableName='INMO' AND a.LINKID=h.KeyID
WHERE d.MO IS NOT NULL AND d.ACO IS NOT NULL
AND NOT EXISTS(SELECT 1 FROM dbo.bPMMF x WHERE x.PMCo=d.PMCo AND x.Project=d.Project AND x.ACO=d.ACO AND x.MO=d.MO)
---- link side ACO
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN inserted i ON i.KeyID=d.KeyID
INNER JOIN dbo.bINMO h ON h.INCo=d.INCo AND h.MO=d.MO
INNER JOIN dbo.bPMOH c ON c.PMCo=d.PMCo AND c.Project=d.Project AND c.ACO=d.ACO
INNER JOIN dbo.vPMRelateRecord a ON a.RecTableName='INMO' AND a.RECID=h.KeyID AND a.LinkTableName='PMOH' AND a.LINKID=c.KeyID
WHERE d.MO IS NOT NULL AND d.ACO IS NOT NULL
AND NOT EXISTS(SELECT 1 FROM dbo.bPMMF x WHERE x.PMCo=d.PMCo AND x.Project=d.Project AND x.ACO=d.ACO AND x.MO=d.MO)	

---- record side PCO
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN inserted i ON i.KeyID=d.KeyID
INNER JOIN dbo.bINMO h ON h.INCo=d.INCo AND h.MO=d.MO
INNER JOIN dbo.bPMOP c ON c.PMCo=d.PMCo AND c.Project=d.Project AND c.PCOType=d.PCOType AND c.PCO=d.PCO
INNER JOIN dbo.vPMRelateRecord a ON a.RecTableName='PMOP' AND a.RECID=c.KeyID AND a.LinkTableName='INMO' AND a.LINKID=h.KeyID
WHERE d.MO IS NOT NULL AND d.PCO IS NOT NULL
AND NOT EXISTS(SELECT 1 FROM dbo.bPMMF x WHERE x.PMCo=d.PMCo AND x.Project=d.Project AND x.PCOType=d.PCOType AND x.PCO=d.PCO AND x.MO=d.MO)
---- link side PCO
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN inserted i ON i.KeyID=d.KeyID
INNER JOIN dbo.bINMO h ON h.INCo=d.INCo AND h.MO=d.MO
INNER JOIN dbo.bPMOP c ON c.PMCo=d.PMCo AND c.Project=d.Project AND c.PCOType=d.PCOType AND c.PCO=d.PCO
INNER JOIN dbo.vPMRelateRecord a ON a.RecTableName='INMO' AND a.RECID=h.KeyID AND a.LinkTableName='PMOP' AND a.LINKID=c.KeyID
WHERE d.MO IS NOT NULL AND d.PCO IS NOT NULL
AND NOT EXISTS(SELECT 1 FROM dbo.bPMMF x WHERE x.PMCo=d.PMCo AND x.Project=d.Project AND x.PCOType=d.PCOType AND x.PCO=d.PCO AND x.MO=d.MO)	


---- if PO change order has changed we need to delete
---- old related record if only one POCONum associated to PCO
---- record side PCO TK-05811
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN inserted i ON i.KeyID=d.KeyID
INNER JOIN dbo.vPMPOCO h ON h.POCo=d.POCo AND h.PO=d.PO AND h.POCONum=d.POCONum
INNER JOIN dbo.bPMOP c ON c.PMCo=d.PMCo AND c.Project=d.Project AND c.PCOType=d.PCOType AND c.PCO=d.PCO
INNER JOIN dbo.vPMRelateRecord a ON a.RecTableName='PMPOCO' AND a.RECID=h.KeyID AND a.LinkTableName='PMOP' AND a.LINKID=c.KeyID
WHERE d.PCO IS NOT NULL AND d.POCONum IS NOT NULL
AND NOT EXISTS(SELECT 1 FROM dbo.bPMMF x WHERE x.PMCo=d.PMCo AND x.Project=d.Project AND x.PCOType=d.PCOType AND x.PCO=d.PCO AND x.POCONum=d.POCONum)
---- link side PCO
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN inserted i ON i.KeyID=d.KeyID
INNER JOIN dbo.vPMPOCO h ON h.POCo=d.POCo AND h.PO=d.PO AND h.POCONum=d.POCONum
INNER JOIN dbo.bPMOP c ON c.PMCo=d.PMCo AND c.Project=d.Project AND c.PCOType=d.PCOType AND c.PCO=d.PCO
INNER JOIN dbo.vPMRelateRecord a ON a.RecTableName='PMOP' AND a.RECID=c.KeyID AND a.LinkTableName='PMPOCO' AND a.LINKID=h.KeyID
WHERE d.PCO IS NOT NULL AND d.POCONum IS NOT NULL
AND NOT EXISTS(SELECT 1 FROM dbo.bPMMF x WHERE x.PMCo=d.PMCo AND x.Project=d.Project AND x.PCOType=d.PCOType AND x.PCO=d.PCO AND x.POCONum=d.POCONum)

---- record side ACO
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN inserted i ON i.KeyID=d.KeyID
INNER JOIN dbo.vPMPOCO h ON h.POCo=d.POCo AND h.PO=d.PO AND h.POCONum=d.POCONum
INNER JOIN dbo.bPMOH c ON c.PMCo=d.PMCo AND c.Project=d.Project AND c.ACO=d.ACO
INNER JOIN dbo.vPMRelateRecord a ON a.RecTableName='PMPOCO' AND a.RECID=h.KeyID AND a.LinkTableName='PMOH' AND a.LINKID=c.KeyID
WHERE d.ACO IS NOT NULL AND d.POCONum IS NOT NULL
AND NOT EXISTS(SELECT 1 FROM dbo.bPMMF x WHERE x.PMCo=d.PMCo AND x.Project=d.Project AND x.ACO=d.ACO AND x.POCONum=d.POCONum)
---- link side ACO
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN inserted i ON i.KeyID=d.KeyID
INNER JOIN dbo.vPMPOCO h ON h.POCo=d.POCo AND h.PO=d.PO AND h.POCONum=d.POCONum
INNER JOIN dbo.bPMOH c ON c.PMCo=d.PMCo AND c.Project=d.Project AND c.ACO=d.ACO
INNER JOIN dbo.vPMRelateRecord a ON a.RecTableName='PMOH' AND a.RECID=c.KeyID AND a.LinkTableName='PMPOCO' AND a.LINKID=h.KeyID
WHERE d.ACO IS NOT NULL AND d.POCONum IS NOT NULL
AND NOT EXISTS(SELECT 1 FROM dbo.bPMMF x WHERE x.PMCo=d.PMCo AND x.Project=d.Project AND x.ACO=d.ACO AND x.POCONum=d.POCONum)




---- PCO and PO
INSERT INTO dbo.vPMRelateRecord(RecTableName, RECID, LinkTableName, LINKID)
SELECT DISTINCT 'PMOP', a.KeyID, 'POHD', b.KeyID
FROM inserted i
INNER JOIN deleted x ON x.KeyID=i.KeyID 
INNER JOIN dbo.bPMOP a ON a.PMCo=i.PMCo AND a.Project=i.Project AND a.PCOType=i.PCOType AND a.PCO=i.PCO
INNER JOIN dbo.bPOHD b ON b.POCo=i.POCo AND b.PO=i.PO
WHERE i.PO IS NOT NULL AND i.PCO IS NOT NULL
AND NOT EXISTS(SELECT 1 FROM dbo.vPMRelateRecord c WHERE c.RecTableName='PMOP' AND c.RECID=a.KeyID
				AND c.LinkTableName='POHD' AND c.LINKID=b.KeyID)
AND NOT EXISTS(SELECT 1 FROM dbo.vPMRelateRecord d WHERE d.RecTableName='POHD' AND d.RECID=b.KeyID
				AND d.LinkTableName='PMOP' AND d.LINKID=a.KeyID)

---- ACO and PO
INSERT INTO dbo.vPMRelateRecord(RecTableName, RECID, LinkTableName, LINKID)
SELECT DISTINCT 'PMOH', a.KeyID, 'POHD', b.KeyID
FROM inserted i
INNER JOIN deleted x ON x.KeyID=i.KeyID 
INNER JOIN dbo.bPMOH a ON a.PMCo=i.PMCo AND a.Project=i.Project AND a.ACO=i.ACO
INNER JOIN dbo.bPOHD b ON b.POCo=i.POCo AND b.PO=i.PO
WHERE i.PO IS NOT NULL AND i.ACO IS NOT NULL
AND NOT EXISTS(SELECT 1 FROM dbo.vPMRelateRecord c WHERE c.RecTableName='PMOH' AND c.RECID=a.KeyID
				AND c.LinkTableName='POHD' AND c.LINKID=b.KeyID)
AND NOT EXISTS(SELECT 1 FROM dbo.vPMRelateRecord d WHERE d.RecTableName='POHD' AND d.RECID=b.KeyID
				AND d.LinkTableName='PMOH' AND d.LINKID=a.KeyID)

---- PCO and MO
INSERT INTO dbo.vPMRelateRecord(RecTableName, RECID, LinkTableName, LINKID)
SELECT DISTINCT 'PMOP', a.KeyID, 'INMO', b.KeyID
FROM inserted i
INNER JOIN deleted x ON x.KeyID=i.KeyID 
INNER JOIN dbo.bPMOP a ON a.PMCo=i.PMCo AND a.Project=i.Project AND a.PCOType=i.PCOType AND a.PCO=i.PCO
INNER JOIN dbo.bINMO b ON b.INCo=i.INCo AND b.MO=i.MO
WHERE i.MO IS NOT NULL AND i.PCO IS NOT NULL
AND NOT EXISTS(SELECT 1 FROM dbo.vPMRelateRecord c WHERE c.RecTableName='PMOP' AND c.RECID=a.KeyID
				AND c.LinkTableName='INMO' AND c.LINKID=b.KeyID)
AND NOT EXISTS(SELECT 1 FROM dbo.vPMRelateRecord d WHERE d.RecTableName='INMO' AND d.RECID=b.KeyID
				AND d.LinkTableName='PMOP' AND d.LINKID=a.KeyID)

---- ACO and MO
INSERT INTO dbo.vPMRelateRecord(RecTableName, RECID, LinkTableName, LINKID)
SELECT DISTINCT 'PMOH', a.KeyID, 'INMO', b.KeyID
FROM inserted i
INNER JOIN deleted x ON x.KeyID=i.KeyID 
INNER JOIN dbo.bPMOH a ON a.PMCo=i.PMCo AND a.Project=i.Project AND a.ACO=i.ACO
INNER JOIN dbo.bINMO b ON b.INCo=i.INCo AND b.MO=i.MO
WHERE i.MO IS NOT NULL AND i.ACO IS NOT NULL
AND NOT EXISTS(SELECT 1 FROM dbo.vPMRelateRecord c WHERE c.RecTableName='PMOH' AND c.RECID=a.KeyID
				AND c.LinkTableName='INMO' AND c.LINKID=b.KeyID)
AND NOT EXISTS(SELECT 1 FROM dbo.vPMRelateRecord d WHERE d.RecTableName='INMO' AND d.RECID=b.KeyID
				AND d.LinkTableName='PMOH' AND d.LINKID=a.KeyID)

---- PCO and POCONum TK-05756
INSERT INTO dbo.vPMRelateRecord(RecTableName, RECID, LinkTableName, LINKID)
SELECT DISTINCT 'PMPOCO', a.KeyID, 'PMOP', b.KeyID
FROM inserted i
INNER JOIN dbo.vPMPOCO a ON a.POCo=i.POCo AND a.PO=i.PO AND a.POCONum=i.POCONum
INNER JOIN dbo.bPMOP b ON b.PMCo=i.PMCo AND b.Project=i.Project AND b.PCOType=i.PCOType AND b.PCO=i.PCO
WHERE i.POCONum IS NOT NULL AND i.PCO IS NOT NULL
AND NOT EXISTS(SELECT 1 FROM dbo.vPMRelateRecord c WHERE c.RecTableName='PMPOCO' AND c.RECID=a.KeyID
				AND c.LinkTableName='PMOP' AND c.LINKID=b.KeyID)
AND NOT EXISTS(SELECT 1 FROM dbo.vPMRelateRecord d WHERE d.RecTableName='PMOP' AND d.RECID=b.KeyID
				AND d.LinkTableName='PMPOCO' AND d.LINKID=a.KeyID)

---- ACO and POCONum TK-05756
INSERT INTO dbo.vPMRelateRecord(RecTableName, RECID, LinkTableName, LINKID)
SELECT DISTINCT 'PMPOCO', a.KeyID, 'PMOH', b.KeyID
FROM inserted i
INNER JOIN dbo.vPMPOCO a ON a.POCo=i.POCo AND a.PO=i.PO AND a.POCONum=i.POCONum
INNER JOIN dbo.bPMOH b ON b.PMCo=i.PMCo AND b.Project=i.Project AND b.ACO=i.ACO
WHERE i.POCONum IS NOT NULL AND i.ACO IS NOT NULL
AND NOT EXISTS(SELECT 1 FROM dbo.vPMRelateRecord c WHERE c.RecTableName='PMPOCO' AND c.RECID=a.KeyID
				AND c.LinkTableName='PMOH' AND c.LINKID=b.KeyID)
AND NOT EXISTS(SELECT 1 FROM dbo.vPMRelateRecord d WHERE d.RecTableName='PMOH' AND d.RECID=b.KeyID
				AND d.LinkTableName='PMPOCO' AND d.LINKID=a.KeyID)






---- HQMA inserts
if not exists(select top 1 1 from inserted i join bPMCO c with (nolock) on i.PMCo=c.PMCo and c.AuditPMMF='Y')
	begin
  	goto trigger_end
	end


if update(Vendor)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMMF','PMCo: ' + isnull(convert(char(3),i.PMCo), '') + ' Project: ' + isnull(i.Project,'')
		+ ' Seq: ' + isnull(convert(varchar(10),i.Seq),'') + ' Phase: ' + isnull(i.Phase,'')
		+ ' CostType: ' + isnull(convert(varchar(3),i.CostType),''), i.PMCo, 'C',
		'Vendor', convert(varchar(10),d.Vendor), convert(varchar(10),i.Vendor), getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.Seq=i.Seq
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.Vendor,'') <> isnull(i.Vendor,'') and c.AuditPMMF='Y'
	end
if update(PO)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMMF','PMCo: ' + isnull(convert(char(3),i.PMCo), '') + ' Project: ' + isnull(i.Project,'')
		+ ' Seq: ' + isnull(convert(varchar(10),i.Seq),'') + ' Phase: ' + isnull(i.Phase,'')
		+ ' CostType: ' + isnull(convert(varchar(3),i.CostType),''), i.PMCo, 'C',
		'PO', d.PO, i.PO, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.Seq=i.Seq
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.PO,'') <> isnull(i.PO,'') and c.AuditPMMF='Y'
	end
if update(POItem)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMMF','PMCo: ' + isnull(convert(char(3),i.PMCo), '') + ' Project: ' + isnull(i.Project,'')
		+ ' Seq: ' + isnull(convert(varchar(10),i.Seq),'') + ' Phase: ' + isnull(i.Phase,'')
		+ ' CostType: ' + isnull(convert(varchar(3),i.CostType),''), i.PMCo, 'C',
		'POItem', convert(varchar(8),d.POItem), convert(varchar(8),i.POItem), getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.Seq=i.Seq
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.POItem,'') <> isnull(i.POItem,'') and c.AuditPMMF='Y'
	end
if update(INCo)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMMF','PMCo: ' + isnull(convert(char(3),i.PMCo), '') + ' Project: ' + isnull(i.Project,'')
		+ ' Seq: ' + isnull(convert(varchar(10),i.Seq),'') + ' Phase: ' + isnull(i.Phase,'')
		+ ' CostType: ' + isnull(convert(varchar(3),i.CostType),''), i.PMCo, 'C',
		'INCo', convert(varchar(3),d.INCo), convert(varchar(3),i.INCo), getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.Seq=i.Seq
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.INCo,'') <> isnull(i.INCo,'') and c.AuditPMMF='Y'
	end
if update(Location)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMMF','PMCo: ' + isnull(convert(char(3),i.PMCo), '') + ' Project: ' + isnull(i.Project,'')
		+ ' Seq: ' + isnull(convert(varchar(10),i.Seq),'') + ' Phase: ' + isnull(i.Phase,'')
		+ ' CostType: ' + isnull(convert(varchar(3),i.CostType),''), i.PMCo, 'C',
		'Location', d.Location, i.Location, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.Seq=i.Seq
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.Location,'') <> isnull(i.Location,'') and c.AuditPMMF='Y'
	end
if update(MO)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMMF','PMCo: ' + isnull(convert(char(3),i.PMCo), '') + ' Project: ' + isnull(i.Project,'')
		+ ' Seq: ' + isnull(convert(varchar(10),i.Seq),'') + ' Phase: ' + isnull(i.Phase,'')
		+ ' CostType: ' + isnull(convert(varchar(3),i.CostType),''), i.PMCo, 'C',
		'MO', d.MO, i.MO, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.Seq=i.Seq
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.MO,'') <> isnull(i.MO,'') and c.AuditPMMF='Y'
	end
if update(MOItem)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMMF','PMCo: ' + isnull(convert(char(3),i.PMCo), '') + ' Project: ' + isnull(i.Project,'')
		+ ' Seq: ' + isnull(convert(varchar(10),i.Seq),'') + ' Phase: ' + isnull(i.Phase,'')
		+ ' CostType: ' + isnull(convert(varchar(3),i.CostType),''), i.PMCo, 'C',
		'MOItem', convert(varchar(8),d.MOItem), convert(varchar(8),i.MOItem), getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.Seq=i.Seq
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.MOItem,'') <> isnull(i.MOItem,'') and c.AuditPMMF='Y'
	end
if update(MSCo)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMMF','PMCo: ' + isnull(convert(char(3),i.PMCo), '') + ' Project: ' + isnull(i.Project,'')
		+ ' Seq: ' + isnull(convert(varchar(10),i.Seq),'') + ' Phase: ' + isnull(i.Phase,'')
		+ ' CostType: ' + isnull(convert(varchar(3),i.CostType),''), i.PMCo, 'C',
		'MSCo', convert(varchar(3),d.MSCo), convert(varchar(3),i.MSCo), getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.Seq=i.Seq
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.MSCo,'') <> isnull(i.MSCo,'') and c.AuditPMMF='Y'
	end
if update(Quote)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMMF','PMCo: ' + isnull(convert(char(3),i.PMCo), '') + ' Project: ' + isnull(i.Project,'')
		+ ' Seq: ' + isnull(convert(varchar(10),i.Seq),'') + ' Phase: ' + isnull(i.Phase,'')
		+ ' CostType: ' + isnull(convert(varchar(3),i.CostType),''), i.PMCo, 'C',
		'Quote', d.Quote, i.Quote, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.Seq=i.Seq
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.Quote,'') <> isnull(i.Quote,'') and c.AuditPMMF='Y'
	end
if update(MaterialCode)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMMF','PMCo: ' + isnull(convert(char(3),i.PMCo), '') + ' Project: ' + isnull(i.Project,'')
		+ ' Seq: ' + isnull(convert(varchar(10),i.Seq),'') + ' Phase: ' + isnull(i.Phase,'')
		+ ' CostType: ' + isnull(convert(varchar(3),i.CostType),''), i.PMCo, 'C',
		'MaterialCode', d.MaterialCode, i.MaterialCode, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.Seq=i.Seq
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.MaterialCode,'') <> isnull(i.MaterialCode,'') and c.AuditPMMF='Y'
	end
if update(VendMatId)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMMF','PMCo: ' + isnull(convert(char(3),i.PMCo), '') + ' Project: ' + isnull(i.Project,'')
		+ ' Seq: ' + isnull(convert(varchar(10),i.Seq),'') + ' Phase: ' + isnull(i.Phase,'')
		+ ' CostType: ' + isnull(convert(varchar(3),i.CostType),''), i.PMCo, 'C',
		'VendMatId', d.VendMatId, i.VendMatId, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.Seq=i.Seq
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.VendMatId,'') <> isnull(i.VendMatId,'') and c.AuditPMMF='Y'
	end
if update(MtlDescription)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMMF','PMCo: ' + isnull(convert(char(3),i.PMCo), '') + ' Project: ' + isnull(i.Project,'')
		+ ' Seq: ' + isnull(convert(varchar(10),i.Seq),'') + ' Phase: ' + isnull(i.Phase,'')
		+ ' CostType: ' + isnull(convert(varchar(3),i.CostType),''), i.PMCo, 'C',
		'MtlDescription', d.MtlDescription, i.MtlDescription, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.Seq=i.Seq
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.MtlDescription,'') <> isnull(i.MtlDescription,'') and c.AuditPMMF='Y'
	end
if update(MaterialOption)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMMF','PMCo: ' + isnull(convert(char(3),i.PMCo), '') + ' Project: ' + isnull(i.Project,'')
		+ ' Seq: ' + isnull(convert(varchar(10),i.Seq),'') + ' Phase: ' + isnull(i.Phase,'')
		+ ' CostType: ' + isnull(convert(varchar(3),i.CostType),''), i.PMCo, 'C',
		'MaterialOption', d.MaterialOption, i.MaterialOption, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.Seq=i.Seq
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.MaterialOption,'') <> isnull(i.MaterialOption,'') and c.AuditPMMF='Y'
	end
if update(RecvYN)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMMF','PMCo: ' + isnull(convert(char(3),i.PMCo), '') + ' Project: ' + isnull(i.Project,'')
		+ ' Seq: ' + isnull(convert(varchar(10),i.Seq),'') + ' Phase: ' + isnull(i.Phase,'')
		+ ' CostType: ' + isnull(convert(varchar(3),i.CostType),''), i.PMCo, 'C',
		'RecvYN', d.RecvYN, i.RecvYN, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.Seq=i.Seq
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.RecvYN,'') <> isnull(i.RecvYN,'') and c.AuditPMMF='Y'
	end
if update(SendFlag)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMMF','PMCo: ' + isnull(convert(char(3),i.PMCo), '') + ' Project: ' + isnull(i.Project,'')
		+ ' Seq: ' + isnull(convert(varchar(10),i.Seq),'') + ' Phase: ' + isnull(i.Phase,'')
		+ ' CostType: ' + isnull(convert(varchar(3),i.CostType),''), i.PMCo, 'C',
		'SendFlag', d.SendFlag, i.SendFlag, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.Seq=i.Seq
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.SendFlag,'') <> isnull(i.SendFlag,'') and c.AuditPMMF='Y'
	end
if update(RequisitionNum)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMMF','PMCo: ' + isnull(convert(char(3),i.PMCo), '') + ' Project: ' + isnull(i.Project,'')
		+ ' Seq: ' + isnull(convert(varchar(10),i.Seq),'') + ' Phase: ' + isnull(i.Phase,'')
		+ ' CostType: ' + isnull(convert(varchar(3),i.CostType),''), i.PMCo, 'C',
		'RequisitionNum', d.RequisitionNum, i.RequisitionNum, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.Seq=i.Seq
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.RequisitionNum,'') <> isnull(i.RequisitionNum,'') and c.AuditPMMF='Y'
	end
if update(UM)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMMF','PMCo: ' + isnull(convert(char(3),i.PMCo), '') + ' Project: ' + isnull(i.Project,'')
		+ ' Seq: ' + isnull(convert(varchar(10),i.Seq),'') + ' Phase: ' + isnull(i.Phase,'')
		+ ' CostType: ' + isnull(convert(varchar(3),i.CostType),''), i.PMCo, 'C',
		'UM', d.UM, i.UM, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.Seq=i.Seq
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.UM,'') <> isnull(i.UM,'') and c.AuditPMMF='Y'
	end
if update(ECM)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMMF','PMCo: ' + isnull(convert(char(3),i.PMCo), '') + ' Project: ' + isnull(i.Project,'')
		+ ' Seq: ' + isnull(convert(varchar(10),i.Seq),'') + ' Phase: ' + isnull(i.Phase,'')
		+ ' CostType: ' + isnull(convert(varchar(3),i.CostType),''), i.PMCo, 'C',
		'ECM', d.ECM, i.ECM, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.Seq=i.Seq
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.ECM,'') <> isnull(i.ECM,'') and c.AuditPMMF='Y'
	end
if update(TaxType)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMMF','PMCo: ' + isnull(convert(char(3),i.PMCo), '') + ' Project: ' + isnull(i.Project,'')
		+ ' Seq: ' + isnull(convert(varchar(10),i.Seq),'') + ' Phase: ' + isnull(i.Phase,'')
		+ ' CostType: ' + isnull(convert(varchar(3),i.CostType),''), i.PMCo, 'C',
		'TaxType', convert(varchar(3),d.TaxType), convert(varchar(3),i.TaxType), getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.Seq=i.Seq
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.TaxType,'') <> isnull(i.TaxType,'') and c.AuditPMMF='Y'
	end
if update(TaxCode)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMMF','PMCo: ' + isnull(convert(char(3),i.PMCo), '') + ' Project: ' + isnull(i.Project,'')
		+ ' Seq: ' + isnull(convert(varchar(10),i.Seq),'') + ' Phase: ' + isnull(i.Phase,'')
		+ ' CostType: ' + isnull(convert(varchar(3),i.CostType),''), i.PMCo, 'C',
		'TaxCode', d.TaxCode, i.TaxCode, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.Seq=i.Seq
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.TaxCode,'') <> isnull(i.TaxCode,'') and c.AuditPMMF='Y'
	end
if update(ReqDate)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMMF','PMCo: ' + isnull(convert(char(3),i.PMCo), '') + ' Project: ' + isnull(i.Project,'')
		+ ' Seq: ' + isnull(convert(varchar(10),i.Seq),'') + ' Phase: ' + isnull(i.Phase,'')
		+ ' CostType: ' + isnull(convert(varchar(3),i.CostType),''), i.PMCo, 'C',
		'ReqDate', convert(char(8),d.ReqDate,1), convert(char(8),i.ReqDate,1), getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.Seq=i.Seq
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.ReqDate,'') <> isnull(i.ReqDate,'') and c.AuditPMMF='Y'
	end
if update(Units)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMMF','PMCo: ' + isnull(convert(char(3),i.PMCo), '') + ' Project: ' + isnull(i.Project,'')
		+ ' Seq: ' + isnull(convert(varchar(10),i.Seq),'') + ' Phase: ' + isnull(i.Phase,'')
		+ ' CostType: ' + isnull(convert(varchar(3),i.CostType),''), i.PMCo, 'C',
		'Units', convert(varchar(20),d.Units), convert(varchar(20),i.Units), getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.Seq=i.Seq
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(convert(varchar(20),d.Units),'') <> isnull(convert(varchar(20),i.Units),'') and c.AuditPMMF='Y'
	end
if update(UnitCost)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMMF','PMCo: ' + isnull(convert(char(3),i.PMCo), '') + ' Project: ' + isnull(i.Project,'')
		+ ' Seq: ' + isnull(convert(varchar(10),i.Seq),'') + ' Phase: ' + isnull(i.Phase,'')
		+ ' CostType: ' + isnull(convert(varchar(3),i.CostType),''), i.PMCo, 'C',
		'UnitCost', convert(varchar(20),d.UnitCost), convert(varchar(20),i.UnitCost), getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.Seq=i.Seq
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(convert(varchar(20),d.UnitCost),'') <> isnull(convert(varchar(20),i.UnitCost),'') and c.AuditPMMF='Y'
	end
if update(Amount)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMMF','PMCo: ' + isnull(convert(char(3),i.PMCo), '') + ' Project: ' + isnull(i.Project,'')
		+ ' Seq: ' + isnull(convert(varchar(10),i.Seq),'') + ' Phase: ' + isnull(i.Phase,'')
		+ ' CostType: ' + isnull(convert(varchar(3),i.CostType),''), i.PMCo, 'C',
		'Amount', convert(varchar(20),d.Amount), convert(varchar(20),i.Amount), getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.Seq=i.Seq
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(convert(varchar(20),d.Amount),'') <> isnull(convert(varchar(20),i.Amount),'') and c.AuditPMMF='Y'
	end



trigger_end:
return


error:
if @opencursor = 1
	begin
	close bPMMF_insert
	deallocate bPMMF_insert
	select @opencursor = 0
	end

   	select @errmsg = isnull(@errmsg,'') + ' - cannot update PMMF'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   










GO
ALTER TABLE [dbo].[bPMMF] WITH NOCHECK ADD CONSTRAINT [CK_bPMMF_ECM] CHECK (([ECM]='E' OR [ECM]='C' OR [ECM]='M' OR [ECM] IS NULL))
GO
ALTER TABLE [dbo].[bPMMF] WITH NOCHECK ADD CONSTRAINT [CK_bPMMF_MaterialOption] CHECK (([MaterialOption]='R' OR [MaterialOption]='Q' OR [MaterialOption]='M' OR [MaterialOption]='P'))
GO
ALTER TABLE [dbo].[bPMMF] WITH NOCHECK ADD CONSTRAINT [CK_bPMMF_RecordType] CHECK (([RecordType]='C' OR [RecordType]='O'))
GO
ALTER TABLE [dbo].[bPMMF] WITH NOCHECK ADD CONSTRAINT [CK_bPMMF_RecvYN] CHECK (([RecvYN]='Y' OR [RecvYN]='N'))
GO
ALTER TABLE [dbo].[bPMMF] WITH NOCHECK ADD CONSTRAINT [CK_bPMMF_SendFlag] CHECK (([SendFlag]='Y' OR [SendFlag]='N'))
GO
ALTER TABLE [dbo].[bPMMF] WITH NOCHECK ADD CONSTRAINT [CK_bPMMF_TaxCode_TaxGroup] CHECK (([TaxCode] IS NULL OR [TaxGroup] IS NOT NULL))
GO
ALTER TABLE [dbo].[bPMMF] WITH NOCHECK ADD CONSTRAINT [CK_bPMMF_TaxType_TaxCode] CHECK (([TaxType] IS NULL OR [TaxCode] IS NOT NULL))
GO
ALTER TABLE [dbo].[bPMMF] WITH NOCHECK ADD CONSTRAINT [CK_bPMMF_UM_MaterialOption] CHECK (([UM]<>'LS' OR [MaterialOption]<>'Q' AND [MaterialOption]<>'M'))
GO
ALTER TABLE [dbo].[bPMMF] WITH NOCHECK ADD CONSTRAINT [CK_bPMMF_UM_UnitAmount] CHECK ((NOT ([UM]<>'LS' AND isnull([Amount],(0))<>(0) AND isnull([Units],(0))=(0))))
GO
ALTER TABLE [dbo].[bPMMF] WITH NOCHECK ADD CONSTRAINT [CK_bPMMF_UM_UnitCost] CHECK (([UM]<>'LS' OR isnull([UnitCost],(0))=(0)))
GO
ALTER TABLE [dbo].[bPMMF] WITH NOCHECK ADD CONSTRAINT [CK_bPMMF_UM_Units] CHECK (([UM]<>'LS' OR isnull([Units],(0))=(0)))
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPMMF] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPMMF] ON [dbo].[bPMMF] ([PMCo], [Project], [Seq]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [biPMMFPOTotals] ON [dbo].[bPMMF] ([PO], [RecordType], [ACO], [MaterialOption], [POCo], [POItem], [Amount], [InterfaceDate], [SendFlag]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bPMMF] WITH NOCHECK ADD CONSTRAINT [FK_bPMMF_bJCJM] FOREIGN KEY ([PMCo], [Project]) REFERENCES [dbo].[bJCJM] ([JCCo], [Job])
GO
ALTER TABLE [dbo].[bPMMF] WITH NOCHECK ADD CONSTRAINT [FK_bPMMF_bHQTX] FOREIGN KEY ([TaxGroup], [TaxCode]) REFERENCES [dbo].[bHQTX] ([TaxGroup], [TaxCode])
GO
ALTER TABLE [dbo].[bPMMF] WITH NOCHECK ADD CONSTRAINT [FK_bPMMF_bAPVM] FOREIGN KEY ([VendorGroup], [Vendor]) REFERENCES [dbo].[bAPVM] ([VendorGroup], [Vendor])
GO
ALTER TABLE [dbo].[bPMMF] NOCHECK CONSTRAINT [FK_bPMMF_bJCJM]
GO
ALTER TABLE [dbo].[bPMMF] NOCHECK CONSTRAINT [FK_bPMMF_bHQTX]
GO
ALTER TABLE [dbo].[bPMMF] NOCHECK CONSTRAINT [FK_bPMMF_bAPVM]
GO
