CREATE TABLE [dbo].[bPMOL]
(
[PMCo] [dbo].[bCompany] NOT NULL,
[Project] [dbo].[bJob] NOT NULL,
[PCOType] [dbo].[bDocType] NULL,
[PCO] [dbo].[bPCO] NULL,
[PCOItem] [dbo].[bPCOItem] NULL,
[ACO] [dbo].[bACO] NULL,
[ACOItem] [dbo].[bACOItem] NULL,
[PhaseGroup] [dbo].[bGroup] NOT NULL,
[Phase] [dbo].[bPhase] NOT NULL,
[CostType] [dbo].[bJCCType] NOT NULL,
[EstUnits] [dbo].[bUnits] NOT NULL,
[UM] [dbo].[bUM] NOT NULL,
[UnitHours] [dbo].[bHrs] NOT NULL,
[EstHours] [dbo].[bHrs] NOT NULL,
[HourCost] [dbo].[bUnitCost] NOT NULL,
[UnitCost] [dbo].[bUnitCost] NOT NULL,
[ECM] [dbo].[bECM] NOT NULL,
[EstCost] [dbo].[bDollar] NOT NULL,
[SendYN] [dbo].[bYN] NOT NULL,
[InterfacedDate] [dbo].[bDate] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[CreatedFromAddOn] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMOL_CreatedFromAddOn] DEFAULT ('N'),
[DistributedAmt] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bPMOL_DistributedAmt] DEFAULT ((0)),
[PO] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[Subcontract] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[PurchaseAmt] [dbo].[bDollar] NULL CONSTRAINT [DF_bPMOL_PurchaseAmt] DEFAULT ((0)),
[VendorGroup] [dbo].[bGroup] NULL,
[Vendor] [dbo].[bVendor] NULL,
[POSLItem] [dbo].[bItem] NULL,
[SubCO] [smallint] NULL,
[SubCOSeq] [int] NULL,
[POCONum] [smallint] NULL,
[POCONumSeq] [int] NULL,
[MaterialCode] [dbo].[bMatl] NULL,
[PurchaseUnits] [dbo].[bUnits] NULL,
[PurchaseUM] [dbo].[bUM] NULL,
[PurchaseUnitCost] [dbo].[bUnitCost] NULL,
[udSource] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[udConv] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[udCGCTable] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[udCGCTableID] [decimal] (12, 0) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPMOLd    Script Date: 8/28/99 9:37:56 AM ******/
CREATE trigger [dbo].[btPMOLd] on [dbo].[bPMOL] for DELETE as
/*--------------------------------------------------------------
* Delete trigger for PMOL
* Created By:	JRE 5/11/98
* Modified By:	GF	4/1/99
*				GF 05/10/01 - Added check if exists in JCOD and has been interfaced.
*				GF 10/09/2002 - changed dbl quotes to single quotes
*				GF 11/04/2003 - issue #21104 - use PMAddons for pending calcs, also performance changes
*				GF 02/29/2008 - issue #127195 #127210 changed to use vspPMOACalcs
*				JG 04/02/2011 - TK-03439 - Remove SL/PO detail when removing PMOL
*				DAN SO 04/26/2011 - TK-04451 & TK-04450 - conflicts with TK-03439
*									- Deleting Items within PCO - user has option to delete Change Order recs
*									- need to discuss with Jeremy
*				GF 06/21/2012 TK-15946 re-worked PCO side of delete. PMSL/PMMF detail cannot be interfaced. Basically backed out TK-04450 04451
*
*
*  Calculates pending amount for PMOI
*--------------------------------------------------------------*/
declare @numrows int, @errmsg varchar(255), @rcode int, @validcnt int, @openaco_cursor int,
		@openpco_cursor int, @phasegroup tinyint, @costtype tinyint, @pmco bCompany,
		@project bJob, @pcotype bDocType, @pco bDocument, @pcoitem bPCOItem, @aco bACO,
		@acoitem bACOItem, @phase bPhase
		
select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

select @rcode = 0, @openaco_cursor = 0, @openpco_cursor = 0


   -----------------------------------------------------------------
   -- This cursor will only pick up ACO's - Approved Change Orders
   -----------------------------------------------------------------
   
   -- use a cursor to process each deleted row
   declare bPMOL_ACO_delete cursor LOCAL FAST_FORWARD for
   select PMCo, Project, ACO, ACOItem, PhaseGroup, Phase, CostType
   from deleted
   where ACO is not null and ACOItem is not null
   
   open bPMOL_ACO_delete
   set @openaco_cursor = 1
   
   PMOL_ACO_LOOP:
   fetch next from bPMOL_ACO_delete into @pmco, @project, @aco, @acoitem, @phasegroup, @phase, @costtype
   if @@fetch_status = -1 goto PMOL_ACO_END
   if @@fetch_status <> 0 goto PMOL_ACO_LOOP
   
   -- check change order detail in bJCOD
   select @validcnt=count(*) from bJCOD j with (nolock)
   join deleted p on p.PMCo=j.JCCo and p.Project=j.Job and p.ACO=j.ACO and p.ACOItem=j.ACOItem
   and p.Phase=j.Phase and p.CostType=j.CostType
   where j.JCCo=@pmco and j.Job=@project and j.ACO=@aco and j.ACOItem=@acoitem and j.Phase=@phase
   and j.CostType=@costtype and p.InterfacedDate is not null
   if @validcnt <> 0
   	begin
   	select @errmsg = 'Change Order Phase detail has been interfaced, delete from Job Cost first.'
   	Goto error
   	end
   
   -- check for subcontract detail in bPMSL
   select @validcnt=count(*) from bPMSL with (nolock)
   where bPMSL.PMCo=@pmco and bPMSL.Project=@project and bPMSL.ACO=@aco and bPMSL.ACOItem=@acoitem
   and bPMSL.PhaseGroup=@phasegroup and bPMSL.Phase=@phase and bPMSL.CostType=@costtype
   and (bPMSL.SL is not null or bPMSL.InterfaceDate is not null)
   if @validcnt <> 0
   	begin
   	select @errmsg = 'Subcontract detail exists, cannot delete.'
   	Goto error
   	end
   else
   	begin
   	delete from bPMSL
   	where bPMSL.PMCo=@pmco and bPMSL.Project=@project and bPMSL.ACO=@aco and bPMSL.ACOItem=@acoitem
   	and bPMSL.PhaseGroup=@phasegroup and bPMSL.Phase=@phase and bPMSL.CostType=@costtype
   	end
   
   -- check for material detail in bPMMF
   select @validcnt=count(*) from bPMMF with (nolock)
   where bPMMF.PMCo=@pmco and bPMMF.Project=@project and bPMMF.ACO=@aco and bPMMF.ACOItem=@acoitem
   and bPMMF.PhaseGroup=@phasegroup and bPMMF.Phase=@phase and bPMMF.CostType=@costtype
   and (bPMMF.PO is not null or bPMMF.MO is not null or bPMMF.InterfaceDate is not null)
   if @validcnt <> 0
   	begin
      	select @errmsg = 'Material detail exists, cannot delete.'
      	Goto error
      	end
   else
   	begin
   	delete from bPMMF
   	where bPMMF.PMCo=@pmco and bPMMF.Project=@project and bPMMF.ACO=@aco and bPMMF.ACOItem=@acoitem
   	and bPMMF.PhaseGroup=@phasegroup and bPMMF.Phase=@phase and bPMMF.CostType=@costtype
   	end
   
   goto PMOL_ACO_LOOP
   
   PMOL_ACO_END:
   	if @openaco_cursor <> 0
   		begin
   		close bPMOL_ACO_delete
   		deallocate bPMOL_ACO_delete
   		set @openaco_cursor = 0
   		end
   
   --------------------------------------------------------------------
   -- this cursor will only pick up PCO's - Pending Change Orders
   --------------------------------------------------------------------
   
   -- use a cursor to process each deleted row
   declare bPMOL_PCO_delete cursor LOCAL FAST_FORWARD FOR
   select PMCo, Project, PCOType, PCO, PCOItem, PhaseGroup, Phase, CostType
   from deleted
	where PCO IS NOT NULL
		AND PCOItem IS NOT NULL
   
   open bPMOL_PCO_delete
   set @openpco_cursor = 1
   
   PMOL_PCO_LOOP:
   fetch next from bPMOL_PCO_delete into @pmco, @project, @pcotype, @pco, @pcoitem, @phasegroup, @phase, @costtype
   if @@fetch_status = -1 goto PMOL_PCO_END
   if @@fetch_status <> 0 goto PMOL_PCO_LOOP
	
	----TK-15946
	---- check for interfaced subcontract detail in bPMSL
	select @validcnt=count(*) from dbo.bPMSL
	where bPMSL.PMCo=@pmco and bPMSL.Project=@project
		AND bPMSL.PCOType = @pcotype
		AND bPMSL.PCO = @pco
		AND bPMSL.PCOItem = @pcoitem
		AND bPMSL.PhaseGroup=@phasegroup 
		AND bPMSL.Phase=@phase
		AND bPMSL.CostType=@costtype
		AND bPMSL.InterfaceDate IS NOT NULL
   if @validcnt <> 0
		BEGIN
		SELECT @errmsg = 'Interfaced Subcontract detail exists, cannot delete.'
		GOTO error
		END
	ELSE
		BEGIN
		DELETE FROM dbo.bPMSL
		WHERE PMCo = @pmco 
			AND Project = @project
			AND PCOType = @pcotype 
			AND PCO = @pco
			AND PCOItem = @pcoitem 
			AND PhaseGroup = @phasegroup 
			AND Phase = @phase
			AND CostType = @costtype
		END

	---- check for interfaced material detail in bPMMF
	select @validcnt=count(*) from dbo.bPMMF
	where bPMMF.PMCo=@pmco and bPMMF.Project=@project 
		AND bPMMF.PCOType = @pcotype
		AND bPMMF.PCO = @pco 
		AND bPMMF.PCOItem=@pcoitem
		AND bPMMF.PhaseGroup=@phasegroup 
		AND bPMMF.Phase=@phase 
		AND bPMMF.CostType=@costtype
		AND bPMMF.InterfaceDate IS NOT NULL
	if @validcnt <> 0
		begin
		select @errmsg = 'Interfaced Material detail exists, cannot delete.'
		Goto error
		END
	ELSE
		BEGIN
		DELETE FROM dbo.bPMMF
		WHERE PMCo = @pmco 
			AND Project = @project
			AND PCOType = @pcotype 
			AND PCO = @pco
			AND PCOItem = @pcoitem 
			AND PhaseGroup = @phasegroup 
			AND Phase = @phase
			AND CostType = @costtype
		END


	---- calculate pending amount
	calc_pending_amount:
	exec @rcode = dbo.vspPMOACalcs @pmco, @project, @pcotype, @pco, @pcoitem

	goto PMOL_PCO_LOOP
   
   
PMOL_PCO_END:
	if @openpco_cursor <> 0
		begin
		close bPMOL_PCO_delete
		deallocate bPMOL_PCO_delete
		set @openpco_cursor = 0
		end

return




error:
   	if @openpco_cursor <> 0
   		begin
   		close bPMOL_PCO_delete
   		deallocate bPMOL_PCO_delete
   		set @openpco_cursor = 0
   		end
   
   	if @openaco_cursor <> 0
   		begin
   		close bPMOL_ACO_delete
   		deallocate bPMOL_ACO_delete
   		set @openaco_cursor = 0
   		end
   
       select @errmsg = isnull(@errmsg,'') + ' - cannot delete Change Order Line PMOL'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



/****** Object:  Trigger dbo.btPMOLi    Script Date: 8/28/99 9:37:57 AM ******/
CREATE  trigger [dbo].[btPMOLi] on [dbo].[bPMOL] for INSERT as
/*--------------------------------------------------------------
*  Insert trigger for PMOL
*  Created By: JRE  5/11/98
*  Modified By: LM  9/29/98
*               GF  1/20/2000 - Use Retg % from JCCI as default if adding PMSL
*               GF 06/29/2001 - Re-wrote trigger - did not work for bulk inserts.
*				GF 04/01/2002 - Changed insert PMSL to get sequence first.
*				GF 10/09/2002 - changed dbl quotes to single quotes
*				GF 02/29/2008 - issue #127195 #127210 changed to use vspPMOACalcs
*				GF 01/25/2009 - issue #131843 do not add to PMSL if units=0, amount<>0, um<>'LS'
*				GF 01/30/2009 - issue #129669 add-on proportional cost distributions
*				GF 03/20/2009 - issue #132108 addons and markups not initialize for internal
*				GF 05/29/2009 - issue #133843 problem with external CO and markups not being set
*				GF 07/22/2009 - issue #129667 add material options with estimates
*				GF 08/31/2009 - issue #135377 missing fetch next when cursor created.
*				GF 06/29/2010 - issue #140152 material records in PMMF being created for all cost types. ANSI?
*				JG 02/17/2011 - V1# B-02366 copy vendor, sl/po, purchase amount to SL
*				GP 02/22/2011 - set purchase amount to 0 if null, was causing multiple NULL unit cost insert errors
*				DAN SO 03/16/2011 - V1# B-02356 - update SCO with PCOType/PCO/PCOItem
*				GP 03/23/2011 - fixed cursor fetch error, columns missing at final fetch
*				GF 03/25/2011 - TK-03354
*				JG 05/02/2011 - TK-04820 - Added Material Code when creating PMMF record
*				GF 05/07/2011 - TK-04937 re-write the PMMF-PMSL insert for assigning to PCO/ACO
*				GF 05/24/2011 - TK-05347 ready for accounting flag
*				GF 06/18/2011 - TK-06041 update PMSL/PMMF with purchase columns
*				GP 06/22/2011 - TK-06208 Added checks for @ImpactSL and @ImpactPO before inserting to PMSL and PMMF
*				DAN SO 06/24/2011 - TK-06237 - fixing PCO Copy error
*				DAN SO 6/27/2011 - TK-06210 - fixed bPMOL_insert does not exist error
*				GF 07/20/2011 - TK-06890 missed wrapping values with is null when inserting PMSL/PMMF records
*				GP 7/27/2011 - TK-07144 changed bPO to varchar(30)
*				GP 8/8/2011	- TK-07549 removed check for @ecm = 'C' in beginning of insert_check
*				GF 11/23/2011 - TK-10530 CI#145135
*				GF 02/10/2012 TK-12465 #145746 do not try to assign to existing PMSL record
*				GF 03/02/2012 TK-12995 #146001
*               JayR 10/15/2012 TK-16099 Fix overlapping variables.
*				ScottP 01/11/2013 TK-20713 Fix mismatch with Select and Fetch with ECM field
*
*  Calculates pending amount for PMOI
*--------------------------------------------------------------*/
declare @numrows int, @rcode int, @errmsg varchar(255), @opencursor tinyint,
		@validcnt INT, @validcnt2 INT,
		@pmco bCompany, @project bJob, @pcotype bDocType, @pco bPCO, @pcoitem bPCOItem, @aco bACO,
		@acoitem bACOItem, @phasegroup bGroup, @phase bPhase, @costtype bJCCType, @estunits bUnits,
		@um bUM, @esthours bHrs, @unitcost bUnitCost, @ecm bECM, @estcost bDollar, @apco bCompany,
		@slcosttype bJCCType, @dfltwcpct bPct, @retcode int, @seq int, @mtlcosttype bJCCType,
		---- B-02366 B-02356 TK-03354 JG0502 TK-04937
		@VendorGroup bGroup, @vendor bVendor, @po varchar(30), @sl VARCHAR(30),
		@PurchaseAmount bDollar, @SubCO smallint, @SubCOSeq INT, @POSLItem bItem,
		@SLItemType TINYINT, @MatlCode bMatl, @POCONum SMALLINT, @POCONumSeq INT,
		@PMMF_POCONum SMALLINT, @PMMF_POCONumSeq INT, @KeyID BIGINT, @PMMF_KeyID BIGINT,
		@POIT_KeyID BIGINT, @Next_Seq INT, @DfltVendorGroup bGroup, @PMSL_SubCO SMALLINT,
		@PMSL_SubCOSeq INT, @PMSL_KeyID BIGINT, @SLIT_KeyID BIGINT, @UseMatlPhaseDesc CHAR(1),
		---- TK-06041
		@UsePhaseDesc CHAR(1), @PhaseDesc bItemDesc, @MaterialCode bMatl,
		@PurchaseUnits bUnits, @PurchaseUM bUM, @PurchaseUnitCost bUnitCost,
		@MaterialGroup bGroup, @ImpactSL bYN, @ImpactPO bYN

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

SET @rcode = 0
SET @opencursor = 0

------ if assigned to PO must have POItem
--SELECT @validcnt = COUNT(*) FROM inserted WHERE PO IS NOT NULL AND POSLItem IS NULL
--IF @validcnt <> 0
--	BEGIN
--	SET @errmsg = 'Missing PO Item'
--	GOTO error
--	END

------ if assigned to subcontract must have slItem
--SELECT @validcnt = COUNT(*) FROM inserted WHERE Subcontract IS NOT NULL AND POSLItem IS NULL
--IF @validcnt <> 0
--	BEGIN
--	SET @errmsg = 'Missing SL Item'
--	GOTO error
--	END

---- Validate Vendor
--SELECT @validcnt = count(*) from dbo.bAPVM r
--		JOIN inserted i ON i.VendorGroup = r.VendorGroup and i.Vendor = r.Vendor
--SELECT @validcnt2 = count(*) from inserted i where i.Vendor is null
--if @validcnt + @validcnt2 <> @numrows
--	BEGIN
--	SELECT @errmsg = 'Vendor is Invalid'
--	goto error
--	END

---- if assigned to a SL the VendorGroup/Vendor must match SL
SELECT @validcnt = COUNT(*) FROM inserted i
JOIN dbo.bPMCO c ON c.PMCo=i.PMCo
JOIN dbo.bSLHD h ON h.SLCo=c.APCo AND h.SL=i.Subcontract AND h.VendorGroup=i.VendorGroup AND h.Vendor=i.Vendor
SELECT @validcnt2 = COUNT(*) FROM inserted i WHERE i.Subcontract IS NULL
if @validcnt + @validcnt2 <> @numrows
	BEGIN
	SELECT @errmsg = 'Vendor is Invalid for Subcontract'
	goto error
	END

---- if assigned to a PO the VendorGroup/Vendor must match PO
SELECT @validcnt = COUNT(*) FROM inserted i
JOIN dbo.bPMCO c ON c.PMCo=i.PMCo
JOIN dbo.bPOHD h ON h.POCo=c.APCo AND h.PO=i.PO AND h.VendorGroup=i.VendorGroup AND h.Vendor=i.Vendor
SELECT @validcnt2 = COUNT(*) FROM inserted i WHERE i.PO IS NULL
if @validcnt + @validcnt2 <> @numrows
	BEGIN
	SELECT @errmsg = 'Vendor is Invalid for Purchase Order'
	goto error
	END

---- validate ACO change order item
SELECT @validcnt = COUNT(*) FROM inserted i
JOIN dbo.bPMOI o ON i.PMCo=o.PMCo AND i.Project=o.Project AND i.ACO=o.ACO AND i.ACOItem=o.ACOItem
SELECT @validcnt2 = COUNT(*) FROM inserted i WHERE i.ACOItem IS NULL
if @validcnt + @validcnt2 <> @numrows
	begin
	select @errmsg = 'Approved Change Order Item is Invalid'
	goto error
	end

---- validate PCO change order item
SELECT @validcnt = COUNT(*) FROM inserted i
JOIN dbo.bPMOI o ON i.PMCo=o.PMCo AND i.Project=o.Project AND i.PCOType=o.PCOType AND i.PCO=o.PCO AND i.PCOItem=o.PCOItem
SELECT @validcnt2 = COUNT(*) FROM inserted i WHERE i.PCOItem IS NULL
if @validcnt + @validcnt2 <> @numrows
	begin
	select @errmsg = 'Pending Change Order Item is Invalid'
	goto error
	end

---- validate not posting soft-closed job with JCCO flag
SELECT @validcnt = COUNT(*) FROM inserted i
JOIN dbo.bJCJM j ON j.JCCo=i.PMCo AND j.Job=i.Project
JOIN dbo.bJCCO c ON c.JCCo=i.PMCo
WHERE i.PMCo=j.JCCo and i.Project=j.Job and i.PMCo=c.JCCo
AND ((c.PostSoftClosedJobs = 'N' and j.JobStatus = 2)
OR   (c.PostClosedJobs = 'N' AND j.JobStatus = 3))
IF @validcnt <> 0
	BEGIN
	SELECT @errmsg = 'Cannot Post to Soft-Closed or Hard-Closed Job'
	goto error
	END


---- create cursor for PMOL inserted rows TK-04937
if @numrows = 1
	BEGIN
	select @pmco=PMCo, @project=Project, @pcotype=PCOType, @pco=PCO, @pcoitem=PCOItem, @aco=ACO,
			@acoitem=ACOItem, @phasegroup=PhaseGroup, @phase=Phase, @costtype=CostType,
			@estunits=EstUnits, @um=UM, @esthours=EstHours, @unitcost=UnitCost, @ecm=ECM,
			@estcost=EstCost,
			----TK-04971
			@VendorGroup=VendorGroup, @vendor=Vendor, @po=PO, @sl=Subcontract, @POSLItem=POSLItem,
			@PurchaseAmount=PurchaseAmt, @SubCO=SubCO, @SubCOSeq=SubCOSeq,
			---- TK-06041
			@POCONum=POCONum, @POCONumSeq=POCONumSeq, @KeyID=KeyID, @MaterialCode=MaterialCode,
			@PurchaseUnits=PurchaseUnits, @PurchaseUM=PurchaseUM, @PurchaseUnitCost=PurchaseUnitCost
	from inserted
	
	END
else
   begin
   -- use a cursor to process each inserted row
   declare bPMOL_insert cursor LOCAL FAST_FORWARD
   for select PMCo, Project, PCOType, PCO, PCOItem, ACO, ACOItem, PhaseGroup, Phase, CostType,
              EstUnits, UM, EstHours, UnitCost, ECM, EstCost,
              ----TK-04971
              VendorGroup, Vendor, PO, Subcontract, POSLItem,
              PurchaseAmt, SubCO, SubCOSeq, POCONum, POCONumSeq, KeyID,
              ---- TK-06041
              MaterialCode, PurchaseUnits, PurchaseUM, PurchaseUnitCost
   from inserted

   open bPMOL_insert
   set @opencursor=1
   
   ---- #135377
   fetch next from bPMOL_insert into @pmco, @project, @pcotype, @pco, @pcoitem, @aco, @acoitem, 
				@phasegroup, @phase, @costtype, @estunits, @um, @esthours, @unitcost, @ecm, @estcost,
				----TK-04971
				@VendorGroup, @vendor, @po, @sl, @POSLItem, @PurchaseAmount, @SubCO, @SubCOSeq,
				@POCONum, @POCONumSeq, @KeyID,
				---- TK-06041
				@MaterialCode, @PurchaseUnits, @PurchaseUM, @PurchaseUnitCost
	if @@fetch_status <> 0
		begin
		select @errmsg = 'Cursor error'
		goto error
		end
   end
----TK-04937

insert_check:

---- get subcontract cost type and material cost type from PMCO
select @apco=p.APCo, @slcosttype=p.SLCostType, @mtlcosttype=p.MtlCostType,
		@DfltVendorGroup=a.VendorGroup, @UsePhaseDesc=PhaseDescYN,
		@UseMatlPhaseDesc=MatlPhaseDesc, @MaterialGroup=h.MatlGroup
FROM dbo.bPMCO p
INNER join dbo.bHQCO h on h.HQCo = p.PMCo
INNER join dbo.bHQCO a on a.HQCo = p.APCo -- TK-06237 --
where PMCo=@pmco

---- set Vendor Group to default if null
IF @VendorGroup IS NULL SET @VendorGroup = @DfltVendorGroup

---- TK-00000
IF ISNULL(@um,'') = '' SET @um = 'LS'

---- insert markups if a PCO
if isnull(@pcotype,'') <> '' and isnull(@pco,'') <> '' and isnull(@pcoitem,'') <> ''
	begin
	-- insert markups
	insert into dbo.bPMOM(PMCo,Project,PCOType,PCO,PCOItem,PhaseGroup,CostType,IntMarkUp,ConMarkUp)
	select distinct PMOL.PMCo, PMOL.Project, PMOL.PCOType, PMOL.PCO, PMOL.PCOItem,
				PMOL.PhaseGroup, PMOL.CostType, 0,
				---- 133843
				case when isnull(h.IntExt,'E') = 'E' then isnull(PMPC.Markup,0)
					 when isnull(t.InitAddons,'Y') = 'Y' then IsNull(PMPC.Markup,0)
					 else 0 end
	from dbo.bPMOL PMOL with (nolock)
	----#132046
	join dbo.bPMOP h with (nolock) on h.PMCo=@pmco and h.Project=@project and h.PCOType=@pcotype and h.PCO=@pco
	JOIN dbo.bPMDT t with (nolock) on t.DocType=h.PCOType
	left join dbo.bPMOM PMOM on PMOM.PMCo=PMOL.PMCo and PMOM.Project=PMOL.Project
		and PMOM.PCOType=PMOL.PCOType and PMOM.PCO=PMOL.PCO and PMOM.PCOItem=PMOL.PCOItem
		and PMOM.PhaseGroup=PMOL.PhaseGroup and PMOM.CostType=PMOL.CostType
	left join bPMPC PMPC on PMPC.PMCo=PMOL.PMCo and PMPC.Project=PMOL.Project
		and PMPC.PhaseGroup=PMOL.PhaseGroup and PMPC.CostType=PMOL.CostType
	where PMOL.PMCo=@pmco and PMOL.Project=@project and PMOL.PCOType=@pcotype and PMOL.PCO=@pco
	and PMOM.PMCo is null

	---- calculate pending amount
	exec @rcode = dbo.vspPMOACalcs @pmco, @project, @pcotype, @pco, @pcoitem
	end

----TK-04937
---- first check to see if the PMOL record added is assigned to a SL and SLITEM
---- if so see if an 'O' PMSL record exists that match the key fields. When one is
---- found, then assign PMOL record to that PMSL record and change the type to 'C' in PMSL.
---- then update the SubCO and SubCOSeq in PMOL. You cannot rely on the PCO, PCOItem
---- being assigned in PMSL. If entered directly from SCO, then was not initially setup
---- as from a change order
IF @sl IS NOT NULL AND @POSLItem IS NOT NULL
	BEGIN
	----IF @SubCO IS NULL
	----	BEGIN
	----	---- check for one PMSL record
	----	SET @PMSL_SubCO = NULL
	----	SET @PMSL_SubCOSeq = NULL
	----	SET @PMSL_KeyID = NULL
	----	SELECT TOP 1 @PMSL_SubCO=s.SubCO, @PMSL_SubCOSeq=s.Seq, @PMSL_KeyID=s.KeyID
	----	FROM dbo.bPMSL s WHERE s.PMCo=@pmco AND s.Project=@project AND s.RecordType='O'
	----			AND s.SL=@sl AND s.SLItem=@POSLItem AND s.Phase=@phase AND s.CostType=@costtype
	----			AND s.PCOItem IS NULL AND s.ACOItem IS NULL AND s.InterfaceDate IS NULL
	----			----TK-00000 SCO must not be approved
	----			AND NOT EXISTS(SELECT 1 FROM dbo.vPMSubcontractCO h WHERE h.SLCo=s.SLCo AND h.SL=s.SL AND h.SubCO=s.SubCO AND h.ReadyForAcctg = 'Y')
	----	IF @PMSL_KeyID IS NOT NULL
	----		BEGIN
	----		---- update the one record with PMOL info
	----		UPDATE dbo.bPMSL SET RecordType='C', PCOType=@pcotype, PCO=@pco, PCOItem=@pcoitem,
	----							 ACO=@aco, ACOItem=@acoitem,
	----							 ----TK-06041 -- TK-06237 --
	----							 UM=ISNULL(@PurchaseUM,@um), 
	----							 Units=ISNULL(@PurchaseUnits,0), 
	----							 UnitCost=ISNULL(@PurchaseUnitCost,0),
	----							 Amount=ISNULL(@PurchaseAmount,0)		  
	----		WHERE KeyID = @PMSL_KeyID	
			
	----		---- update the SubCO and SubCOSeq to the current PMOL record
	----		UPDATE dbo.bPMOL SET SubCO=@PMSL_SubCO, SubCOSeq=@PMSL_SubCOSeq
	----		WHERE KeyID = @KeyID
	----			AND SubCO <> @PMSL_SubCO
			
	----		---- done move to next row
	----		GOTO NEXTROW
	----		END 
	----	END
	----ELSE
	----	BEGIN
		-------------
		-- B-02356 --
		-------------
		IF @SubCO IS NOT NULL AND @SubCOSeq IS NOT NULL
			BEGIN
			---- validate record really exists in PMSL
			SET @PMSL_KeyID = NULL
			SELECT @PMSL_KeyID = KeyID
			FROM dbo.bPMSL WHERE PMCo=@pmco AND Project=@project
					AND PhaseGroup=@phasegroup AND Phase=@phase
					AND CostType=@costtype AND SubCO=@SubCO
					AND Seq=@SubCOSeq AND InterfaceDate IS NULL
			---- update PMSL
			IF @PMSL_KeyID IS NOT NULL
				BEGIN
				UPDATE dbo.bPMSL
						SET RecordType = 'C',
							PCOType = @pcotype, PCO = @pco,
							PCOItem = @pcoitem, ACO = @aco,
							ACOItem = @acoitem,
							----TK-06041 -- TK-06237 --
							UM=ISNULL(@PurchaseUM,@um),
							Units=ISNULL(@PurchaseUnits,0), 
							----TK-12995
							UnitCost = CASE WHEN ISNULL(@PurchaseUM,@um) = 'LS' THEN 0 ELSE ISNULL(@PurchaseUnitCost,0) END,
							Amount=ISNULL(@PurchaseAmount,0)
				WHERE KeyID=@PMSL_KeyID	
				END
			
			---- DONE move to next row
			GOTO NEXTROW
			END
		----END
	END

----TK-04937
---- first check to see if the PMOL record added is assigned to a PO and POITEM
---- if so see if an 'O' PMMF record exists that match the key fields. When one is
---- found, then assign PMOL record to that PMMF record and change the type to 'C' in PMMF.
---- then update the POCONum and POCONumSeq in PMOL. You cannot rely on the PCO, PCOItem
---- being assigned in PMMF. If entered directly from POCO, then was not initially setup
---- as from a change order
IF @po IS NOT NULL AND @POSLItem IS NOT NULL
	BEGIN
	----IF @POCONum IS NULL
	----	BEGIN
	----	---- check for one PMMF original record
	----	SET @PMMF_POCONum = NULL
	----	SET @PMMF_POCONumSeq = NULL
	----	SET @PMMF_KeyID = NULL
	----	SELECT TOP 1 @PMMF_POCONum=m.POCONum, @PMMF_POCONumSeq=m.Seq, @PMMF_KeyID=m.KeyID
	----	FROM dbo.bPMMF m WHERE m.PMCo=@pmco AND m.Project=@project AND m.RecordType='O'
	----			AND m.PO=@po AND m.POItem=@POSLItem AND m.Phase=@phase AND m.CostType=@costtype
	----			AND m.PCOItem IS NULL AND m.ACOItem IS NULL AND m.InterfaceDate IS NULL
	----			AND m.MaterialOption = 'P'
	----			----TK-00000 SCO must not be approved
	----			AND NOT EXISTS(SELECT 1 FROM dbo.vPMPOCO h WHERE h.POCo=m.POCo AND h.PO=m.PO AND h.POCONum=m.POCONum AND h.ReadyForAcctg = 'Y')		
				
	----	IF @PMMF_KeyID IS NOT NULL
	----		BEGIN

	----		---- update the one record with PMOL info
	----		UPDATE dbo.bPMMF SET RecordType='C', PCOType=@pcotype, PCO=@pco, PCOItem=@pcoitem,
	----							 ACO=@aco, ACOItem=@acoitem,
	----							 ----TK-06041
	----							 MaterialGroup=@MaterialGroup,
	----							 MaterialCode=@MaterialCode,
	----							  -- TK-06237 --
	----							 UM=ISNULL(@PurchaseUM,@um), 
	----							 Units=ISNULL(@PurchaseUnits,0), 
	----							 UnitCost=ISNULL(@PurchaseUnitCost,0),
	----							 Amount=ISNULL(@PurchaseAmount,0),
	----							 ECM=@ECM
	----		WHERE KeyID = @PMMF_KeyID	

	----		---- update the POCONum and POCONumSeq to the current PMOL record
	----		UPDATE dbo.bPMOL SET POCONum=@PMMF_POCONum, POCONumSeq=@PMMF_POCONumSeq
	----		WHERE KeyID = @KeyID AND POCONum <> @PMMF_POCONum
	----		---- done move to next row
	----		GOTO NEXTROW
	----		END 
	----	END
	----ELSE
	----	BEGIN
		IF @POCONum IS NOT NULL AND @POCONumSeq IS NOT NULL
			BEGIN
			---- validate record really exists in PMMF
			SET @PMMF_KeyID = NULL
			SELECT @PMMF_KeyID = KeyID
			FROM dbo.bPMMF WHERE PMCo=@pmco AND Project=@project
					AND PhaseGroup=@phasegroup AND Phase=@phase
					AND CostType=@costtype AND POCONum=@POCONum
					AND Seq=@POCONumSeq AND InterfaceDate IS NULL
			---- update PMMF
			IF @PMMF_KeyID IS NOT NULL
				BEGIN
				UPDATE dbo.bPMMF
						SET RecordType = 'C',
							PCOType = @pcotype, PCO = @pco,
							PCOItem = @pcoitem, ACO = @aco,
							ACOItem = @acoitem,
							----TK-06041
							MaterialGroup=@MaterialGroup,
							MaterialCode=@MaterialCode,
							-- TK-06237 --
							UM=ISNULL(@PurchaseUM,@um), 
							Units=ISNULL(@PurchaseUnits,0),
							----TK-12995
							UnitCost = CASE WHEN ISNULL(@PurchaseUM,@um) = 'LS' THEN 0 ELSE ISNULL(@PurchaseUnitCost,0) END,
							Amount=ISNULL(@PurchaseAmount,0)
				WHERE KeyID=@PMMF_KeyID	
				END
			
			---- DONE move to next row
			GOTO NEXTROW
			END
		--END
	END

---- if the cost type is not the subcontract cost type
---- or not the material cost type then add records based on PM Company parameters

IF @costtype NOT IN (ISNULL(@slcosttype,0), ISNULL(@mtlcosttype,0))
	BEGIN
   -- execute procedure to add JCCH records based on PM Company parameters
	exec @retcode = dbo.bspPMSubOrMatlChgAdd @pmco, @project, @phasegroup, @phase, @costtype,
						@estunits, @um, @unitcost, @estcost, @pcotype, @pco, @pcoitem, @aco,
						@acoitem, @vendor, NULL, @sl, @POSLItem, @PurchaseAmount, @errmsg output
	END

---- if not the subcontract cost type goto material check
if @costtype <> isnull(@slcosttype,0) goto PMMF_CHECK

---- check if PMSL record exists for phase and cost type
if exists (select 1 from dbo.bPMSL with (nolock) where PMCo=@pmco and Project=@project 
		and isnull(PCOType,'') = isnull(@pcotype,'') and isnull(PCO,'') = isnull(@pco,'') 
		and isnull(PCOItem,'') = isnull(@pcoitem,'') and isnull(ACO,'') = isnull(@aco,'') 
		and isnull(ACOItem,'') = isnull(@acoitem,'') and PhaseGroup=@phasegroup 
		and Phase=@phase and CostType=@costtype)
	BEGIN
	
	goto PMMF_CHECK
	END
else
	BEGIN
	----TK-06041 do we have purchase values to insert?? must be PCO side only
	IF @acoitem IS NULL AND @PurchaseUnits = 0 AND @PurchaseAmount = 0 AND @PurchaseUM IS NULL GOTO PMMF_CHECK

	---- get default retg pct from JCCI to use as a default
	select @dfltwcpct = isnull(i.RetainPCT,0), @PhaseDesc=p.Description
	from dbo.bJCJP p 
	join dbo.bJCCI i on i.JCCo = p.JCCo and i.Contract = p.Contract and i.Item = p.Item
	where p.JCCo=@pmco and p.Job=@project and p.PhaseGroup=@phasegroup and p.Phase=@phase

	---- Set unit cost to the purchase amount price
	IF @estunits <> 0
		BEGIN
		SELECT @unitcost = @estcost/@estunits
		END
	ELSE
		BEGIN
		SET @unitcost = 0
		END

	---- set units and unit cost to zero if UM = 'LS'
	IF @um IS NULL SET @um = 'LS'
	if @um = 'LS'
		begin
		select @estunits = 0, @unitcost = 0
		end

	--TK-06208 - Get Impact Type SL from PCO Header
	select @ImpactSL = SubType from dbo.bPMOP where PMCo = @pmco and Project = @project and PCOType = @pcotype and PCO = @pco

	----TK-06041 do old method if adding phase cost type detail from the ACO item
	IF @acoitem IS NOT NULL
		BEGIN
   		---- #131843 if units = 0, amount <> 0, and @um <> 'LS' then we do not want to add
		if isnull(@estunits,0) = 0 and isnull(@estcost,0) <> 0 and isnull(@um,'LS') <> 'LS'
			begin
			goto PMMF_CHECK
			END
		ELSE
			BEGIN
			insert dbo.bPMSL (PMCo, Project, Seq, RecordType, PCOType, PCO, PCOItem, ACO, ACOItem, PhaseGroup,
					Phase, CostType, SLCo, SLItemType, Units, UM, UnitCost, Amount, SendFlag, WCRetgPct, SMRetgPct)
			select @pmco, @project, isnull(max(bPMSL.Seq),0) + 1, 'C', @pcotype, @pco, @pcoitem, @aco, @acoitem,
					@phasegroup, @phase, @costtype, @apco, 2,
					----TK-06890
					ISNULL(@estunits,0),
					@um,
					ISNULL(@unitcost,0), 
					ISNULL(@estcost,0),
					'Y', @dfltwcpct, @dfltwcpct
			from dbo.bPMSL where PMCo=@pmco and Project=@project
			END
		------ if FROM pco CHECK THE SL Impact flag
		--if @ImpactSL = 'Y'
		--	begin
		--	---- insert PMSL
		--	insert dbo.bPMSL (PMCo, Project, Seq, RecordType, PCOType, PCO, PCOItem, ACO, ACOItem, PhaseGroup,
		--			Phase, CostType, SLCo, SLItemType, Units, UM, UnitCost, Amount, SendFlag, WCRetgPct, SMRetgPct)
		--	select @pmco, @project, isnull(max(bPMSL.Seq),0) + 1, 'C', @pcotype, @pco, @pcoitem, @aco, @acoitem,
		--			@phasegroup, @phase, @costtype, @apco, 2, @estunits, @um, @unitcost, @estcost, 'Y',
		--			@dfltwcpct, @dfltwcpct
		--	from bPMSL where PMCo=@pmco and Project=@project
		--	END
			
		---- done goto to next row
		GOTO PMMF_CHECK
		END
			
	---- #131843 if units = 0, amount <> 0, and @um <> 'LS' then we do not want to add
	if isnull(@PurchaseUnits, 0) = 0 and isnull(@PurchaseAmount, 0) <> 0 and isnull(@PurchaseUM,'LS') <> 'LS'
		begin
		goto PMMF_CHECK
		end
	else if @ImpactSL = 'Y'
		BEGIN
		---- V1# B-02366
		---- first get next sequence
		SELECT @Next_Seq = ISNULL(MAX(Seq),0) + 1 FROM dbo.bPMSL WHERE PMCo=@pmco AND Project=@project
		---- insert PMSL with no sl info
		IF @sl IS NULL OR @POSLItem IS NULL
			BEGIN
			insert dbo.bPMSL (PMCo, Project, Seq, RecordType, PCOType, PCO, PCOItem, ACO, ACOItem,
					PhaseGroup, Phase, CostType, SLCo, SLItemType, Units, UM, UnitCost, Amount,
					SendFlag, WCRetgPct, SMRetgPct, VendorGroup, Vendor, SLItemDescription)
			select @pmco, @project, @Next_Seq, 'C', @pcotype, @pco, @pcoitem, @aco, @acoitem,
					@phasegroup, @phase, @costtype, @apco, 2,
					----TK-06041 TK-06237 --
					ISNULL(@PurchaseUnits,0), 
					ISNULL(@PurchaseUM, 'LS'),
					----TK-12995
					CASE WHEN ISNULL(@PurchaseUM,@um) = 'LS' THEN 0 ELSE ISNULL(@PurchaseUnitCost,0) END, 
					ISNULL(@PurchaseAmount,0),
					'Y', @dfltwcpct, @dfltwcpct, @VendorGroup, @vendor,
					case when isnull(@UsePhaseDesc, 'N') = 'Y' then @PhaseDesc else NULL END
			END
		ELSE
			BEGIN
			---- check for existance in SLIT and join to SLIT for item values
			SET @SLIT_KeyID = NULL
			SELECT @SLIT_KeyID = KeyID
			FROM dbo.bSLIT WHERE SLCo=@apco AND SL=@sl AND SLItem=@POSLItem
			IF @SLIT_KeyID IS NOT NULL
				BEGIN				
				INSERT dbo.bPMSL (PMCo, Project, Seq, RecordType, PCOType, PCO, PCOItem, ACO, ACOItem, PhaseGroup,
						Phase, CostType, SLCo, SLItemType, Units, UM, UnitCost, Amount, SendFlag, WCRetgPct, SMRetgPct,
						VendorGroup, Vendor, SL, SLItem, TaxGroup, TaxType, TaxCode, SLItemDescription)
				SELECT @pmco, @project, @Next_Seq, 'C', @pcotype, @pco, @pcoitem, @aco, @acoitem, @phasegroup,
						@phase, @costtype, @apco, i.ItemType,
						----TK-06041 TK-06890
						ISNULL(@PurchaseUnits,0), i.UM,
						CASE WHEN i.UM = 'LS' THEN 0 ELSE i.CurUnitCost END,
						ISNULL(@PurchaseAmount,0), 'Y', i.WCRetPct, i.SMRetPct,
						@VendorGroup, @vendor, i.SL, i.SLItem, i.TaxGroup, i.TaxType, i.TaxCode,
						case when isnull(@UsePhaseDesc, 'N') = 'Y' then @PhaseDesc else NULL END
				FROM dbo.bSLIT i WHERE i.KeyID = @SLIT_KeyID AND i.ItemType IN (1,2)
				END
			ELSE
				BEGIN
				insert dbo.bPMSL (PMCo, Project, Seq, RecordType, PCOType, PCO, PCOItem, ACO, ACOItem,
						PhaseGroup, Phase, CostType, SLCo, SLItemType, Units, UM, UnitCost, Amount,
						SendFlag, WCRetgPct, SMRetgPct, VendorGroup, Vendor, SL, SLItem, SLItemDescription)
				select @pmco, @project, @Next_Seq, 'C', @pcotype, @pco, @pcoitem, @aco, @acoitem,
						@phasegroup, @phase, @costtype, @apco, 2,
						----TK-06041 -- TK-06237 -- TK-06890
						ISNULL(@PurchaseUnits,0),
						ISNULL(@PurchaseUM, 'LS'),
						----TK-12995
						CASE WHEN ISNULL(@PurchaseUM,@um) = 'LS' THEN 0 ELSE ISNULL(@PurchaseUnitCost,0) END,
						ISNULL(@PurchaseAmount,0),
						'Y', @dfltwcpct, @dfltwcpct, @VendorGroup, @vendor, @sl, @POSLItem,
						case when isnull(@UsePhaseDesc, 'N') = 'Y' then @PhaseDesc else NULL END
				END
			END
		END
	END


---- purchase order and material cost type
PMMF_CHECK:

---- done if not material cost type #140152
if @costtype <> isnull(@mtlcosttype,0) goto NEXTROW

---- check if PMMF record exists for phase and cost type
if exists (select 1 from dbo.bPMMF with (nolock) where PMCo=@pmco and Project=@project 
		and isnull(PCOType,'') = isnull(@pcotype,'') and isnull(PCO,'') = isnull(@pco,'') 
		and isnull(PCOItem,'') = isnull(@pcoitem,'') and isnull(ACO,'') = isnull(@aco,'') 
		and isnull(ACOItem,'') = isnull(@acoitem,'') and PhaseGroup=@phasegroup 
		and Phase=@phase and CostType=@costtype)
	BEGIN
	goto NEXTROW
	END
else
	BEGIN
	
	----TK-06041 do we have purchase values to insert?? must be PCO side only
	IF @acoitem IS NULL AND @PurchaseUnits = 0 AND @PurchaseAmount = 0 AND @PurchaseUM IS NULL AND @MaterialCode IS NULL GOTO NEXTROW
	
	---- get default retg pct from JCCI to use as a default
	select @dfltwcpct = isnull(i.RetainPCT,0)
	from dbo.bJCJP p with (nolock)
	join dbo.bJCCI i with (nolock) on i.JCCo = p.JCCo and i.Contract = p.Contract and i.Item = p.Item
	where p.JCCo=@pmco and p.Job=@project and p.PhaseGroup=@phasegroup and p.Phase=@phase
	
	---- Set unit cost to the purchase amount price
	IF @estunits <> 0
		BEGIN
		SELECT @unitcost = @estcost/@estunits
		END
	ELSE
		BEGIN
		SET @unitcost = 0
		END

	---- set units and unit cost to zero if UM = 'LS'
	IF @um IS NULL SET @um = 'LS'
	if @um = 'LS'
		BEGIN
		select @estunits = 0, @unitcost = 0
		END
	
	--TK-06208 - Get Impact Type SL from PCO Header
	select @ImpactPO = POType from dbo.bPMOP where PMCo = @pmco and Project = @project and PCOType = @pcotype and PCO = @pco	
	
	---- #131843 if units = 0, amount <> 0, and @um <> 'LS' then we do not want to add
	----TK-06041 do old method if adding phase cost type detail from the ACO item
	IF @acoitem IS NOT NULL
		BEGIN
		---- #131843 if units = 0, amount <> 0, and @um <> 'LS' then we do not want to add
		if isnull(@estunits,0) = 0 and isnull(@estcost,0) <> 0 and isnull(@um,'LS') <> 'LS'
			begin
			goto NEXTROW
			end
		else ----if @ImpactPO = 'Y'
			begin
			insert into dbo.bPMMF(PMCo, Project, Seq, RecordType, PCOType, PCO, PCOItem, ACO, ACOItem, PhaseGroup,
					Phase, CostType, VendorGroup, MaterialOption, POCo, RecvYN, UM, Units, UnitCost,
					ECM, Amount, SendFlag, MaterialGroup)
			select @pmco, @project, isnull(max(bPMMF.Seq),0) + 1, 'C', @pcotype, @pco, @pcoitem, @aco, @acoitem, @phasegroup,
					@phase, @costtype, @VendorGroup, 'P', @apco, 'N',
					@um,
					ISNULL(@estunits,0),
					CASE WHEN @um = 'LS' THEN 0 ELSE ISNULL(@unitcost,0) END, 
					'E', ISNULL(@estcost,0), 'Y', @MaterialGroup
			from dbo.bPMMF where PMCo=@pmco and Project=@project
			end
		
		---- done goto to next row
		GOTO NEXTROW
		END
				
	---- adding from the PCO item we need to use the new purchase columns in PMOL to create PMMF
	if isnull(@PurchaseUnits, 0) = 0 and isnull(@PurchaseAmount, 0) <> 0 and isnull(@PurchaseUM,'LS') <> 'LS'
		BEGIN
		goto NEXTROW
		END
	else if @ImpactPO = 'Y'
		BEGIN
		---- first get next sequence
		SELECT @Next_Seq = ISNULL(MAX(Seq),0) + 1 FROM dbo.bPMMF WHERE PMCo=@pmco AND Project=@project
		---- insert PMMF with no PO info
		IF @po IS NULL OR @POSLItem IS NULL
			BEGIN
			insert into dbo.bPMMF(PMCo, Project, Seq, RecordType, PCOType, PCO, PCOItem, ACO, ACOItem,
					PhaseGroup, Phase, CostType, VendorGroup, MaterialOption, POCo, RecvYN, UM,
					Units, UnitCost, ECM, Amount, MaterialGroup, MaterialCode, SendFlag,
					Vendor, MtlDescription)
			select @pmco, @project, @Next_Seq, 'C', @pcotype, @pco, @pcoitem,
					@aco, @acoitem, @phasegroup, @phase, @costtype, @VendorGroup, 'P', @apco, 'N',
					----TK-06041 -- TK-06237 --
					ISNULL(@PurchaseUM, 'LS'), -- TK-06237 --
					ISNULL(@PurchaseUnits,0),
					CASE WHEN ISNULL(@PurchaseUM, 'LS') = 'LS' THEN 0 ELSE ISNULL(@PurchaseUnitCost,0) END,
					@ecm,
					ISNULL(@PurchaseAmount,0), @MaterialGroup, @MaterialCode, 'Y', @vendor,
					case when @UseMatlPhaseDesc = 'Y' then @PhaseDesc else null END
			END
		ELSE
			BEGIN
			---- check for existance in POIT and join to POIT for item values
			SET @POIT_KeyID = NULL
			SELECT @POIT_KeyID = KeyID
			FROM dbo.bPOIT WHERE POCo=@apco AND PO=@po AND POItem=@POSLItem
			IF @POIT_KeyID IS NOT NULL
				BEGIN
				INSERT INTO dbo.bPMMF(PMCo, Project, Seq, RecordType, PCOType, PCO, PCOItem, ACO, ACOItem,
						PhaseGroup, Phase, CostType, VendorGroup, MaterialOption, POCo, UM, Units,
						UnitCost, ECM, Amount, SendFlag, Vendor, PO, POItem,
						RecvYN, MaterialCode, MaterialGroup, MtlDescription, TaxGroup, TaxType, TaxCode)
				SELECT @pmco, @project, @Next_Seq, 'C', @pcotype, @pco, @pcoitem, @aco, @acoitem,
						@phasegroup, @phase, @costtype, @VendorGroup, 'P', @apco, i.UM,
						----TK-06041
						ISNULL(@PurchaseUnits,0), i.CurUnitCost, i.CurECM, ISNULL(@PurchaseAmount,0), 'Y',
						@vendor, @po, @POSLItem,
						i.RecvYN, i.Material, i.MatlGroup, i.Description, i.TaxGroup, i.TaxType, i.TaxCode
				from dbo.bPOIT i WHERE i.KeyID = @POIT_KeyID
				END
			ELSE
				BEGIN
				insert into dbo.bPMMF(PMCo, Project, Seq, RecordType, PCOType, PCO, PCOItem, ACO, ACOItem,
						PhaseGroup, Phase, CostType, VendorGroup, MaterialOption, POCo, RecvYN, UM,
						Units, UnitCost, ECM, Amount, MaterialGroup, MaterialCode, SendFlag, 
						Vendor, PO, POItem, MtlDescription)
				select @pmco, @project, @Next_Seq, 'C', @pcotype, @pco, @pcoitem,
						@aco, @acoitem, @phasegroup, @phase, @costtype, @VendorGroup, 'P', @apco, 'N',
						----TK-06041 -- TK-06237 --
						ISNULL(@PurchaseUM, 'LS'), -- TK-06237 --
						ISNULL(@PurchaseUnits,0),
						CASE WHEN ISNULL(@PurchaseUM, 'LS') = 'LS' THEN 0 ELSE ISNULL(@PurchaseUnitCost,0) END,
						@ecm, 
						ISNULL(@PurchaseAmount,0),
						@MaterialGroup, @MaterialCode, 'Y', @vendor, 
						@po, @POSLItem,
						case when @UseMatlPhaseDesc = 'Y' then @PhaseDesc else null END
				END
			END
		END
	END
----TK-04937

	-- TK-06210 - commented out --
   --fetch next from bPMOL_insert into @pmco, @project, @pcotype, @pco, @pcoitem, @aco, @acoitem, 
			--	@phasegroup, @phase, @costtype, @estunits, @um, @esthours, @unitcost, @ecm, @estcost,
			--	----TK-04971
			--	@VendorGroup, @vendor, @po, @sl, @POSLItem, @PurchaseAmount, @SubCO, @SubCOSeq,
			--	@POCONum, @POCONumSeq, @KeyID,
			--	---- TK-06041
			--	@MaterialCode, @PurchaseUnits, @PurchaseUM, @PurchaseUnitCost, @ECM


NEXTROW:

	if @numrows > 1
	   begin
	   fetch next from bPMOL_insert into @pmco, @project, @pcotype, @pco, @pcoitem, @aco, @acoitem, 
				@phasegroup, @phase, @costtype, @estunits, @um, @esthours, @unitcost, @ecm, @estcost,
				----TK-04971
				@VendorGroup, @vendor, @po, @sl, @POSLItem, @PurchaseAmount, @SubCO, @SubCOSeq,
				@POCONum, @POCONumSeq, @KeyID,
				---- TK-06041 & TK-06237 --
				@MaterialCode, @PurchaseUnits, @PurchaseUM, @PurchaseUnitCost
	   if @@fetch_status = 0 
		goto insert_check
	else
		begin
		close bPMOL_insert
		deallocate bPMOL_insert
		set @opencursor = 0
		end
	end


---- update the ready for accounting flag to 'Y' in PMOH
---- when detail added to an ACO and the Send flag is 'Y'
---- and the ACO ready for accounting flag is 'N' TK-05347
---- GF 11/23/2011 TK-10530 CI#145135
UPDATE dbo.bPMOH SET ReadyForAcctg = 'Y'
FROM inserted i
INNER JOIN dbo.bPMOH h ON h.PMCo=i.PMCo AND h.Project=i.Project AND h.ACO=i.ACO
WHERE i.ACO IS NOT NULL AND h.ReadyForAcctg = 'N' AND i.SendYN = 'Y'




return
   
    --------------------
	-- ERROR HANDLING --
	-------------------- 
   error:

   	if @opencursor = 1
   	    begin
   	    close bPMOL_insert
   	    deallocate bPMOL_insert
   		set @opencursor = 0
   	    end
   
   	select @errmsg = isnull(@errmsg,'') + ' - cannot insert into PMOL!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction


GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






/****** Object:  Trigger dbo.btPMOLu    Script Date: 8/28/99 9:37:57 AM ******/
CREATE trigger [dbo].[btPMOLu] on [dbo].[bPMOL] for UPDATE as
/*--------------------------------------------------------------
* Update trigger for PMOL
* Modified By:	GF 06/29/2011 TK-06482 d-02349
*				DAN SO 07/07/2011 - TK-06553 - Added PCOType and PCO to some update statements
*				GP 07/08/2011 - TK-06688 - Added check before nulling out POCONum or SubCOSeq to remove link from PCO, 
*								also added link back when re-added to form
*				GP 7/27/2011 - TK-07144 changed bPO to varchar(30)
*				GF 11/23/2011 - TK-10530 CI#145133
*				GF 02/12/2012 TK-12469 PMOL purchase values may be zero - not allowed in PMSL or PMMF
*				GF 02/12/2012 TK-12381 #145741 get SL Item information for update to PMSL when SL and Item assigned
*				gf 02/20/2012 TK-12469 #145650 when assigning subco or poconum do not update purchase values in PMSL or PMMF
*				GF 03/06/2012 TK-12996 #146016 Sync changes between PCO Item detail and SubCO
*				GF 03/09/2012 TK-13116 #146042 problems with the old vs new values check for update to PMSL/PMMF
*				JayR 03/24/2012 TK-00000 Convert part of this to using constraints
*				GF 06/20/2112 TK-15946 cleanup
*
* Does some standard validation first. Then creates a cursor
* to update PCO information.
*
* 1. check PCO Item markups and add-ons, then calculates pending amount for PMOI.
* 2. we want to sync PMSL record to the changes made in PMOL for purchase info if we can.
* 3. we want to sync PMMF record to the changes made in PMOL for purchase info if we can.
* 
*--------------------------------------------------------------*/
declare @numrows int, @errmsg varchar(255), @rcode int, @opencursor tinyint,
		@validcnt INT, @validcnt2 INT,
   		@PMCo bCompany, @Project bJob, @PCOType bDocType, @PCO bPCO, @PCOItem bPCOItem,
   		@Phase bPhase, @CostType bJCCType, @units bUnits, @um bUM, @unitcost bUnitCost,
   		@amount bDollar, @sendYN bYN, @aco bPCO, @acoitem bPCOItem, @apco bCompany,
   		---- B-02356 TK-04937 TK-04830 TK-04971
   		@VendorGroup bGroup, @Vendor bVendor, @PO varchar(30), @Subcontract VARCHAR(30),
   		@ECM CHAR(1), @PurchaseAmt bDollar, @SubCO smallint, @SubCOSeq INT, @POSLItem bItem,
		@SLItemType TINYINT, @MatlCode bMatl, @POCONum SMALLINT, @POCONumSeq INT,
		@PMMF_POCONum SMALLINT, @PMMF_POCONumSeq INT, @KeyID BIGINT, @PMMF_KeyID BIGINT,
		@POIT_KeyID BIGINT, @Next_Seq INT, @DfltVendorGroup bGroup, @PhaseGroup bGroup,
		---- TK-06122 TK-06482
		@SLType CHAR(1), @POType CHAR(1), @OldPurchaseAmt bDollar, @OldMaterialCode bMatl,
		@OldPurchaseUnits bUnits, @OldPurchaseUM bUM, @OldPurchaseUnitCost bUnitCost,
		@OldPO varchar(30), @OldSubcontract VARCHAR(30), @OldVendor bVendor, @OldPOSLItem bItem,
		@OldSubCO SMALLINT, @OldSubCOSeq INT, @OldPOCONum SMALLINT, @OldPOCONumSeq INT,
		@OldECM CHAR(1), @MaterialCode bMatl, @PurchaseUnits bUnits, @PurchaseUM bUM,
		@PurchaseUnitCost bUnitCost, @PMSLSeq INT, @PMMFSeq INT,
		---- TK-12381
		@WCRetPct bPct, @SMRetPct bPct, @TaxGroup bGroup, @TaxType TINYINT,
		@TaxCode bTaxCode
   		
SET @numrows = @@rowcount
if @numrows = 0 return
set nocount on
   
SET @opencursor = 0
   
---- check for change to primary key
if UPDATE(PMCo)
	begin
	select @errmsg = 'Company is not allowed to be updated'
	goto error
	end

if UPDATE(Project)
	begin
	select @errmsg = 'Company is not allowed to be updated'
	goto error
	end

if UPDATE(PhaseGroup)
	begin
	select @errmsg = 'Phase Group is not allowed to be updated'
	goto error
	end

if UPDATE(Phase)
	begin
	select @errmsg = 'Phase is not allowed to be updated'
	goto error
	end

if UPDATE(CostType)
	begin
	select @errmsg = 'Cost Type is not allowed to be updated'
	goto error
	end

---- JG 06/28/2011 - Rem'd outline
---- skip if updating ECM - project copy, imports
--if UPDATE(ECM) return
	
	
---- if assigned to a SL the VendorGroup/Vendor must match SL
SELECT @validcnt = COUNT(*) FROM inserted i
JOIN dbo.bPMCO c ON c.PMCo=i.PMCo
JOIN dbo.bSLHD h ON h.SLCo=c.APCo AND h.SL=i.Subcontract AND h.VendorGroup=i.VendorGroup AND h.Vendor=i.Vendor
SELECT @validcnt2 = COUNT(*) FROM inserted i WHERE i.Subcontract IS NULL
if @validcnt + @validcnt2 <> @numrows
	BEGIN
	SELECT @errmsg = 'Vendor is Invalid for Subcontract'
	goto error
	END

---- if assigned to a PO the VendorGroup/Vendor must match PO
SELECT @validcnt = COUNT(*) FROM inserted i
JOIN dbo.bPMCO c ON c.PMCo=i.PMCo
JOIN dbo.bPOHD h ON h.POCo=c.APCo AND h.PO=i.PO AND h.VendorGroup=i.VendorGroup AND h.Vendor=i.Vendor
SELECT @validcnt2 = COUNT(*) FROM inserted i WHERE i.PO IS NULL
if @validcnt + @validcnt2 <> @numrows
	BEGIN
	SELECT @errmsg = 'Vendor is Invalid for Purchase Order'
	goto error
	END




---- declare cursor on insert for updates to PMSL, PMMF, markups, and addons.
if @numrows = 1
	BEGIN
	SELECT @PMCo=i.PMCo, @Project=i.Project, @PCOType=i.PCOType, @PCO=i.PCO, @PCOItem=i.PCOItem,
		   @aco=i.ACO, @acoitem=i.ACOItem, @PhaseGroup=i.PhaseGroup, @Phase=i.Phase,
		   @CostType=i.CostType, @units=i.EstUnits, @um=i.UM, @unitcost=i.UnitCost, 
		   @amount=i.EstCost, @sendYN=i.SendYN, @ECM=i.ECM,
		   ----TK-04971 TK-06122 TK-06482
		   @VendorGroup=i.VendorGroup, @Vendor=i.Vendor, @PO=i.PO, @Subcontract=i.Subcontract,
		   @POSLItem=i.POSLItem, @PurchaseAmt=i.PurchaseAmt, @SubCO=i.SubCO,
		   @SubCOSeq=i.SubCOSeq, @POCONum=i.POCONum, @POCONumSeq=i.POCONumSeq, @KeyID=i.KeyID,
		   @PurchaseUM=i.PurchaseUM, @PurchaseUnitCost=i.PurchaseUnitCost,
		   @PurchaseUnits=i.PurchaseUnits, @MaterialCode=i.MaterialCode,
		   ----OLD
		   @OldPurchaseAmt=d.PurchaseAmt, @OldMaterialCode=d.MaterialCode,
		   @OldPurchaseUnits=d.PurchaseUnits, @OldPurchaseUM=d.PurchaseUM,
		   @OldPurchaseUnitCost=d.PurchaseUnitCost, @OldPO=d.PO, @OldSubcontract=d.Subcontract,
		   @OldVendor=d.Vendor, @OldPOSLItem=d.POSLItem, @OldSubCO=d.SubCO, @OldSubCOSeq=d.SubCOSeq,
		   @OldPOCONum=d.POCONum, @OldPOCONumSeq=d.POCONumSeq, @OldECM=d.ECM

	FROM inserted i
	INNER JOIN deleted d on i.KeyID=d.KeyID
	END
ELSE
	BEGIN
	---- use a cursor to process each updated row
	DECLARE bPMOL_insert cursor LOCAL FAST_FORWARD
		FOR SELECT i.PMCo, i.Project, i.PCOType, i.PCO, i.PCOItem, i.ACO, i.ACOItem,
				   i.PhaseGroup, i.Phase, i.CostType, i.EstUnits, i.UM, i.UnitCost,
				   i.EstCost, i.SendYN, i.ECM,
				   ----TK-04971 TK-06122 TK-06482
				   i.VendorGroup, i.Vendor, i.PO, i.Subcontract, i.POSLItem, i.PurchaseAmt,
				   i.SubCO, i.SubCOSeq, i.POCONum, i.POCONumSeq, i.KeyID,
				   i.PurchaseUM, i.PurchaseUnitCost, i.PurchaseUnits, i.MaterialCode,
				   ----OLD
				   d.PurchaseAmt, d.MaterialCode, d.PurchaseUnits, d.PurchaseUM,
				   d.PurchaseUnitCost, d.PO, d.Subcontract, d.Vendor, d.POSLItem,
				   d.SubCO, d.SubCOSeq, d.POCONum, d.POCONumSeq, d.ECM
	FROM inserted i
	INNER JOIN deleted d on i.KeyID=d.KeyID

	---- open cursor
   	OPEN bPMOL_insert
   	SET @opencursor = 1
   	
   	FETCH NEXT FROM bPMOL_insert INTO @PMCo, @Project, @PCOType, @PCO, @PCOItem, @aco, @acoitem,
   				@PhaseGroup, @Phase, @CostType, @units, @um, @unitcost,
   				@amount, @sendYN, @ECM,
   				----TK-04971 TK-06122 TK-06482
				@VendorGroup, @Vendor, @PO, @Subcontract, @POSLItem, @PurchaseAmt,
				@SubCO, @SubCOSeq, @POCONum, @POCONumSeq, @KeyID,
				@PurchaseUM, @PurchaseUnitCost, @PurchaseUnits, @MaterialCode,
				----OLD
			    @OldPurchaseAmt, @OldMaterialCode, @OldPurchaseUnits, @OldPurchaseUM,
			    @OldPurchaseUnitCost, @OldPO, @OldSubcontract, @OldVendor, @OldPOSLItem,
			    @OldSubCO, @OldSubCOSeq, @OldPOCONum, @OldPOCONumSeq, @OldECM
				
   	if @@fetch_status <> 0
   		BEGIN
   		select @errmsg = 'Cursor error'
   		goto error
   		END
   	END



---- process detail row
bPMOL_insert:

---- we only care about PCO side of the line detail, skip if just ACO
IF ISNULL(@PCO,'') = '' GOTO NEXT_ROW

---- from copy or import skip
IF @OldECM = 'C' AND @ECM = 'E' GOTO NEXT_ROW

---- get PM and HQ company information
SELECT @apco=p.APCo, @DfltVendorGroup=h.VendorGroup
FROM dbo.bPMCO p
INNER JOIN dbo.bHQCO h on h.HQCo = p.PMCo
WHERE PMCo=@PMCo

---- if the PCO item exists we need to insert markups and calculate add-ons.
if ISNULL(@PCOItem,'') <> ''
	BEGIN
   	---- Validate PMOI
   	IF NOT EXISTS(SELECT TOP 1 1 FROM dbo.bPMOI WHERE PMCo=@PMCo and Project=@Project 
   					and PCOType=@PCOType and PCO=@PCO and PCOItem=@PCOItem)
		BEGIN
		SELECT @errmsg = 'Change order item ' + ISNULL(RTRIM(@PCOItem),'') + ' not found'
		GOTO error
		END
   
	---- insert markups
	insert into dbo.bPMOM(PMCo,Project,PCOType,PCO,PCOItem,PhaseGroup,CostType,IntMarkUp,ConMarkUp)
	select distinct PMOL.PMCo, PMOL.Project, PMOL.PCOType, PMOL.PCO, PMOL.PCOItem,
			PMOL.PhaseGroup, PMOL.CostType, 0,
			case when isnull(h.IntExt,'E') = 'E' then isnull(PMPC.Markup,0)
				 when isnull(t.InitAddons,'Y') = 'Y' then IsNull(PMPC.Markup,0)
				 else 0 end
	from dbo.bPMOL PMOL with (nolock)
	----#132046
	join dbo.bPMOP h with (nolock) on h.PMCo=@PMCo and h.Project=@Project and h.PCOType=@PCOType and h.PCO=@PCO
	join dbo.bPMDT t with (nolock) on t.DocType=h.PCOType
	left join dbo.bPMOM PMOM on PMOM.PMCo=PMOL.PMCo and PMOM.Project=PMOL.Project
	and PMOM.PCOType=PMOL.PCOType and PMOM.PCO=PMOL.PCO and PMOM.PCOItem=PMOL.PCOItem
	and PMOM.PhaseGroup=PMOL.PhaseGroup and PMOM.CostType=PMOL.CostType
	left join bPMPC PMPC on PMPC.PMCo=PMOL.PMCo and PMPC.Project=PMOL.Project
	and PMPC.PhaseGroup=PMOL.PhaseGroup and PMPC.CostType=PMOL.CostType
	where PMOL.PMCo=@PMCo and PMOL.Project=@Project and PMOL.PCOType=@PCOType and PMOL.PCO=@PCO
	and PMOM.PMCo is null

   	---- calculate pending amount
   	exec @rcode = dbo.vspPMOACalcs @PMCo, @Project, @PCOType, @PCO, @PCOItem
	END


---- from this point on we are only managing PMOL purchase values
---- and syncing the PM Subcontract Detail (PMSL) OR PM Material Detail (PMMF)
---- in sync. If no of the relevant columns have been changed then we
---- can skip this section and move to the next row in the cursor.

---- first check for changes between old and new values for purchase columns
----TK-13116
IF ISNULL(@ECM,'') = ISNULL(@OldECM,'')
	AND ISNULL(@PO,'') = ISNULL(@OldPO,'')
	AND ISNULL(@Subcontract,'') = ISNULL(@OldSubcontract,'')
	AND ISNULL(@Vendor,0) = ISNULL(@OldVendor,0)
	AND ISNULL(@POSLItem,0) = ISNULL(@OldPOSLItem,0)
	AND ISNULL(@SubCO,0) = ISNULL(@OldSubCO,0)
	AND ISNULL(@SubCOSeq,0) = ISNULL(@OldSubCOSeq,0)
	AND ISNULL(@POCONum,0) = ISNULL(@OldPOCONum,0)
	AND ISNULL(@POCONumSeq,0) = ISNULL(@OldPOCONumSeq,0)
	AND ISNULL(@MaterialCode,'') = ISNULL(@OldMaterialCode,'')
	AND ISNULL(@PurchaseAmt,0) = ISNULL(@OldPurchaseAmt,0)
	AND ISNULL(@PurchaseUnits,0) = ISNULL(@OldPurchaseUnits,0)
	AND ISNULL(@PurchaseUM,'') = ISNULL(@OldPurchaseUM,'')
	AND ISNULL(@PurchaseUnitCost,0) = ISNULL(@OldPurchaseUnitCost,0)
	BEGIN
	GOTO NEXT_ROW
	END
	
---- something has change that we need to update to PMSL/PMMF
---- get the impact types for the PCO. NO UPDATES IF NO IMPACT
SELECT @SLType=SubType, @POType=POType
FROM dbo.bPMOP
WHERE PMCo=@PMCo 
	AND Project=@Project 
	AND PCOType=@PCOType
	AND PCO=@PCO

---- skip if no impact
IF ISNULL(@SLType,'N') = 'N' AND ISNULL(@POType,'N') = 'N' GOTO NEXT_ROW

---- PMSL UPDATE
---- PM Subcontract Detail sync (PMSL)
IF ISNULL(@SLType,'N') = 'N' GOTO PMMF_UPDATE


---- now lets update the PMSL record not assigned to a
---- SubCO if we can find one. We want to update the
---- minimum sequence found in PMSL. Possible more than
---- one record exists in PMSL that matches the criteria
---- but we only want to update one.
---- Must be type 'C' change order and not interfaced
SET @PMSLSeq = NULL
SELECT @PMSLSeq = MIN(Seq)
FROM dbo.bPMSL 
WHERE PMCo = @PMCo
	AND Project		= @Project
	AND PCOType		= @PCOType
	AND PCO			= @PCO
	AND PCOItem		= @PCOItem
	AND Phase		= @Phase
	AND CostType	= @CostType
	AND RecordType	= 'C'
	AND InterfaceDate IS NULL
	AND ISNULL(Vendor,'')	= ISNULL(@OldVendor,'')
	AND ISNULL(SL,'')		= ISNULL(@OldSubcontract,'') 
	AND ISNULL(SLItem,'')	= ISNULL(@OldPOSLItem,'')

---- no match found
IF @@ROWCOUNT = 0 GOTO PMMF_UPDATE

---- do we have a sequence SKIP IF NO
IF @PMSLSeq IS NULL GOTO PMMF_UPDATE

---- TK-12381 get SL Item information
SET @SLItemType = 2
SET @WCRetPct = 0
SET @SMRetPct = 0
SET @TaxGroup = NULL
SET @TaxType = NULL
SET @TaxCode = NULL

---- get PMSL data first
SELECT @SLItemType = PMSL.SLItemType, @WCRetPct = PMSL.WCRetgPct,
		@SMRetPct = PMSL.SMRetgPct, @TaxGroup = PMSL.TaxGroup,
		@TaxType = PMSL.TaxType, @TaxCode = PMSL.TaxCode
FROM dbo.bPMSL PMSL
WHERE PMCo = @PMCo
	AND Project = @Project
	AND Seq		= @PMSLSeq

---- get SLIT data second
IF @Subcontract IS NOT NULL AND @POSLItem IS NOT NULL 
	AND EXISTS(SELECT 1 FROM dbo.bSLIT WHERE SLCo=@apco AND SL = @Subcontract AND SLItem = @POSLItem)
	BEGIN
	SELECT @SLItemType = SLIT.ItemType, @WCRetPct = SLIT.WCRetPct,
			@SMRetPct = SLIT.SMRetPct, @TaxGroup = SLIT.TaxGroup,
			@TaxType = SLIT.TaxType, @TaxCode = SLIT.TaxCode
	FROM dbo.bSLIT SLIT
	WHERE SLIT.SLCo=@apco
		AND SLIT.SL = @Subcontract
		AND SLIT.SLItem = @POSLItem
	END
ELSE
	BEGIN
	---- if not in SLIT, but the SL or SL Item has changed, may be a new item 
	---- and we need to set type item type 2-Change Order
	IF @Subcontract IS NOT NULL AND @POSLItem IS NOT NULL 
		AND NOT EXISTS(SELECT 1 FROM dbo.bPMSL WHERE SLCo=@apco AND SL = @Subcontract AND SLItem = @POSLItem)
		BEGIN
		SET @SLItemType = 2
		END
	END
	
---- set update for PMSL when the PMOL record changes and we have a PMSL sequence
UPDATE dbo.bPMSL
		SET  Vendor		= @Vendor, 
			 SL			= @Subcontract, 
			 SLItem		= @POSLItem,
			 ----TK-12381
			 SLItemType = ISNULL(@SLItemType,2),
			 WCRetgPct  = ISNULL(@WCRetPct,0),
			 SMRetgPct  = ISNULL(@SMRetPct,0),
			 TaxGroup   = @TaxGroup,
			 TaxType    = @TaxType,
			 TaxCode	= @TaxCode,
			 ----TK-12469
			 UM			= ISNULL(@PurchaseUM, bPMSL.UM),
			 Units		= ISNULL(@PurchaseUnits ,bPMSL.Units),
			 UnitCost	= ISNULL(@PurchaseUnitCost, bPMSL.UnitCost),
			 Amount		= ISNULL(@PurchaseAmt, bPMSL.Amount),
			 SubCO		= @SubCO
WHERE PMCo = @PMCo
	AND Project = @Project
	AND Seq		= @PMSLSeq
	AND InterfaceDate IS NULL
	
---- DONE WITH PMSL UPDATE FOR NOW
GOTO NEXT_ROW


----------------------
---- PMMF SIDE
----------------------
PMMF_UPDATE:
---- PM Material Detail sync (PMMF)
IF ISNULL(@POType,'N') = 'N' GOTO NEXT_ROW

---- This was implemented to fix a problem in the 
---- PCO Item Detail update to the POCONum field.
---- If we null out the POCONum then PM PO Change Order Detail 
---- form will no longer see the record (they share the bPMMF table).
---- Instead we want to unassign the POCO record from the PCO by
---- nulling out those values. TK-06688
IF ISNULL(@PO,'') <> '' AND ISNULL(@POCONumSeq,'') = '' AND (ISNULL(@POCONumSeq,'') <> ISNULL(@OldPOCONumSeq,''))
BEGIN
	UPDATE dbo.bPMMF
	SET PCOType = NULL, PCO = NULL, PCOItem = NULL, RecordType = 'O'
	WHERE PMCo = @PMCo AND Project = @Project 
		AND PCOType = @PCOType AND PCO = @PCO 
		AND PCOItem = @PCOItem AND PhaseGroup = @PhaseGroup 
		AND Phase = @Phase AND CostType = @CostType
		AND InterfaceDate IS NULL
END

---- first lets see if we need to null out the POCONum
---- in PMMF from the PMOL. This would occur if the @OldPOCONumSeq
---- has changed from the @POCONumSeq. 
IF ISNULL(@OldPOCONumSeq,'') <> ISNULL(@POCONumSeq,'')
	BEGIN
	IF ISNULL(@OldPOCONumSeq,'') <> ''
		BEGIN	
		UPDATE dbo.bPMMF SET POCONum = NULL
		WHERE PMCo=@PMCo
			AND Project=@Project
			AND Seq = @OldPOCONumSeq
			-- TK-06553 --
			AND POCONum = @OldPOCONum
			AND PCOType=@PCOType
			AND PCO=@PCO
			AND InterfaceDate IS NULL
		END
	END

---- if we have a POCONum and POCONumSeq then we can update
---- the PMMF record directly using these values
IF @POCONum IS NOT NULL AND @POCONumSeq IS NOT NULL
	BEGIN
	UPDATE dbo.bPMMF
		SET  Vendor			= @Vendor,
			 PO				= @PO, 
			 POItem			= @POSLItem,
			 ----TK-12469
			 --UM				= ISNULL(@PurchaseUM, bPMMF.UM),
			 --Units			= ISNULL(@PurchaseUnits ,bPMMF.Units),
			 --UnitCost		= ISNULL(@PurchaseUnitCost, bPMMF.UnitCost),
			 --Amount			= ISNULL(@PurchaseAmt, bPMMF.Amount),
			 --ECM			= ISNULL(@ECM,'E'),
			 --MaterialCode	= isnull(@MaterialCode, bPMMF.MaterialCode),
			 POCONum		= @POCONum,
			 PCOType		= @PCOType,		-- added update for PCOType, PCO, and PCOItem
			 PCO			= @PCO,			-- due to nulling them above when SubCO is removed. TK-06688
			 PCOItem		= @PCOItem
	WHERE PMCo = @PMCo 
		AND Project=@Project
		AND Seq=@POCONumSeq
		AND InterfaceDate IS NULL
		
	---- WE ARE DONE MOVE TO NEXT
	GOTO NEXT_ROW
	END


---- now lets update the PMMF record not assigned to a
---- POCONum if we can find one. We want to update the
---- minimum sequence found in PMMF. Possible more than
---- one record exists in PMMF that matches the criteria
---- but we only want to update one.
---- Must be type 'C' change order and not interfaced
SET @PMMFSeq = NULL
SELECT @PMMFSeq = MIN(Seq)
FROM dbo.bPMMF 
WHERE PMCo = @PMCo
	AND Project			= @Project
	AND PCOType			= @PCOType
	AND PCO				= @PCO
	AND PCOItem			= @PCOItem
	AND Phase			= @Phase
	AND CostType		= @CostType
	AND RecordType		= 'C'
	AND MaterialOption	= 'P'
	AND InterfaceDate IS NULL
	AND ISNULL(Vendor,'')	= ISNULL(@OldVendor,'')
	AND ISNULL(PO,'')		= ISNULL(@OldPO,'') 
	AND ISNULL(POItem,'')	= ISNULL(@OldPOSLItem,'')
	
---- no match found
IF @@ROWCOUNT = 0 GOTO NEXT_ROW

---- do we have a sequence SKIP IF NO
IF @PMMFSeq IS NULL GOTO NEXT_ROW


---- set update for PMMF when the PMOL record changes and we have a PMMF sequence
UPDATE dbo.bPMMF
		SET  Vendor			= @Vendor, 
			 PO				= @PO, 
			 POItem			= @POSLItem,
			 ----TK-12469
			 UM				= ISNULL(@PurchaseUM, bPMMF.UM),
			 Units			= ISNULL(@PurchaseUnits ,bPMMF.Units),
			 UnitCost		= ISNULL(@PurchaseUnitCost, bPMMF.UnitCost),
			 Amount			= ISNULL(@PurchaseAmt, bPMMF.Amount),
			 ECM			= ISNULL(@ECM,'E'),
			 MaterialCode	= isnull(@MaterialCode, bPMMF.MaterialCode),
			 POCONum		= @POCONum
WHERE PMCo = @PMCo
	AND Project = @Project
	AND Seq		= @PMMFSeq
	AND InterfaceDate IS NULL
	
---- DONE WITH PMSL UPDATE FOR NOW
GOTO NEXT_ROW



 
------------------------
---- NEXT ROW IN CURSOR
------------------------
NEXT_ROW:
if @numrows > 1
	BEGIN	    
   	FETCH NEXT FROM bPMOL_insert INTO @PMCo, @Project, @PCOType, @PCO, @PCOItem, @aco, @acoitem,
   				@PhaseGroup, @Phase, @CostType, @units, @um, @unitcost,
   				@amount, @sendYN, @ECM,
   				----TK-04971 TK-06122 TK-06482
				@VendorGroup, @Vendor, @PO, @Subcontract, @POSLItem, @PurchaseAmt,
				@SubCO, @SubCOSeq, @POCONum, @POCONumSeq, @KeyID,
				@PurchaseUM, @PurchaseUnitCost, @PurchaseUnits, @MaterialCode,
				----OLD
			    @OldPurchaseAmt, @OldMaterialCode, @OldPurchaseUnits, @OldPurchaseUM,
			    @OldPurchaseUnitCost, @OldPO, @OldSubcontract, @OldVendor, @OldPOSLItem,
			    @OldSubCO, @OldSubCOSeq, @OldPOCONum, @OldPOCONumSeq, @OldECM
				
	if @@fetch_status = 0
		goto bPMOL_insert
	else
		BEGIN
		close bPMOL_insert
		deallocate bPMOL_insert
		set @opencursor = 0
		END
	END

if update(SendYN)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMOL','PMCo: ' + isnull(convert(char(3),i.PMCo), '') + ' Project: ' + isnull(i.Project,'')
		+ ' PCOType: ' + isnull(i.PCOType,'') + ' PCO: ' + isnull(i.PCO,'')
		+ ' PCOItem: ' + isnull(i.PCOItem,'') + ' Phase: ' + ISNULL(i.Phase,'')
		+ ' CostType: ' + isnull(convert(char(3),i.CostType),'')
		, i.PMCo, 'C',
		'SendYN', d.SendYN, i.SendYN, getdate(), SUSER_SNAME()
	from inserted i
	join deleted d on d.KeyID = i.KeyID
	where isnull(d.SendYN,'') <> isnull(i.SendYN,'')
	END
	
---- update the ready for accounting flag to 'Y' in PMOH
---- when detail added to an ACO and the Send flag is 'Y'
---- and the ACO ready for accounting flag is 'N' TK-05347
---- GF 11/23/2011 - TK-10530 CI#145133
UPDATE dbo.bPMOH SET ReadyForAcctg = 'Y'
FROM inserted i
INNER JOIN deleted d ON d.KeyID = i.KeyID
INNER JOIN dbo.bPMOH h ON h.PMCo=i.PMCo AND h.Project=i.Project AND h.ACO=i.ACO
WHERE i.ACO IS NOT NULL AND h.ReadyForAcctg = 'N' AND i.SendYN = 'Y'
AND ISNULL(i.SendYN,'N') <> ISNULL(d.SendYN,'N')



RETURN



error:
	if @opencursor = 1
		BEGIN
		close bPMOL_insert
		deallocate bPMOL_insert
		set @opencursor = 0
		END
   
   	select @errmsg = isnull(@errmsg,'') + ' - cannot update into PMOL'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction





GO
ALTER TABLE [dbo].[bPMOL] WITH NOCHECK ADD CONSTRAINT [CK_bPMOL_POPOSLItem] CHECK (([PO] IS NULL OR [POSLItem] IS NOT NULL))
GO
ALTER TABLE [dbo].[bPMOL] WITH NOCHECK ADD CONSTRAINT [CK_bPMOL_SubcontractPOSLItem] CHECK (([Subcontract] IS NULL OR [POSLItem] IS NOT NULL))
GO
ALTER TABLE [dbo].[bPMOL] WITH NOCHECK ADD CONSTRAINT [CK_bPMOL_Vendor] CHECK (([Vendor] IS NULL OR [VendorGroup] IS NOT NULL))
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPMOL] ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [IX_bPMOL_CLUSTERED] ON [dbo].[bPMOL] ([PMCo], [Project], [PCOType], [PCO], [PCOItem], [ACO], [ACOItem], [PhaseGroup], [Phase], [CostType]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_bPMOL2_NONCLUSTERED] ON [dbo].[bPMOL] ([PMCo], [Project], [PhaseGroup], [Phase], [CostType], [PCOType], [PCO], [PCOItem], [ACO], [ACOItem]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bPMOL] WITH NOCHECK ADD CONSTRAINT [FK_bPMOL_bPMDT] FOREIGN KEY ([PCOType]) REFERENCES [dbo].[bPMDT] ([DocType])
GO
ALTER TABLE [dbo].[bPMOL] WITH NOCHECK ADD CONSTRAINT [FK_bPMOL_bAPVM] FOREIGN KEY ([VendorGroup], [Vendor]) REFERENCES [dbo].[bAPVM] ([VendorGroup], [Vendor])
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPMOL].[EstUnits]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPMOL].[EstHours]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPMOL].[HourCost]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPMOL].[UnitCost]'
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bPMOL].[ECM]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPMOL].[EstCost]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPMOL].[SendYN]'
GO
