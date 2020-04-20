CREATE TABLE [dbo].[bAPLB]
(
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[BatchSeq] [int] NOT NULL,
[APLine] [smallint] NOT NULL,
[BatchTransType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[LineType] [tinyint] NOT NULL,
[PO] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[POItem] [dbo].[bItem] NULL,
[ItemType] [tinyint] NULL,
[SL] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[SLItem] [dbo].[bItem] NULL,
[JCCo] [dbo].[bCompany] NULL,
[Job] [dbo].[bJob] NULL,
[PhaseGroup] [dbo].[bGroup] NULL,
[Phase] [dbo].[bPhase] NULL,
[JCCType] [dbo].[bJCCType] NULL,
[EMCo] [dbo].[bCompany] NULL,
[WO] [dbo].[bWO] NULL,
[WOItem] [dbo].[bItem] NULL,
[Equip] [dbo].[bEquip] NULL,
[EMGroup] [dbo].[bGroup] NULL,
[CostCode] [dbo].[bCostCode] NULL,
[EMCType] [dbo].[bEMCType] NULL,
[CompType] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Component] [dbo].[bEquip] NULL,
[INCo] [dbo].[bCompany] NULL,
[Loc] [dbo].[bLoc] NULL,
[MatlGroup] [dbo].[bGroup] NULL,
[Material] [dbo].[bMatl] NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[GLAcct] [dbo].[bGLAcct] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[UM] [dbo].[bUM] NULL,
[Units] [dbo].[bUnits] NOT NULL,
[UnitCost] [dbo].[bUnitCost] NOT NULL CONSTRAINT [DF_bAPLB_UnitCost] DEFAULT ((0)),
[ECM] [dbo].[bECM] NULL,
[VendorGroup] [dbo].[bGroup] NULL,
[Supplier] [dbo].[bVendor] NULL,
[PayType] [tinyint] NOT NULL,
[GrossAmt] [dbo].[bDollar] NOT NULL,
[MiscAmt] [dbo].[bDollar] NOT NULL,
[MiscYN] [dbo].[bYN] NOT NULL,
[TaxGroup] [dbo].[bGroup] NULL,
[TaxCode] [dbo].[bTaxCode] NULL,
[TaxType] [tinyint] NULL,
[TaxBasis] [dbo].[bDollar] NOT NULL,
[TaxAmt] [dbo].[bDollar] NOT NULL,
[Retainage] [dbo].[bDollar] NOT NULL,
[Discount] [dbo].[bDollar] NOT NULL,
[BurUnitCost] [dbo].[bUnitCost] NOT NULL CONSTRAINT [DF_bAPLB_BurUnitCost] DEFAULT ((0)),
[BECM] [dbo].[bECM] NULL,
[SMChange] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bAPLB_SMChange] DEFAULT ((0)),
[OldLineType] [tinyint] NULL,
[OldPO] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[OldPOItem] [dbo].[bItem] NULL,
[OldItemType] [tinyint] NULL,
[OldSL] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[OldSLItem] [dbo].[bItem] NULL,
[OldJCCo] [dbo].[bCompany] NULL,
[OldJob] [dbo].[bJob] NULL,
[OldPhaseGroup] [dbo].[bGroup] NULL,
[OldPhase] [dbo].[bPhase] NULL,
[OldJCCType] [dbo].[bJCCType] NULL,
[OldEMCo] [dbo].[bCompany] NULL,
[OldWO] [dbo].[bWO] NULL,
[OldWOItem] [dbo].[bItem] NULL,
[OldEquip] [dbo].[bEquip] NULL,
[OldEMGroup] [dbo].[bGroup] NULL,
[OldCostCode] [dbo].[bCostCode] NULL,
[OldEMCType] [dbo].[bEMCType] NULL,
[OldCompType] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[OldComponent] [dbo].[bEquip] NULL,
[OldINCo] [dbo].[bCompany] NULL,
[OldLoc] [dbo].[bLoc] NULL,
[OldMatlGroup] [dbo].[bGroup] NULL,
[OldMaterial] [dbo].[bMatl] NULL,
[OldGLCo] [dbo].[bCompany] NULL,
[OldGLAcct] [dbo].[bGLAcct] NULL,
[OldDesc] [dbo].[bDesc] NULL,
[OldUM] [dbo].[bUM] NULL,
[OldUnits] [dbo].[bUnits] NULL,
[OldUnitCost] [dbo].[bUnitCost] NULL,
[OldECM] [dbo].[bECM] NULL,
[OldVendorGroup] [dbo].[bGroup] NULL,
[OldSupplier] [dbo].[bVendor] NULL,
[OldPayType] [tinyint] NULL,
[OldGrossAmt] [dbo].[bDollar] NULL,
[OldMiscAmt] [dbo].[bDollar] NULL,
[OldMiscYN] [dbo].[bYN] NULL,
[OldTaxGroup] [dbo].[bGroup] NULL,
[OldTaxCode] [dbo].[bTaxCode] NULL,
[OldTaxType] [tinyint] NULL,
[OldTaxBasis] [dbo].[bDollar] NULL,
[OldTaxAmt] [dbo].[bDollar] NULL,
[OldRetainage] [dbo].[bDollar] NULL,
[OldDiscount] [dbo].[bDollar] NULL,
[OldBurUnitCost] [dbo].[bUnitCost] NULL,
[OldBECM] [dbo].[bECM] NULL,
[PaidYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bAPLB_PaidYN] DEFAULT ('N'),
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[POPayTypeYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bAPLB_POPayTypeYN] DEFAULT ('N'),
[PayCategory] [int] NULL,
[OldPayCategory] [int] NULL,
[SLDetailKeyID] [bigint] NULL,
[Receiver#] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[SLKeyID] [bigint] NULL,
[SMCo] [dbo].[bCompany] NULL,
[SMWorkOrder] [int] NULL,
[Scope] [int] NULL,
[OldSMCo] [dbo].[bCompany] NULL,
[OldSMWorkOrder] [int] NULL,
[OldScope] [int] NULL,
[SMStandardItem] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[OldSMStandardItem] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[APTLKeyID] [bigint] NULL,
[POItemLine] [int] NULL,
[OldPOItemLine] [int] NULL,
[SMCostType] [smallint] NULL,
[OldSMCostType] [smallint] NULL,
[SMJCCostType] [dbo].[bJCCType] NULL,
[OldSMJCCostType] [dbo].[bJCCType] NULL,
[SMPhaseGroup] [dbo].[bGroup] NULL,
[OldSMPhaseGroup] [dbo].[bGroup] NULL,
[SubjToOnCostYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bAPLB_SubjToOnCostYN] DEFAULT ('N'),
[OldSubjToOnCostYN] [dbo].[bYN] NULL,
[ocApplyMth] [dbo].[bMonth] NULL,
[ocApplyTrans] [dbo].[bTrans] NULL,
[ocApplyLine] [smallint] NULL,
[ATOCategory] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[ocSchemeID] [smallint] NULL,
[ocMembershipNbr] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[SMPhase] [dbo].[bPhase] NULL,
[OldSMPhase] [dbo].[bPhase] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
ALTER TABLE [dbo].[bAPLB] ADD
CONSTRAINT [CK_bAPLB_BECM] CHECK (([BECM]='E' OR [BECM]='C' OR [BECM]='M' OR [BECM] IS NULL))
ALTER TABLE [dbo].[bAPLB] ADD
CONSTRAINT [CK_bAPLB_ECM] CHECK (([ECM]='E' OR [ECM]='C' OR [ECM]='M' OR [ECM] IS NULL))
ALTER TABLE [dbo].[bAPLB] ADD
CONSTRAINT [CK_bAPLB_MiscYN] CHECK (([MiscYN]='Y' OR [MiscYN]='N'))
ALTER TABLE [dbo].[bAPLB] ADD
CONSTRAINT [CK_bAPLB_OldBECM] CHECK (([OldBECM]='E' OR [OldBECM]='C' OR [OldBECM]='M' OR [OldBECM] IS NULL))
ALTER TABLE [dbo].[bAPLB] ADD
CONSTRAINT [CK_bAPLB_OldECM] CHECK (([OldECM]='E' OR [OldECM]='C' OR [OldECM]='M' OR [OldECM] IS NULL))
ALTER TABLE [dbo].[bAPLB] ADD
CONSTRAINT [CK_bAPLB_OldMiscYN] CHECK (([OldMiscYN]='Y' OR [OldMiscYN]='N' OR [OldMiscYN] IS NULL))
ALTER TABLE [dbo].[bAPLB] ADD
CONSTRAINT [CK_bAPLB_POPayTypeYN] CHECK (([POPayTypeYN]='Y' OR [POPayTypeYN]='N'))
ALTER TABLE [dbo].[bAPLB] ADD
CONSTRAINT [CK_bAPLB_PaidYN] CHECK (([PaidYN]='Y' OR [PaidYN]='N'))
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
  
  
CREATE trigger [dbo].[btAPLBd] on [dbo].[bAPLB] for DELETE as
/*--------------------------------------------------------------
*  Created:  SE  8/25/97
*  Modified: EN 9/3/98
*            GH 9/7/99 Modified SLIT,SLHD,POIT,POHD where clause to not look at
*          		specific BatchSeq but to look through the whole batch for the Subcontract or the PO.
*            GG 12/06/99 - Cleanup
*            SR 12/15/00 - Rewrote removing cursors, and added oldPO and oldSL checks
*			  GF 08/12/2003 - issue #22112 - performance
*			  MV 06/21/05 - #28731 - redo PO unlock
*			  MV 07/28/05 - #28731 - add cursor for multiple POItems being deleted
*			  MV 02/19/07 - #123776 - improved inuse for OldPO and OldSL
*			  MV 02/19/07 - #121178 - added 'LineType=6' to PO cursor where clause so InUse update only
*				happens on PO lines.  Added PO or SL 'is not null' to PO/SL select statements
*			GG 03/16/07 - #121178 - performance improvements, removed cursors
*			GG 03/04/08 - #127204 - fix error unlocking PO and SL
*			MV 08/03/11 - TK-07233 - unlock POItemLine
*			MV 09/20/11 - TK-08578 -set @unlockPO,@unlockOldPO for PO Item Line
*			MV 04/16/12 - TK-14041 - reset OnCostStatus when deleting OnCost lines.
*
*  Delete trigger for AP Line Batch table
*--------------------------------------------------------------*/
 DECLARE	@numrows int,
			@errmsg varchar(255),
			@unlockPO bYN,
			@unlockOldPO bYN,
			@unlockSL bYN,
			@unlockOldSL bYN,
			@Co INT,
			@Mth bDate,
			@BatchId INT,
			@BatchSeq INT,
			@ocApplyMth bDate,
			@ocApplyTrans INT,
			@ocApplyLine INT,
			@openAPLB INT
              
select @numrows = @@rowcount
if @numrows = 0 return

set nocount on

-- indicates whether the PO and SL Headers should be checked and possibly unlocked
select @unlockPO = 'N', @unlockOldPO = 'N', @unlockSL = 'N', @unlockOldSL = 'N', @openAPLB = 0	

/************ Purchase Orders ***************/
-- unlock PO Items no longer referenced in an AP Entry batch (can only be locked by a single batch) 
if exists(select top 1 1 from deleted where PO is not null)
	begin
	update dbo.bPOIT
	set InUseMth = null, InUseBatchId = null
	from deleted d
	join dbo.bPOIT i (nolock) on i.POCo = d.Co and i.PO = d.PO and i.POItem = d.POItem
	where not exists(select top 1 1 from dbo.bAPLB l (nolock)
					where l.Co = d.Co and ((l.PO = d.PO and l.POItem = d.POItem) or (l.OldPO = d.PO and l.OldPOItem = d.POItem)))
	if @@rowcount > 0 set @unlockPO = 'Y'	-- some PO Items were unlocked, check PO Header
	end
	--unlock POItemLine
	BEGIN
	UPDATE dbo.vPOItemLine
	SET InUseMth = NULL, InUseBatchId = NULL  
	FROM deleted d
	JOIN dbo.vPOItemLine i (nolock) ON i.POCo = d.Co and i.PO = d.PO and i.POItem = d.POItem and i.POItemLine = d.POItemLine
	WHERE NOT EXISTS
		(
			SELECT TOP 1 1 
			FROM dbo.bAPLB l (nolock)
			WHERE l.Co = d.Co AND 
			(
				(
					l.PO = d.PO and l.POItem = d.POItem and l.POItemLine = d.POItemLine
				) 
				OR 
				(
					l.OldPO = d.PO and l.OldPOItem = d.POItem and l.OldPOItemLine = d.POItemLine
				)
			)
		)
	IF @@ROWCOUNT > 0 SET @unlockPO = 'Y'	-- some PO Item Lines were unlocked, check PO Header
	END
-- unlock old PO Items no longer referenced in an AP Entry batch (can only be locked by a single batch) 
if exists(select top 1 1 from deleted where OldPO is not null)
			-- #127204 - comment out following line, was failing to unlock PO if AP Line type changed
			-- and (isnull(PO,OldPO) <> OldPO or isnull(POItem,OldPOItem) <> OldPOItem))	-- skip if current and old PO values match
	begin
	update dbo.bPOIT
	set InUseMth = null, InUseBatchId = null
	from deleted d
	join dbo.bPOIT i (nolock) on i.POCo = d.Co and i.PO = d.OldPO and i.POItem = d.OldPOItem
	where not exists(select top 1 1 from dbo.bAPLB l (nolock)
					where l.Co = d.Co and ((l.PO = d.OldPO and l.POItem = d.OldPOItem) or (l.OldPO = d.OldPO and l.OldPOItem = d.OldPOItem)))
	if @@rowcount > 0 set @unlockOldPO = 'Y'
	end
	--unlock OldPOItemLine
	BEGIN
	UPDATE dbo.vPOItemLine
	SET InUseMth = NULL, InUseBatchId = NULL  
	FROM deleted d
	JOIN dbo.vPOItemLine i (nolock) ON i.POCo = d.Co and i.PO = d.OldPO and i.POItem = d.OldPOItem and i.POItemLine = d.OldPOItemLine
	WHERE NOT EXISTS
		(
			SELECT TOP 1 1 
			FROM dbo.bAPLB l (nolock)
			WHERE l.Co = d.Co AND 
			(
				(
					l.PO = d.OldPO and l.POItem = d.OldPOItem and l.POItemLine = d.OldPOItemLine
				) 
				OR 
				(
					l.OldPO = d.OldPO and l.OldPOItem = d.OldPOItem and l.OldPOItemLine = d.OldPOItemLine
				)
			)
		)
	IF @@ROWCOUNT > 0 SET @unlockOldPO = 'Y'
	END
-- unlock PO Headers no longer referenced in an AP Entry batch (can only be locked by a single batch)
if @unlockPO = 'Y'
	begin 
	update dbo.bPOHD
	set InUseMth = null, InUseBatchId = null
	from deleted d
	join dbo.bPOHD i (nolock) on i.POCo = d.Co and i.PO = d.PO 
	where not exists(select top 1 1 from dbo.bAPLB l (nolock)
					where l.Co = d.Co and (l.PO = d.PO or l.OldPO = d.PO)) 
	end
-- unlock Old PO Headers no longer referenced in an AP Entry batch (can only be locked by a single batch)
if @unlockOldPO = 'Y'
	begin
	update dbo.bPOHD
	set InUseMth = null, InUseBatchId = null
	from deleted d
	join dbo.bPOHD i (nolock) on i.POCo = d.Co and i.PO = d.OldPO 
	where not exists(select top 1 1 from dbo.bAPLB l (nolock)
					where l.Co = d.Co and (l.PO = d.OldPO or l.OldPO = d.OldPO)) 
	end 

/********** Subcontracts *************/
-- unlock SL Items no longer referenced in an AP Entry batch (can only be locked by a single batch) 
if exists(select top 1 1 from deleted where SL is not null)
	begin
	update dbo.bSLIT
	set InUseMth = null, InUseBatchId = null
	from deleted d
	join dbo.bSLIT i (nolock) on i.SLCo = d.Co and i.SL = d.SL and i.SLItem = d.SLItem
	where not exists(select top 1 1 from dbo.bAPLB l (nolock)
					where l.Co = d.Co and ((l.SL = d.SL and l.SLItem = d.SLItem) or (l.OldSL = d.SL and l.OldSLItem = d.SLItem)))
	if @@rowcount > 0 set @unlockSL = 'Y'	-- some SL Items were unlocked, check SL Header
	end
-- unlock old SL Items no longer referenced in an AP Entry batch (can only be locked by a single batch) 
if exists(select top 1 1 from deleted where OldSL is not null)
			-- #127204 - comment out following line, was failing to unlock SL if AP Line type changed
			--and (isnull(SL,OldSL) <> OldSL or isnull(SLItem,OldSLItem) <> OldSLItem))	-- skip  if current and old SL values match
	begin
	update dbo.bSLIT
	set InUseMth = null, InUseBatchId = null
	from deleted d
	join dbo.bSLIT i (nolock) on i.SLCo = d.Co and i.SL = d.OldSL and i.SLItem = d.OldSLItem
	where not exists(select top 1 1 from dbo.bAPLB l (nolock)
					where l.Co = d.Co and ((l.SL = d.OldSL and l.SLItem = d.OldSLItem) or (l.OldSL = d.OldSL and l.OldSLItem = d.OldSLItem)))
	if @@rowcount > 0 set @unlockOldSL = 'Y'
	end

-- unlock SL Headers no longer referenced in an AP Entry batch (can only be locked by a single batch)
if @unlockSL = 'Y'
	begin 
	update dbo.bSLHD
	set InUseMth = null, InUseBatchId = null
	from deleted d
	join dbo.bSLHD i (nolock) on i.SLCo = d.Co and i.SL = d.SL 
	where not exists(select top 1 1 from dbo.bAPLB l (nolock)
					where l.Co = d.Co and (l.SL = d.SL or l.OldSL = d.SL))
	end
-- unlock Old SL Headers no longer referenced in an AP Entry batch (can only be locked by a single batch)
if @unlockOldSL = 'Y'
	begin
	update dbo.bSLHD
	set InUseMth = null, InUseBatchId = null
	from deleted d
	join dbo.bSLHD i (nolock) on i.SLCo = d.Co and i.SL = d.OldSL 
	where not exists(select top 1 1 from dbo.bAPLB l (nolock)
					where l.Co = d.Co and (l.SL = d.OldSL or l.OldSL = d.OldSL)) 
	end 

/*	if this line is an On-cost invoice line being deleted then update APTL OnCostStatus back to 0 if there are 
	no other on-cost invoice lines either posted or in this batch or other batches */
IF @numrows = 1 -- deleting one line 
BEGIN
	SELECT	@Co				= Co,
			@Mth			= Mth,
			@BatchId		= BatchId,
			@BatchSeq		= BatchSeq,
			@ocApplyMth		= ocApplyMth,
			@ocApplyTrans	= ocApplyTrans,
			@ocApplyLine	= ocApplyLine
	FROM deleted
	IF @ocApplyMth iS NOT NULL AND @ocApplyTrans IS NOT NULL AND @ocApplyLine iS NOT NULL
	BEGIN
		UPDATE dbo.bAPTL 
		SET OnCostStatus = 0
		WHERE APCo=@Co AND Mth=@ocApplyMth AND APTrans=@ocApplyTrans AND APLine=@ocApplyLine
		AND NOT EXISTS	-- no oncost invoices in this or other batches
						(
							SELECT * 
							FROM dbo.bAPLB 
							WHERE Co=@Co AND ocApplyMth = @ocApplyMth 
								AND ocApplyTrans = @ocApplyTrans AND ocApplyLine = @ocApplyLine
								AND (Mth <> @Mth OR BatchId <> @BatchId OR BatchSeq <> @BatchSeq)
						) 
		AND NOT EXISTS		-- no oncost invoices posted to APTL
						(
							SELECT * 
							FROM dbo.bAPTL 
							WHERE APCo=@Co AND ocApplyMth = @ocApplyMth 
								AND ocApplyTrans = @ocApplyTrans AND ocApplyLine = @ocApplyLine
						)
		--AND NOT EXISTS	-- no oncost invoices in unapproved
		--				(
		--					SELECT * 
		--					FROM dbo.bAPUL 
		--					WHERE APCo=@Co AND ocApplyMth = @ocApplyMth 
		--						AND ApplyTrans = @ApplyTrans AND ocApplyLine = @ocApplyLine
		--				)
	END
END
ELSE -- deleting multiple lines
BEGIN
	DECLARE vcAPLB CURSOR LOCAL FAST_FORWARD FOR SELECT 
			Co,
			Mth,
			BatchId,
			BatchSeq,
			ocApplyMth,
			ocApplyTrans,
			ocApplyLine		
	FROM deleted
	WHERE ocApplyMth IS NOT NULL AND ocApplyTrans IS NOT NULL AND ocApplyLine IS NOT NULL	

	OPEN vcAPLB
	SELECT @openAPLB = 1
	  
APLB_loop:      
		FETCH NEXT FROM vcAPLB 
				   INTO	@Co,
						@Mth,
						@BatchId,
						@BatchSeq,
						@ocApplyMth,
						@ocApplyTrans,
						@ocApplyLine
			
		IF @@fetch_status <> 0 
		BEGIN
			GOTO APLB_End
		END
		ELSE
		BEGIN
			UPDATE dbo.bAPTL 
			SET OnCostStatus = 0
			WHERE APCo=@Co AND Mth=@ocApplyMth AND APTrans=@ocApplyTrans AND APLine=@ocApplyLine
			AND NOT EXISTS	-- no oncost invoices in this or other batches
							(
								SELECT * 
								FROM dbo.bAPLB 
								WHERE Co=@Co AND ocApplyMth = @ocApplyMth 
									AND ocApplyTrans = @ocApplyTrans AND ocApplyLine = @ocApplyLine
									AND (Mth <> @Mth OR BatchId <> @BatchId OR BatchSeq <> @BatchSeq)
							) 
			AND NOT EXISTS		-- no oncost invoices posted to APTL
							(
								SELECT * 
								FROM dbo.bAPTL 
								WHERE APCo=@Co AND ocApplyMth = @ocApplyMth 
									AND ocApplyTrans = @ocApplyTrans AND ocApplyLine = @ocApplyLine
							)
			--AND NOT EXISTS	-- no oncost invoices in unapproved
			--				(
			--					SELECT * 
			--					FROM dbo.bAPUL 
			--					WHERE APCo=@Co AND ocApplyMth = @ocApplyMth 
			--						AND ApplyTrans = @ApplyTrans AND ocApplyLine = @ocApplyLine
			--				)
			GOTO APLB_loop
		END
		
APLB_End:
	IF @openAPLB = 1
	BEGIN
		CLOSE vcAPLB
		DEALLOCATE vcAPLB
		SELECT @openAPLB = 0
	END
END
 	
 RETURN
    
    
 error_handle:
	select @errmsg =  ' cannot delete AP Batch Lines'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction
   
    
    
    
    
    
    
   
   
  
 





GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
 
CREATE trigger [dbo].[btAPLBi] on [dbo].[bAPLB] for INSERT as
/*--------------------------------------------------------------
* Created: SE	08/25/1997
* Modified: kb	01/04/1999
*			GG	12/06/1999	- Cleanup bHQCC update
*			MV	07/01/2002	- #17277 - cleaned up err msg and tweaked msg date.
*			MV	11/25/2002	- #19364 - more info in error msg.
*			MV	11/26/2002	- #18667 - more info in PO and SL err msgs.
*			RT	03/11/2004	- #23972 - wrap variables with isnull() in error message.
*			GG	07/25/2007	- #120561 - remove bHQCC insert for AP GL Co#, cleanup
*			MV	04/03/2009	- #133073 - (nolock)
*			GP	06/06/2010	- #135813 changed bSL to varchar(30)
*			GP	07/27/2011	- TK-07144 changed bPO to varchar(30)
*			CHS	08/04/2011	- TK-07460 added POItemLine
*			MV	09/20/11	- TK-08578 - uncommented code to lock PO header
*
* Insert trigger for AP Line Batch table.
* Reject if header does not exist in bAPHB.
* Lock PO and POItem, SL and SL Item unless already in use by another batch.
* Insert entries into bHQCC as needed for 'posted to' and AP GL Co#s.
*--------------------------------------------------------------*/
    
declare @numrows int, @errmsg varchar(255), @validcnt int, @errstart varchar(100),
	@apco bCompany, @mth bMonth, @batchid bBatchID, @batchseq int, @apline smallint,
	@po varchar(30), @poitem bItem, @poitemline int, 
	@inusebatchid bBatchID, @inusemth bMonth, @sl varchar(30), @slitem bItem,
	@glco bCompany, @opencursor tinyint, @netamtopt bYN, @burdenyn bYN, @loc bLoc, @units bUnits,
	@grossamt bDollar, @miscamt bDollar, @taxamt bDollar, @discount bDollar, @burunitcost bUnitCost,
	@source bSource

select @numrows = @@rowcount
if @numrows = 0 return

set nocount on

/* check for header in APHB */
select @validcnt = count(*)
from bAPHB b (nolock)
join inserted i on b.Co = i.Co and b.Mth = i.Mth and b.BatchId = i.BatchId and b.BatchSeq = i.BatchSeq
if @validcnt <> @numrows
	begin
	select @errmsg = 'AP Batch Header does not exist'
	goto error
	end
    
-- use a cursor to process PO and SL lines
declare bcAPLB cursor for
select Co, Mth, BatchId, BatchSeq, APLine, PO, POItem, POItemLine, SL, SLItem, GLCo
from inserted
where PO is not null or SL is not null or Loc is not null

open bcAPLB
select @opencursor = 1

nextloop:
    fetch next from bcAPLB into @apco, @mth, @batchid, @batchseq, @apline,
        @po, @poitem, @poitemline, @sl, @slitem, @glco

    if @@fetch_status <> 0 goto endloop

    select @errstart = 'Line: ' + convert(varchar(4), isnull(@apline,''))

    -- add entry to HQ Close Control as needed
    if not exists(select * from bHQCC (nolock) where Co = @apco and Mth = @mth and BatchId = @batchid and GLCo = @glco)
		begin
		insert bHQCC (Co, Mth, BatchId, GLCo)
		values (@apco, @mth, @batchid, @glco)
		end
    
	-- lock PO Header
	if @po is not null
		begin    -- check PO Header to see if it is already locked
		select @inusemth = InUseMth, @inusebatchid = InUseBatchId
		from bPOHD (nolock)
		where POCo = @apco and PO = @po
		if @@rowcount = 0
			begin
			select @errmsg = @errstart + ' PO: ' + isnull(@po,'') + ' not valid for Company: '
				+ convert (varchar(3),@apco)	--19364
			--select @errmsg = @errstart + ' Invalid PO: ' + @po
			goto error
			end

 	--	if @mth <> isnull(@inusemth,@mth) or @batchid <> isnull(@inusebatchid,@batchid)
		--	begin
		--	select @source = Source
		--	from bHQBC (nolock) 
		--	where Co=@apco and Mth=@inusemth and BatchId=@inusebatchid
 			
		--	select @errmsg = @errstart + ' PO: ' + isnull(@po,'') + ' is already in use by Batch: '
  --			+ isnull(convert(varchar(6),@inusebatchid),'') + ' in month '
  --			+ isnull(convert(varchar(8),@inusemth,1),'')	--18667
		--	+ ' Source: ' + isnull(@source,'')	--18667
 	--		goto error
 	--		end

		-- Lock the PO header to prevent closing the PO while in use.
		if @inusemth is null or @inusebatchid is null
			begin
			update bPOHD set InUseMth = @mth, InUseBatchId = @batchid
			where POCo = @apco and PO = @po
			if @@rowcount = 0
				begin
				select @errmsg = @errstart + 'Unable to lock header for PO:' + isnull(@po,'')
				goto error
				end
    	 	end
    
            -- validate PO Item
    	 	select @inusemth = InUseMth, @inusebatchid = InUseBatchId
    	 	from bPOIT (nolock)
            where POCo = @apco and PO = @po and POItem = @poitem
            if @@rowcount = 0
                begin
    	 		select @errmsg = @errstart + 'Invalid Item: ' + isnull(convert(varchar(5),@poitem),'') + ' on PO: ' + isnull(@po,'')
    	 		goto error
    	 		end
    
    	 	--if @mth <> isnull(@inusemth,@mth) or @batchid <> isnull(@inusebatchid,@batchid)
    	 	--	begin
    	 	--	select @errmsg = @errstart + ' PO ' + isnull(@po,'') + ' Item ' + isnull(convert(varchar(5),@poitem),'')
    			--		+ ' is already in use by Batch Id : ' + isnull(convert(varchar(6),@inusebatchid),'')
    			--		+ ' in month ' + isnull(convert(varchar(8),@inusemth,1),'')	
    	 	--	goto error
    	 	--	end
    
    	 	--if @inusemth is null or @inusebatchid is null
    	 	--	begin
    	 	--	update bPOIT set InUseMth = @mth, InUseBatchId = @batchid
    	 	--	where POCo = @apco and PO = @po and POItem = @poitem
    	 	--	if @@rowcount = 0
    	 	--		begin
    	 	--		select @errmsg = @errstart + 'Unable to lock Item: ' + isnull(convert(varchar(5),@poitem),'') + ' on PO: ' + isnull(@po,'')
    	 	--		goto error
    	 	--		end
    	 	--	end
    	 	--end
    
             -- validate PO Item Line
    	 	select @inusemth = InUseMth, @inusebatchid = InUseBatchId
    	 	from vPOItemLine (nolock)
            where POCo = @apco and PO = @po and POItem = @poitem and POItemLine = @poitemline
            if @@rowcount = 0
                begin
    	 		select @errmsg = @errstart + 'Invalid Item Line: ' + isnull(convert(varchar(5),@poitemline),'')
    	 			+ ' on PO Item: ' + isnull(convert(varchar(5),@poitem),'') 
    	 			+ ' on PO: ' + isnull(@po,'')
    	 		goto error
    	 		end
    
    	 	if @mth <> isnull(@inusemth,@mth) or @batchid <> isnull(@inusebatchid,@batchid)
    	 		begin
    	 		select @errmsg = @errstart + ' PO ' + isnull(@po,'') + ' Item ' + isnull(convert(varchar(5),@poitem),'')
    	 				+ ' Item ' + isnull(convert(varchar(5),@poitemline),'')
    					+ ' is already in use by Batch Id : ' + isnull(convert(varchar(6),@inusebatchid),'')
    					+ ' in month ' + isnull(convert(varchar(8),@inusemth,1),'')	
    	 		goto error
    	 		end
    
    	 	if @inusemth is null or @inusebatchid is null
    	 		begin
    	 		update vPOItemLine set InUseMth = @mth, InUseBatchId = @batchid
    	 		where POCo = @apco and PO = @po and POItem = @poitem and POItemLine = @poitemline
    	 		if @@rowcount = 0
    	 			begin
    	 			select @errmsg = @errstart + 'Unable to lock Item: ' + isnull(convert(varchar(5),@poitem),'') + ' on PO: ' + isnull(@po,'')
    	 			goto error
    	 			end
    	 		end
    	 	end     
    
    
        -- lock SL Header
        if @sl is not null
            begin    -- check SL Header to see if it is already locked
    	 	select @inusemth = InUseMth, @inusebatchid = InUseBatchId
    	 	from bSLHD (nolock)
            where SLCo = @apco and SL = @sl
            if @@rowcount = 0
                begin
                select @errmsg = @errstart + ' Invalid Subcontract: ' + @sl 
    			+ ' for Company: ' + isnull(convert (varchar(3),@apco),'')	--19364
                goto error
                end
    
    	 	if @mth <> isnull(@inusemth,@mth) or @batchid <> isnull(@inusebatchid,@batchid)
                begin	
    			select @source = Source from bHQBC (nolock) where Co=@apco and Mth=@inusemth and BatchId=@inusebatchid 	--18667		 			
    			select @errmsg = @errstart + ' Subcontract: ' + isnull(@sl,'') + ' is already in use by Batch: '
    	  			+ isnull(convert(varchar(6),@inusebatchid),'') + ' in Month: '
    				+ isnull(convert(varchar(8),@inusemth,1),'')	--#17277 tweaked the date format
    				+ ' Source: ' + isnull(@source,'')	--18667
    	 		goto error
    	 		end
    
            if @inusemth is null or @inusebatchid is null
    	 		begin
    	 		update bSLHD set InUseMth = @mth, InUseBatchId = @batchid
    	 		where SLCo = @apco and SL = @sl
    	 		if @@rowcount = 0
                    begin
    	 			select @errmsg = @errstart + 'Unable to lock header for Subcontract:' + isnull(@sl,'')
    	 			goto error
    	 			end
    	 		end
    
            -- validate SL Item
    	 	select @inusemth = InUseMth, @inusebatchid = InUseBatchId
    	 	from bSLIT (nolock)
            where SLCo = @apco and SL = @sl and SLItem = @slitem
            if @@rowcount = 0
                begin
    	 		select @errmsg = @errstart + 'Invalid Item: ' + isnull(convert(varchar(5),@slitem),'')
                    + ' on Subcontract: ' + isnull(@sl,'')
    	 		goto error
    	 		end
    
    	 	if @mth <> isnull(@inusemth,@mth) or @batchid <> isnull(@inusebatchid,@batchid)
    	 		begin
    	 		select @errmsg = @errstart + ' Subcontract ' + isnull(@sl,'') + ' Item: ' + isnull(convert(varchar(5),@slitem),'') --#17277
                    + ' is already in use by Batch: ' + isnull(convert(varchar(6),@inusebatchid),'') + ' in Month: '
                    + isnull(convert(varchar(8),@inusemth,1),'')	--#17277 tweaked the date format
    			/*+ convert(varchar(8),@inusemth)*/
    	 		goto error
    	 		end
    
    	 	if @inusemth is null or @inusebatchid is null
    	 		begin
    	 		update bSLIT set InUseMth = @mth, InUseBatchId = @batchid
    	 		where SLCo = @apco and SL = @sl and SLItem = @slitem
    	 		if @@rowcount = 0
    	 			begin
    	 			select @errmsg = @errstart + 'Unable to lock Item: ' + isnull(convert(varchar(5),@slitem),'')
                        + ' on Subcontract: ' + isnull(@sl,'')
    	 			goto error
    	 			end
    	 		end
    	 	end
    
      goto nextloop
    
    endloop:
        close bcAPLB
        deallocate bcAPLB
        select @opencursor = 0
    
    -- update HQ Close Control for all 'posted to' GL Co#s
    insert into bHQCC(Co, Mth, BatchId, GLCo)
        select distinct Co, Mth, BatchId, GLCo from inserted i
           where not exists(select * from bHQCC c (nolock) where c.Co = i.Co and c.Mth = i.Mth
           				and c.BatchId = i.BatchId and c.GLCo = i.GLCo)
    
        
    return
    
    error:
        if @opencursor = 1
            begin
            close bcAPLB
            deallocate bcAPLB
            end
        select @errmsg = @errmsg + ' - cannot insert AP Line Batch entry'
        RAISERROR(@errmsg, 11, -1);
        rollback transaction
    
    
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   
   /****** Object:  Trigger btAPLBu    Script Date: 8/28/99 9:36:55 AM ******/
   CREATE    trigger [dbo].[btAPLBu] on [dbo].[bAPLB] for UPDATE as
   

/*-----------------------------------------------------------------
    * Created :  9/3/98 EN
    * Modified : 1/4/99 EN
    *            GH 9/7/99 Modified SLIT,SLHD,POIT,POHD where clause to not look at
    *  				specific BatchSeq but to look through the whole batch for the Subcontract or the PO.
    *			  GG 12/1/99 - Cleanup
    *			  MV 10/17/02 - #18878 quoted identifier cleanup.
    *			  GF 08/12/2003 - issue #22112 - performance
    *			  ES 03/12/04 - #23061 isnull wrapping
    *			GP 6/6/2010 - #135813 changed bSL to varchar(30)
    *			GP 7/27/2011 - TK-07144 changed bPO to varchar(30)
    *			MV 08/04/11 - TK-07233 - AP project to use POItemLine
    *			MV 09/07/11 - TK-08249 - There are two cursor fetches BOTH need the new POItemLine fields.
	*			MV 09/20/11	- TK-08578 - uncommented code to lock/unlock PO header
	*
    *	This trigger rejects update in bAPLB (Line Batch)
    *	if any of the following error conditions exist:
    *
    *		Cannot change Co
    *		Cannot change Mth
    *		Cannot change BatchId
    *		Cannot change BatchSeq
    *		Cannot change APLine
    *
    *	Also, if PO, PO Item, SL or SL Item is changed, unlock old and lock new
    *	as needed.
    *	If GL Co is changed, inserts new bHQCC entries as needed.
    */----------------------------------------------------------------
   
   declare @oldpo varchar(30), @oldpoitem bItem, @newpo varchar(30), @newpoitem bItem,
       @apco bCompany, @mth bMonth, @batchid bBatchID, @batchseq int,
       @oldsl varchar(30), @oldslitem bItem, @oldglco bCompany, @newsl varchar(30), @newslitem bItem,
       @apline smallint, @newglco bCompany, @inusemth bMonth, @inusebatchid bBatchID,
       @errmsg varchar(255), @numrows int, @validcnt int, @errstart varchar(100), @opencursor tinyint,
       @OldPOItemLine int, @NewPOItemLine int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   set @opencursor = 0
   
   -- verify primary key not changed 
   select @validcnt = count(*) from deleted d, inserted i
   where d.Co = i.Co and d.Mth = i.Mth and d.BatchId = i.BatchId
    	and d.BatchSeq = i.BatchSeq and d.APLine = i.APLine
   if @numrows <> @validcnt
       begin
    	select @errmsg = 'Cannot change Primary Key'
    	goto error
    	end
   
   
   
   Begin_Process: -- begin process
   if @numrows = 1
   BEGIN
    	select @apco=i.Co, @mth=i.Mth, @batchid=i.BatchId, @batchseq=i.BatchSeq, @apline=i.APLine, @oldpo=d.PO, 
   		   @oldpoitem=d.POItem, @oldsl=d.SL, @oldslitem=d.SLItem, @oldglco=d.GLCo, @newpo=i.PO, 
   		   @newpoitem=i.POItem, @newsl=i.SL, @newslitem=i.SLItem, @newglco=i.GLCo, 
   		   @OldPOItemLine=d.POItemLine, @NewPOItemLine=i.POItemLine
   	from deleted d join inserted i on d.Co = i.Co and d.Mth = i.Mth and d.BatchId = i.BatchId
   	and d.BatchSeq = i.BatchSeq and d.APLine = i.APLine
   END
   else
   BEGIN
   	-- use a cursor to process all updated rows
   	declare bcAPLB cursor LOCAL FAST_FORWARD for
   	SELECT	i.Co, i.Mth, i.BatchId, i.BatchSeq, i.APLine, d.PO, d.POItem, d.SL, d.SLItem, d.GLCo,
   	    	i.PO, i.POItem, i.SL, i.SLItem, i.GLCo, d.POItemLine, i.POItemLine
   	FROM deleted d 
   	JOIN inserted i on d.Co = i.Co and d.Mth = i.Mth and d.BatchId = i.BatchId and d.BatchSeq = i.BatchSeq and d.APLine = i.APLine
   
    open bcAPLB
   	select @opencursor = 1
   
   	fetch next from bcAPLB into 
   				@apco, @mth, @batchid, @batchseq, @apline, @oldpo, @oldpoitem,
   				@oldsl, @oldslitem, @oldglco, @newpo, @newpoitem, @newsl, @newslitem, @newglco,
   				@OldPOItemLine, @NewPOItemLine
   
   	if @@fetch_status <> 0
    		begin
    		select @errmsg = 'Cursor error'
    		goto error
    		end
   END
   
   
   update_check:
   --reset values for each row
   select @errstart = 'Line: ' + isnull(convert(varchar(4), @apline), '')  --#23061
  
   
   -- add entry to HQ Close Control as needed
   if not exists(select top 1 1 from bHQCC with (nolock) where Co = @apco and Mth = @mth 
   					and BatchId = @batchid and GLCo = @newglco)
   	begin
   	insert bHQCC (Co, Mth, BatchId, GLCo)
   	values (@apco, @mth, @batchid, @newglco)
   	end
   
   -- handle Purchase Orders
   if @oldpo is not null
   	begin  
   	-- unlock PO ItemLine if no longer referenced in this Batch
   	IF NOT EXISTS
   		(
   			SELECT TOP 1 1
   			FROM dbo.bAPLB WITH (nolock)
   			WHERE Co = @apco AND Mth = @mth AND BatchId = @batchid AND
   			(
   				(
   					PO = @oldpo AND POItem = @oldpoitem AND POItemLine=@OldPOItemLine
   				)
   			OR 
   				(
   					OldPO = @oldpo AND OldPOItem = @oldpoitem AND @OldPOItemLine=OldPOItemLine
   				)
   			)
   		)
   		BEGIN
   		UPDATE vPOItemLine SET InUseMth = null, InUseBatchId = null
   		WHERE POCo = @apco AND PO = @oldpo AND POItem = @oldpoitem and POItemLine=@OldPOItemLine
   		END
   	
   	-- unlock PO Item if no longer referenced in this Batch
   	if not exists(select top 1 1 from bAPLB with (nolock) where Co = @apco and Mth = @mth and BatchId = @batchid
               and ((PO = @oldpo and POItem = @oldpoitem) or (OldPO = @oldpo and OldPOItem = @oldpoitem)))
   		begin
   		update bPOIT set InUseMth = null, InUseBatchId = null
   		where POCo = @apco and PO = @oldpo and POItem = @oldpoitem
   		end
   
   	-- unlock PO Header if no longer referenced in this Batch
   	if not exists(select top 1 1 from bAPLB with (nolock) where Co = @apco and Mth = @mth and BatchId = @batchid
               	and (PO = @oldpo or OldPO = @oldpo))
   		begin
   		update bPOHD set InUseMth = null, InUseBatchId = null
   		where POCo = @apco and PO = @oldpo
   		end
   	end
   
   if @newpo is not null
   	BEGIN
   	    -- validate PO Header
   		select @inusemth = InUseMth, @inusebatchid = InUseBatchId
   		from bPOHD with (nolock) where POCo = @apco and PO = @newpo
   		if @@rowcount = 0
   			begin
   			select @errmsg = @errstart + ' Invalid PO: ' + isnull(@newpo,'')
   			goto error
   			end
	   
	   -- TK-07233 Per AP project to use POItemLine (Carillion) we are no longer going to lock POHD or POIT when in use by AP
   		--if @mth <> isnull(@inusemth,@mth) or @batchid <> isnull(@inusebatchid,@batchid)
   		--	begin
   		--	select @errmsg = @errstart + ' PO: ' + isnull(@newpo,'') + ' is already in use by Batch: '
   		--		+ isnull(convert(varchar(6),@inusebatchid), '') + ' in month ' + isnull(convert(varchar(8),@inusemth), '')  --#23061
   		--	goto error
   		--	end
	   
	   -- Lock the PO header to prevent closing the PO while in use. 
   		if @inusemth is null or @inusebatchid is null
   			begin
   			update bPOHD set InUseMth = @mth, InUseBatchId = @batchid
   			where POCo = @apco and PO = @newpo
   			if @@rowcount = 0
   				begin
   				select @errmsg = @errstart + 'Unable to lock header for PO:' + isnull(@newpo,'')
   				goto error
   				end
   			end
   
   		-- validate PO Item
   		select @inusemth = InUseMth, @inusebatchid = InUseBatchId
   		from bPOIT with (nolock)
   		where POCo = @apco and PO = @newpo and POItem = @newpoitem
   		if @@rowcount = 0
   			begin
   			select @errmsg = @errstart + 'Invalid Item: ' + isnull(convert(varchar(5),@newpoitem), '') + 
   				' on PO: ' + isnull(@newpo, '')
   			goto error
   			end
	   
		-- TK-07233 Per AP project to use POItemLine (Carillion project) we are no longer going to lock POIT when in use by AP
   		--if @mth <> isnull(@inusemth,@mth) or @batchid <> isnull(@inusebatchid,@batchid)
   		--	begin
   		--	select @errmsg = @errstart + 'PO ' + isnull(@newpo, '') + ' Item ' 
   		--		+ isnull(convert(varchar(5),@newpoitem), '') + ' is already in use by Batch Id : '
   		-- 		+ isnull(convert(varchar(6),@inusebatchid), '') + ' in month ' + isnull(convert(varchar(8),@inusemth), '') --#23061
   		--	goto error
   		--	end
	   
   		--if @inusemth is null or @inusebatchid is null
   		--	begin
   		--	update bPOIT set InUseMth = @mth, InUseBatchId = @batchid
   		--	where POCo = @apco and PO = @newpo and POItem = @newpoitem
   		--	if @@rowcount = 0
   		--		begin
   		--		select @errmsg = @errstart + 'Unable to lock Item: ' + isnull(convert(varchar(5),@newpoitem), '')  --#23061
		--                   + ' on PO: ' + @newpo
   		--		goto error
   		--		end
   		--	end
	   	
   		-- TK-07233 Validate PO Item Line and lock it
   		SELECT @inusemth = InUseMth, @inusebatchid = InUseBatchId
   		FROM dbo.vPOItemLine (NOLOCK)
   		WHERE POCo = @apco AND PO = @newpo AND POItem = @newpoitem and POItemLine = @NewPOItemLine
   		IF @@ROWCOUNT = 0
   			BEGIN
   			SELECT @errmsg = @errstart + 'Invalid Item Line: ' + ISNULL(convert(varchar(5),@NewPOItemLine), '') + 
   				' on PO: ' + isnull(@newpo, '')
   			GOTO error
   			END
   		IF @mth <> ISNULL(@inusemth,@mth) or @batchid <> ISNULL(@inusebatchid,@batchid)
   			BEGIN
   			SELECT @errmsg = @errstart + 'PO ' + ISNULL(@newpo, '') 
   				+ ' Item ' + ISNULL(CONVERT(VARCHAR(5),@newpoitem), '') 
   				+ ' ItemLine' + ISNULL(CONVERT(VARCHAR(5),@NewPOItemLine),'') + ' is already in use by Batch Id : '
   	 			+ ISNULL(CONVERT(VARCHAR(6),@inusebatchid), '') + ' in month ' + ISNULL(CONVERT(VARCHAR(8),@inusemth), '') --#23061
   			GOTO error
   			END
	   
   		IF @inusemth IS NULL OR @inusebatchid IS NULL
   			BEGIN
   			UPDATE dbo.vPOItemLine
   			SET InUseMth = @mth, InUseBatchId = @batchid
   			WHERE POCo = @apco and PO = @newpo and POItem = @newpoitem AND POItemLine=@NewPOItemLine
   			IF @@ROWCOUNT = 0
   				BEGIN
   				SELECT @errmsg = @errstart + 'Unable to lock Item: ' + ISNULL(CONVERT(VARCHAR(5),@newpoitem), '')  --#23061
						   + ' on PO: ' + @newpo
   				GOTO error
   				END
   			END
   	END -- end PO validation
   	
   
   
   -- handle Subcontracts
   if @oldsl is not null
   	begin   -- unlock SL Item if no longer referenced in this Batch
   	if not exists(select top 1 1 from bAPLB with (nolock) where Co = @apco and Mth = @mth and BatchId = @batchid
               and ((SL = @oldsl and SLItem = @oldslitem) or (OldSL = @oldsl and OldSLItem = @oldslitem)))
   		begin
   		update bSLIT set InUseMth = null, InUseBatchId = null
   		where SLCo = @apco and SL = @oldsl and SLItem = @oldslitem
   		end
   
   	-- unlock SL Header if no longer referenced in this Batch
   	if not exists(select top 1 1 from bAPLB with (nolock) where Co = @apco and Mth = @mth and BatchId = @batchid
               and (SL = @oldsl or OldSL = @oldsl))
   		begin
   		update bSLHD set InUseMth = null, InUseBatchId = null
   		where SLCo = @apco and SL = @oldsl
   		end
   	end
   
   if @newsl is not null
   	begin    -- check SL Header to see if it is already locked
   	select @inusemth = InUseMth, @inusebatchid = InUseBatchId
   	from bSLHD with (nolock) where SLCo = @apco and SL = @newsl
   	if @@rowcount = 0
   		begin
   		select @errmsg = @errstart + ' Invalid Subcontract: ' + isnull(@newsl, '')
   		goto error
   		end
   
   	if @mth <> isnull(@inusemth,@mth) or @batchid <> isnull(@inusebatchid,@batchid)
   		begin
   		select @errmsg = @errstart + ' Subcontract: ' + isnull(@newsl, '') + ' is already in use by Batch: '
   				+ isnull(convert(varchar(6),@inusebatchid), '') + ' in Month: ' 
   				+ isnull(convert(varchar(8),@inusemth), '')	--#23061
   		goto error
   		end
   
   	if @inusemth is null or @inusebatchid is null
   		begin
   		update bSLHD set InUseMth = @mth, InUseBatchId = @batchid
   		where SLCo = @apco and SL = @newsl
   		if @@rowcount = 0
   			begin
   			select @errmsg = @errstart + 'Unable to lock header for Subcontract:' + isnull(@newsl, '') --#23061
   			goto error
   			end
   		end
   
   	-- validate SL Item
   	select @inusemth = InUseMth, @inusebatchid = InUseBatchId
   	from bSLIT with (nolock)
   	where SLCo = @apco and SL = @newsl and SLItem = @newslitem
   	if @@rowcount = 0
   		begin
   		select @errmsg = @errstart + 'Invalid Item: ' + isnull(convert(varchar(5),@newslitem), '')
                   + ' on Subcontract: ' + isnull(@newsl, '')
   		goto error
   		end
   
   	if @mth <> isnull(@inusemth,@mth) or @batchid <> isnull(@inusebatchid,@batchid)
   		begin
   		select @errmsg = @errstart + 'Subcontract ' + isnull(@newsl, '') + ' Item ' 
   		+ isnull(convert(varchar(5),@newslitem), '') + ' is already in use by Batch: ' 
   		+ isnull(convert(varchar(6),@inusebatchid), '') + ' in Month: ' + isnull(convert(varchar(8),@inusemth), '') --#23061
   		goto error
   		end
   
   	if @inusemth is null or @inusebatchid is null
   		begin
   		update bSLIT set InUseMth = @mth, InUseBatchId = @batchid
   		where SLCo = @apco and SL = @newsl and SLItem = @newslitem
   		if @@rowcount = 0
   			begin
   			select @errmsg = @errstart + 'Unable to lock Item: ' + isnull(convert(varchar(5),@newslitem), '') 
                       + ' on Subcontract: ' + isnull(@newsl, '') -- #23061
   			goto error
   			end
   		end
   	end
   
   
   -- finished with validation and updates (except HQ Audit)
   Valid_Finished:
   if @numrows > 1
   	begin
   	fetch next from bcAPLB into @apco, @mth, @batchid, @batchseq, @apline, @oldpo, @oldpoitem,
   				@oldsl, @oldslitem, @oldglco, @newpo, @newpoitem, @newsl, @newslitem, @newglco,
   				@OldPOItemLine, @NewPOItemLine
    	if @@fetch_status = 0
    		goto update_check
    	else
    		begin
    		close bcAPLB
    		deallocate bcAPLB
   		set @opencursor = 0
    		end
    	end
   
   return
   
   
   
   error:
       if @opencursor = 1
           begin
           close bcAPLB
           deallocate bcAPLB
           end
    	select @errmsg = @errmsg + ' - cannot update AP Line Batch!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biAPLB] ON [dbo].[bAPLB] ([Co], [Mth], [BatchId], [BatchSeq], [APLine]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_bAPLB_SLDetailKeyID] ON [dbo].[bAPLB] ([SLDetailKeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_bAPLB_SLKeyID] ON [dbo].[bAPLB] ([SLKeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bAPLB].[UnitCost]'
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bAPLB].[ECM]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPLB].[MiscYN]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bAPLB].[BurUnitCost]'
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bAPLB].[BECM]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bAPLB].[SMChange]'
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bAPLB].[OldECM]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPLB].[OldMiscYN]'
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bAPLB].[OldBECM]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPLB].[PaidYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPLB].[POPayTypeYN]'
GO
