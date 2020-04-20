CREATE TABLE [dbo].[vPOItemLine]
(
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[POITKeyID] [bigint] NOT NULL,
[POCo] [dbo].[bCompany] NOT NULL,
[PO] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[POItem] [dbo].[bItem] NOT NULL,
[POItemLine] [int] NOT NULL,
[ItemType] [tinyint] NOT NULL,
[PostToCo] [dbo].[bCompany] NOT NULL,
[JCCo] [dbo].[bCompany] NULL,
[Job] [dbo].[bJob] NULL,
[PhaseGroup] [dbo].[bGroup] NULL,
[Phase] [dbo].[bPhase] NULL,
[JCCType] [dbo].[bJCCType] NULL,
[INCo] [dbo].[bCompany] NULL,
[Loc] [dbo].[bLoc] NULL,
[EMCo] [dbo].[bCompany] NULL,
[EMGroup] [dbo].[bGroup] NULL,
[Equip] [dbo].[bEquip] NULL,
[CompType] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Component] [dbo].[bEquip] NULL,
[CostCode] [dbo].[bCostCode] NULL,
[EMCType] [dbo].[bEMCType] NULL,
[WO] [dbo].[bWO] NULL,
[WOItem] [dbo].[bItem] NULL,
[SMCo] [dbo].[bCompany] NULL,
[SMWorkOrder] [int] NULL,
[SMWorkCompleted] [int] NULL,
[SMScope] [int] NULL,
[TaxGroup] [dbo].[bGroup] NULL,
[TaxType] [tinyint] NULL,
[TaxCode] [dbo].[bTaxCode] NULL,
[TaxRate] [dbo].[bRate] NOT NULL CONSTRAINT [DF_vPOItemLine_TaxRate] DEFAULT ((0)),
[GSTRate] [dbo].[bRate] NOT NULL CONSTRAINT [DF_vPOItemLine_GSTRate] DEFAULT ((0)),
[GLCo] [dbo].[bCompany] NOT NULL,
[GLAcct] [dbo].[bGLAcct] NOT NULL,
[ReqDate] [dbo].[bDate] NULL,
[PayCategory] [int] NULL,
[PayType] [tinyint] NULL,
[OrigUnits] [dbo].[bUnits] NOT NULL CONSTRAINT [DF_vPOItemLine_OrigUnits] DEFAULT ((0)),
[OrigCost] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_vPOItemLine_OrigCost] DEFAULT ((0)),
[OrigTax] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_vPOItemLine_OrigTax] DEFAULT ((0)),
[CurUnits] [dbo].[bUnits] NOT NULL CONSTRAINT [DF_vPOItemLine_CurUnits] DEFAULT ((0)),
[CurCost] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_vPOItemLine_CurCost] DEFAULT ((0)),
[CurTax] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_vPOItemLine_CurTax] DEFAULT ((0)),
[RecvdUnits] [dbo].[bUnits] NOT NULL CONSTRAINT [DF_vPOItemLine_RecvdUnits] DEFAULT ((0)),
[RecvdCost] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_vPOItemLine_RecvdCost] DEFAULT ((0)),
[BOUnits] [dbo].[bUnits] NOT NULL CONSTRAINT [DF_vPOItemLine_BOUnits] DEFAULT ((0)),
[BOCost] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_vPOItemLine_BOCost] DEFAULT ((0)),
[InvUnits] [dbo].[bUnits] NOT NULL CONSTRAINT [DF_vPOItemLine_InvUnits] DEFAULT ((0)),
[InvCost] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_vPOItemLine_InvCost] DEFAULT ((0)),
[InvTax] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_vPOItemLine_InvTax] DEFAULT ((0)),
[InvMiscAmt] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_vPOItemLine_InvMiscAmt] DEFAULT ((0)),
[RemUnits] [dbo].[bUnits] NOT NULL CONSTRAINT [DF_vPOItemLine_RemUnits] DEFAULT ((0)),
[RemCost] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_vPOItemLine_RemCost] DEFAULT ((0)),
[RemTax] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_vPOItemLine_RemTax] DEFAULT ((0)),
[JCCmtdTax] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_vPOItemLine_JCCmtdTax] DEFAULT ((0)),
[JCRemCmtdTax] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_vPOItemLine_JCRemCmtdTax] DEFAULT ((0)),
[TotalUnits] [dbo].[bUnits] NOT NULL CONSTRAINT [DF_vPOItemLine_TotalUnits] DEFAULT ((0)),
[TotalCost] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_vPOItemLine_TotalCost] DEFAULT ((0)),
[TotalTax] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_vPOItemLine_TotalTax] DEFAULT ((0)),
[PostedDate] [dbo].[bDate] NOT NULL,
[JCMonth] [dbo].[bMonth] NULL,
[InUseMth] [dbo].[bMonth] NULL,
[InUseBatchId] [dbo].[bBatchID] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[PurgeYN] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_vPOItemLine_PurgeYN] DEFAULT ('N'),
[LineDelete] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_vPOItemLine_LineDelete] DEFAULT ('N'),
[UniqueAttchID] [uniqueidentifier] NULL,
[SMPhaseGroup] [dbo].[bGroup] NULL,
[SMPhase] [dbo].[bPhase] NULL,
[SMJCCostType] [dbo].[bJCCType] NULL,
[udCGC_ASQ02] [numeric] (18, 0) NULL,
[udConv] [dbo].[bYN] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



/****** Object:  Trigger dbo.vtPOItemLined ******/
CREATE trigger [dbo].[vtPOItemLined] on [dbo].[vPOItemLine] for DELETE as  

/*--------------------------------------------------------------
* Created By:	GF 08/04/2011 TK-07440
* Modified By:	GF 01/22/2012 TK-11964 #145600 using wrong phase for update
*		DAN SO 04/20/2012 TK-14139 - Committed costs for SM PO w/job
*		GF 05/17/2012 TK-14983
*
*
* Delete trigger for PO Item Distribution Lines
*
* The delete validation is from the item delete trigger for now.
* 
* When the line being deleted is line 1, then we are deleting the item
* and nothing else needs to be done.
* 
* When the line being deleted is not line 1, then we will need to reverse
* the distributions (IN,JC) for the line(s) being deleted. We then need
* to update line 1 with the units and amount so that the values foot to
* the item values.
*
* Reversing distributions for line(s) other than 1 will be handled here.
* Line 1 Units and Amount update will happen here, with the update trigger
* handle line 1 updates.
*
*--------------------------------------------------------------*/
declare @numrows INT, @validcnt INT, @ErrMsg VARCHAR(255), @opencursor INT,
		@rcode INT, @POLineKeyID BIGINT, @POITKeyID BIGINT, @Month bMonth,
		@PurgeYN CHAR(1), @POPurge CHAR(1), @POItemLine INT, @GLCo bCompany,
		@ItemType TINYINT, @POCo bCompany, @PO VARCHAR(30), @POItem bItem,
		@UM bUM, @CurUnitCost bUnitCost, @CurECM bECM, @Description bItemDesc,
		@MatlGroup bGroup, @Material bMatl, @PostToCo bCompany, @Location bLoc,
		@TaxGroup bGroup, @TaxType TINYINT, @TaxCode bTaxCode, @PostedDate bDate,
		@PhaseGroup bGroup, @Job bJob, @Phase bPhase, @JCCType bJCCType,
		@TaxRate bRate, @GSTRate bRate, @CurUnits bUnits, @CurCost bDollar,
		@CurTax bDollar, @BOUnits bUnits, @BOCost bDollar, @RemUnits bUnits,
		@RemCost bDollar, @RemTax bDollar, @TotalUnits bUnits,
		@TotalCost bDollar, @TotalTax bDollar, @JCCmtdTax bDollar,
		@JCRemCmtdTax bDollar, @JCUM bUM, @JCUMConv bUnitCost, @StdUM bUM,
		@UMConv bUnitCost, @HQMatl CHAR(1), @TaxPhase bPhase, @TaxCT bJCCType,
		@TaxJCUM bUM, @JCTransType VARCHAR(10), @OldCmtdRemCost bDollar,
		@OldCmtdRemUnits bDollar
		-----TK-14983
		,@AddedMth bMonth,
  		-- TK-14139 --
  		@SMJob bJob, @SMPhaseGroup bGroup, @SMPhase bPhase, @SMJCCostType bJCCType, @SMJobExistsYN bYN,
  		@SMCo bCompany, @SMWorkOrder int, @SMWorkCompleted int, @SMScope int

		
select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

SET @PostedDate = dbo.vfDateOnly()

---- the first distribution line is the item distribution
---- and cannot be deleted if we are not purging the PO
---- via PO Purge or deleting the PO Item via POHB Post.
IF EXISTS(SELECT 1 FROM DELETED d 
	JOIN dbo.bPOHD h ON h.POCo=d.POCo AND h.PO=d.PO
	WHERE d.POItemLine = 1 AND h.Purge = 'N' AND d.PurgeYN = 'N')
        begin
        select @ErrMsg = 'The first PO Item Distribution line cannot be deleted.'
        goto Error
        end

---- Purge = 'N' check for open or pending PO
IF EXISTS(SELECT 1 FROM DELETED d
	JOIN dbo.bPOHD h ON h.POCo=d.POCo AND h.PO=d.PO and h.Status not in (0,3)
	WHERE h.Purge = 'N')
        BEGIN
        SELECT @ErrMsg = 'Purchase Order must be Open or Pending'
        GOTO Error
        END
			
---- Purge = 'N' or 'Y' - Received must match Invoiced
IF EXISTS(SELECT 1 FROM	 DELETED d
	JOIN dbo.bPOIT i ON i.POCo=d.POCo AND i.PO=d.PO AND i.POItem=d.POItem
	WHERE (i.UM = 'LS' AND d.RecvdCost <> d.InvCost)
			OR (i.UM <> 'LS' AND d.RecvdUnits <> d.InvUnits))
        BEGIN
        SELECT @ErrMsg = 'Invoiced must equal Received.'
        GOTO Error
        END
    
---- Purge = 'Y' - Remaining must equal 0.00
IF EXISTS(SELECT 1 from DELETED d
	JOIN dbo.bPOHD h on d.POCo=h.POCo and d.PO=h.PO
	WHERE (d.RemUnits <> 0 OR d.RemCost <> 0) AND h.Purge = 'Y')
        BEGIN
        SELECT @ErrMsg = 'Remaining units and costs must be 0.00 '
        GOTO Error
        END

---- Purge = 'N' check for Receipt Detail
IF EXISTS(SELECT 1 FROM DELETED d
	join dbo.bPORD c on d.POCo = c.POCo and d.PO = c.PO and d.POItem = c.POItem AND c.POItemLine = d.POItemLine
	join dbo.bPOHD h on d.POCo=h.POCo and d.PO=h.PO
   	where h.Purge = 'N' OR d.PurgeYN = 'N')
        begin
        select @ErrMsg = 'Receipt Detail exists.'
        goto Error
        end

---- Purge = 'N' check Change Detail
if exists(select 1 from DELETED d
	join dbo.bPOCD c on d.POCo = c.POCo and d.PO = c.PO and d.POItem = c.POItem
	join dbo.bPOHD h on d.POCo=h.POCo and d.PO=h.PO
   	where d.POItemLine = 1 AND (h.Purge = 'N' OR d.PurgeYN = 'N'))
        BEGIN
        select @ErrMsg = 'Change Detail exists '
        goto Error
        END

---- check AP unapproved invoices
IF EXISTS(SELECT 1 FROM DELETED d
	JOIN dbo.bAPUL c ON d.POCo = c.APCo AND d.PO = c.PO and d.POItem = c.POItem AND d.POItemLine = c.POItemLine
	JOIN dbo.bPOHD h on d.POCo=h.POCo and d.PO=h.PO
	WHERE h.Purge = 'N' OR d.PurgeYN = 'N')
        BEGIN
        SELECT @ErrMsg = 'Unapproved Invoice exists for PO Item Line ' 
        GOTO Error
        END
		




---- cursor for item lines to update POIT information 
---- we will update the total columns in POIT for line 1 only which represents the item values.
---- additional lines (2 and greater) will adjust line 1 so that the values foot to the item totals.
if @numrows = 1
	BEGIN
  	SELECT  @POLineKeyID = d.KeyID, @POITKeyID = d.POITKeyID
	FROM DELETED d
	END
ELSE
	BEGIN
	-- use a cursor to update Total and Remaining values
	DECLARE vcPOItemLine_Delete CURSOR FOR SELECT d.KeyID, d.POITKeyID
	FROM DELETED d

	OPEN vcPOItemLine_Delete
	SET @opencursor = 1

	-- get 1st Item inserted
	FETCH NEXT FROM vcPOItemLine_Delete INTO @POLineKeyID, @POITKeyID
	if @@fetch_status <> 0
		BEGIN
		SET @ErrMsg = 'Cursor Error '
		goto Error
		END
	END



POItemLine_Loop:
---- get line data
SELECT  @POCo = d.POCo, @PostToCo = d.PostToCo, @PO = d.PO, @POItem = d.POItem,
		@POItemLine = d.POItemLine, @PurgeYN = d.PurgeYN, @ItemType = d.ItemType,
		@TaxGroup = d.TaxGroup, @TaxType = d.TaxType, @TaxCode = d.TaxCode,
		@Location = d.Loc, @GLCo = d.GLCo, @PhaseGroup = d.PhaseGroup,
		@Job = d.Job, @Phase = d.Phase, @JCCType = d.JCCType,
		@TaxRate = d.TaxRate, @GSTRate = d.GSTRate, 
		@CurUnits = d.CurUnits, @CurCost = d.CurCost, @CurTax = d.CurTax,
		@BOUnits = d.BOUnits, @BOCost = d.BOCost, @RemUnits = d.RemUnits,
		@RemCost = d.RemCost, @RemTax = d.RemTax, @TotalUnits = d.TotalUnits,
		@TotalCost = d.TotalCost, @TotalTax = d.TotalTax, 
		@JCCmtdTax = d.JCCmtdTax, @JCRemCmtdTax = d.JCRemCmtdTax,
		@Month = d.JCMonth,
  		-- TK-14139 --
  		@SMPhaseGroup = d.SMPhaseGroup, @SMPhase = d.SMPhase, @SMJCCostType = d.SMJCCostType,
  		@SMCo = d.SMCo, @SMWorkOrder = d.SMWorkOrder, @SMWorkCompleted = d.SMWorkCompleted, @SMScope = d.SMScope 
FROM DELETED d
WHERE d.KeyID = @POLineKeyID
IF @@ROWCOUNT = 0
	BEGIN
    SELECT @ErrMsg = 'Error retrieving line record information.'
    GOTO Error
    END
    
    
---- get item data
SELECT  @UM = i.UM, @CurUnitCost = i.CurUnitCost, @CurECM = i.CurECM,
		@MatlGroup = i.MatlGroup, @Material = i.Material, @Description = i.Description
		----TK-14983
		,@AddedMth = AddedMth
FROM dbo.bPOIT i
WHERE i.KeyID = @POITKeyID
IF @@ROWCOUNT = 0
	BEGIN
    SELECT @ErrMsg = 'Error retrieving item record information.'
    GOTO Error
    END
    

---- get PO data
SELECT @POPurge = p.Purge
FROM dbo.bPOHD p
WHERE p.POCo = @POCo AND p.PO = @PO
IF @@ROWCOUNT = 0 SET @POPurge = 'N'

----TK-14983
IF ISNULL(@Month,'') = '' SET @Month = @AddedMth
---- Month used for GL and JC distributions.
IF ISNULL(@Month,'') = ''
	BEGIN
	SET @Month = dbo.vfDateOnlyMonth()
	END
	
---- if ItemType = 2 inventory update INMT On Order for location material
IF @ItemType = 2 AND @CurUnits <> 0 AND @POPurge = 'N'
	BEGIN
	----TK-11964
	IF ISNULL(@Material,'') <> '' AND @POItemLine > 1
		BEGIN
		EXEC @rcode = dbo.vspPOINMTUpdateOnOrder @MatlGroup, @Material, @UM, 
						@PostToCo, @Location, @CurUnits, 'OLD', @ErrMsg OUTPUT
		if @rcode <> 0 GOTO Error
		END
	END


---- if Itemtype = 1 job create JCCD distributions to update committed cost 
IF @ItemType = 1 AND @POPurge = 'N'
	BEGIN
	---- validate job
	EXEC @rcode = dbo.bspJobTypeVal @PostToCo, @PhaseGroup, @Job, @Phase, @JCCType,
						@JCUM OUTPUT, @ErrMsg OUTPUT
	if @rcode <> 0
		BEGIN
		SELECT @ErrMsg = ISNULL(@ErrMsg,'')
		GOTO Error
		END

	---- GET JCUM Conversion Factor
	EXEC @rcode = dbo.vspPOItemLineJCUMConvGet @MatlGroup, @Material, @UM, @JCUM,
						@JCUMConv OUTPUT, @ErrMsg OUTPUT
	if @rcode <> 0
		BEGIN
		SELECT @ErrMsg = ISNULL(@ErrMsg,'')
		GOTO Error
		END
		
	---- initialize tax variables
	SET @TaxPhase = NULL
	SET @TaxCT = NULL
	SET @TaxJCUM = NULL

	---- validate tax code if item type = 1-Job will also validate tax phase and cost type
	IF ISNULL(@TaxCode,'') <> ''
		BEGIN
		EXEC @rcode = dbo.vspPOItemLineTaxCodeVal @PostToCo, @Job, @PhaseGroup, @Phase, @JCCType, @ItemType,
							@TaxGroup, @TaxType, @TaxCode, @TaxPhase OUTPUT, @TaxCT OUTPUT, @TaxJCUM OUTPUT,
							@ErrMsg OUTPUT
		IF @rcode <> 0
			BEGIN
			SELECT @ErrMsg = ISNULL(@ErrMsg,'')
			GOTO Error
			END
		END
		
	---- check tax phase cost type
	IF ISNULL(@TaxPhase,'') = '' SET @TaxPhase = @Phase
	IF ISNULL(@TaxCT,0) = 0 SET @TaxCT = @JCCType

	SET @JCTransType = 'PO Entry'
	SET @OldCmtdRemCost = 0
	SET @OldCmtdRemUnits = 0
	IF @POItemLine > 1 SET @JCTransType = 'PO Dist'
	
	---- generate JC committed cost transactions for 'OLD' values
	EXEC @rcode = dbo.vspPOItemLineJCCmtdCostUpdate 'OLD', @Month, @PostToCo, @Job, @PhaseGroup,
					@Phase, @JCCType, @POItemLine, @JCUM, @PostedDate, @TaxGroup, @TaxType,
					@TaxCode, @TaxPhase, @TaxCT, @TaxJCUM, @POITKeyID, @JCUMConv,
					@CurUnits, @CurCost, @CurTax, @RemTax, @JCCmtdTax, @JCRemCmtdTax,
					@OldCmtdRemCost, @OldCmtdRemUnits, @JCTransType, 
					-- TK-14139 --
					NULL, NULL, NULL,
					@ErrMsg OUTPUT
	IF @rcode <> 0 GOTO Error
		
	END
	

----------------------
-- TK-14139 -- START
--------------
---- if Itemtype = 6 SM PO w/Job create JCCD distributions to update committed cost 
IF @ItemType = 6
BEGIN
	IF @POPurge = 'N'
	BEGIN

		-- GET SM JOB --
		SELECT  @SMJob = Job,
				@SMJobExistsYN = CASE
									WHEN Job IS NOT NULL THEN 'Y'
									ELSE 'N'
									END
		  FROM  dbo.vSMWorkOrderScope 
		 WHERE  SMCo = @PostToCo AND WorkOrder = @SMWorkOrder AND Scope = @SMScope 

		IF @SMJobExistsYN = 'Y'
			BEGIN
			
				-- VALIDATE JOB --
				EXEC @rcode = dbo.bspJobTypeVal @PostToCo, @SMPhaseGroup, @SMJob, @SMPhase, @SMJCCostType,
									@JCUM OUTPUT, @ErrMsg OUTPUT
				IF @rcode <> 0
					BEGIN
						SET @ErrMsg = ISNULL(@ErrMsg,'')
						GOTO Error
					END

				-- GET JCUM CONVERSION FACTOR --
				EXEC @rcode = dbo.vspPOItemLineJCUMConvGet @MatlGroup, @Material, @UM, @JCUM,
									@JCUMConv OUTPUT, @ErrMsg OUTPUT
				IF @rcode <> 0
					BEGIN
						SET @ErrMsg = ISNULL(@ErrMsg,'')
						GOTO Error
					END
					
				-- INIT TAX VARIABLES --
				SET @TaxPhase = NULL
				SET @TaxCT = NULL
				SET @TaxJCUM = NULL

				-- VALIDATE TAX CODE, INCLUDES TAX PHASE AND COST TYPE VALIDATION --
				IF ISNULL(@TaxCode,'') <> ''
					BEGIN
						EXEC @rcode = dbo.vspPOItemLineTaxCodeVal @PostToCo, @SMJob, @SMPhaseGroup, 
										@SMPhase, @SMJCCostType, @ItemType, @TaxGroup, @TaxType, @TaxCode, 
										@TaxPhase OUTPUT, @TaxCT OUTPUT, @TaxJCUM OUTPUT, @ErrMsg OUTPUT
						IF @rcode <> 0
							BEGIN
								SET @ErrMsg = ISNULL(@ErrMsg,'')
								GOTO Error
							END
					END
					
				-- CHECK TAX PHASE AND COSTTYPE
				IF ISNULL(@TaxPhase,'') = '' SET @TaxPhase = @SMPhase
				IF ISNULL(@TaxCT,0) = 0 SET @TaxCT = @SMJCCostType
				
				SET @JCTransType = 'PO Entry'
				SET @OldCmtdRemCost = 0
				SET @OldCmtdRemUnits = 0
				IF @POItemLine > 1 SET @JCTransType = 'PO Dist'
				
				---- generate JC committed cost transactions for 'OLD' values
				EXEC @rcode = dbo.vspPOItemLineJCCmtdCostUpdate 'OLD', @Month, @PostToCo, @SMJob, @SMPhaseGroup,
								@SMPhase, @SMJCCostType, @POItemLine, @JCUM, @PostedDate, @TaxGroup, @TaxType,
								@TaxCode, @TaxPhase, @TaxCT, @TaxJCUM, @POITKeyID, @JCUMConv,
								@CurUnits, @CurCost, @CurTax, @RemTax, @JCCmtdTax, @JCRemCmtdTax,
								@OldCmtdRemCost, @OldCmtdRemUnits, @JCTransType, 
								-- TK-14139 --
								@SMCo, @SMWorkOrder, @SMScope,
								@ErrMsg OUTPUT
				IF @rcode <> 0 GOTO Error
				
			END -- @SMJobExistsYN
	END --@POPurge = 'N'

	EXEC @rcode = dbo.vspSMWorkCompletedPurchaseUpdate @POCo = @POCo, @PO = @PO, @POItem = @POItem, @POItemLine = @POItemLine, @OldSMCo = @SMCo, @OldWorkOrder = @SMWorkOrder, @OldScope = @SMScope, @OldWorkCompleted = @SMWorkCompleted, @msg = @ErrMsg OUTPUT
	IF @rcode <> 0 GOTO Error
END -- @ItemType = 6
--------------
-- TK-14139 -- END
--------------



	
---- when line 1 is deleted we are done because the item is being deleted.
---- if not line 1 then we need to update line 1 to add back the current quantity
---- and current amount so that the line totals will foot to the item
---- update trigger will handle line 1 distributions and item totals
IF @POItemLine > 1 AND @POPurge = 'N' AND @PurgeYN = 'N'
	BEGIN
	UPDATE dbo.vPOItemLine
			SET JCMonth		= @Month,
				CurUnits	= CurUnits + @CurUnits,
				CurCost		= CurCost + @CurCost,
				LineDelete	= 'Y'
	WHERE POITKeyID = @POITKeyID
		AND POItemLine = 1
	IF @@ROWCOUNT = 0
		BEGIN
		SELECT @ErrMsg = 'Missing Line 1 for PO: ' + ISNULL(@PO,'') + ' PO Item: ' + ISNULL(CONVERT(VARCHAR(10),@POItem),'')
		GOTO Error
		END
	END
	



if @numrows > 1
	BEGIN
	FETCH NEXT FROM vcPOItemLine_Delete INTO @POLineKeyID, @POITKeyID

	if @@fetch_status = 0 goto POItemLine_Loop

	CLOSE vcPOItemLine_Delete
	DEALLOCATE vcPOItemLine_Delete
	SET @opencursor = 0
	END






---- HQ Auditing
insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'vPOItemLine',  'PO:' + d.PO + ' POItem:' + CONVERT(VARCHAR(10),d.POItem) + ' POItemLine:' + CONVERT(VARCHAR(10),d.POItemLine),
		d.POCo, 'D', null, null, null, getdate(), SUSER_SNAME()
from deleted d
join dbo.bPOCO c on d.POCo = c.POCo
join dbo.bPOHD h on d.POCo = h.POCo and d.PO = h.PO
---- check audit and purge flags
where c.AuditPOs = 'Y' and h.Purge = 'N' 




return




Error:
	select @ErrMsg = isnull(@ErrMsg,'') + ' - cannot delete PO Item Distribution Line'
	RAISERROR(@ErrMsg, 11, -1);
	rollback transaction



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



/****** Object:  Trigger dbo.vtPOItemLinei    Script Date: 8/28/99 9:38:07 AM ******/   
CREATE trigger [dbo].[vtPOItemLinei] on [dbo].[vPOItemLine] for INSERT as
/*--------------------------------------------------------------
* Created By:	GF 08/12/2011 TK-07438 TK-07439 TK-07440
* Modified:		JG 09/23/2011 TK-08142 - Add a SMPOItemLine record when ItemType is 6.
*				MH 10/03/2011 TK-08742 - Corrected parameter list for call to vspSMModifySMPOItemLine
*				GF 10/20/2011 TK-09213 GL Sub Type for S - Service
*				GF 01/22/2012 TK-11964 #145600 using wrong phase for update
*				DAN SO 04/20/2012 TK-14139 - Committed costs for SM PO w/job
*				GF 05/17/2012 TK-14983
*
* Insert trigger on vPOItemLine - PO Item Distribution Lines
*
* Job Cost and Inventory distributions will be created for all lines
* of the correct type. The Line values for CurTax, TotalUnits, TotalCost,
* TotalTax, RemUnits, RemCost, RemTax, JCCmtdTax, JCRemCmtdTax will
* be calculated for the line and the line updated. If the line is not
* line one (item line) we will update line one units and amount deduction
* the values so that the line will foot to the item totals. The update
* trigger will handle this.
*
* The month for JC Distributions will be the JC Cost Month column and will
* will be populated when lines are added. For Line one will be set during
* post processes and will equal the batch month.
*
*
*--------------------------------------------------------------*/
declare @numrows INT, @validcnt INT, @validcnt2 INT, @ErrMsg VARCHAR(255),
		@rcode INT, @opencursor INT, @POITKeyID BIGINT, @POItemLine INT, @ItemType TINYINT,
		@POCo bCompany, @PO VARCHAR(30), @POItem bItem, @UM bUM, @CurUnitCost bUnitCost,
		@CurECM bECM, @TaxGroup bGroup, @TaxCode bTaxCode, @GLCo bCompany, @GLAcct bGLAcct,
		@AcctType CHAR(1), @WO bWO, @WOItem bItem, @Equip bEquip, @CompType VARCHAR(10),
		@Component bEquip, @CostCode bCostCode, @EMGroup bGroup, @EMCType bEMCType,
		@PhaseGroup bGroup, @Job bJob, @Phase bPhase, @JCCType bJCCType, @JCUM bUM,
  		@JCUMConv bUnitCost, @StdUM bUM, @UMConv bUnitCost, @HQMatl CHAR(1), @SMWorkOrder INT,
  		@SMScope INT, @WOStatus TINYINT, @PayType TINYINT, @PayCategory INT,
  		@Month bMonth, @RecvdUnits bUnits, @RecvdCost bDollar, @BOUnits bUnits,
  		@BOCost bDollar, @InvUnits bUnits, @InvCost bDollar, @TaxRate bRate, @GSTRate bRate,
  		@Factor SMALLINT, @TotalUnits bUnits, @RemUnits bUnits, @TotalCost bDollar,
  		@RemCost bDollar, @TotalTax bDollar, @RemTax bDollar, @ValueAdd bYN, @PSTRate bRate,
  		@GSTTaxAmt bDollar, @HQTXdebtGLAcct bGLAcct, @JCCmtdTax bDollar, @JCRemCmtdTax bDollar,
  		@PostedDate bDate, @POLineKeyID BIGINT, @MatlGroup bGroup, @Material bMatl,
  		@PostToCo bCompany, @Location bLoc, @CurUnits bUnits, @CurCost bDollar,
  		@TaxPhase bPhase, @TaxCT bJCCType, @TaxJCUM bUM, @TaxType TINYINT,
  		@JCTrans bTrans, @Description bItemDesc, @ErrorStart VARCHAR(255),
  		@CmtdUnits bUnits, @CmtdCost bDollar, @CmtdRemUnits bUnits,
  		@CmtdRemCost bDollar, @JCTransType VARCHAR(10), @OldCmtdRemCost bDollar,
  		@OldCmtdRemUnits bUnits
  		----TK-14983
  		,@AddedMth bMonth,
  		@SMJob bJob, @SMPhaseGroup bGroup, @SMPhase bPhase, @SMJCCostType bJCCType, 
  		@SMCo bCompany, @SMJobExistsYN bYN
  		

SELECT @numrows = @@rowcount
IF @numrows = 0 RETURN

SET NOCOUNT ON

SET @opencursor = 0
SET @SMJobExistsYN = 'N'	--  TK-14139 --

---- validate PO
select @validcnt = count(*)
from dbo.bPOHD r with (nolock) JOIN inserted i ON i.POCo = r.POCo and i.PO = r.PO
if @validcnt <> @numrows
	BEGIN
	select @ErrMsg = 'PO is Invalid.'
	goto Error
	END

---- ALL VALIDATION WILL BE FOR LINES > 1.
---- WE ARE ASSUMING LINE 1 IS HANDLED IN BATCH VALIDATION

---- make sure 'LS' Items have 0.00 units and unit costs
if exists(select 1 from inserted i
	JOIN dbo.bPOIT t ON t.POCo=i.POCo AND t.PO=i.PO AND t.POItem=i.POItem
	WHERE t.UM = 'LS' AND i.POItemLine > 1 AND (i.CurUnits <> 0 OR t.CurUnitCost <> 0))
        begin
        select @ErrMsg = 'Lump sum PO Item Lines must have 0.00 Units and Unit Cost.'
        goto Error
        END

---- make sure 'LS' item lines have current cost
IF EXISTS(SELECT 1 FROM INSERTED i
	JOIN dbo.bPOIT t ON t.POCo=i.POCo AND t.PO=i.PO AND t.POItem=i.POItem
	WHERE t.UM = 'LS' AND i.POItemLine > 1 and i.CurCost = 0)
        begin
        select @ErrMsg = 'Lump sum PO Item Lines must have an amount.'
        goto Error
        END
        
---- make sure non 'LS' item lines have units
IF EXISTS(SELECT 1 FROM INSERTED i
	JOIN dbo.bPOIT t ON t.POCo=i.POCo AND t.PO=i.PO AND t.POItem=i.POItem
	WHERE t.UM <> 'LS' AND i.POItemLine > 1 and i.CurUnits = 0)
	BEGIN
	SET @ErrMsg = 'Non Lump Sum Item Lines must have units.'
    GOTO Error
    END
        
---- make sure unit based Item Lines have 0.00 Recvd and BO Costs
if exists(select 1 from inserted i
	JOIN dbo.bPOIT t ON t.POCo=i.POCo AND t.PO=i.PO AND t.POItem=i.POItem
	WHERE t.UM = 'LS' AND i.POItemLine > 1 AND (i.RecvdCost <> 0 or i.BOCost <> 0))
        begin
        select @ErrMsg = 'Lump Sum unit based PO Item Distribution lines must have zero Received and Backordered Costs.'
        goto Error
        end

---- Check Job Line type PostToCo = JCCo
if exists(select 1 from inserted Where ItemType = 1 and PostToCo <> JCCo) 
	BEGIN
	SET @ErrMsg = 'PostToCo and JCCo are not in sync '
	goto Error
	END

--Check Job Line type PostToCo = INCo
if exists(select 1 from inserted Where ItemType = 2 and PostToCo <> INCo) 
	BEGIN
	SET @ErrMsg = 'PostToCo and INCo are not in sync '
	goto Error
	END

--Check Job Line type PostToCo = EMCo
if exists(select 1 from inserted Where ItemType IN (4,5) and PostToCo <> EMCo) 
	BEGIN
	SET @ErrMsg = 'PostToCo and EMCo are not in sync '
	goto Error
	END

--Check SM Line type PostToCo = SMCo
if exists(select 1 from inserted Where ItemType = 6 and PostToCo <> SMCo) 
	BEGIN
	SET @ErrMsg = 'PostToCo and SMCo are not in sync '
	goto Error
	END

---- validate pay category
SELECT @validcnt  = count(*) FROM dbo.bAPPC c JOIN INSERTED i ON i.POCo = c.APCo AND i.PayCategory = c.PayCategory
SELECT @validcnt2 = count(*) from INSERTED i where i.PayCategory IS NULL
IF @validcnt + @validcnt2 <> @numrows
   	BEGIN
   	SET @ErrMsg = 'Pay Code is Invalid '
   	GOTO Error
   	END

---- validate pay type
SELECT @validcnt  = count(*) FROM dbo.bAPPT c JOIN INSERTED i ON i.POCo = c.APCo AND i.PayType = c.PayType
SELECT @validcnt2 = count(*) from INSERTED i where i.PayType IS NULL
IF @validcnt + @validcnt2 <> @numrows
   	BEGIN
   	SET @ErrMsg = 'Pay Type is Invalid '
   	GOTO Error
   	END

---- verify we have a PhaseGroup for Job Item Type
IF EXISTS(SELECT 1 FROM INSERTED i WHERE i.ItemType = 1 AND i.PhaseGroup IS NULL)
	BEGIN
   	SET @ErrMsg = 'Missing Phase Group for Item Type - 1 Job '
   	GOTO Error
   	END

---- verify we have a TaxGroup when a TaxCode exists
IF EXISTS(SELECT 1 FROM INSERTED i WHERE ISNULL(i.TaxCode,'') <> '' AND i.TaxGroup IS NULL)
	BEGIN
   	SET @ErrMsg = 'Missing Tax Group '
   	GOTO Error
   	END

---- verify we have a TaxType when a TaxCode exists
IF EXISTS(SELECT 1 FROM INSERTED i WHERE ISNULL(i.TaxCode,'') <> '' AND i.TaxType IS NULL)
	BEGIN
   	SET @ErrMsg = 'Missing Tax Type '
   	GOTO Error
   	END		

---- cursor for item lines to update POIT information 
---- we will update the total columns in POIT for line 1 only which represents the item values.
---- additional lines (2 and greater) will adjust line 1 so that the values foot to the item totals.
if @numrows = 1
	BEGIN
  	SELECT  @POLineKeyID = i.KeyID, @POITKeyID = i.POITKeyID
	FROM INSERTED i
	END
ELSE
	BEGIN
	-- use a cursor to update Total and Remaining values
	DECLARE vcPOItemLine_insert CURSOR FOR SELECT i.KeyID, i.POITKeyID
	FROM INSERTED i

	OPEN vcPOItemLine_insert
	SET @opencursor = 1

	-- get 1st Item inserted
	FETCH NEXT FROM vcPOItemLine_insert INTO @POLineKeyID, @POITKeyID
	if @@fetch_status <> 0
		BEGIN
		SET @ErrMsg = 'Cursor error '
		goto Error
		END
	END


POItemLine_Loop:
---- get line data
SELECT  @POCo = i.POCo, @PostToCo = i.PostToCo, @PO = i.PO, @POItem = i.POItem,
		@POItemLine = i.POItemLine, @ItemType = i.ItemType, @TaxGroup = i.TaxGroup,
		@TaxCode = i.TaxCode, @Location = i.Loc,
		@GLCo = i.GLCo, @GLAcct = i.GLAcct, @WO = i.WO, @WOItem = i.WOItem,
		@Equip = i.Equip, @CompType = i.CompType, @Component = i.Component,
		@CostCode = i.CostCode, @EMGroup = i.EMGroup, @EMCType = i.EMCType,
		@PhaseGroup = i.PhaseGroup, @Job = i.Job, @Phase = i.Phase,
		@JCCType = i.JCCType, @SMWorkOrder = i.SMWorkOrder, @SMScope = i.SMScope,
		@PayType = i.PayType, @PayCategory = i.PayCategory, @RecvdUnits = i.RecvdUnits,
		@RecvdCost = i.RecvdCost, @BOUnits = i.BOUnits, @BOCost = i.BOCost,
		@InvUnits = i.InvUnits, @InvCost = i.InvCost, @TaxRate = i.TaxRate,
		@GSTRate = i.GSTRate, @CurUnits = i.CurUnits, @CurCost = i.CurCost,
		@TaxType = i.TaxType, @PostedDate = i.PostedDate, @Month = i.JCMonth,
  		-- TK-14139 --
  		@SMPhaseGroup = i.SMPhaseGroup, @SMPhase = i.SMPhase, @SMJCCostType = i.SMJCCostType,
  		@SMCo = i.SMCo, @SMWorkOrder = i.SMWorkOrder, @SMScope = i.SMScope
FROM INSERTED i
WHERE i.KeyID = @POLineKeyID
IF @@ROWCOUNT = 0
	BEGIN
    SELECT @ErrMsg = 'Error retrieving line record information.'
    GOTO Error
    END


---- get item data
SELECT  @UM = i.UM, @CurUnitCost = i.CurUnitCost, @CurECM = i.CurECM,
		@MatlGroup = i.MatlGroup, @Material = i.Material, @Description = i.Description
		----TK-14983
		,@AddedMth = AddedMth
FROM dbo.bPOIT i
WHERE i.KeyID = @POITKeyID
IF @@ROWCOUNT = 0
	BEGIN
    SELECT @ErrMsg = 'Error retrieving item record information.'
    GOTO Error
    END

----TK-14983
IF ISNULL(@Month,'') = '' SET @Month = @AddedMth
---- Month used for GL and JC distributions.
IF ISNULL(@Month,'') = ''
	BEGIN
	SET @Month = dbo.vfDateOnlyMonth()
	END
	
---- use system date if missing posted date
IF ISNULL(@PostedDate,'') = ''
	BEGIN
	SET @PostedDate = dbo.vfDateOnly()
	END

---- validation for all types
EXEC @rcode = dbo.bspGLMonthVal @GLCo, @Month, @ErrMsg OUTPUT
if @rcode <> 0
	BEGIN
	SELECT @ErrMsg = ISNULL(@ErrMsg,'')
	GOTO Error
	END
				
---- SET GL Account Type: 1 - J, 2 - I, 3,6 - N, 4,5 - E
----TK-09213
SELECT @AcctType = CASE @ItemType WHEN 1 THEN 'J' 
								  WHEN 2 THEN 'I' 
								  WHEN 4 THEN 'E' 
								  WHEN 5 THEN 'E'
								  WHEN 6 THEN 'S'
								  ELSE 'N' END
---- validate GL Account
exec @rcode = dbo.bspGLACfPostable @GLCo, @GLAcct, @AcctType, @ErrMsg output
if @rcode <> 0
	BEGIN
	SELECT @ErrMsg = ISNULL(@ErrMsg,'') + ' - GL Account: ' + isnull(@GLAcct,'')
	GOTO Error
	END

---- validate Pay Type is associated with Pay Category
if @PayCategory is not null and @PayType is not null
	BEGIN
	IF NOT EXISTS(SELECT 1 FROM dbo.bAPPT WHERE	APCo = @POCo AND PayType = @PayType 
					AND (PayCategory IS NULL OR PayCategory = @PayCategory))
		BEGIN
		SELECT @ErrMsg = 'Pay Type ' + dbo.vfToString(@PayType) + ' not associated with Pay Category ' + dbo.vfToString(@PayCategory)
		GOTO Error
		END
	END


---- Item Type 1 - Job
if @ItemType = 1
	BEGIN
	---- VALIDATE JOB
	EXEC @rcode = dbo.bspJobTypeVal @PostToCo, @PhaseGroup, @Job, @Phase, @JCCType,
						@JCUM OUTPUT, @ErrMsg OUTPUT
	if @rcode <> 0
		BEGIN
		SELECT @ErrMsg = ISNULL(@ErrMsg,'')
		GOTO Error
		END


	---- GET JCUM Conversion Factor
	EXEC @rcode = dbo.vspPOItemLineJCUMConvGet @MatlGroup, @Material, @UM, @JCUM,
						@JCUMConv OUTPUT, @ErrMsg OUTPUT
	if @rcode <> 0
		BEGIN
		SELECT @ErrMsg = ISNULL(@ErrMsg,'')
		GOTO Error
		END
		
	END

	
---- Item Type 2 - Inventory
if @ItemType = 2
	BEGIN
	EXEC @rcode = dbo.bspPOInvTypeVal @PostToCo, @Location, @MatlGroup, @Material, @UM, @ErrMsg output
	if @rcode <> 0
		BEGIN
		SELECT @ErrMsg = ISNULL(@ErrMsg,'') + ' - Location: ' + ISNULL(@Location,'') + ' Material: ' + ISNULL(@Material,'')
		GOTO Error
		END
	END

---- Item Type 3 - Expense


---- Item Type 4 - EM Equipment
IF @ItemType = 4
	BEGIN
	EXEC @rcode = dbo.bspPOEquipTypeVal @PostToCo, @Equip, @EMGroup, @CostCode, @EMCType, @ErrMsg OUTPUT
	if @rcode <> 0
		BEGIN
		SELECT @ErrMsg = ISNULL(@ErrMsg,'')
		GOTO Error
		END
	END
				
---- Item Type 5 - EM Work Order
IF @ItemType = 5
	BEGIN
	
	EXEC @rcode = dbo.bspAPLBValWO @PostToCo, @WO, @WOItem, @Equip, @CompType, @Component,
						@EMGroup, @CostCode, @ErrMsg OUTPUT
	IF @rcode <> 0
		BEGIN
		SELECT @ErrMsg = ISNULL(@ErrMsg,'')
		GOTO Error
		END
	END


---- Item Type 6 - SM Work Order
IF @ItemType = 6
	BEGIN
		---- Make sure the SMWorkOrder is a valid Work Order for the SMCo and is not closed. @smworkorder
		SET @WOStatus = null
		SELECT @WOStatus = WOStatus FROM dbo.vSMWorkOrder WHERE SMCo = @PostToCo AND WorkOrder = @SMWorkOrder
		IF (@WOStatus <> 0)
			BEGIN
				SET @ErrMsg = 'Invalid SMWorkOrder ' + dbo.vfToString(@SMWorkOrder) + 
							  ' for SMCo ' + dbo.vfToString(@PostToCo) + ' is not open.'
				GOTO Error
			END
			
		---- validate SM Scope		
		IF NOT EXISTS(SELECT 1 FROM vSMWorkOrderScope WHERE SMCo = @PostToCo AND WorkOrder = @SMWorkOrder AND Scope = @SMScope)
			BEGIN
				SET @ErrMsg = 'Invalid SMScope ' + dbo.vfToString(@SMScope) + 
							  ' for SMCo ' + dbo.vfToString(@PostToCo) + ' - SMWorkOrder ' + dbo.vfToString(@SMWorkOrder) + ' is not valid.'
				GOTO Error
			END
			
		-- TK-14139 --
		-- GET SM JOB --
		SELECT  @SMJob = Job,
				@SMJobExistsYN = CASE
									WHEN Job IS NOT NULL THEN 'Y'
									ELSE 'N'
									END
		  FROM  dbo.vSMWorkOrderScope 
		 WHERE  SMCo = @PostToCo AND WorkOrder = @SMWorkOrder AND Scope = @SMScope 
			
		---- JG 09/23/2011 TK-08142
		---- Insert SMPOLineItem record
		EXEC @rcode = dbo.vspSMModifySMPOItemLine @POCo, @PO, @POItem, @POItemLine, NULL, @ErrMsg OUTPUT
		IF @rcode <> 0 GOTO Error
		
	END -- @ItemType = 6


---- initialize tax variables
SET @TaxPhase = NULL
SET @TaxCT = NULL
SET @TaxJCUM = NULL

---- validate tax code if item type = 1-Job OR will also validate tax phase and cost type
IF (ISNULL(@TaxCode,'') <> '')	
	BEGIN
	
		-- TK-14139 --
		-- SM AND JOB? --
		IF (@ItemType = 6) AND (@SMJobExistsYN = 'Y')
			BEGIN
				EXEC @rcode = dbo.vspPOItemLineTaxCodeVal @PostToCo, 
								@SMJob, @SMPhaseGroup, @SMPhase, @SMJCCostType, 
								@ItemType, @TaxGroup, @TaxType, @TaxCode,
								@TaxPhase OUTPUT, @TaxCT OUTPUT, @TaxJCUM OUTPUT,
								@ErrMsg OUTPUT
			END
		ELSE
			BEGIN
				EXEC @rcode = dbo.vspPOItemLineTaxCodeVal @PostToCo, 
								@Job, @PhaseGroup, @Phase, @JCCType, 
								@ItemType, @TaxGroup, @TaxType, @TaxCode, 
								@TaxPhase OUTPUT, @TaxCT OUTPUT, @TaxJCUM OUTPUT, 
								@ErrMsg OUTPUT
			END
	
		IF @rcode <> 0
			BEGIN
				SELECT @ErrMsg = ISNULL(@ErrMsg,'')
				GOTO Error
			END
	END

	
---- if Item Type = 2 inventory update INMT On Order for location material
IF @ItemType = 2 AND @CurUnits <> 0
	BEGIN
	----TK-11964
	IF ISNULL(@Material,'') <> '' AND @POItemLine > 1
		BEGIN
		EXEC @rcode = dbo.vspPOINMTUpdateOnOrder @MatlGroup, @Material, @UM, @PostToCo, @Location, @CurUnits, 'NEW', @ErrMsg OUTPUT
		if @rcode <> 0 GOTO Error
		END
	END

	
---- when not line 1 we need to set BOUnits and BOCost
---- for insert the BOUnits and Cost will equal Current Values
IF @POItemLine > 1
	BEGIN
	IF @UM = 'LS'
		BEGIN
		SET @BOUnits = 0
		SET @BOCost = @CurCost
		END
	ELSE
		BEGIN
		SET @BOCost = 0
		SET @BOUnits = @CurUnits
		END
	END
	
				
---- we need to calculate the totals and get tax rates to update POIT.
---- This code was in the POIT insert trigger and has been moved to here.
---- get Tax Rate to recalculate tax amounts
---- calculate Total and Remaining
if @UM = 'LS'
	BEGIN
   	SELECT  @RecvdUnits=0, @BOUnits=0, @TotalUnits = 0, @RemUnits = 0,
   			@TotalCost	= @RecvdCost + @BOCost,
   			@RemCost	= @TotalCost - @InvCost
	END
else
	BEGIN
	SELECT  @Factor = CASE @CurECM WHEN 'C' THEN 100 WHEN 'M' THEN 1000 ELSE 1 END
   	SELECT  @TotalUnits = @RecvdUnits + @BOUnits,
   			@TotalCost	= (@TotalUnits * @CurUnitCost) / @Factor,
   			@RemUnits	= @TotalUnits - @InvUnits,
			@RemCost	= (@RemUnits * @CurUnitCost) / @Factor
	END


---- initialize tax values
SET @HQTXdebtGLAcct = NULL
SET @TotalTax = null
SET @RemTax = NULL
SET @JCCmtdTax = NULL
SET @JCRemCmtdTax = NULL

---- Calculate PO Item Line Tax amounts
if ISNULL(@TaxCode,'') <> ''
	BEGIN
	---- calculate tax values for update
	EXEC @rcode = dbo.vspPOItemLineTaxCalcs @TaxGroup, @ItemType, @SMJobExistsYN, @PostedDate, @TaxCode, 
							@TaxRate, @GSTRate, @TotalCost, @RemCost,
							@TotalTax OUTPUT, @RemTax OUTPUT, @JCCmtdTax OUTPUT,
							@JCRemCmtdTax OUTPUT, @HQTXdebtGLAcct OUTPUT,
							@ErrMsg OUTPUT
	IF @rcode <> 0 GOTO Error

	END


---- Item Type 1 - Job : create JCCD Committed transactions
IF @ItemType = 1
	BEGIN	
	---- check tax phase cost type
	IF ISNULL(@TaxPhase,'') = '' SET @TaxPhase = @Phase
	IF ISNULL(@TaxCT,0) = 0 SET @TaxCT = @JCCType
	
	SET @JCTransType = 'PO Entry'
	IF @POItemLine > 1 SET @JCTransType = 'PO Dist'
	SET @OldCmtdRemCost = 0
	SET @OldCmtdRemUnits = 0
	

	---- generate JC committed cost transactions for 'NEW'
	EXEC @rcode = dbo.vspPOItemLineJCCmtdCostUpdate 'NEW', @Month, @PostToCo, @Job, @PhaseGroup,
					@Phase, @JCCType, @POItemLine, @JCUM, @PostedDate, @TaxGroup, @TaxType,
					@TaxCode, @TaxPhase, @TaxCT, @TaxJCUM, @POITKeyID, @JCUMConv,
					@CurUnits, @CurCost, @TotalTax, @RemTax, @JCCmtdTax, @JCRemCmtdTax,
					@OldCmtdRemCost, @OldCmtdRemUnits, @JCTransType, 
					-- TK-14139 --
					NULL, NULL, NULL,
					@ErrMsg OUTPUT
	IF @rcode <> 0 GOTO Error

	END

---------------------
-- TK- 14139 START --
--------------------------------
-- ItemType: 6 - SM WorkOrder --
--	AND a JobSMWO             --
--------------------------------
IF @ItemType = 6
	BEGIN	
			
		-- CHECK FOR SMJob --
		If @SMJobExistsYN = 'Y'
			BEGIN	

				-- VALIDATE JOB --
				EXEC @rcode = dbo.bspJobTypeVal @PostToCo, @SMPhaseGroup, @SMJob, @SMPhase, @SMJCCostType,
									@JCUM OUTPUT, @ErrMsg OUTPUT
				IF @rcode <> 0
					BEGIN
						SELECT @ErrMsg = ISNULL(@ErrMsg,'')
						GOTO Error
					END
									
				-- GET JCUM CONVERSION FACTOR --
				EXEC @rcode = dbo.vspPOItemLineJCUMConvGet @MatlGroup, @Material, @UM, @JCUM,
									@JCUMConv OUTPUT, @ErrMsg OUTPUT
				IF @rcode <> 0
					BEGIN
						SELECT @ErrMsg = ISNULL(@ErrMsg,'')
						GOTO Error
					END
	
				-- CHECK TAX PHASE AND COSTTYPE --
				IF ISNULL(@TaxPhase,'') = '' SET @TaxPhase = @SMPhase
				IF ISNULL(@TaxCT,0) = 0 SET @TaxCT = @SMJCCostType
				
				SET @JCTransType = 'PO Entry'
				IF @POItemLine > 1 SET @JCTransType = 'PO Dist'
				SET @OldCmtdRemCost = 0
				SET @OldCmtdRemUnits = 0
		
				---- generate JC committed cost transactions for 'NEW'
				EXEC @rcode = dbo.vspPOItemLineJCCmtdCostUpdate 'NEW', @Month, @PostToCo, 
								@SMJob, @SMPhaseGroup, @SMPhase, @SMJCCostType, 
								@POItemLine, @JCUM, @PostedDate, @TaxGroup, @TaxType,
								@TaxCode, @TaxPhase, @TaxCT, @TaxJCUM, @POITKeyID, @JCUMConv,
								@CurUnits, @CurCost, @TotalTax, @RemTax, @JCCmtdTax, @JCRemCmtdTax,
								@OldCmtdRemCost, @OldCmtdRemUnits, @JCTransType, 
								-- TK-14139 --
								@PostToCo, @SMWorkOrder, @SMScope,
								@ErrMsg OUTPUT
				IF @rcode <> 0 GOTO Error
				
			END -- @SMJobExistsYN
	END -- @ItemType = 6
-------------------
-- TK- 14139 END --
-------------------	

---- update item line certain values only update for lines not one
update dbo.vPOItemLine
		SET PostedDate	= @PostedDate,
			JCMonth		= @Month,
			CurTax		= CASE @POItemLine WHEN 1 THEN CurTax ELSE ISNULL(@TotalTax, CurTax) END,
			BOUnits		= CASE @POItemLine WHEN 1 THEN BOUnits ELSE @BOUnits END,
			BOCost		= CASE @POItemLine WHEN 1 THEN BOCost ELSE @BOCost END,
			TotalUnits	= @TotalUnits,
			TotalCost	= @TotalCost, 
			TotalTax	= ISNULL(@TotalTax, TotalTax),
			RemUnits	= @RemUnits,
			RemCost		= @RemCost,
			RemTax		= ISNULL(@RemTax, RemTax),
			JCCmtdTax	= ISNULL(@JCCmtdTax, JCCmtdTax),
			JCRemCmtdTax= ISNULL(@JCRemCmtdTax, JCRemCmtdTax)
WHERE KeyID = @POLineKeyID
if @@rowcount <> 1
	BEGIN
	select @ErrMsg = 'Error occurred updating PO Item Line Totals.'
	goto Error
	END


POItemLine_Next:
if @numrows > 1
	BEGIN
	FETCH NEXT FROM vcPOItemLine_insert INTO @POLineKeyID, @POITKeyID

	if @@fetch_status = 0 goto POItemLine_Loop

	CLOSE vcPOItemLine_insert
	DEALLOCATE vcPOItemLine_insert
	SET @opencursor = 0
	END




---- HQ Auditing
INSERT dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
SELECT 'vPOItemLine',  'PO:' + i.PO + ' POItem:' + CONVERT(VARCHAR(10),i.POItem) + ' POItemLine:' + CONVERT(VARCHAR(10),i.POItemLine),
		i.POCo, 'A', null, null, null, getdate(), SUSER_SNAME()
FROM inserted i
join dbo.bPOCO c on i.POCo = c.POCo
WHERE c.AuditPOs = 'Y'
   
   
   
RETURN


Error:
	if @opencursor = 1
		BEGIN
		CLOSE vcPOItemLine_insert
		DEALLOCATE vcPOItemLine_insert
		END
   
	select @ErrMsg = @ErrMsg + ' - cannot insert PO Item Distribution Lines'
	RAISERROR(@ErrMsg, 11, -1);
	rollback transaction



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






/****** Object:  Trigger dbo.vtPOItemLineu   ******/
CREATE  trigger [dbo].[vtPOItemLineu] on [dbo].[vPOItemLine] for UPDATE as   
/*--------------------------------------------------------------
* Created By:	GF 08/08/2011 TK-07029
* Modified:		JG 09/23/2011 TK-08142 - Update/Delete the SMPOItemLine record when ItemType is/n't 6.
*				GF 01/22/2012 TK-11964 TK-12013 #145600 #145627 using wrong phase for update
*				DAN SO 04/20/2012 TK-14139 - Committed costs for SM PO w/job
*				GF 05/09/2012 TK-00000 per Jacob post to co drives tax group changes. do not check old vs new tax group
*				GF 05/17/2012 TK-14983
*
*
* Update trigger on vPOItemLine - PO Item Distribution Lines
*
* This is the base trigger and will need to be update as we
* progress with the PO Item Distribution enhancement.
*
*--------------------------------------------------------------*/
declare @numrows INT, @validcnt INT, @ErrMsg VARCHAR(255), @opencursor INT,
		@rcode INT, @POITKeyID BIGINT, @POLineKeyID BIGINT,
		---- LINE
		@POCo bCompany, @PO VARCHAR(30), @POItem bItem, @POItemLine INT, @ItemType TINYINT,
		@PostToCo bCompany, @Job bJob, @PhaseGroup bGroup, @Phase bPhase,
		@JCCType bJCCType, @Loc bLoc, @EMGroup bGroup, @Equip bEquip, @CompType VARCHAR(10),
		@Component bEquip, @CostCode bCostCode, @EMCType bEMCType, @WO bWO,
		@WOItem bItem, @SMCo bCompany, @SMWorkOrder INT, @SMScope INT, @SMWorkCompleted int, @TaxGroup bGroup, @TaxType TINYINT,
		@TaxCode bTaxCode, @TaxRate bRate, @GSTRate bRate, @GLCo bCompany, @GLAcct bGLAcct,
		@ReqDate bDate, @PayCategory INT, @PayType TINYINT, @PostedDate bDate,
		@OrigUnits bUnits, @OrigCost bDollar, @OrigTax bDollar, @CurUnits bUnits,
		@CurCost bDollar, @CurTax bDollar, @RecvdUnits bUnits, @RecvdCost bDollar,
		@BOUnits bUnits, @BOCost bDollar, @InvUnits bUnits, @InvCost bDollar, @InvTax bDollar,
		@RemUnits bUnits, @RemCost bDollar, @RemTax bDollar, @OldCmtdRemCost bDollar,
		@OldCmtdRemUnits bUnits, @JCCmtdTax bDollar, @JCRemCmtdTax bDollar, @TotalUnits bUnits,
		@TotalCost bDollar, @TotalTax bDollar, @Purge CHAR(1), @InUseBatchId bBatchID,
		@InUseMth bMonth,
		---- ITEM
		@UM bUM, @CurUnitCost bUnitCost, @CurECM bECM, @MatlGroup bGroup, @Material bMatl,
		@ItemCurUnits bUnits, @ItemCurCost bDollar, @VarUnits bUnits, @VarCost bDollar,
  		----
  		@Factor SMALLINT,  @HQTXdebtGLAcct bGLAcct, @JCUM bUM, @JCUMConv bUnitCost,
  		@TaxPhase bPhase, @TaxCT bJCCType, @TaxJCUM bUM, @Month bMonth,
  		@POPurge CHAR(1), @JCTransType VARCHAR(10), @LineFlag CHAR(1), @ReceiptUpdate CHAR(1),
  		---- OLD LINE
  		@OldPostToCo bCompany, @OldItemType TINYINT, @OldJob bJob, @OldPhaseGroup bGroup,
		@OldPhase bPhase, @OldJCCType bJCCType, @OldLoc bLoc, @OldTaxGroup bGroup,
		@OldTaxType TINYINT, @OldTaxCode bTaxCode, @OldTaxRate bRate, @OldGSTRate bRate,
		@OldGLCo bCompany, @OldGLAcct bGLAcct,
		@OldOrigUnits bUnits, @OldOrigCost bDollar, @OldOrigTax bDollar,
		@OldCurUnits bUnits, @OldCurCost bDollar, @OldCurTax bDollar,
		@OldRemUnits bUnits, @OldRemCost bDollar, @OldRemTax bDollar,
		@OldBOUnits bUnits, @OldBOCost bDollar, @OldJCCmtdTax bDollar, @OldJCRemCmtdTax bDollar,
		@OldTotalUnits bUnits, @OldTotalCost bDollar, @OldTotalTax bDollar,
		@OldTotalTax1 bDollar, @OldRecvdUnits bUnits, @OldRecvdCost bDollar,
		@OldInvUnits bUnits, @OldInvCost bDollar, @OldPurge CHAR(1),
		---- NEW
		@NewCurUnits bUnits, @NewCurCost bDollar
		-----TK-14983
		,@AddedMth bMonth,
		-- TK-14139 --
  		@SMJob bJob, @SMPhaseGroup bGroup, @SMPhase bPhase, @SMJCCostType bJCCType, 
  		@SMJobExistsYN bYN, @SMWOStatus TINYINT, 
  		@OldSMJob bJob, @OldSMPhaseGroup bGroup, @OldSMPhase bPhase, @OldSMJCCostType bJCCType, 
  		@OldSMWorkCompleted int, @OldSMWorkOrder INT, @OldSMScope INT, @OldSMCo bCompany, @OldSMJobExistsYN bYN,
  		@SMProjCost bDollar


select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

SET @opencursor = 0
SET @SMJobExistsYN = 'N'	--  TK-14139 --
SET @OldSMJobExistsYN = 'N'	--  TK-14139 --

---- check for key changes
if UPDATE(POCo) OR UPDATE(PO) OR UPDATE(POItem) OR UPDATE(POItemLine)
	BEGIN
	select @ErrMsg = 'Cannot change PO Company, PO, PO Item, or PO Item Line.'
	goto ERROR
	END
   
---- make sure 'LS' Item Lines have 0.00 units and unit costs
if exists(select 1 from inserted i
	JOIN dbo.bPOIT t ON t.POCo=i.POCo AND t.PO=i.PO AND t.POItem=i.POItem
	JOIN dbo.bPOHD h ON h.POCo=i.POCo AND h.PO=i.PO
	WHERE h.PO = 'N' AND t.UM = 'LS' and (i.CurUnits <> 0 or t.CurUnitCost <> 0))
        begin
        select @ErrMsg = 'Lump sum PO Item Distribution Lines must have 0.00 Units and Unit Cost.'
        goto ERROR
        end

---- if we are updating InUseBatchId and InUseMth we are done. Nothing else should be updated
---- when the in use batch and month are updated
IF UPDATE(InUseBatchId) AND UPDATE(InUseMth) RETURN

---- cursor for item lines to update POIT information 
---- we will update the total columns in POIT for line 1 only which represents the item values.
---- additional lines (2 and greater) will adjust line 1 so that the values foot to the item totals.
if @numrows = 1
	BEGIN
	SELECT @POLineKeyID = i.KeyID, @POITKeyID = i.POITKeyID, @POItemLine = i.POItemLine
	FROM INSERTED i
	END
ELSE
	BEGIN
	-- use a cursor to update line and item Total and Remaining values
	DECLARE vcPOItemLine_update CURSOR FOR SELECT i.KeyID, i.POITKeyID, i.POItemLine
	FROM INSERTED i

	OPEN vcPOItemLine_update
	SET @opencursor = 1
	
	-- fetch next 
	FETCH NEXT FROM vcPOItemLine_update INTO @POLineKeyID, @POITKeyID, @POItemLine
	if @@fetch_status <> 0
		BEGIN
		SET @ErrMsg = 'Cursor ERROR '
		goto ERROR
		END
	END


POItemLine_Loop:

---- if we are updating line one move to the line one update section.
---- an update to line one will only happen via batch post processes
---- in PO or AP. Handle line one updates in one section to avoid unwanted
---- distribution updates to IN or JC do to possible rounding problems
---- when adjusting line one. 

---- get line data
SELECT  @POCo = i.POCo, @PostToCo = i.PostToCo, @PO = i.PO, @POItem = i.POItem,
		@ItemType = i.ItemType, @Job = i.Job, @PhaseGroup = i.PhaseGroup,
		@Phase = i.Phase, @JCCType = i.JCCType, @Loc = i.Loc, @EMGroup = i.EMGroup,
		@Equip = i.Equip, @CompType = i.CompType, @Component = i.Component, @CostCode = i.CostCode, 
		@EMCType = i.EMCType, @WO = i.WO, @WOItem = i.WOItem, @SMCo = i.SMCo, @SMWorkOrder = i.SMWorkOrder, 
		@SMScope = i.SMScope, @TaxGroup = i.TaxGroup, @TaxType = i.TaxType,
		@TaxCode = i.TaxCode, @TaxRate = i.TaxRate, 
		@GSTRate = i.GSTRate, @GLCo = i.GLCo, @GLAcct = i.GLAcct, @ReqDate = i.ReqDate, 
		@PayCategory = i.PayCategory, @PayType = i.PayType, @PostedDate = i.PostedDate, 
		----
		@OrigUnits = i.OrigUnits, @OrigCost = i.OrigCost, @OrigTax = i.OrigTax, @CurUnits = i.CurUnits,
		@CurCost = i.CurCost, @CurTax = i.CurTax, @RecvdUnits = i.RecvdUnits, @RecvdCost = i.RecvdCost, 
		@BOUnits = i.BOUnits, @BOCost = i.BOCost, @InvUnits = i.InvUnits, @InvCost = i.InvCost,
		@InvTax = i.InvTax, @RemUnits = i.RemUnits, @RemCost = i.RemCost,
		@RemTax = i.RemTax, @JCCmtdTax = i.JCCmtdTax, @JCRemCmtdTax = i.JCRemCmtdTax,
		@TotalUnits = i.TotalUnits, @TotalCost = i.TotalCost, @TotalTax = i.TotalTax,
		@Month = i.JCMonth, @PostedDate = i.PostedDate, @Purge = i.PurgeYN,
		@LineFlag = i.LineDelete, 
		-- TK-14139 --
  		@SMPhaseGroup = i.SMPhaseGroup, @SMPhase = i.SMPhase, @SMJCCostType = i.SMJCCostType,
  		@SMCo = i.SMCo, @SMWorkOrder = i.SMWorkOrder, @SMScope = i.SMScope, @SMWorkCompleted = i.SMWorkCompleted
FROM INSERTED i
WHERE i.KeyID = @POLineKeyID
IF @@ROWCOUNT = 0
	BEGIN
    SELECT @ErrMsg = 'ERROR retrieving line record information.'
    GOTO ERROR
    END
   

---- get old line data
SELECT  @OldPostToCo = d.PostToCo, @OldItemType = d.ItemType, @OldJob = d.Job, @OldPhaseGroup = d.PhaseGroup,
		@OldPhase = d.Phase, @OldJCCType = d.JCCType, @OldLoc = d.Loc, @OldTaxGroup = d.TaxGroup,
		@OldTaxType = d.TaxType, @OldTaxCode = d.TaxCode, @OldTaxRate = d.TaxRate, @OldGSTRate = d.GSTRate,
		@OldGLCo = d.GLCo, @OldGLAcct = d.GLAcct,
		@OldOrigUnits = d.OrigUnits, @OldOrigCost = d.OrigCost, @OldOrigTax = d.OrigTax,
		@OldCurUnits = d.CurUnits, @OldCurCost = d.CurCost, @OldCurTax = d.CurTax,
		@OldRemUnits = d.RemUnits, @OldRemCost = d.RemCost, @OldRemTax = d.RemTax,
		@OldBOUnits  = d.BOUnits, @OldBOCost = d.BOCost, @OldJCCmtdTax = d.JCCmtdTax,
		@OldJCRemCmtdTax = d.JCRemCmtdTax, @OldTotalUnits = d.TotalUnits,
		@OldTotalCost = d.TotalCost, @OldTotalTax = d.TotalTax,
		@OldRecvdUnits = d.RecvdUnits, @OldRecvdCost = d.RecvdCost,
		@OldInvUnits = d.InvUnits, @OldInvCost = d.InvCost, @OldPurge = d.PurgeYN,
		-- TK-14139 --
  		@OldSMPhaseGroup = d.SMPhaseGroup, @OldSMPhase = d.SMPhase, @OldSMJCCostType = d.SMJCCostType,
  		@OldSMCo = d.SMCo, @OldSMWorkOrder = d.SMWorkOrder, @OldSMScope = d.SMScope, @OldSMWorkCompleted = d.SMWorkCompleted
FROM DELETED d
WHERE d.KeyID = @POLineKeyID
IF @@ROWCOUNT = 0
	BEGIN
    SELECT @ErrMsg = 'ERROR retrieving old line record information.'
    GOTO ERROR
    END


---- if old purge <> purge then POHB process or PO Purge process
---- is updating the flag for delete and we can skip
IF @OldPurge <> @Purge GOTO POItemLine_Next

---- get PO Company data
SELECT @ReceiptUpdate = ReceiptUpdate
FROM dbo.bPOCO
WHERE POCo = @POCo
IF @@ROWCOUNT = 0 SET @ReceiptUpdate = 'N'

---- get PO data
SELECT @POPurge = h.Purge
FROM dbo.bPOHD h
WHERE h.POCo = @POCo AND h.PO = @PO
IF @@ROWCOUNT = 0 SET @POPurge = 'N'

---- if we are purging PO we are done
IF @POPurge = 'Y' GOTO POItemLine_Next

---- get item data
SELECT  @UM = i.UM, @CurUnitCost = i.CurUnitCost, @CurECM = i.CurECM,
		@MatlGroup = i.MatlGroup, @Material = i.Material,
		@ItemCurUnits = i.CurUnits, @ItemCurCost = i.CurCost
		----TK-14983
		,@AddedMth = AddedMth
FROM dbo.bPOIT i
WHERE i.KeyID = @POITKeyID
IF @@ROWCOUNT = 0
	BEGIN
    SELECT @ErrMsg = 'ERROR retrieving item record information.'
    GOTO ERROR
    END

----TK-14983
IF ISNULL(@Month,'') = '' SET @Month = @AddedMth
---- month for JC distributions
IF ISNULL(@Month,'') = ''
	BEGIN
	SET @Month = dbo.vfDateOnlyMonth()
	END
	
---- use system date if missing posted date
IF ISNULL(@PostedDate,'') = ''
	BEGIN
	SET @PostedDate = dbo.vfDateOnly()
	END

--------------
-- TK-14139 -- START
--------------
---- Item Type 6 - PO - VALIDATE/GET DATA
IF @ItemType = 6
	BEGIN
		-- VERIFY SMWorkOrder IS VALID AND NOT CLOSED --
		SET @SMWOStatus = NULL
		
		SELECT @SMWOStatus = WOStatus FROM dbo.vSMWorkOrder WHERE SMCo = @PostToCo AND WorkOrder = @SMWorkOrder
		IF (@SMWOStatus <> 0)
			BEGIN
				SET @ErrMsg = 'Invalid SMWorkOrder ' + dbo.vfToString(@SMWorkOrder) + 
							  ' for SMCo ' + dbo.vfToString(@PostToCo) + ' is not open.'
				GOTO ERROR
			END
			
		-- VALIDATE SMScope	 --	
		IF NOT EXISTS(SELECT 1 FROM vSMWorkOrderScope WHERE SMCo = @PostToCo AND WorkOrder = @SMWorkOrder AND Scope = @SMScope)
			BEGIN
				SET @ErrMsg = 'Invalid SMScope ' + dbo.vfToString(@SMScope) + 
							  ' for SMCo ' + dbo.vfToString(@PostToCo) + ' - SMWorkOrder ' + dbo.vfToString(@SMWorkOrder) + ' is not valid.'
				GOTO ERROR
			END
			
		-- DOES SM JOB EXIST? --
		SELECT  @SMJob = Job,  
				@SMJobExistsYN = CASE
									WHEN Job IS NOT NULL THEN 'Y'
									ELSE 'N'
									END
		  FROM  dbo.vSMWorkOrderScope 
		 WHERE  SMCo = @PostToCo AND WorkOrder = @SMWorkOrder AND Scope = @SMScope 
		 
		-- DOES OLD SM JOB EXIST? --
		SELECT  @OldSMJob = Job,  
				@OldSMJobExistsYN = CASE
									WHEN Job IS NOT NULL THEN 'Y'
									ELSE 'N'
									END
		  FROM  dbo.vSMWorkOrderScope 
		 WHERE  SMCo = @OldPostToCo AND WorkOrder = @OldSMWorkOrder AND Scope = @OldSMScope 
			
	END
--------------
-- TK-14139 -- END
--------------

---- when we are updating PO Item Line One directly we are coming from
---- either one of the AP/PO Batch Processes or the delete trigger
---- when line > 1 is deleted and we are updating line one.
---- we can skip this section if line one
IF @POItemLine = 1
	BEGIN

	---- will be either a source of 'PO Entry' or 'PO Change'
	SET @JCTransType = 'PO Entry'
	---- if flag = 'Y' then we are updating line 1 and is a 'PO Dist'
	IF @LineFlag = 'Y'
		BEGIN
		SET @JCTransType = 'PO Dist'
		END
	ELSE
		BEGIN
		IF @LineFlag = 'C'
			BEGIN
			SET @JCTransType = 'PO Change'
			END
		ELSE
			BEGIN
			 
				-- TK-14139 --
				IF @ItemType = 6 AND @SMJobExistsYN = 'Y'
					BEGIN

						IF (@OldItemType <> @ItemType
							OR @OldPostToCo <> @PostToCo
							OR ISNULL(@Loc,'') <> ISNULL(@OldLoc,'')
							OR ISNULL(@SMJob,'') <> ISNULL(@OldSMJob,'')
							OR ISNULL(@SMPhaseGroup,0) <> ISNULL(@OldSMPhaseGroup,0)
							OR ISNULL(@SMPhase,'') <> ISNULL(@OldSMPhase,'')
							OR ISNULL(@SMJCCostType,0) <> ISNULL(@OldSMJCCostType,0)
							--OR ISNULL(@TaxGroup,0) <> ISNULL(@OldTaxGroup,0) --PostToCo change drives tax group change check not required
							OR ISNULL(@TaxType,0) <> ISNULL(@OldTaxType,0)
							OR ISNULL(@TaxCode,'') <> ISNULL(@OldTaxCode,'')
							OR @OrigUnits <> @OldOrigUnits
							OR @OrigCost <> @OldOrigCost
							OR @OrigTax <> @OldOrigTax)
							BEGIN
								SET @JCTransType = 'PO Entry'
							END					
					END
				ELSE
					BEGIN
						---- any original changes?
						IF (@OldItemType <> @ItemType
							OR @OldPostToCo <> @PostToCo
							OR ISNULL(@Loc,'') <> ISNULL(@OldLoc,'')
							OR ISNULL(@Job,'') <> ISNULL(@OldJob,'')
							OR ISNULL(@PhaseGroup,0) <> ISNULL(@OldPhaseGroup,0)
							OR ISNULL(@Phase,'') <> ISNULL(@OldPhase,'')
							OR ISNULL(@JCCType,0) <> ISNULL(@OldJCCType,0)
							--OR ISNULL(@TaxGroup,0) <> ISNULL(@OldTaxGroup,0) --PostToCo change drives tax group change check not required
							OR ISNULL(@TaxType,0) <> ISNULL(@OldTaxType,0)
							OR ISNULL(@TaxCode,'') <> ISNULL(@OldTaxCode,'')
							OR @OrigUnits <> @OldOrigUnits
							OR @OrigCost <> @OldOrigCost
							OR @OrigTax <> @OldOrigTax)
							BEGIN
								SET @JCTransType = 'PO Entry'
							END
					END
			END
		END


	GOTO POItemLineOne_Update_Only
	END


---- we are doing line distributions
SET @JCTransType = 'PO Dist'

---- when the old item type is 2 then we need to update INMT On Order and back out the old units
---- if ItemType = 2 inventory,  get UM conversion rate
IF @OldItemType = 2 AND @OldCurUnits <> @CurUnits AND @OldCurUnits <> 0
	BEGIN
	----TK-11964
	IF ISNULL(@Material,'') <> ''
	BEGIN
	EXEC @rcode = dbo.vspPOINMTUpdateOnOrder @MatlGroup, @Material, @UM, @OldPostToCo, @OldLoc, @OldCurUnits, 'OLD', @ErrMsg OUTPUT
	if @rcode <> 0 GOTO ERROR
	END
	END	

---- when the new item type is 2 then we need to update INMT On Order and update with new values
---- if ItemType = 2 inventory,  get UM conversion rate
IF @ItemType = 2 AND @OldCurUnits <> @CurUnits AND @CurUnits <> 0
	BEGIN
	----TK-11964
	IF ISNULL(@Material,'') <> ''
	BEGIN
	EXEC @rcode = dbo.vspPOINMTUpdateOnOrder @MatlGroup, @Material, @UM, @PostToCo, @Loc, @CurUnits, 'NEW', @ErrMsg OUTPUT
	if @rcode <> 0 GOTO ERROR
	END
	END


---- when the old item type is 1 then we need to create JCCD committed cost transactions to back out old values
---- when old ItemType = 1 Job
IF @OldItemType = 1 AND
	(@OldPostToCo <> @PostToCo
        OR ISNULL(@Job,'') <> ISNULL(@OldJob,'')
        OR ISNULL(@PhaseGroup,0) <> ISNULL(@OldPhaseGroup,0)
		OR ISNULL(@Phase,'') <> ISNULL(@OldPhase,'')
        OR ISNULL(@JCCType,0) <> ISNULL(@OldJCCType,0)
        --OR ISNULL(@TaxGroup,0) <> ISNULL(@OldTaxGroup,0) --PostToCo change drives tax group change check not required
        OR ISNULL(@TaxType,0) <> ISNULL(@OldTaxType,0)
        OR ISNULL(@TaxCode,'') <> ISNULL(@OldTaxCode,'')
        OR @CurUnits <> @OldCurUnits
        OR @CurCost <> @OldCurCost)
	BEGIN
	
	---- validate job
	EXEC @rcode = dbo.bspJobTypeVal @OldPostToCo, @OldPhaseGroup, @OldJob, @OldPhase, @OldJCCType, @JCUM OUTPUT, @ErrMsg OUTPUT
	if @rcode <> 0
		BEGIN
		SELECT @ErrMsg = ISNULL(@ErrMsg,'')
		GOTO ERROR
		END

	---- GET JCUM Conversion Factor
	EXEC @rcode = dbo.vspPOItemLineJCUMConvGet @MatlGroup, @Material, @UM, @JCUM, @JCUMConv OUTPUT, @ErrMsg OUTPUT
	if @rcode <> 0
		BEGIN
		SELECT @ErrMsg = ISNULL(@ErrMsg,'')
		GOTO ERROR
		END
		
	---- initialize tax variables
	SET @TaxPhase = NULL
	SET @TaxCT = NULL
	SET @TaxJCUM = NULL

	---- validate tax code if item type = 1-Job will also validate tax phase and cost type
	IF ISNULL(@OldTaxCode,'') <> ''
		BEGIN
		EXEC @rcode = dbo.vspPOItemLineTaxCodeVal @OldPostToCo, @OldJob, @OldPhaseGroup, @OldPhase,
							@OldJCCType, @OldItemType, @OldTaxGroup, @OldTaxType, @OldTaxCode,
							@TaxPhase OUTPUT, @TaxCT OUTPUT, @TaxJCUM OUTPUT, @ErrMsg OUTPUT
		IF @rcode <> 0
			BEGIN
			SELECT @ErrMsg = ISNULL(@ErrMsg,'')
			GOTO ERROR
			END
		END
		
	---- check tax phase cost type
	---- TK-11964
	IF ISNULL(@TaxPhase,'') = '' SET @TaxPhase = @OldPhase
	IF ISNULL(@TaxCT,0) = 0 SET @TaxCT = @OldJCCType
	

	---- generate JC committed cost transactions for 'OLD' values
	EXEC @rcode = dbo.vspPOItemLineJCCmtdCostUpdate 'OLD', @Month, @OldPostToCo, @OldJob, @OldPhaseGroup,
					@OldPhase, @OldJCCType, @POItemLine, @JCUM, @PostedDate, @OldTaxGroup, @OldTaxType,
					@OldTaxCode, @TaxPhase, @TaxCT, @TaxJCUM, @POITKeyID, @JCUMConv,
					@OldCurUnits, @OldCurCost, @OldCurTax, @OldRemTax, @OldJCCmtdTax, @OldJCRemCmtdTax,
					0, 0, @JCTransType, 
					-- TK-14139 --
					NULL, NULL, NULL,
					@ErrMsg OUTPUT
	IF @rcode <> 0 GOTO ERROR
	
	END

--------------
-- TK-14139 -- START
-------------------------
-- FOR ItemType = 6 PO --
-------------------------
-- when the old item type is 6 then we need to create JCCD committed cost transactions to back out old values
-- when old ItemType = 6 PO
IF @OldItemType = 6 AND
	(@OldPostToCo <> @PostToCo
        OR ISNULL(@SMJob,'') <> ISNULL(@OldSMJob,'')
        OR ISNULL(@SMPhaseGroup,0) <> ISNULL(@OldSMPhaseGroup,0)
		OR ISNULL(@SMPhase,'') <> ISNULL(@OldSMPhase,'')
        OR ISNULL(@SMJCCostType,0) <> ISNULL(@OldSMJCCostType,0)
        --OR ISNULL(@TaxGroup,0) <> ISNULL(@OldTaxGroup,0) --PostToCo change drives tax group change check not required
        OR ISNULL(@TaxType,0) <> ISNULL(@OldTaxType,0)
        OR ISNULL(@TaxCode,'') <> ISNULL(@OldTaxCode,'')
        OR @CurUnits <> @OldCurUnits
        OR @CurCost <> @OldCurCost)
	BEGIN
	
		IF @OldSMJobExistsYN = 'Y'
			BEGIN
				-- VALIDATE SM JOB --
				EXEC @rcode = dbo.bspJobTypeVal @OldPostToCo, 
								@OldSMPhaseGroup, @OldSMJob, @OldSMPhase, @OldSMJCCostType, 
								@JCUM OUTPUT, @ErrMsg OUTPUT
				IF @rcode <> 0
					BEGIN
						SET @ErrMsg = ISNULL(@ErrMsg,'')
						GOTO ERROR
					END

				-- GET JCUM CONVERSION FACTOR --
				EXEC @rcode = dbo.vspPOItemLineJCUMConvGet @MatlGroup, @Material, @UM, @JCUM, 
								@JCUMConv OUTPUT, @ErrMsg OUTPUT
				IF @rcode <> 0
					BEGIN
						SET @ErrMsg = ISNULL(@ErrMsg,'')
						GOTO ERROR
					END
					
				-- INIT TAX VARIABLE --
				SET @TaxPhase = NULL
				SET @TaxCT = NULL
				SET @TaxJCUM = NULL

				-- VALIDATE OLD TAX CODE --
				IF ISNULL(@OldTaxCode,'') <> ''
					BEGIN
						EXEC @rcode = dbo.vspPOItemLineTaxCodeVal @OldPostToCo, 
											@OldSMJob, @OldSMPhaseGroup, @OldSMPhase, @OldSMJCCostType, 
											@OldItemType, @OldTaxGroup, @OldTaxType, @OldTaxCode,
											@TaxPhase OUTPUT, @TaxCT OUTPUT, @TaxJCUM OUTPUT, @ErrMsg OUTPUT
						IF @rcode <> 0
							BEGIN
								SET @ErrMsg = ISNULL(@ErrMsg,'')
								GOTO ERROR
							END
					END
					
				-- CHECK/SET PHASE AND CT --
				IF ISNULL(@TaxPhase,'') = '' SET @TaxPhase = @OldSMPhase
				IF ISNULL(@TaxCT,0) = 0 SET @TaxCT = @OldSMJCCostType
				

				-- GENERATE JC COMMITTED COST TRANSACTIONS FOR 'OLD' VALUES --
				EXEC @rcode = dbo.vspPOItemLineJCCmtdCostUpdate 'OLD', @Month, @OldPostToCo, 
								@OldSMJob, @OldSMPhaseGroup, @OldSMPhase, @OldSMJCCostType, 
								@POItemLine, @JCUM, @PostedDate, @OldTaxGroup, @OldTaxType,
								@OldTaxCode, @TaxPhase, @TaxCT, @TaxJCUM, @POITKeyID, @JCUMConv,
								@OldCurUnits, @OldCurCost, @OldCurTax, @OldRemTax, @OldJCCmtdTax, @OldJCRemCmtdTax,
								0, 0, @JCTransType, 
								-- TK-14139 --
								@OldSMCo, @OldSMWorkOrder, @OldSMScope,
								@ErrMsg OUTPUT
				IF @rcode <> 0 GOTO ERROR
		
			END -- @SMJobExistsYN 
	
	END -- @OldItemType = 6
--------------
-- TK-14139 -- END
--------------	
	
	
---- set backordered units/cost
IF @UM = 'LS'
	BEGIN
	SET @BOUnits = 0
	IF @OldCurCost = 0 AND @CurCost > 0
		BEGIN
		SET @BOCost = @CurCost - @RecvdCost
		END
	ELSE
		BEGIN
		SET @BOCost = @BOCost - @OldCurCost + @CurCost
		END
	END
ELSE
	BEGIN
	SET @BOCost = 0
	IF @OldCurUnits = 0 AND @CurUnits > 0
		BEGIN
		SET @BOUnits = @CurUnits - @RecvdUnits
		END
	ELSE
		BEGIN
		SET @BOUnits = @BOUnits - @OldCurUnits + @CurUnits
		END
	END

---- calculate Total and Remaining
if @UM = 'LS'
	BEGIN
   	SELECT  @RecvdUnits=0, @BOUnits=0, @TotalUnits = 0, @RemUnits = 0,
   			@TotalCost	= @RecvdCost + @BOCost,
   			@RemCost	= @TotalCost - @InvCost
	END
else
	BEGIN
	SELECT  @Factor = CASE @CurECM WHEN 'C' THEN 100 WHEN 'M' THEN 1000 ELSE 1 END
   	SELECT  @TotalUnits = @RecvdUnits + @BOUnits,
   			@TotalCost	= (@TotalUnits * @CurUnitCost) / @Factor,
   			@RemUnits	= @TotalUnits - @InvUnits,
			@RemCost	= (@RemUnits * @CurUnitCost) / @Factor
	END


----DC The @totaltax, @remtax, @JCCmtdTax and @JCRemCmtdTax do not get set to anything 
----if there is no tax code.  Below if those variable are null, it uses the original value from POIT
----which was causing problems.  I solved those problems by setting these variables to 0.00 if there is no tax code
SET @HQTXdebtGLAcct = NULL
SET @TotalTax = 0
SET @RemTax = 0
SET @JCCmtdTax = 0
SET @JCRemCmtdTax = 0
SET @TaxPhase = NULL
SET @TaxCT = NULL
SET @TaxJCUM = NULL


IF ISNULL(@TaxCode,'') <> ''
	BEGIN

		---- initialize tax variables
		SET @TaxPhase = NULL
		SET @TaxCT = NULL
		SET @TaxJCUM = NULL

		-- TK-14139 --
		IF (@ItemType = 6) AND (@SMJobExistsYN = 'Y')
			BEGIN
				---- validate tax code and if item type 6 will also validate tax phase and cost type
				EXEC @rcode = dbo.vspPOItemLineTaxCodeVal @PostToCo, 
									@SMJob, @SMPhaseGroup, @SMPhase, @SMJCCostType, 
									@ItemType, @TaxGroup, @TaxType, @TaxCode,
									@TaxPhase OUTPUT, @TaxCT OUTPUT, @TaxJCUM OUTPUT, @ErrMsg OUTPUT
			END
		ELSE
			BEGIN
				---- validate tax code and if item type 1 will also validate tax phase and cost type
				EXEC @rcode = dbo.vspPOItemLineTaxCodeVal @PostToCo, @Job, @PhaseGroup, @Phase,
									@JCCType, @ItemType, @TaxGroup, @TaxType, @TaxCode,
									@TaxPhase OUTPUT, @TaxCT OUTPUT, @TaxJCUM OUTPUT, @ErrMsg OUTPUT
			END 
			
		IF @rcode <> 0
			BEGIN
				SET @ErrMsg = ISNULL(@ErrMsg,'')
				GOTO ERROR
			END
		
		---- calculate tax values
		EXEC @rcode = dbo.vspPOItemLineTaxCalcs @TaxGroup, @ItemType, @SMJobExistsYN, @PostedDate, 
							@TaxCode, @TaxRate, @GSTRate, @TotalCost, @RemCost,
							@TotalTax OUTPUT, @RemTax OUTPUT, @JCCmtdTax OUTPUT,
							@JCRemCmtdTax OUTPUT, @HQTXdebtGLAcct OUTPUT,
							@ErrMsg OUTPUT
		IF @rcode <> 0 GOTO ERROR

	END
	
---- when the new item type is 1 then we need to create JCCD committed cost transactions for the new values
---- new ItemType = 1 Job
IF @ItemType = 1 AND
	(@PostToCo <> @OldPostToCo
        OR ISNULL(@Job,'') <> ISNULL(@OldJob,'')
        OR ISNULL(@PhaseGroup,0) <> ISNULL(@OldPhaseGroup,0)
		OR ISNULL(@Phase,'') <> ISNULL(@OldPhase,'')
        OR ISNULL(@JCCType,0) <> ISNULL(@OldJCCType,0)
        --OR ISNULL(@TaxGroup,0) <> ISNULL(@OldTaxGroup,0) --PostToCo change drives tax group change check not required
        OR ISNULL(@TaxType,0) <> ISNULL(@OldTaxType,0)
        OR ISNULL(@TaxCode,'') <> ISNULL(@OldTaxCode,'')
        OR @CurUnits <> @OldCurUnits
        OR @CurCost <> @OldCurCost)
	BEGIN
	

	---- validate job
	EXEC @rcode = dbo.bspJobTypeVal @PostToCo, @PhaseGroup, @Job, @Phase, @JCCType, @JCUM OUTPUT, @ErrMsg OUTPUT
	if @rcode <> 0
		BEGIN
		SELECT @ErrMsg = ISNULL(@ErrMsg,'')
		GOTO ERROR
		END

	---- GET JCUM Conversion Factor
	EXEC @rcode = dbo.vspPOItemLineJCUMConvGet @MatlGroup, @Material, @UM, @JCUM,
						@JCUMConv OUTPUT, @ErrMsg OUTPUT
	if @rcode <> 0
		BEGIN
		SELECT @ErrMsg = ISNULL(@ErrMsg,'')
		GOTO ERROR
		END
		
	---- check tax phase cost type
	IF ISNULL(@TaxPhase,'') = '' SET @TaxPhase = @Phase
	IF ISNULL(@TaxCT,0) = 0 SET @TaxCT = @JCCType
	
	---- generate JC committed cost transactions for 'NEW' values
	EXEC @rcode = dbo.vspPOItemLineJCCmtdCostUpdate 'NEW', @Month, @PostToCo, @Job, @PhaseGroup,
					@Phase, @JCCType, @POItemLine, @JCUM, @PostedDate, @TaxGroup, @TaxType,
					@TaxCode, @TaxPhase, @TaxCT, @TaxJCUM, @POITKeyID, @JCUMConv,
					@CurUnits, @CurCost, @TotalTax, @RemTax, @JCCmtdTax, @JCRemCmtdTax,
					0, 0, @JCTransType, 
					-- TK-14139 --
					NULL, NULL, NULL,
					@ErrMsg OUTPUT
	IF @rcode <> 0 GOTO ERROR

	END
	
	
--------------
-- TK-14139 -- START
------------------
-- ItemType = 6 --
------------------
---- when the new item type is 6 then we need to create JCCD committed cost transactions for the new values
---- new ItemType = 6 PO
IF @ItemType = 6 AND
	(@PostToCo <> @OldPostToCo
        OR ISNULL(@SMJob,'') <> ISNULL(@OldSMJob,'')
        OR ISNULL(@SMPhaseGroup,0) <> ISNULL(@OldSMPhaseGroup,0)
		OR ISNULL(@SMPhase,'') <> ISNULL(@OldSMPhase,'')
        OR ISNULL(@SMJCCostType,0) <> ISNULL(@OldSMJCCostType,0)
        --OR ISNULL(@TaxGroup,0) <> ISNULL(@OldTaxGroup,0) --PostToCo change drives tax group change check not required
        OR ISNULL(@TaxType,0) <> ISNULL(@OldTaxType,0)
        OR ISNULL(@TaxCode,'') <> ISNULL(@OldTaxCode,'')
        OR @CurUnits <> @OldCurUnits
        OR @CurCost <> @OldCurCost)
	BEGIN
	
		-- SM JOB? --
		IF @SMJobExistsYN = 'Y'
			BEGIN
				---- validate job
				EXEC @rcode = dbo.bspJobTypeVal @PostToCo, @SMPhaseGroup, @SMJob, @SMPhase, @SMJCCostType, 
								@JCUM OUTPUT, @ErrMsg OUTPUT
				if @rcode <> 0
					BEGIN
					SELECT @ErrMsg = ISNULL(@ErrMsg,'')
					GOTO ERROR
					END

				---- GET JCUM Conversion Factor
				EXEC @rcode = dbo.vspPOItemLineJCUMConvGet @MatlGroup, @Material, @UM, @JCUM,
									@JCUMConv OUTPUT, @ErrMsg OUTPUT
				if @rcode <> 0
					BEGIN
					SELECT @ErrMsg = ISNULL(@ErrMsg,'')
					GOTO ERROR
					END
					
				---- check tax phase cost type
				IF ISNULL(@TaxPhase,'') = '' SET @TaxPhase = @SMPhase
				IF ISNULL(@TaxCT,0) = 0 SET @TaxCT = @SMJCCostType
				
				---- generate JC committed cost transactions for 'NEW' values
				EXEC @rcode = dbo.vspPOItemLineJCCmtdCostUpdate 'NEW', @Month, @PostToCo, @SMJob, @SMPhaseGroup,
								@SMPhase, @SMJCCostType, @POItemLine, @JCUM, @PostedDate, @TaxGroup, @TaxType,
								@TaxCode, @TaxPhase, @TaxCT, @TaxJCUM, @POITKeyID, @JCUMConv,
								@CurUnits, @CurCost, @TotalTax, @RemTax, @JCCmtdTax, @JCRemCmtdTax,
								0, 0, @JCTransType, 
								-- TK-14139 --
								@SMCo, @SMWorkOrder, @SMScope,
								@ErrMsg OUTPUT
				IF @rcode <> 0 GOTO ERROR
				
			END -- @SMJobExistsYN
	END -- @ItemType = 6
--------------
-- TK-14139 -- END
--------------	

IF @OldItemType = 6 OR @ItemType = 6
BEGIN
	SELECT @SMProjCost = @CurCost + ISNULL(@TotalTax, CurTax)
	FROM dbo.vPOItemLine
	WHERE KeyID = @POLineKeyID

	EXEC @rcode = dbo.vspSMWorkCompletedPurchaseUpdate @POCo = @POCo, @PO = @PO, @POItem = @POItem, @POItemLine = @POItemLine, @OldSMCo = @OldSMCo, @OldWorkOrder = @OldSMWorkOrder, @OldScope = @OldSMScope, @OldWorkCompleted = @OldSMWorkCompleted, @Quantity = @CurUnits, @ProjCost = @SMProjCost, @msg = @ErrMsg OUTPUT
	IF @rcode <> 0 GOTO ERROR
END
	
---- update item line with recalculated Totals and Remaining units, costs, and taxes
update dbo.vPOItemLine
		SET JCMonth		= @Month,
			CurTax		= ISNULL(@TotalTax, CurTax),
			BOUnits		= @BOUnits,
			BOCost		= @BOCost,
			TotalUnits	= @TotalUnits,
			TotalCost	= @TotalCost, 
			TotalTax	= ISNULL(@TotalTax, TotalTax),
			RemUnits	= @RemUnits,
			RemCost		= @RemCost,
			RemTax		= ISNULL(@RemTax, RemTax),
			JCCmtdTax	= ISNULL(@JCCmtdTax, JCCmtdTax),
			JCRemCmtdTax= ISNULL(@JCRemCmtdTax, JCRemCmtdTax) 
WHERE KeyID = @POLineKeyID
if @@rowcount <> 1
	BEGIN
	select @ErrMsg = 'ERROR occurred updating PO Item Line Totals.'
	goto ERROR
	END


---- JG 09/23/2011 TK-08142
---- Update the SMPOItemLine
IF @OldItemType = 6 OR @ItemType = 6
BEGIN
	DECLARE @ColumnsUpdated varbinary(max)
	SET @ColumnsUpdated = COLUMNS_UPDATED()

	-- Update SMPOItemLine
	EXEC @rcode = dbo.vspSMModifySMPOItemLine @POCo, @PO, @POItem, @POItemLine, @ColumnsUpdated, @ErrMsg OUTPUT
	IF @rcode <> 0 GOTO ERROR
END

POItemLineUpdateDone:
---- we need to update item line one when another line changes, adjusting the values
---- so that they foot. First get the PO Item Line KeyID, get old values, get current values,
---- and calculate change to current units and current cost.
---- get key id for line 1 in vPOItemLine
SELECT @POLineKeyID = KeyID
FROM dbo.vPOItemLine
WHERE POITKeyID = @POITKeyID
	AND POItemLine = 1
IF @@ROWCOUNT = 0
	BEGIN
	SELECT @ErrMsg = 'ERROR retrieving line one record information.'
	GOTO ERROR
	END

---- get current LINE ONE values from table.
SELECT  @POCo = i.POCo, @PostToCo = i.PostToCo, @PO = i.PO, @POItem = i.POItem,
		@ItemType = i.ItemType, @Job = i.Job, @PhaseGroup = i.PhaseGroup,
		@Phase = i.Phase, @JCCType = i.JCCType, @Loc = i.Loc, @EMGroup = i.EMGroup,
		@Equip = i.Equip, @CompType = i.CompType, @Component = i.Component, @CostCode = i.CostCode, 
		@EMCType = i.EMCType, @WO = i.WO, @WOItem = i.WOItem, @SMCo = i.SMCo, @SMWorkOrder = i.SMWorkOrder, 
		@SMScope = i.SMScope, @TaxGroup = i.TaxGroup, @TaxType = i.TaxType,
		@TaxCode = i.TaxCode, @TaxRate = i.TaxRate, 
		@GSTRate = i.GSTRate, @GLCo = i.GLCo, @GLAcct = i.GLAcct, @ReqDate = i.ReqDate, 
		@PayCategory = i.PayCategory, @PayType = i.PayType, @PostedDate = i.PostedDate, 
		----
		@OrigUnits = i.OrigUnits, @OrigCost = i.OrigCost, @OrigTax = i.OrigTax, @CurUnits = i.CurUnits,
		@CurCost = i.CurCost, @CurTax = i.CurTax, @RecvdUnits = i.RecvdUnits, @RecvdCost = i.RecvdCost, 
		@BOUnits = i.BOUnits, @BOCost = i.BOCost, @InvUnits = i.InvUnits, @InvCost = i.InvCost,
		@InvTax = i.InvTax, @RemUnits = i.RemUnits, @RemCost = i.RemCost,
		@RemTax = i.RemTax, @JCCmtdTax = i.JCCmtdTax, @JCRemCmtdTax = i.JCRemCmtdTax,
		@TotalUnits = i.TotalUnits, @TotalCost = i.TotalCost, @TotalTax = i.TotalTax,
		-- TK-14139 --
  		@SMPhaseGroup = i.SMPhaseGroup, @SMPhase = i.SMPhase, @SMJCCostType = i.SMJCCostType,
		@SMCo = i.SMCo, @SMWorkOrder = i.SMWorkOrder, @SMScope = i.SMScope
FROM dbo.vPOItemLine i
WHERE i.KeyID = @POLineKeyID
IF @@ROWCOUNT = 0
	BEGIN
    SELECT @ErrMsg = 'ERROR retrieving line one record information.'
    GOTO ERROR
    END

---- assume old current values = current values when we are updating line one
---- when a change is made to another line most of the old values do not change
SELECT 	@OldItemType = @ItemType, @OldPostToCo = @PostToCo, @OldJob = @Job,
		@OldPhaseGroup = @PhaseGroup, @OldPhase = @Phase, @OldJCCType = @JCCType,
		@OldLoc = @Loc, @OldOrigUnits = @OrigUnits, @OldOrigCost = @OrigCost, @OldOrigTax = @OrigTax,
		@OldCurUnits = @CurUnits, @OldCurCost = @CurCost, @OldCurTax = @CurTax,
		@OldRemUnits = @RemUnits, @OldRemCost = @RemCost, @OldRemTax = @RemTax,
		@OldBOUnits  = @BOUnits, @OldBOCost = @BOCost, @OldJCCmtdTax = @JCCmtdTax,
		@OldJCRemCmtdTax = @JCRemCmtdTax, @OldTotalUnits = @TotalUnits,
		@OldTotalCost = @TotalCost, @OldTotalTax = @TotalTax,
		-- TK-14139 --
  		@OldSMPhaseGroup = @SMPhaseGroup, @OldSMPhase = @SMPhase, @OldSMJCCostType = @SMJCCostType,
		@OldSMCo = @SMCo, @OldSMWorkOrder = @SMWorkOrder, @OldSMScope = @SMScope

---- check for differences between item units/cost and sum lines units and cost
SET @NewCurUnits = 0
SET @NewCurCost = 0
SELECT  @NewCurUnits = SUM(l.CurUnits),
		@NewCurCost = SUM(l.CurCost)
FROM dbo.vPOItemLine l
WHERE l.POITKeyID = @POITKeyID AND POItemLine > 1
---- if we have a variance between item and line units set line one current units
SET @CurUnits = @ItemCurUnits - @NewCurUnits
---- if we have a variance between item and line cost set line one current cost
SET @CurCost = @ItemCurCost - @NewCurCost



---------------------------------------------
---- UPDATES FOR LINE ONE EITHER DIRECTLY
---- OR WHEN ANOTHER LINE CHANGES AND LINE
---- ONE NEEDS TO BE UPDATED
---------------------------------------------


POItemLineOne_Update_Only:
---- back out old inventory
---- when the old item type is 2 then we need to update INMT On Order and back out the old units
---- if ItemType = 2 inventory,  get UM conversion rate
IF @OldItemType = 2 AND @OldCurUnits <> @CurUnits AND @OldCurUnits <> 0
	BEGIN
	----TK-11964
	IF ISNULL(@Material,'') <> '' AND @POItemLine > 1
		BEGIN
		EXEC @rcode = dbo.vspPOINMTUpdateOnOrder @MatlGroup, @Material, @UM, @OldPostToCo, @OldLoc, @OldCurUnits, 'OLD', @ErrMsg OUTPUT
		if @rcode <> 0 GOTO ERROR
		END
	END	

---- update new inventory 
---- when the new item type is 2 then we need to update INMT On Order and update with new units
---- if ItemType = 2 inventory,  get UM conversion rate
IF @ItemType = 2 AND @OldCurUnits <> @CurUnits AND @CurUnits <> 0
	BEGIN
	----TK-11964
	IF ISNULL(@Material,'') <> '' AND @POItemLine > 1
		BEGIN
		EXEC @rcode = dbo.vspPOINMTUpdateOnOrder @MatlGroup, @Material, @UM, @PostToCo, @Loc, @CurUnits, 'NEW', @ErrMsg OUTPUT
		if @rcode <> 0 GOTO ERROR
		END
	END

IF @ItemType = 6
	BEGIN
		-- VERIFY SMWorkOrder IS VALID AND NOT CLOSED --
		SET @SMWOStatus = NULL
		
		SELECT @SMWOStatus = WOStatus FROM dbo.vSMWorkOrder WHERE SMCo = @PostToCo AND WorkOrder = @SMWorkOrder
		IF (@SMWOStatus <> 0)
			BEGIN
				SET @ErrMsg = 'Invalid SMWorkOrder ' + dbo.vfToString(@SMWorkOrder) + 
							  ' for SMCo ' + dbo.vfToString(@PostToCo) + ' is not open.'
				GOTO ERROR
			END
			
		-- VALIDATE SMScope	 --	
		IF NOT EXISTS(SELECT 1 FROM vSMWorkOrderScope WHERE SMCo = @PostToCo AND WorkOrder = @SMWorkOrder AND Scope = @SMScope)
			BEGIN
				SET @ErrMsg = 'Invalid SMScope ' + dbo.vfToString(@SMScope) + 
							  ' for SMCo ' + dbo.vfToString(@PostToCo) + ' - SMWorkOrder ' + dbo.vfToString(@SMWorkOrder) + ' is not valid.'
				GOTO ERROR
			END
			
		-- DOES SM JOB EXIST? --
		SELECT  @SMJob = Job,  
				@SMJobExistsYN = CASE
									WHEN Job IS NOT NULL THEN 'Y'
									ELSE 'N'
									END
		  FROM  dbo.vSMWorkOrderScope 
		 WHERE  SMCo = @PostToCo AND WorkOrder = @SMWorkOrder AND Scope = @SMScope 
		 
		-- DOES OLD SM JOB EXIST? --
		SELECT  @OldSMJob = Job,  
				@OldSMJobExistsYN = CASE
									WHEN Job IS NOT NULL THEN 'Y'
									ELSE 'N'
									END
		  FROM  dbo.vSMWorkOrderScope 
		 WHERE  SMCo = @OldPostToCo AND WorkOrder = @OldSMWorkOrder AND Scope = @OldSMScope 
	END

---- when the old item type is 1 then we need to create JCCD committed cost transactions to back out old values
---- when old ItemType = 1 Job
IF @OldItemType = 1 AND
	(@OldPostToCo <> @PostToCo
        OR ISNULL(@Job,'') <> ISNULL(@OldJob,'')
        OR ISNULL(@PhaseGroup,0) <> ISNULL(@OldPhaseGroup,0)
		OR ISNULL(@Phase,'') <> ISNULL(@OldPhase,'')
        OR ISNULL(@JCCType,0) <> ISNULL(@OldJCCType,0)
        --OR ISNULL(@TaxGroup,0) <> ISNULL(@OldTaxGroup,0) --PostToCo change drives tax group change check not required
        OR ISNULL(@TaxType,0) <> ISNULL(@OldTaxType,0)
        OR ISNULL(@TaxCode,'') <> ISNULL(@OldTaxCode,'')
        OR @CurUnits <> @OldCurUnits
        OR @CurCost <> @OldCurCost)
	BEGIN
	
	---- validate job
	EXEC @rcode = dbo.bspJobTypeVal @OldPostToCo, @OldPhaseGroup, @OldJob, @OldPhase, @OldJCCType, @JCUM OUTPUT, @ErrMsg OUTPUT
	if @rcode <> 0
		BEGIN
		SELECT @ErrMsg = ISNULL(@ErrMsg,'')
		GOTO ERROR
		END

	---- GET JCUM Conversion Factor
	EXEC @rcode = dbo.vspPOItemLineJCUMConvGet @MatlGroup, @Material, @UM, @JCUM,
						@JCUMConv OUTPUT, @ErrMsg OUTPUT
	if @rcode <> 0
		BEGIN
		SELECT @ErrMsg = ISNULL(@ErrMsg,'')
		GOTO ERROR
		END
		
	---- initialize tax variables
	SET @TaxPhase = NULL
	SET @TaxCT = NULL
	SET @TaxJCUM = NULL

	---- validate tax code if item type = 1-Job will also validate tax phase and cost type
	IF ISNULL(@OldTaxCode,'') <> ''
		BEGIN
		EXEC @rcode = dbo.vspPOItemLineTaxCodeVal @OldPostToCo, @OldJob, @OldPhaseGroup, @OldPhase,
							@OldJCCType, @OldItemType, @OldTaxGroup, @OldTaxType, @OldTaxCode,
							@TaxPhase OUTPUT, @TaxCT OUTPUT, @TaxJCUM OUTPUT, @ErrMsg OUTPUT
		IF @rcode <> 0
			BEGIN
			SELECT @ErrMsg = ISNULL(@ErrMsg,'')
			GOTO ERROR
			END
		END
		
	---- check tax phase cost type
	----TK-11964
	IF ISNULL(@TaxPhase,'') = '' SET @TaxPhase = @OldPhase
	IF ISNULL(@TaxCT,0) = 0 SET @TaxCT = @OldJCCType
	
	---- generate JC committed cost transactions for 'OLD' values
	---- po change order batch post will handle JC commits
	IF @JCTransType <> 'PO Change'
		BEGIN

		SET @OldCmtdRemCost = 0
		SET @OldCmtdRemUnits = 0
		---- if changing from blanket to regular PO we do not have current cost yet
		IF @UM = 'LS' AND @OldOrigCost = 0 AND @OrigCost <> 0
			BEGIN
			SET @OldCurCost = @OldTotalCost
			SET @OldCurTax = @OldTotalTax
			IF @ReceiptUpdate = 'Y'
				BEGIN
				SET @OldCmtdRemCost = @OldRecvdCost
				END
			ELSE	
				BEGIN
				SET @OldCmtdRemCost = @OldInvCost
				END
			END
			
		IF @UM <> 'LS' AND @OldOrigUnits = 0 AND @OrigUnits <> 0
			BEGIN
			SET @OldCurUnits = @OldTotalUnits
			SET @OldCurCost = @OldTotalCost
			SET @OldCurTax = @OldTotalTax
			IF @ReceiptUpdate = 'Y'
				BEGIN
				SET @OldCmtdRemCost = (@OldRecvdUnits * @JCUMConv) * @CurUnitCost
				END
			ELSE	
				BEGIN
				SET @OldCmtdRemCost = (@OldInvUnits * @JCUMConv) * @CurUnitCost
				END
			END
					
		EXEC @rcode = dbo.vspPOItemLineJCCmtdCostUpdate 'OLD', @Month, @OldPostToCo, @OldJob, @OldPhaseGroup,
						@OldPhase, @OldJCCType, 1, @JCUM, @PostedDate, @OldTaxGroup, @OldTaxType,
						@OldTaxCode, @TaxPhase, @TaxCT, @TaxJCUM, @POITKeyID, @JCUMConv,
						@OldCurUnits, @OldCurCost, @OldCurTax, @OldRemTax, @OldJCCmtdTax, @OldJCRemCmtdTax,
						@OldCmtdRemCost, @OldCmtdRemUnits, @JCTransType, 
						-- TK-14139 --
						NULL, NULL, NULL,
						@ErrMsg OUTPUT
		IF @rcode <> 0 GOTO ERROR
		END
	END

--------------
-- TK-14139 -- START
----------------------
-- @OldItemType = 6 --
----------------------
---- when the old item type is 6 then we need to create JCCD committed cost transactions to back out old values
---- when old ItemType = 6 PO
IF @OldItemType = 6 AND
	(@OldPostToCo <> @PostToCo
        OR ISNULL(@SMJob,'') <> ISNULL(@OldSMJob,'')
        OR ISNULL(@SMPhaseGroup,0) <> ISNULL(@OldSMPhaseGroup,0)
		OR ISNULL(@SMPhase,'') <> ISNULL(@OldSMPhase,'')
        OR ISNULL(@SMJCCostType,0) <> ISNULL(@OldSMJCCostType,0)
        --OR ISNULL(@TaxGroup,0) <> ISNULL(@OldTaxGroup,0) --PostToCo change drives tax group change check not required
        OR ISNULL(@TaxType,0) <> ISNULL(@OldTaxType,0)
        OR ISNULL(@TaxCode,'') <> ISNULL(@OldTaxCode,'')
        OR @CurUnits <> @OldCurUnits
        OR @CurCost <> @OldCurCost)
	BEGIN
		-- Validate the SM Work Order
		EXEC @rcode = vspSMWorkCompletedWorkOrderVal @SMCo = @OldSMCo, @WorkOrder = @OldSMWorkOrder, @IsCancelledOK ='N', @msg = @ErrMsg OUTPUT
		IF (@rcode <> 0)
		BEGIN
			SELECT @ErrMsg = 'Error validating the original Item Distribution for an SM Work Order - ' + ISNULL(@ErrMsg, '')
			GOTO ERROR
		END
		
		-- WAS THERE AN SM JOB? --
		IF @OldSMJobExistsYN = 'Y'
			BEGIN
				-- VALIDATE JOB --
				EXEC @rcode = dbo.bspJobTypeVal @OldPostToCo, @OldSMPhaseGroup, @OldSMJob, 
								@OldSMPhase, @OldSMJCCostType, 
								@JCUM OUTPUT, @ErrMsg OUTPUT
				if @rcode <> 0
					BEGIN
						SELECT @ErrMsg = ISNULL(@ErrMsg,'')
						GOTO ERROR
					END

				-- GET JCUM CONVERSION FACTOR -- 
				EXEC @rcode = dbo.vspPOItemLineJCUMConvGet @MatlGroup, @Material, @UM, @JCUM,
									@JCUMConv OUTPUT, @ErrMsg OUTPUT
				if @rcode <> 0
					BEGIN
						SELECT @ErrMsg = ISNULL(@ErrMsg,'')
						GOTO ERROR
					END
			
				-- INIT TAX VARIABLES --
				SET @TaxPhase = NULL
				SET @TaxCT = NULL
				SET @TaxJCUM = NULL

				-- VALIDATE TAX CODE - ALSO VALIDATES TAX PHASE AND TAX COSTTYPE --
				IF ISNULL(@OldTaxCode,'') <> ''
					BEGIN
						EXEC @rcode = dbo.vspPOItemLineTaxCodeVal @OldPostToCo, @OldSMJob, 
											@OldSMPhaseGroup, @OldSMPhase,@OldSMJCCostType, 
											@OldItemType, @OldTaxGroup, @OldTaxType, @OldTaxCode,
											@TaxPhase OUTPUT, @TaxCT OUTPUT, @TaxJCUM OUTPUT, @ErrMsg OUTPUT
						IF @rcode <> 0
							BEGIN
								SELECT @ErrMsg = ISNULL(@ErrMsg,'')
								GOTO ERROR
							END
						END
					
				-- CHECK TAX PHASE AND COSTTYPE --
				----TK-11964
				IF ISNULL(@TaxPhase,'') = '' SET @TaxPhase = @OldSMPhase
				IF ISNULL(@TaxCT,0) = 0 SET @TaxCT = @OldSMJCCostType
	
	
		--END -- @SMJobExistsYN
	
	
				---- generate JC committed cost transactions for 'OLD' values
				---- po change order batch post will handle JC commits
				IF @JCTransType <> 'PO Change'
					BEGIN

						SET @OldCmtdRemCost = 0
						SET @OldCmtdRemUnits = 0
						---- if changing from blanket to regular PO we do not have current cost yet
						IF @UM = 'LS' AND @OldOrigCost = 0 AND @OrigCost <> 0
							BEGIN
								SET @OldCurCost = @OldTotalCost
								SET @OldCurTax = @OldTotalTax
								IF @ReceiptUpdate = 'Y'
									BEGIN
										SET @OldCmtdRemCost = @OldRecvdCost
									END
								ELSE	
									BEGIN
										SET @OldCmtdRemCost = @OldInvCost
									END
							END
						
						IF @UM <> 'LS' AND @OldOrigUnits = 0 AND @OrigUnits <> 0
							BEGIN
								SET @OldCurUnits = @OldTotalUnits
								SET @OldCurCost = @OldTotalCost
								SET @OldCurTax = @OldTotalTax
								IF @ReceiptUpdate = 'Y'
									BEGIN
										SET @OldCmtdRemCost = (@OldRecvdUnits * @JCUMConv) * @CurUnitCost
									END
								ELSE	
									BEGIN
										SET @OldCmtdRemCost = (@OldInvUnits * @JCUMConv) * @CurUnitCost
									END
							END
								
						IF @OldSMJobExistsYN = 'Y'
							BEGIN
								EXEC @rcode = dbo.vspPOItemLineJCCmtdCostUpdate 'OLD', @Month, @OldPostToCo, 
												@OldSMJob, @OldSMPhaseGroup, @OldSMPhase, @OldSMJCCostType, 1, 
												@JCUM, @PostedDate, @OldTaxGroup, @OldTaxType, @OldTaxCode, 
												@TaxPhase, @TaxCT, @TaxJCUM, @POITKeyID, @JCUMConv, @OldCurUnits, 
												@OldCurCost, @OldCurTax, @OldRemTax, @OldJCCmtdTax, @OldJCRemCmtdTax,
												@OldCmtdRemCost, @OldCmtdRemUnits, @JCTransType, 
												-- TK-14139 --
												@OldSMCo, @OldSMWorkOrder, @OldSMScope,
												@ErrMsg OUTPUT
								IF @rcode <> 0 GOTO ERROR
							END
						
					END -- @JCTransType
			END -- @SMJobExistsYN
	END -- @OldItemType
--------------
-- TK-14139 -- END
--------------


---- if flag = 'N' and we are updating line 1 then we
---- do not need to calculate backordered units/cost
---- handled in batch processes
IF @LineFlag IN ('N','C') AND @POItemLine = 1 GOTO calc_line_one_totals

---- set backordered units/cost
IF @UM = 'LS'
	BEGIN
	SET @BOUnits = 0
	SET @BOCost = @CurCost - @RecvdCost
	END
ELSE
	BEGIN
	SET @BOCost = 0
	SET @BOUnits = @CurUnits - @RecvdUnits
	END
	

calc_line_one_totals:

---- calculate Total and Remaining
if @UM = 'LS'
	BEGIN
   	SELECT  @RecvdUnits=0, @BOUnits=0, @TotalUnits = 0, @RemUnits = 0,
   			@TotalCost	= @RecvdCost + @BOCost,
   			@RemCost	= @TotalCost - @InvCost
	END
else
	BEGIN
	SELECT  @Factor = CASE @CurECM WHEN 'C' THEN 100 WHEN 'M' THEN 1000 ELSE 1 END
   	SELECT  @TotalUnits = @RecvdUnits + @BOUnits,
   			@TotalCost	= (@TotalUnits * @CurUnitCost) / @Factor,
   			@RemUnits	= @TotalUnits - @InvUnits,
			@RemCost	= (@RemUnits * @CurUnitCost) / @Factor
	END


----DC The @totaltax, @remtax, @JCCmtdTax and @JCRemCmtdTax do not get set to anything 
----if there is no tax code.  Below if those variable are null, it uses the original value from POIT
----which was causing problems.  I solved those problems by setting these variables to 0.00 if there is no tax code
SET @HQTXdebtGLAcct = NULL
SET @TotalTax = 0
SET @RemTax = 0
SET @JCCmtdTax = 0
SET @JCRemCmtdTax = 0
SET @TaxPhase = NULL
SET @TaxCT = NULL
SET @TaxJCUM = NULL

IF ISNULL(@TaxCode,'') <> ''
	BEGIN
        
		---- initialize tax variables
		SET @TaxPhase = NULL
		SET @TaxCT = NULL
		SET @TaxJCUM = NULL

		-- TK-14139 --
		-- SM WITH A JOB? --
		IF (@ItemType = 6) AND (@SMJobExistsYN = 'Y')
			BEGIN
				EXEC @rcode = dbo.vspPOItemLineTaxCodeVal @PostToCo, 
								@SMJob, @SMPhaseGroup, @SMPhase, @SMJCCostType, 
								@ItemType, @TaxGroup, @TaxType, @TaxCode, 
								@TaxPhase OUTPUT, @TaxCT OUTPUT, @TaxJCUM OUTPUT,
								@ErrMsg OUTPUT
			END
		ELSE
			BEGIN
				---- validate tax code and if item type 1 will also validate tax phase and cost type
				EXEC @rcode = dbo.vspPOItemLineTaxCodeVal @PostToCo, @Job, @PhaseGroup, @Phase,
									@JCCType, @ItemType, @TaxGroup, @TaxType, @TaxCode,
									@TaxPhase OUTPUT, @TaxCT OUTPUT, @TaxJCUM OUTPUT, 
									@ErrMsg OUTPUT
			END
		IF @rcode <> 0
			BEGIN
			SELECT @ErrMsg = ISNULL(@ErrMsg,'')
			GOTO ERROR
			END
	
		SET @OldCmtdRemCost = @TotalCost
		---- if changing from blanket to regular PO with BO Cost we need to calculate total cost
		IF @UM = 'LS' AND @OldOrigCost = 0 AND @OrigCost <> 0 AND @OldBOCost <> 0
			BEGIN
			SET @OldCmtdRemCost = @TotalCost + @RemCost
			END
		---- same logic for non LS except check units
		IF @UM <> 'LS' AND @OldOrigUnits = 0 AND @OrigUnits <> 0 AND @OldBOUnits <> 0
			BEGIN
			SET @OldCmtdRemCost = @TotalCost + @RemCost
			END
			
		---- calculate tax values
		EXEC @rcode = dbo.vspPOItemLineTaxCalcs @TaxGroup, @ItemType, @SMJobExistsYN, @PostedDate, 
							@TaxCode, @TaxRate, @GSTRate, @OldCmtdRemCost, @RemCost,
							@TotalTax OUTPUT, @RemTax OUTPUT, @JCCmtdTax OUTPUT,
							@JCRemCmtdTax OUTPUT, @HQTXdebtGLAcct OUTPUT,
							@ErrMsg OUTPUT
		IF @rcode <> 0 GOTO ERROR

	END


---- when the new item type is 1 then we need to create JCCD committed cost transactions for the new values
---- new ItemType = 1 Job
IF @ItemType = 1 AND
	(@PostToCo <> @OldPostToCo
        OR ISNULL(@Job,'') <> ISNULL(@OldJob,'')
        OR ISNULL(@PhaseGroup,0) <> ISNULL(@OldPhaseGroup,0)
		OR ISNULL(@Phase,'') <> ISNULL(@OldPhase,'')
        OR ISNULL(@JCCType,0) <> ISNULL(@OldJCCType,0)
        --OR ISNULL(@TaxGroup,0) <> ISNULL(@OldTaxGroup,0) --PostToCo change drives tax group change check not required
        OR ISNULL(@TaxType,0) <> ISNULL(@OldTaxType,0)
        OR ISNULL(@TaxCode,'') <> ISNULL(@OldTaxCode,'')
        OR @CurUnits <> @OldCurUnits
        OR @CurCost <> @OldCurCost)
	BEGIN

	---- validate job
	EXEC @rcode = dbo.bspJobTypeVal @PostToCo, @PhaseGroup, @Job, @Phase, @JCCType, @JCUM OUTPUT, @ErrMsg OUTPUT
	if @rcode <> 0
		BEGIN
		SELECT @ErrMsg = ISNULL(@ErrMsg,'')
		GOTO ERROR
		END

	---- GET JCUM Conversion Factor
	EXEC @rcode = dbo.vspPOItemLineJCUMConvGet @MatlGroup, @Material, @UM, @JCUM,
						@JCUMConv OUTPUT, @ErrMsg OUTPUT
	if @rcode <> 0
		BEGIN
		SELECT @ErrMsg = ISNULL(@ErrMsg,'')
		GOTO ERROR
		END
		
	---- check tax phase cost type
	IF ISNULL(@TaxPhase,'') = '' SET @TaxPhase = @Phase
	IF ISNULL(@TaxCT,0) = 0 SET @TaxCT = @JCCType

	---- generate JC committed cost transactions for 'NEW' values
	---- po change order batch post will handle JC commits
	IF @JCTransType <> 'PO Change'
		BEGIN
		
		SET @OldCmtdRemCost = 0
		SET @OldCmtdRemUnits = 0
		---- if changing from blanket to regular PO we need to do something special
		IF @UM = 'LS' AND @OldOrigCost = 0 AND @OrigCost <> 0
			BEGIN
			IF @OldBOCost = 0
				BEGIN
				SET @OldCmtdRemCost = @OldTotalCost
				END
			ELSE
				BEGIN
				SET @OldCmtdRemCost = @OldTotalCost - @OldBOCost
				END
			END
			
		IF @UM <> 'LS' AND @OldOrigUnits = 0 AND @OrigUnits <> 0
			BEGIN
			IF @ReceiptUpdate = 'N'
				BEGIN
				SET @OldCmtdRemUnits = @OldInvUnits
				SET @OldCmtdRemCost = (@OldInvUnits * @JCUMConv) * @CurUnitCost
				END
			ELSE
				BEGIN
				SET @OldCmtdRemUnits = @OldTotalUnits
				SET @OldCmtdRemCost = @OldTotalCost
				END
			END
					
		EXEC @rcode = dbo.vspPOItemLineJCCmtdCostUpdate 'NEW', @Month, @PostToCo, @Job, @PhaseGroup,
						@Phase, @JCCType, 1, @JCUM, @PostedDate, @TaxGroup, @TaxType,
						@TaxCode, @TaxPhase, @TaxCT, @TaxJCUM, @POITKeyID, @JCUMConv,
						@CurUnits, @CurCost, @TotalTax, @RemTax, @JCCmtdTax, @JCRemCmtdTax,
						@OldCmtdRemCost, @OldCmtdRemUnits, @JCTransType, 
						-- TK-14139 --
						NULL, NULL, NULL,
						@ErrMsg OUTPUT
		IF @rcode <> 0 GOTO ERROR
		END
	END


--------------
-- TK-14139 -- START
--------------
---- when the new item type is 6 then we need to create JCCD committed cost transactions for the new values
---- new ItemType = 6 PO
IF @ItemType = 6 AND
	(@PostToCo <> @OldPostToCo
        OR ISNULL(@SMJob,'') <> ISNULL(@OldSMJob,'')
        OR ISNULL(@SMPhaseGroup,0) <> ISNULL(@OldSMPhaseGroup,0)
		OR ISNULL(@SMPhase,'') <> ISNULL(@OldSMPhase,'')
        OR ISNULL(@SMJCCostType,0) <> ISNULL(@OldSMJCCostType,0)
        --OR ISNULL(@TaxGroup,0) <> ISNULL(@OldTaxGroup,0) --PostToCo change drives tax group change check not required
        OR ISNULL(@TaxType,0) <> ISNULL(@OldTaxType,0)
        OR ISNULL(@TaxCode,'') <> ISNULL(@OldTaxCode,'')
        OR @CurUnits <> @OldCurUnits
        OR @CurCost <> @OldCurCost)
	BEGIN

		IF @SMJobExistsYN = 'Y'
			BEGIN
				---- validate job
				EXEC @rcode = dbo.bspJobTypeVal @PostToCo, @SMPhaseGroup, @SMJob, 
								@SMPhase, @SMJCCostType, @JCUM OUTPUT, @ErrMsg OUTPUT
				if @rcode <> 0
					BEGIN
						SET @ErrMsg = ISNULL(@ErrMsg,'')
						GOTO ERROR
					END

				---- GET JCUM Conversion Factor
				EXEC @rcode = dbo.vspPOItemLineJCUMConvGet @MatlGroup, @Material, @UM, @JCUM,
									@JCUMConv OUTPUT, @ErrMsg OUTPUT
				if @rcode <> 0
					BEGIN
						SELECT @ErrMsg = ISNULL(@ErrMsg,'')
						GOTO ERROR
					END
			END -- @SMJobExistsYN
		
		-- CHECK TAX PHASE AND COSTTYPE
		IF ISNULL(@TaxPhase,'') = '' SET @TaxPhase = @Phase
		IF ISNULL(@TaxCT,0) = 0 SET @TaxCT = @JCCType

		---- generate JC committed cost transactions for 'NEW' values
		---- po change order batch post will handle JC commits
		IF @JCTransType <> 'PO Change'
			BEGIN
			
				SET @OldCmtdRemCost = 0
				SET @OldCmtdRemUnits = 0
				---- if changing from blanket to regular PO we need to do something special
				IF @UM = 'LS' AND @OldOrigCost = 0 AND @OrigCost <> 0
					BEGIN
						IF @OldBOCost = 0
							BEGIN
								SET @OldCmtdRemCost = @OldTotalCost
							END
						ELSE
							BEGIN
								SET @OldCmtdRemCost = @OldTotalCost - @OldBOCost
							END
					END
				
				IF @UM <> 'LS' AND @OldOrigUnits = 0 AND @OrigUnits <> 0
					BEGIN
						IF @ReceiptUpdate = 'N'
							BEGIN
								SET @OldCmtdRemUnits = @OldInvUnits
								SET @OldCmtdRemCost = (@OldInvUnits * @JCUMConv) * @CurUnitCost
							END
						ELSE
							BEGIN
								SET @OldCmtdRemUnits = @OldTotalUnits
								SET @OldCmtdRemCost = @OldTotalCost
							END
					END

				-- SM HAS A JOB? --
				IF @SMJobExistsYN = 'Y'
					BEGIN
						EXEC @rcode = dbo.vspPOItemLineJCCmtdCostUpdate 'NEW', @Month, @PostToCo, 
										@SMJob, @SMPhaseGroup, @SMPhase, @SMJCCostType, 1, 
										@JCUM, @PostedDate, @TaxGroup, @TaxType, @TaxCode, @TaxPhase, 
										@TaxCT, @TaxJCUM, @POITKeyID, @JCUMConv, @CurUnits, @CurCost, 
										@TotalTax, @RemTax, @JCCmtdTax, @JCRemCmtdTax,
										@OldCmtdRemCost, @OldCmtdRemUnits, @JCTransType, 
										-- TK-14139 --
										@SMCo, @SMWorkOrder, @SMScope,
										@ErrMsg OUTPUT
						IF @rcode <> 0 GOTO ERROR
						END
			END -- @JCTransType
	END -- @ItemType
--------------
-- TK-14139 -- END
--------------

IF @OldItemType = 6 OR @ItemType = 6
BEGIN
	IF @LineFlag = 'N' AND @POItemLine = 1
	BEGIN
		SET @SMProjCost = @CurCost + @CurTax
	END
	ELSE
	BEGIN
		SELECT @SMProjCost = @CurCost + ISNULL(@TotalTax, CurTax)
		FROM dbo.vPOItemLine
		WHERE KeyID = @POLineKeyID
	END

	EXEC @rcode = dbo.vspSMWorkCompletedPurchaseUpdate @POCo = @POCo, @PO = @PO, @POItem = @POItem, @POItemLine = 1, @OldSMCo = @OldSMCo, @OldWorkOrder = @OldSMWorkOrder, @OldScope = @OldSMScope, @OldWorkCompleted = @OldSMWorkCompleted, @Quantity = @CurUnits, @ProjCost = @SMProjCost, @msg = @ErrMsg OUTPUT
	IF @rcode <> 0 GOTO ERROR
END

---- update item line one with recalcalated values
---- only update values depending on if a PO batch
---- process is posting to line 1 or we are making
---- an adjustment to line 1 via another line.
IF @LineFlag = 'N' AND @POItemLine = 1
	BEGIN
	update dbo.vPOItemLine
			SET BOCost		= @BOCost,
				TotalUnits	= @TotalUnits,
				TotalCost	= @TotalCost, 
				TotalTax	= ISNULL(@TotalTax, TotalTax),
				RemUnits	= @RemUnits,
				RemCost		= @RemCost,
				RemTax		= ISNULL(@RemTax, RemTax),
				JCCmtdTax	= ISNULL(@JCCmtdTax, JCCmtdTax),
				JCRemCmtdTax= ISNULL(@JCRemCmtdTax, JCRemCmtdTax),
				LineDelete	= 'N'
	WHERE KeyID = @POLineKeyID
	if @@rowcount <> 1
		BEGIN
		select @ErrMsg = 'ERROR occurred updating PO Item Line Totals.'
		goto ERROR
		END
	END
ELSE
	BEGIN
	update dbo.vPOItemLine
			SET CurUnits	= @CurUnits,
				CurCost		= @CurCost,
				CurTax		= ISNULL(@TotalTax, CurTax),
				BOUnits		= @BOUnits,
				BOCost		= @BOCost,
				TotalUnits	= @TotalUnits,
				TotalCost	= @TotalCost, 
				TotalTax	= ISNULL(@TotalTax, TotalTax),
				RemUnits	= @RemUnits,
				RemCost		= @RemCost,
				RemTax		= ISNULL(@RemTax, RemTax),
				JCCmtdTax	= ISNULL(@JCCmtdTax, JCCmtdTax),
				JCRemCmtdTax= ISNULL(@JCRemCmtdTax, JCRemCmtdTax),
				LineDelete	= 'N'
	WHERE KeyID = @POLineKeyID
	if @@rowcount <> 1
		BEGIN
		select @ErrMsg = 'ERROR occurred updating PO Item Line Totals.'
		goto ERROR
		END
	END

---- update POIT item with total units, cost, tax, remain units, cost, tax,
---- JC committed tax, and JC remain committed tax
UPDATE poit
		SET CurUnits	= line.CurUnits,
			CurCost		= line.CurCost,
			CurTax		= line.CurTax,
			TotalUnits	= line.TotalUnits,
			TotalCost	= line.TotalCost,
			TotalTax	= line.TotalTax,
			BOUnits		= line.BOUnits,
			BOCost		= line.BOCost,
			RemUnits	= line.RemUnits,
			RemCost		= line.RemCost,
			RemTax		= line.RemTax,
			JCCmtdTax	= line.JCCmtdTax,
			JCRemCmtdTax= line.JCRemCmtdTax,
			RecvdUnits	= line.RecvdUnits,
			RecvdCost	= line.RecvdCost,
			InvUnits	= line.InvUnits,
			InvCost		= line.InvCost,
			InvTax		= line.InvTax,
			InvMiscAmt	= line.InvMiscAmt
			
		FROM dbo.bPOIT poit
		INNER JOIN (SELECT  POITKeyID,
							SUM(CurUnits) CurUnits,
							SUM(CurCost) CurCost,
							SUM(CurTax)	CurTax,
							SUM(TotalUnits) TotalUnits,
							SUM(TotalCost) TotalCost,
							SUM(TotalTax) TotalTax,
							SUM(BOUnits) BOUnits,
							SUM(BOCost) BOCost,
							SUM(RemUnits) RemUnits,
							SUM(RemCost) RemCost,
							SUM(RemTax) RemTax,
							SUM(JCCmtdTax) JCCmtdTax,
							SUM(JCRemCmtdTax) JCRemCmtdTax,
							SUM(RecvdUnits) RecvdUnits,
							SUM(RecvdCost) RecvdCost,
							SUM(InvUnits) InvUnits,
							SUM(InvCost) InvCost,
							SUM(InvTax) InvTax,
							SUM(InvMiscAmt) InvMiscAmt
							
		FROM dbo.vPOItemLine
					WHERE POITKeyID = @POITKeyID GROUP BY POITKeyID) line
					ON line.POITKeyID = poit.KeyID 
					WHERE poit.KeyID = @POITKeyID
	
POItemLine_Next:
if @numrows > 1
	BEGIN
	FETCH NEXT FROM vcPOItemLine_update INTO @POLineKeyID, @POITKeyID, @POItemLine

	if @@fetch_status = 0 goto POItemLine_Loop

	CLOSE vcPOItemLine_update
	DEALLOCATE vcPOItemLine_update
	SET @opencursor = 0
	END
	
	
	
---- Insert records into HQMA for changes made to audited fields
IF NOT EXISTS(SELECT 1 FROM INSERTED i JOIN dbo.bPOCO c ON c.POCo = i.POCo where c.AuditPOs = 'Y')
	BEGIN
	RETURN
	END

if update(ItemType)
	insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vPOItemLine', 'PO: ' + i.PO + ' Item: ' + convert(varchar(10),i.POItem) + ' Line: ' + CONVERT(VARCHAR(10),i.POItemLine),
		i.POCo, 'C', 'Item Type', Convert(varchar(2),d.ItemType), Convert(varchar(2),i.ItemType), getdate(), SUSER_SNAME()
 	from inserted i
    join deleted d on i.POCo = d.POCo and i.PO = d.PO and i.POItem = d.POItem
    join dbo.bPOCO c with (nolock) on c.POCo = i.POCo
    where i.ItemType <> d.ItemType and c.AuditPOs = 'Y'

if update(PostToCo)
    insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vPOItemLine', 'PO: ' + i.PO + ' Item: ' + convert(varchar(10),i.POItem) + ' Line: ' + CONVERT(VARCHAR(10),i.POItemLine),
			i.POCo, 'C', 'Post To Co#', convert(varchar(3),d.PostToCo), convert(varchar(3),i.PostToCo), getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.POCo = d.POCo and i.PO = d.PO and i.POItem = d.POItem
    join dbo.bPOCO c with (nolock) on c.POCo = i.POCo
    where i.PostToCo <> d.PostToCo and c.AuditPOs = 'Y'
   
if update(Loc)
    insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vPOItemLine', 'PO: ' + i.PO + ' Item: ' + convert(varchar(10),i.POItem) + ' Line: ' + CONVERT(VARCHAR(10),i.POItemLine),
			i.POCo, 'C', 'Location', d.Loc, i.Loc, getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.POCo = d.POCo and i.PO = d.PO and i.POItem = d.POItem
    join dbo.bPOCO c with (nolock) on c.POCo = i.POCo
    where isnull(i.Loc,'') <> isnull(d.Loc,'') and c.AuditPOs = 'Y'

if update(Job)
    insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vPOItemLine', 'PO: ' + i.PO + ' Item: ' + convert(varchar(10),i.POItem) + ' Line: ' + CONVERT(VARCHAR(10),i.POItemLine),
			i.POCo, 'C', 'Job', d.Job, i.Job, getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.POCo = d.POCo and i.PO = d.PO and i.POItem = d.POItem
    join dbo.bPOCO c with (nolock) on c.POCo = i.POCo
    where isnull(i.Job,'') <> isnull(d.Job,'') and c.AuditPOs = 'Y'

if update(Phase)
    insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vPOItemLine', 'PO: ' + i.PO + ' Item: ' + convert(varchar(10),i.POItem) + ' Line: ' + CONVERT(VARCHAR(10),i.POItemLine),
			i.POCo, 'C', 'Phase', d.Phase, i.Phase, getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.POCo = d.POCo and i.PO = d.PO and i.POItem = d.POItem
    join dbo.bPOCO c with (nolock) on c.POCo = i.POCo
    where isnull(i.Phase,'') <> isnull(d.Phase,'') and c.AuditPOs = 'Y'

if update(JCCType)
    insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vPOItemLine', 'PO: ' + i.PO + ' Item: ' + convert(varchar(10),i.POItem) + ' Line: ' + CONVERT(VARCHAR(10),i.POItemLine),
			i.POCo, 'C', 'JC Cost Type', convert(varchar(3),d.JCCType), convert(varchar(3),i.JCCType), getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.POCo = d.POCo and i.PO = d.PO and i.POItem = d.POItem
	join dbo.bPOCO c with (nolock) on c.POCo = i.POCo
    where isnull(i.JCCType,0) <> isnull(d.JCCType,0) and c.AuditPOs = 'Y'
   
if update(Equip)
    insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vPOItemLine', 'PO: ' + i.PO + ' Item: ' + convert(varchar(10),i.POItem) + ' Line: ' + CONVERT(VARCHAR(10),i.POItemLine),
			i.POCo, 'C', 'Equipment', d.Equip, i.Equip, getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.POCo = d.POCo and i.PO = d.PO and i.POItem = d.POItem
    join dbo.bPOCO c with (nolock) on c.POCo = i.POCo
    where isnull(i.Equip,'') <> isnull(d.Equip,'') and c.AuditPOs = 'Y'

if update(Component)
    insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vPOItemLine', 'PO: ' + i.PO + ' Item: ' + convert(varchar(10),i.POItem) + ' Line: ' + CONVERT(VARCHAR(10),i.POItemLine),
			i.POCo, 'C', 'Component', d.Component, i.Component, getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.POCo = d.POCo and i.PO = d.PO and i.POItem = d.POItem
    join dbo.bPOCO c with (nolock) on c.POCo = i.POCo
    where isnull(i.Component,'') <> isnull(d.Component,'') and c.AuditPOs = 'Y'
   
if update(CostCode)
    insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vPOItemLine', 'PO: ' + i.PO + ' Item: ' + convert(varchar(10),i.POItem) + ' Line: ' + CONVERT(VARCHAR(10),i.POItemLine),
			i.POCo, 'C', 'Cost Code', d.CostCode, i.CostCode, getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.POCo = d.POCo and i.PO = d.PO and i.POItem = d.POItem
    JOIN dbo.bPOCO c with (nolock) on c.POCo = i.POCo
    where isnull(i.CostCode,'') <> isnull(d.CostCode,'') and c.AuditPOs = 'Y'

if update(EMCType)
    insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vPOItemLine', 'PO: ' + i.PO + ' Item: ' + convert(varchar(10),i.POItem) + ' Line: ' + CONVERT(VARCHAR(10),i.POItemLine),
			i.POCo, 'C', 'EM Cost Type', convert(varchar(3),d.EMCType), convert(varchar(3),i.EMCType), getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.POCo = d.POCo and i.PO = d.PO and i.POItem = d.POItem
    JOIN dbo.bPOCO c with (nolock) on c.POCo = i.POCo
    where isnull(i.EMCType,0) <> isnull(d.EMCType,0) and c.AuditPOs = 'Y'
   
if update(WO)
    insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vPOItemLine', 'PO: ' + i.PO + ' Item: ' + convert(varchar(10),i.POItem) + ' Line: ' + CONVERT(VARCHAR(10),i.POItemLine),
			i.POCo, 'C', 'Work Order', d.WO, i.WO, getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.POCo = d.POCo and i.PO = d.PO and i.POItem = d.POItem
    JOIN dbo.bPOCO c with (nolock) on c.POCo = i.POCo
    where isnull(i.WO,'') <> isnull(d.WO,'') and c.AuditPOs = 'Y'

if update(WOItem)
    insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vPOItemLine', 'PO: ' + i.PO + ' Item: ' + convert(varchar(10),i.POItem) + ' Line: ' + CONVERT(VARCHAR(10),i.POItemLine),
			i.POCo, 'C', 'WO Item', convert(varchar(6),d.WOItem), convert(varchar(6),i.WOItem), getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.POCo = d.POCo and i.PO = d.PO and i.POItem = d.POItem
    JOIN dbo.bPOCO c with (nolock) on c.POCo = i.POCo
    where isnull(i.WOItem,0) <> isnull(d.WOItem,0) and c.AuditPOs = 'Y'

if update(GLCo)
    insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vPOItemLine', 'PO: ' + i.PO + ' Item: ' + convert(varchar(10),i.POItem) + ' Line: ' + CONVERT(VARCHAR(10),i.POItemLine),
			i.POCo, 'C', 'GL Co#', convert(varchar(3),d.GLCo), convert(varchar(3),i.GLCo), getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.POCo = d.POCo and i.PO = d.PO and i.POItem = d.POItem
    JOIN dbo.bPOCO c with (nolock) on c.POCo = i.POCo
    where i.GLCo <> d.GLCo and c.AuditPOs = 'Y'

if update(GLAcct)
    insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vPOItemLine', 'PO: ' + i.PO + ' Item: ' + convert(varchar(10),i.POItem) + ' Line: ' + CONVERT(VARCHAR(10),i.POItemLine),
			i.POCo, 'C', 'GL Account', d.GLAcct, i.GLAcct, getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.POCo = d.POCo and i.PO = d.PO and i.POItem = d.POItem
    JOIN dbo.bPOCO c with (nolock) on c.POCo = i.POCo
    where i.GLAcct <> d.GLAcct and c.AuditPOs = 'Y'
   
if update(ReqDate)
    insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vPOItemLine', 'PO: ' + i.PO + ' Item: ' + convert(varchar(10),i.POItem) + ' Line: ' + CONVERT(VARCHAR(10),i.POItemLine),
			i.POCo, 'C', 'Req Date', convert(varchar(8),d.ReqDate,1), convert(varchar(8),i.ReqDate,1), getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.POCo = d.POCo and i.PO = d.PO and i.POItem = d.POItem
    JOIN dbo.bPOCO c with (nolock) on c.POCo = i.POCo
    where isnull(i.ReqDate,'') <> isnull(d.ReqDate,'') and c.AuditPOs = 'Y'

if update(TaxCode)
    insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vPOItemLine', 'PO: ' + i.PO + ' Item: ' + convert(varchar(10),i.POItem) + ' Line: ' + CONVERT(VARCHAR(10),i.POItemLine),
			i.POCo, 'C', 'Tax Code', d.TaxCode, i.TaxCode, getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.POCo = d.POCo and i.PO = d.PO and i.POItem = d.POItem
    JOIN dbo.bPOCO c with (nolock) on c.POCo = i.POCo
    where isnull(i.TaxCode,'') <> isnull(d.TaxCode,'') and c.AuditPOs = 'Y'
   
if update(TaxType)
    insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vPOItemLine', 'PO: ' + i.PO + ' Item: ' + convert(varchar(10),i.POItem) + ' Line: ' + CONVERT(VARCHAR(10),i.POItemLine),
			i.POCo, 'C', 'Tax Type', convert(varchar(2),d.TaxType), convert(varchar(2),i.TaxType), getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.POCo = d.POCo and i.PO = d.PO and i.POItem = d.POItem
    JOIN dbo.bPOCO c with (nolock) on c.POCo = i.POCo
    where isnull(i.TaxType,99) <> isnull(d.TaxType,99) and c.AuditPOs = 'Y'

if update(OrigUnits)
    insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vPOItemLine', 'PO: ' + i.PO + ' Item: ' + convert(varchar(10),i.POItem) + ' Line: ' + CONVERT(VARCHAR(10),i.POItemLine),
			i.POCo, 'C', 'Orig Units', convert(varchar(20),d.OrigUnits), convert(varchar(20),i.OrigUnits), getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.POCo = d.POCo and i.PO = d.PO and i.POItem = d.POItem
    JOIN dbo.bPOCO c with (nolock) on c.POCo = i.POCo
    where i.OrigUnits <> d.OrigUnits and c.AuditPOs = 'Y'
   
if update(OrigCost)
    insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vPOItemLine', 'PO: ' + i.PO + ' Item: ' + convert(varchar(10),i.POItem) + ' Line: ' + CONVERT(VARCHAR(10),i.POItemLine),
			i.POCo, 'C', 'Orig Cost', convert(varchar(20),d.OrigCost), convert(varchar(20),i.OrigCost), getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.POCo = d.POCo and i.PO = d.PO and i.POItem = d.POItem
    JOIN dbo.bPOCO c with (nolock) on c.POCo = i.POCo
    where i.OrigCost <> d.OrigCost and c.AuditPOs = 'Y'

if update(OrigTax)
    insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vPOItemLine', 'PO: ' + i.PO + ' Item: ' + convert(varchar(10),i.POItem) + ' Line: ' + CONVERT(VARCHAR(10),i.POItemLine),
			i.POCo, 'C', 'Orig Tax', convert(varchar(20),d.OrigTax), convert(varchar(20),i.OrigTax), getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.POCo = d.POCo and i.PO = d.PO and i.POItem = d.POItem
    JOIN dbo.bPOCO c with (nolock) on c.POCo = i.POCo
    where i.OrigTax <> d.OrigTax and c.AuditPOs = 'Y'
   
if update(PayType)
    insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vPOItemLine', 'PO: ' + i.PO + ' Item: ' + convert(varchar(10),i.POItem) + ' Line: ' + CONVERT(VARCHAR(10),i.POItemLine),
			i.POCo, 'C', 'Pay Type', convert(varchar(3),d.PayType), convert(varchar(3),i.PayType), getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.POCo = d.POCo and i.PO = d.PO and i.POItem = d.POItem
    JOIN dbo.bPOCO c with (nolock) on c.POCo = i.POCo
    where i.PayType <> d.PayType and c.AuditPOs = 'Y'

if update(PayCategory)
    insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vPOItemLine', 'PO: ' + i.PO + ' Item: ' + convert(varchar(10),i.POItem) + ' Line: ' + CONVERT(VARCHAR(10),i.POItemLine),
			i.POCo, 'C', 'Pay Category', isnull(convert(varchar(3),d.PayCategory),''),
		 isnull(convert(varchar(3),i.PayCategory),''), getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.POCo = d.POCo and i.PO = d.PO and i.POItem = d.POItem
    JOIN dbo.bPOCO c with (nolock) on c.POCo = i.POCo
	where i.PayCategory <> d.PayCategory and c.AuditPOs = 'Y'
   
IF UPDATE(SMCo)
   	insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vPOItemLine', 'PO: ' + i.PO + ' Item: ' + convert(varchar(10),i.POItem) + ' Line: ' + CONVERT(VARCHAR(10),i.POItemLine),
		i.POCo, 'C', 'SMCo', isnull(convert(varchar(3),d.SMCo),''), isnull(convert(varchar(3),i.SMCo),''), getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.POCo = d.POCo and i.PO = d.PO and i.POItem = d.POItem
    join dbo.bPOCO c with (nolock) on c.POCo = i.POCo
    where ISNULL(i.SMCo,0) <> ISNULL(d.SMCo,0) and c.AuditPOs = 'Y'
	
IF UPDATE(SMWorkOrder)
    insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vPOItemLine', 'PO: ' + i.PO + ' Item: ' + convert(varchar(10),i.POItem) + ' Line: ' + CONVERT(VARCHAR(10),i.POItemLine),
		i.POCo, 'C', 'SMWorkOrder', d.SMWorkOrder, i.SMWorkOrder, getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.POCo = d.POCo and i.PO = d.PO and i.POItem = d.POItem
    join dbo.bPOCO c with (nolock) on c.POCo = i.POCo
    where isnull(i.SMWorkOrder,'') <> isnull(d.SMWorkOrder,'') and c.AuditPOs = 'Y'
   	    
-- TK-14139 --
IF UPDATE(SMScope)
    insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vPOItemLine', 'PO: ' + i.PO + ' Item: ' + convert(varchar(10),i.POItem) + ' Line: ' + CONVERT(VARCHAR(10),i.POItemLine),
		i.POCo, 'C', 'SMScope', d.SMScope, i.SMScope, getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.POCo = d.POCo and i.PO = d.PO and i.POItem = d.POItem
    join dbo.bPOCO c with (nolock) on c.POCo = i.POCo
    where isnull(i.SMScope,'') <> isnull(d.SMScope,'') and c.AuditPOs = 'Y'	

-- TK-14139 --
IF UPDATE(SMPhase)
    insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vPOItemLine', 'PO: ' + i.PO + ' Item: ' + convert(varchar(10),i.POItem) + ' Line: ' + CONVERT(VARCHAR(10),i.POItemLine),
		i.POCo, 'C', 'SMPhase', d.SMPhase, i.SMPhase, getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.POCo = d.POCo and i.PO = d.PO and i.POItem = d.POItem
    join dbo.bPOCO c with (nolock) on c.POCo = i.POCo
    where isnull(i.SMPhase,'') <> isnull(d.SMPhase,'') and c.AuditPOs = 'Y'    
     
-- TK-14139 --
IF UPDATE(SMJCCostType)
    insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vPOItemLine', 'PO: ' + i.PO + ' Item: ' + convert(varchar(10),i.POItem) + ' Line: ' + CONVERT(VARCHAR(10),i.POItemLine),
		i.POCo, 'C', 'SMJCCostType', d.SMJCCostType, i.SMJCCostType, getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.POCo = d.POCo and i.PO = d.PO and i.POItem = d.POItem
    join dbo.bPOCO c with (nolock) on c.POCo = i.POCo
    where isnull(i.SMJCCostType,'') <> isnull(d.SMJCCostType,'') and c.AuditPOs = 'Y' 
      
      
RETURN
         
ERROR:
	if @opencursor = 1
		BEGIN
		CLOSE vcPOItemLine_update
		DEALLOCATE vcPOItemLine_update
		END

   select @ErrMsg = @ErrMsg + ' - cannot update PO Item Distribution Lines'
   RAISERROR(@ErrMsg, 11, -1);
   rollback transaction






GO
ALTER TABLE [dbo].[vPOItemLine] ADD CONSTRAINT [CK_vPOItemLine_ItemType] CHECK (([ItemType]>(0) AND [ItemType]<(8)))
GO
ALTER TABLE [dbo].[vPOItemLine] ADD CONSTRAINT [CK_vPOItemLine_LineDelete] CHECK (([LineDelete]='N' OR [LineDelete]='Y' OR [LineDelete]='C' OR [LineDelete]='I'))
GO
ALTER TABLE [dbo].[vPOItemLine] ADD CONSTRAINT [CK_vPOItemLine_PurgeYN] CHECK (([PurgeYN]='N' OR [PurgeYN]='Y'))
GO
ALTER TABLE [dbo].[vPOItemLine] ADD CONSTRAINT [CK_vPOItemLine_TaxType] CHECK (([TaxType] IS NULL OR ([TaxType]=(3) OR [TaxType]=(2) OR [TaxType]=(1))))
GO
ALTER TABLE [dbo].[vPOItemLine] ADD CONSTRAINT [PK_vPOItemLine] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ciPOPOItem] ON [dbo].[vPOItemLine] ([POCo], [PO], [POItem]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_vPOItemLine_POItemLine] ON [dbo].[vPOItemLine] ([POCo], [PO], [POItem], [POItemLine]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ciPOudSeq] ON [dbo].[vPOItemLine] ([POCo], [PO], [POItem], [udCGC_ASQ02]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_vPOItemLine_POITKeyID] ON [dbo].[vPOItemLine] ([POITKeyID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPOItemLine] WITH NOCHECK ADD CONSTRAINT [FK_vPOItemLine_bPOIT_KeyID] FOREIGN KEY ([POITKeyID]) REFERENCES [dbo].[bPOIT] ([KeyID]) ON DELETE CASCADE
GO
