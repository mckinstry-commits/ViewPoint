CREATE TABLE [dbo].[bARTL]
(
[ARCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[ARTrans] [dbo].[bTrans] NOT NULL,
[ARLine] [smallint] NOT NULL,
[RecType] [tinyint] NULL,
[LineType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[Description] [dbo].[bDesc] NULL,
[GLCo] [dbo].[bCompany] NULL,
[GLAcct] [dbo].[bGLAcct] NULL,
[TaxGroup] [dbo].[bGroup] NULL,
[TaxCode] [dbo].[bTaxCode] NULL,
[Amount] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bARTL_Amount] DEFAULT ((0)),
[TaxBasis] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bARTL_TaxBasis] DEFAULT ((0)),
[TaxAmount] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bARTL_TaxAmount] DEFAULT ((0)),
[RetgPct] [dbo].[bPct] NOT NULL,
[Retainage] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bARTL_Retainage] DEFAULT ((0)),
[DiscOffered] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bARTL_DiscOffered] DEFAULT ((0)),
[TaxDisc] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bARTL_TaxDisc] DEFAULT ((0)),
[DiscTaken] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bARTL_DiscTaken] DEFAULT ((0)),
[ApplyMth] [dbo].[bMonth] NOT NULL,
[ApplyTrans] [dbo].[bTrans] NOT NULL,
[ApplyLine] [smallint] NOT NULL,
[JCCo] [dbo].[bCompany] NULL,
[Contract] [dbo].[bContract] NULL,
[Item] [dbo].[bContractItem] NULL,
[ContractUnits] [dbo].[bUnits] NULL,
[Job] [dbo].[bJob] NULL,
[PhaseGroup] [dbo].[bGroup] NULL,
[Phase] [dbo].[bPhase] NULL,
[CostType] [dbo].[bJCCType] NULL,
[UM] [dbo].[bUM] NULL,
[JobUnits] [dbo].[bUnits] NULL,
[JobHours] [dbo].[bHrs] NULL,
[ActDate] [dbo].[bDate] NULL,
[INCo] [dbo].[bCompany] NULL,
[Loc] [dbo].[bLoc] NULL,
[MatlGroup] [dbo].[bGroup] NULL,
[Material] [dbo].[bMatl] NULL,
[UnitPrice] [dbo].[bUnitCost] NULL CONSTRAINT [DF_bARTL_UnitPrice] DEFAULT ((0)),
[ECM] [dbo].[bECM] NULL,
[MatlUnits] [dbo].[bUnits] NULL,
[CustJob] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[CustPO] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[EMCo] [dbo].[bCompany] NULL,
[Equipment] [dbo].[bEquip] NULL,
[EMGroup] [dbo].[bGroup] NULL,
[CostCode] [dbo].[bCostCode] NULL,
[EMCType] [dbo].[bEMCType] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[CompType] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Component] [dbo].[bEquip] NULL,
[PurgeFlag] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bARTL_PurgeFlag] DEFAULT ('N'),
[FinanceChg] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bARTL_FinanceChg] DEFAULT ((0)),
[rptApplyMth] [dbo].[bMonth] NULL,
[rptApplyTrans] [dbo].[bTrans] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[RetgTax] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bARTL_RetgTax] DEFAULT ((0)),
[SMWorkCompletedID] [bigint] NULL,
[SMAgreementBillingScheduleID] [bigint] NULL,
[udHistYN] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[udHistCMRef] [varchar] (15) COLLATE Latin1_General_BIN NULL,
[udARTOPDID] [bigint] NULL,
[udSeqNo] [int] NULL,
[udSeqNo05] [int] NULL,
[udCVStoredProc] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[udRecCode] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[udItemsBilled] [decimal] (16, 4) NULL,
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
 
  
   
   
   /****** Object:  Trigger dbo.btARTLd    Script Date: 8/28/99 9:38:19 AM ******/
   CREATE trigger [dbo].[btARTLd] on [dbo].[bARTL] for delete as
   

/*--------------------------------------------------------------
   *
   *  Delete trigger for ARTL
   *  Created By: JRE
   *  Date:       5/15/97
   *
   *  Modified: JM 6/22/99 - Added HQMA insert.  Ref Issue 3852.
   *  		bc 7/13/99 - check to make sure no other lines apply to deleted line
   *   	GG 04/10/01 - change GL Acct validation to use bspGLACfPostable
   *		TJL 09/07/01 - Issue #13931, Code change to Use PurgeFlag from bARTL rather than from bARTH
   *    	TJL 09/12/01 - Issue #14588, corrected duplicate HQMA entries for each bARTL delete
   *		TJL 03/01/02 - Issue #14171, Add FinanceChg, rptApplyMth, rptApplyTrans columns
   *		TJL 04/06/05 - Issue #28357, Remove GLAcct validation during line delete
   *
   *  	When doing an adjustment on a line that doesn't exist on the invoice
   *  	then the posting program must create the invoice line using the same
   *  	values (RecType, Contract, Tax Code, etc as the Adjustment but with
   * 	the amounts=0
   *--------------------------------------------------------------*/
   
   DECLARE @numrows int, @oldnumrows int, @errmsg varchar(255), @bemsg varchar(15),
     	@errno tinyint, @audit bYN, @validcnt int, @validcnt2 int, @rcode int
   
   SELECT @numrows = @@rowcount
   IF @numrows = 0 RETURN
   SET nocount ON
   
   DECLARE @ARCo bCompany, @Mth bMonth, @ARTrans bTrans, @ARLine smallint,
   	@RecType tinyint, @LineType char(1), @Description bDesc, @GLCo bCompany,
   	@GLAcct bGLAcct, @TaxGroup bGroup, @TaxCode bTaxCode, @Amount bDollar,
       @TaxBasis bDollar, @TaxAmount bDollar, @RetgPct bPct, @Retainage bDollar,
       @DiscOffered bDollar, @DiscTaken bDollar, @ApplyMth bMonth,
       @ApplyTrans bTrans, @ApplyLine smallint, @JCCo bCompany, @Contract bContract,
       @Item bContractItem, @ContractUnits bUnits, @Job bJob, @PhaseGroup bGroup,
       @Phase bPhase, @CostType bJCCType, @UM bUM, @JobUnits bUnits,
       @JobHours bHrs, @INCo bCompany, @Loc bLoc, @MatlGroup bGroup,
       @Material bMatl, @UnitPrice bUnitCost, @MatlUnits bUnits,
       @CustJob varchar(20), @CustPO varchar(20), @EMCo bCompany, @Equipment bEquip,
       @EMGroup bGroup, @CostCode bCostCode, @EMCType bEMCType, @CompType varchar(10),
       @Component bEquip, @ARTransType char(1), @subtype char(1), @InvoiceAmount bDollar, @PaidAmount bDollar,
       @CustGroup bGroup,@Customer bCustomer,@Invoiced bDollar,@Paid bDollar,
       @LastInvDate bDate, @LastPayDate bDate,@TransDate bDate,@HighestCredit bDollar,
       @PrevAmtDue bDollar, @AmountDue bDollar,@PayFullDate bDate,@PrevPayFullDate bDate,
       @ApplyARTransType char(1),@PurgeFlag char(1), @FinanceChg bDollar, 
   	@rptApplyMth bMonth, @rptApplyTrans bTrans
   
   
   /* loop through the records */
   /* get the first Company */
   SELECT @ARCo=MIN(ARCo) FROM deleted
   WHILE @ARCo IS NOT NULL
   	begin
       /* grt the first month for this company */
       SELECT @Mth=MIN(Mth) FROM deleted WHERE ARCo=@ARCo
       WHILE @Mth IS NOT NULL
       	BEGIN
         	/* get the first transaction for this Company & Mth */
         	SELECT @ARTrans=MIN(ARTrans) FROM deleted WHERE ARCo=@ARCo AND Mth=@Mth
         	WHILE @ARTrans IS NOT NULL
         		BEGIN
           	/* Validate Transaction */
           	SELECT @ARTransType=ARTransType,@TransDate=TransDate,
                  	@CustGroup=CustGroup,@Customer=Customer	-- Per Issue 13931 ,@PurgeFlag=PurgeFlag
              	FROM bARTH
             	WHERE @ARCo = ARCo AND Mth=@Mth AND ARTrans=@ARTrans
           	IF @@rowcount<>1
           		BEGIN
             		SELECT @errmsg = 'Transaction Header not found'
             		GOTO error
           		END
   
           	SELECT @ARLine=MIN(ARLine)FROM deleted WHERE ARCo=@ARCo AND Mth=@Mth AND ARTrans=@ARTrans
           	WHILE @ARLine IS NOT NULL
               	BEGIN
               	/* if purging dont validate or update ARTH or ARMT for this Purged Line */
               	SELECT @PurgeFlag = PurgeFlag FROM deleted
               	WHERE ARCo=@ARCo AND Mth=@Mth AND ARTrans=@ARTrans AND ARLine = @ARLine
               	IF @PurgeFlag = 'Y' goto GetNextLine
   
               	SELECT @RecType = RecType, @LineType = LineType, @Description = Description,
               		@GLCo = GLCo, @GLAcct = GLAcct, @TaxGroup = TaxGroup, @TaxCode = TaxCode,
               		@Amount = Amount, @TaxBasis = TaxBasis, @TaxAmount = TaxAmount,
               		@RetgPct = RetgPct, @Retainage = Retainage, @DiscOffered = DiscOffered,
               		@DiscTaken = DiscTaken, @ApplyMth = ApplyMth, @ApplyTrans = ApplyTrans,
               		@ApplyLine = ApplyLine, @JCCo = JCCo, @Contract = Contract,
               		@Item = Item, @ContractUnits = ContractUnits, @Job = Job,
               		@PhaseGroup = PhaseGroup, @Phase = Phase, @CostType = CostType,
               		@UM = UM, @JobUnits = JobUnits, @JobHours = JobHours, @INCo = INCo,
               		@Loc = Loc, @MatlGroup = MatlGroup, @Material = Material,
               		@UnitPrice = UnitPrice, @MatlUnits = MatlUnits,
               		@CustJob = CustJob, @CustPO = CustPO, @EMCo = EMCo, @Equipment = Equipment,
               		@EMGroup = EMGroup, @CostCode = CostCode, @EMCType = EMCType, @CompType = CompType,
   	        		@Component = Component, @FinanceChg = FinanceChg, @rptApplyMth = rptApplyMth,
   					@rptApplyTrans = rptApplyTrans
               	FROM deleted
     	        	WHERE ARCo=@ARCo AND Mth=@Mth AND ARTrans=@ARTrans and ARLine= @ARLine
   
               	/* do not allow a line to be deleted that has other lines applied to it */
               	select @validcnt = count(*)
               	from ARTL
               	where ARCo = @ARCo and ApplyMth = @Mth and ApplyTrans = @ARTrans and ApplyLine = @ARLine
                   		and (ARTrans <> @ARTrans or Mth <> @Mth or ARLine <> @ARLine)
               	if @validcnt <> 0
                   	begin
                   	select @errmsg = 'Line ' + convert(varchar(10),@ARLine) + ' of transaction ' + convert(varchar(10),@ARTrans) +
                                ' has other lines applied to it'
                   	goto error
                   	end
   
               	/* Validate GLAcct */
   --             	if @GLAcct is not null
   --                 	begin
   --                 	select @subtype = null
   --                 	if @Contract is not null select @subtype = 'J'
   --                 	exec @rcode = bspGLACfPostable @GLCo, @GLAcct, @subtype, @errmsg output
   --                 	IF @rcode <> 0 goto error
   --                 	end
   
               	/* Validate TaxCode */
               	IF NOT EXISTS (SELECT * FROM bHQTX WHERE @TaxGroup = TaxGroup AND @TaxCode = TaxCode)
                   		AND @TaxCode IS NOT NULL
                   	BEGIN
                   	SELECT @errmsg = 'TaxCode is Invalid '
                   	GOTO error
                   	END
               	IF @TaxCode IS NULL AND @TaxAmount<>0
                   	BEGIN
                   	SELECT @errmsg = 'Tax Amount not allowed without a Tax Code'
                   	GOTO error
                   	END
   
               	/* UPDATE ARTH & ARMT*/
               	/*reverse the amounts for a delete */
               	select @Amount=-(@Amount),@Retainage=-(@Retainage),@DiscTaken=-(@DiscTaken),
   						@FinanceChg=-(@FinanceChg)
               	exec @rcode= bspARTHUpdate @ARCo,@Mth,@CustGroup,@Customer,
                   		@Amount,@Retainage,@FinanceChg,@DiscTaken,@ARTransType,@TransDate,
                   		@ApplyMth,@ApplyTrans,@errmsg output
   
               	if @rcode<>0 goto error
   
               	/* done with validation - get next line */
           	GetNextLine:
               	SELECT @ARLine=MIN(ARLine)FROM deleted
               	WHERE ARCo=@ARCo AND Mth=@Mth AND ARTrans=@ARTrans AND ARLine>@ARLine
               	END		/* END OF LINES */
   
     		GetNextTrans:
           	SELECT @ARTrans=MIN(ARTrans) FROM deleted
             	WHERE ARCo=@ARCo AND Mth=@Mth AND ARTrans>@ARTrans
         		END /* trans loop */
   
         	SELECT @Mth=MIN(Mth) FROM deleted WHERE ARCo=@ARCo AND Mth>@Mth
       	END  /* mth loop */
   
       SELECT @ARCo=MIN(ARCo) FROM deleted WHERE ARCo>@ARCo
     	End /* Co loop */
   
   /* Audit deletions if PurgeFlag in detail file = 'N' */
   insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   select 'bARTL', 'ARCo: ' + convert(varchar(3),d.ARCo)
     	+ ' Mth: ' + convert(varchar(8), d.Mth,1)
     	+ ' ARTrans: ' + convert(varchar(6), d.ARTrans)
     	+ ' ARLine: ' + convert(varchar(6),d.ARLine),
     	d.ARCo, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
   from deleted d
   join bARCO c on c.ARCo = d.ARCo
   where d.ARCo = c.ARCo and c.AuditTrans = 'Y' and d.PurgeFlag = 'N'
   
   Return
   error:
   SELECT @errmsg = 'Trans ' + convert(varchar(10),@ARTrans) + ' Line ' + convert(varchar(10),@ARLine) +' ' + @errmsg
   SELECT @errmsg = @errmsg + ' - cannot Delete from ARTL'
   RAISERROR(@errmsg, 11, -1);
   rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
  
  
  /****** Object:  Trigger dbo.btARTLi    Script Date: 8/28/99 9:38:19 AM ******/
   CREATE trigger [dbo].[btARTLi] on [dbo].[bARTL] for INSERT as
 
/*--------------------------------------------------------------
   *
   *  Insert trigger for ARTL
   *  Created By: JRE
   *  Modified By:
   *    	bc 07/11/00 - the original invoice can have a different tax code then the apply trans
   *                 	when the apply trans is an adjustment or write off
   *		JM 6/21/99 - Add audit of inserts where ARCo.AuditTrans = 'Y'. Ref Issue 3852.
   *     	bc 02/02/00 - remmed out IN Location validation
   *    	bc 08/30/00 - added artranstype 'P'ayment in the code that checks to make sure that
   *                	trans info equals that of the original line that it is applied towards.
   *     	bc 02/19/01 - added code to handle Release Retainage Sub Ledger Types when
   *           		ARTL.Contract is not null
   *     	GG 04/10/01 - changed GL Account validation to use bspGLACfPostable
   *		TJL 07/23/01 - Issue #13833, Don't Validate RecType IF ARTransType = 'M' and RecType is NULL
   *		TJL 08/17/01 - Validate JC CostType for Misc Receipt only if LineType = 'J'
   *					Add validation for Misc Receipt LineType 'E' equipment
   *		TJL 08/28/01 - Allow Detail LineType changes on Adjustments and Credits per Issue #13448
   *		TJL 09/12/01 - Issue #14382, corrected duplicate HQMA entries for each bARTL insert
   *		TJL 09/24/01 - Issue #14610,  Minor change to Compare orig TaxGroup and TaxCode for 'A' and 'W' as well as 'C' types.
   *		TJL 09/27/01 - Related to Issue 13104,  We do not need to Validate GL Acct when processing a Retainage Line.
   *		TJL 10/02/01 - Issue #13104, Supercedes Issue #13448, Remove all LineType validation completely
   *		TJL 03/01/02 - Issue #14171, Add FinanceChg, rptApplyMth, rptApplyTrans columns
   *		SR 07/09/02 - 17738 pass @PhaseGroup to bspJCVCOSTTYPE
   *		TJL 08/09/02 - Issue #15923, Among much else, fixed bspJCVCOSTTYPE error occuring here.
   *		TJL 10/23/02 - Issue #18598, JB must be allowed to Change TaxCode on an Item
   *		TJL 04/30/03 - Issue #20936, Reverse Release Retainage
   *		GF 07/14/2003 - issue #21828 - speed improvements, no locks, fast forward cursor, top 1 1 not exists
   *		TJL 09/11/06 - Issue #30663, Don't Validate GLRevAcct (Form GLAcct) on 0.00 value lines
   *		TJL 11/13/09 - Issue #136580, Modified only to be consistent with bspARBHVal
   *
   *  	When doing an adjustment on a line that doesn't exist on the invoice
   *  	then the posting program must create the invoice line using the same
   *  	values (RecType, Contract, Tax Code, etc as the Adjustment but with
   * 	the amounts=0
   *--------------------------------------------------------------*/
   DECLARE @numrows int,@errmsg varchar(255), @validcnt int, @validcnt2 int, @rcode int
   SELECT @numrows = @@rowcount
   IF @numrows = 0 RETURN
   SET nocount ON
   
   DECLARE @ARCo bCompany, @Mth bMonth, @ARTrans bTrans, @ARLine smallint,
           @RecType tinyint, @LineType char(1), @Description bDesc, @GLCo bCompany,
           @GLAcct bGLAcct, @TaxGroup bGroup, @TaxCode bTaxCode, @Amount bDollar,
           @TaxBasis bDollar, @TaxAmount bDollar, @RetgPct bPct, @Retainage bDollar,
           @DiscOffered bDollar, @DiscTaken bDollar, @ApplyMth bMonth,
           @ApplyTrans bTrans, @ApplyLine smallint, @JCCo bCompany, @Contract bContract,
           @Item bContractItem, @ContractUnits bUnits, @Job bJob, @PhaseGroup bGroup,
           @Phase bPhase, @CostType bJCCType, @UM bUM, @JobUnits bUnits,
           @JobHours bHrs, @INCo bCompany, @Loc bLoc, @MatlGroup bGroup,
           @Material bMatl, @UnitPrice bUnitCost, @MatlUnits bUnits,
           @CustJob varchar(20), @CustPO varchar(20), @EMCo bCompany, @Equipment bEquip,
           @EMGroup bGroup, @CostCode bCostCode, @EMCType bEMCType, @CompType varchar(10),
           @Component bEquip, @ARTransType char(1), @subtype char(1), @InvoiceAmount bDollar, @PaidAmount bDollar,
           @CustGroup bGroup,@Customer bCustomer,@Invoiced bDollar,@Paid bDollar,
           @LastInvDate bDate, @LastPayDate bDate,@TransDate bDate,@HighestCredit bDollar,
           @PrevAmtDue bDollar, @AmountDue bDollar,@PayFullDate bDate,@PrevPayFullDate bDate,
           @ApplyARTransType char(1), @TMP varchar(100), @FinanceChg bDollar, 
   		@rptApplyMth bMonth, @rptApplyTrans bTrans, @CostTypeAbbrev varchar(3)
   
   -- create cursor to loop throught the records
   -- validate for various line types
   if @numrows = 1
   	select @ARCo = ARCo, @Mth = Mth, @ARTrans = ARTrans, @ARLine = ARLine, @RecType = RecType, 
   		   @LineType = LineType, @Description = Description, @GLCo = GLCo, @GLAcct = GLAcct, 
   		   @TaxGroup = TaxGroup, @TaxCode = TaxCode, @Amount = Amount, @TaxBasis = TaxBasis, 
   		   @TaxAmount = TaxAmount, @RetgPct = RetgPct, @Retainage = Retainage, @DiscOffered = DiscOffered,
   		   @DiscTaken = DiscTaken, @ApplyMth = ApplyMth, @ApplyTrans = ApplyTrans, @ApplyLine = ApplyLine, 
   		   @JCCo = JCCo, @Contract = Contract, @Item = Item, @ContractUnits = ContractUnits, @Job = Job,
   		   @PhaseGroup = PhaseGroup, @Phase = Phase, @CostType = CostType, @UM = UM, @JobUnits = JobUnits, 
   		   @JobHours = JobHours, @INCo = INCo, @Loc = Loc, @MatlGroup = MatlGroup, @Material = Material,
   		   @UnitPrice = UnitPrice, @MatlUnits = MatlUnits, @CustJob = CustJob, @CustPO = CustPO, @EMCo = EMCo, 
   		   @Equipment = Equipment, @EMGroup = EMGroup, @CostCode = CostCode, @EMCType = EMCType, @CompType = CompType,
   		   @Component = Component, @FinanceChg = FinanceChg, @rptApplyMth = rptApplyMth, @rptApplyTrans = rptApplyTrans
   	from inserted
   else
   	begin
   	-- use a cursor to process each inserted row
   	declare bARTL_insert cursor FAST_FORWARD
   	for select ARCo, Mth, ARTrans, ARLine, RecType, LineType, Description, GLCo, GLAcct, TaxGroup, TaxCode,
   		   Amount, TaxBasis, TaxAmount, RetgPct, Retainage, DiscOffered, DiscTaken, ApplyMth, ApplyTrans, 
   		   ApplyLine, JCCo, Contract, Item, ContractUnits, Job, PhaseGroup, Phase, CostType, UM, JobUnits, 
   		   JobHours, INCo, Loc, MatlGroup, Material, UnitPrice, MatlUnits, CustJob, CustPO, EMCo, Equipment, 
   		   EMGroup, CostCode, EMCType, CompType, Component, FinanceChg, rptApplyMth, rptApplyTrans
   	from inserted
   	-- open cursor
   	open bARTL_insert
   	fetch next from bARTL_insert 
   	into @ARCo, @Mth, @ARTrans, @ARLine, @RecType, @LineType, @Description, @GLCo, @GLAcct, @TaxGroup, @TaxCode, 
   		 @Amount, @TaxBasis, @TaxAmount, @RetgPct, @Retainage, @DiscOffered, @DiscTaken, @ApplyMth, @ApplyTrans, 
   		 @ApplyLine, @JCCo, @Contract, @Item, @ContractUnits, @Job, @PhaseGroup, @Phase, @CostType, @UM, @JobUnits, 
   		 @JobHours, @INCo, @Loc, @MatlGroup, @Material, @UnitPrice, @MatlUnits, @CustJob, @CustPO, @EMCo, @Equipment, 
   		 @EMGroup, @CostCode, @EMCType, @CompType, @Component, @FinanceChg, @rptApplyMth, @rptApplyTrans
   	if @@fetch_status <> 0
   		begin
   		select @errmsg = 'Cursor error'
   		goto error
   		end
   	end
   
   insert_check:
   select @ARTransType=ARTransType, @TransDate=TransDate, @CustGroup=CustGroup, @Customer=Customer
   from bARTH with (nolock) where @ARCo = ARCo AND Mth=@Mth AND ARTrans=@ARTrans
   if @@rowcount = 0
   	begin
   	select @errmsg = 'Transaction header not found!'
   	goto error
   	end
   
   
   -- Validate Apply To information
   IF @ARTransType not in ('I','M','F','R','V')
   	BEGIN
   	IF NOT EXISTS (SELECT top 1 1 FROM bARTL l with (nolock) WHERE @ARCo = ARCo AND Mth=@ApplyMth 
   				AND ARTrans=@ApplyTrans AND ARLine=@ApplyLine)
   		BEGIN
   		SELECT @errmsg = 'Apply to Transaction or Line not found'
   		GOTO error
   		END
   
   
	IF NOT EXISTS (SELECT top 1 1 
			FROM bARTL with (nolock) 
			WHERE ARCo = @ARCo AND Mth=@ApplyMth AND ARTrans=@ApplyTrans AND ARLine=@ApplyLine 
				AND RecType=@RecType
				AND IsNull(JCCo,0)=IsNull(@JCCo,0) AND IsNull(Contract,'')=IsNull(@Contract,'')
				AND IsNull(INCo,0)=IsNull(@INCo,0) AND IsNull(Loc,'')=IsNull(@Loc,'')
				AND ((@ARTransType in ('P')) 
					or (@ARTransType in ('A', 'C', 'W') AND isnull(@TaxGroup,0)=isnull(TaxGroup,0)	--TaxGroup must always be same, Orig = Applied		
						AND IsNull(TaxCode,'') = IsNull(@TaxCode,IsNull(TaxCode,'')))))				--If Applied TaxCode exists, must be equal to Orig.  If Applied empty, Orig can be anything (??)
		BEGIN
		SELECT @errmsg = 'Information does not match the Original Invoice Line'
		GOTO error
		END
   	END
   
   -- Validate RecType
   IF @ARTransType <> 'M' or (@ARTransType = 'M' and @RecType is not NULL)
   	BEGIN
   	IF NOT EXISTS (SELECT top 1 1 FROM bARRT with (nolock) WHERE @ARCo = ARCo AND @RecType = RecType)
   		BEGIN
   		SELECT @errmsg = 'Invalid Receivable Type'
   		GOTO error
   		END
   	END
   
   -- Validate Line Type for Invoices,Credit memos,Adjustments, WriteOffs
   IF @ARTransType in ('I','C','A','W') AND @LineType not in ('M','C','O','E','R', 'F')
   	BEGIN
   	SELECT @errmsg = 'LineType is Invalid, use (M)aterial, (C)ontract, (E)quipment, (R)etainage, (O)ther, (F)inChg'
   	GOTO error
   	END
   
   -- Validate GLAcct
   If @Amount <> 0 and @ARTransType not in ('P','R','V')
   	begin
   	select @subtype = null
   	if @Contract is not null select @subtype =  'J'
   	exec @rcode=bspGLACfPostable @GLCo, @GLAcct, @subtype, @errmsg output
   	if @rcode <> 0 GOTO error
   	end
   
   -- Validate TaxCode
   if @TaxCode is not null
   	begin
   	IF NOT EXISTS (SELECT top 1 1 FROM bHQTX with (nolock) WHERE @TaxGroup = TaxGroup AND @TaxCode = TaxCode)
   		BEGIN
   		SELECT @errmsg = 'TaxCode is Invalid '
   		GOTO error
   		END
   	end
   
   if @TaxCode is null and @TaxAmount <> 0
   	begin
   	SELECT @errmsg = 'Tax Amount not allowed without a Tax Code'
   	GOTO error
   	END
   
   -- Validate ApplyLine
   -- Validate Contract Item on Invoices
   if @ARTransType = 'I' and @Item is not null
   	begin
   	IF NOT EXISTS (SELECT top 1 1 FROM bJCCI with (nolock) WHERE @JCCo=JCCo AND @Contract=Contract AND @Item=Item)
   		BEGIN
   		SELECT @errmsg = 'Invalid Contract or Contract Item'
   		GOTO error
   		END
   	end
   
   -- Validate Job on Misc Cash Receipt
   IF @ARTransType='M' AND @LineType = 'J' AND @Job IS NOT NULL
   	BEGIN
   	select @CostTypeAbbrev=str(@CostType,3)
   	exec @rcode=bspJCVCOSTTYPE @JCCo, @Job, @PhaseGroup, @Phase, @CostTypeAbbrev, null,
   							null, null, null, null, null, null, null, null, null, @errmsg output
   	IF @rcode<>0 GOTO error
   	END
   
   -- Validate Equipment on Misc Cash Receipt
   IF @ARTransType='M' AND @LineType = 'E' 
   	BEGIN
   	-- validate EM Company
   	if not exists(select top 1 1 from bEMCO with (nolock) where EMCo = @EMCo)
   		BEGIN
   		SELECT @errmsg = 'Invalid EM Company'
   		GOTO error
   		END
   
   	-- validate Equipment
   	if not exists(select top 1 1 from bEMEM with (nolock) where EMCo = @EMCo and Equipment = @Equipment)
   		BEGIN
   		SELECT @errmsg = 'Invalid Equipment'
   		GOTO error
   		END
   
   	-- validate Cost Code
   	if not exists(select top 1 1 from bEMCC with (nolock) where EMGroup = @EMGroup and CostCode = @CostCode)
   		BEGIN
   		SELECT @errmsg = 'Invalid Cost Code'
   		GOTO error
   		END
   
   	-- validate EM Cost Type
   	if not exists(select top 1 1 from bEMCT with (nolock) where EMGroup = @EMGroup and CostType = @EMCType)
   		BEGIN
   		SELECT @errmsg = 'Invalid EM Cost Type'
   		GOTO error
   		END
   
   	-- validate EM CostType / EM CostCode combination
   	if not exists(select top 1 1 from bEMCH with (nolock) where EMCo = @EMCo and EMGroup = @EMGroup 
   				and Equipment = @Equipment and CostType = @EMCType and CostCode = @CostCode)
   		BEGIN
   		if not exists(select top 1 1 from bEMCX with (nolock) where EMGroup=@EMGroup and CostType=@EMCType 
   				and CostCode=@CostCode)
   			BEGIN
   			SELECT @errmsg = 'Invalid cost type/cost code combination'
   			GOTO error
   			END
   		END
   	END
   
   IF @ARTransType<>'M' AND (@Job IS NOT NULL or @Phase IS NOT NULL or @CostType IS NOT NULL)
   	BEGIN
   	SELECT @errmsg = 'Invalid Contract or Contract Item'
   	GOTO error
   	END
   
   -- UM
   if @UM is not null
   	begin
   	IF NOT EXISTS (SELECT top 1 1 FROM bHQUM with (nolock) WHERE UM=@UM)
   		BEGIN
   		SELECT @errmsg = 'Invalid UM'
   		GOTO error
   		END
   	end
   
   -- Validate rptApplyMth and rptApplyTrans.  If both have values,
   -- then they must be valid to be useful.  Validate to assure this.
   if isnull(@rptApplyMth, '') <> '' and isnull(@rptApplyTrans, 0) <> 0
   	begin
   	if not exists(select top 1 1 from bARTH with (nolock) where ARCo = @ARCo and Mth = @rptApplyMth 
   			and ARTrans = @rptApplyTrans and Mth = AppliedMth and ARTrans = AppliedTrans)
   		begin
   		select @errmsg = 'The original Mth: ' + isnull(convert(varchar(8), @rptApplyMth, 1),'')
   		select @errmsg = @errmsg + ' and Transaction: ' + isnull(convert(varchar(10), @rptApplyTrans),'')
   		select @errmsg = @errmsg + ' have been purged or is invalid.'
   		goto error
   		end 
   	end
   
   -- UPDATE ARTH & ARMT
   exec @rcode= bspARTHUpdate @ARCo, @Mth, @CustGroup, @Customer, @Amount, @Retainage, @FinanceChg, 
   			@DiscTaken, @ARTransType, @TransDate, @ApplyMth, @ApplyTrans, @errmsg output
   if @rcode<>0 goto error
   
   
   /*
   SELECT @ARCo=MIN(ARCo) FROM inserted
   WHILE @ARCo IS NOT NULL
   	begin
    	-- get the first month for this company
      	SELECT @Mth=MIN(Mth) FROM inserted WHERE ARCo=@ARCo
      	WHILE @Mth IS NOT NULL
       	BEGIN
         	-- get the first transaction for this Company & Mth
   	   	SELECT @ARTrans=MIN(ARTrans) FROM inserted WHERE ARCo=@ARCo AND Mth=@Mth
          		WHILE @ARTrans IS NOT NULL
               	BEGIN
                 	-- Validate Transaction
                	SELECT @ARTransType=ARTransType,@TransDate=TransDate,
                      		@CustGroup=CustGroup,@Customer=Customer
               	FROM bARTH
              	 	WHERE @ARCo = ARCo AND Mth=@Mth AND ARTrans=@ARTrans
               	IF @@rowcount<>1
                 		BEGIN
                 		SELECT @errmsg = 'Transaction Header not found'
                 		GOTO error
                 		END
               	SELECT @ARLine=MIN(ARLine) FROM inserted WHERE ARCo=@ARCo AND Mth=@Mth AND ARTrans=@ARTrans
              		WHILE @ARLine IS NOT NULL
                 		BEGIN
                 		SELECT @RecType = RecType, @LineType = LineType, @Description = Description,
                       		@GLCo = GLCo, @GLAcct = GLAcct, @TaxGroup = TaxGroup, @TaxCode = TaxCode,
                       		@Amount = Amount, @TaxBasis = TaxBasis, @TaxAmount = TaxAmount,
                       		@RetgPct = RetgPct, @Retainage = Retainage, @DiscOffered = DiscOffered,
                       		@DiscTaken = DiscTaken, @ApplyMth = ApplyMth, @ApplyTrans = ApplyTrans,
                       		@ApplyLine = ApplyLine, @JCCo = JCCo, @Contract = Contract,
                       		@Item = Item, @ContractUnits = ContractUnits, @Job = Job,
                       		@PhaseGroup = PhaseGroup, @Phase = Phase, @CostType = CostType,
                       		@UM = UM, @JobUnits = JobUnits, @JobHours = JobHours, @INCo = INCo,
                       		@Loc = Loc, @MatlGroup = MatlGroup, @Material = Material,
                       		@UnitPrice = UnitPrice, @MatlUnits = MatlUnits,
                       		@CustJob = CustJob, @CustPO = CustPO, @EMCo = EMCo, @Equipment = Equipment,
                       		@EMGroup = EMGroup, @CostCode = CostCode, @EMCType = EMCType, @CompType = CompType,
   	       					@Component = Component, @FinanceChg = FinanceChg, @rptApplyMth = rptApplyMth,
   							@rptApplyTrans = rptApplyTrans
                     	FROM inserted
         	      		WHERE ARCo=@ARCo AND Mth=@Mth AND ARTrans=@ARTrans and ARLine=@ARLine
   
                 		-- Validate Apply To information
   	              	IF @ARTransType not in ('I','M','F','R','V')
                   		BEGIN
                  			IF NOT EXISTS (SELECT * FROM bARTL l
                                 	WHERE @ARCo = ARCo AND Mth=@ApplyMth AND ARTrans=@ApplyTrans AND ARLine=@ApplyLine)
                       		BEGIN
                       		SELECT @errmsg = 'Apply to Transaction or Line not found'
                       		GOTO error
                       		END
   
                   		IF NOT EXISTS (SELECT * FROM bARTL
                              		WHERE ARCo = @ARCo AND Mth=@ApplyMth AND ARTrans=@ApplyTrans AND ARLine=@ApplyLine
                                  		AND RecType=@RecType
   -- Mod Per Issue #13104 					AND IsNull(LineType, '') = case when @ARTransType = 'W' then IsNull(@LineType, '') else IsNull(LineType, '') end
   -- Mod Per Issue #13448		   				AND IsNull(LineType,'')=IsNull(@LineType,'')
                                		AND IsNull(JCCo,0)=IsNull(@JCCo,0) AND IsNull(Contract,'')=IsNull(@Contract,'')
                                 		AND ((@ARTransType in ('P')) or (@ARTransType in ('A', 'C', 'W') and IsNull(@TaxGroup,0)=IsNull(TaxGroup,0) 
   -- Mod Per Issue #18598				AND IsNull(TaxCode,'') = IsNull(@TaxCode,IsNull(TaxCode,'')) )))
                     			BEGIN
                     			SELECT @errmsg = 'Information does not match the Original Invoice Line'
                               	--debug.  keep this in here.  its handy to uncomment on customer systems.
                               	--+ convert(varchar(20),@ApplyMth) + ' ' + convert(varchar(10),@ApplyTrans) + ' ' + convert(varchar(10),@ApplyLine)
                     			GOTO error
                     			END
                   		END
   
                 		-- Validate RecType
   					IF @ARTransType <> 'M' or (@ARTransType = 'M' and @RecType is not NULL)
   						BEGIN
                			IF NOT EXISTS (SELECT * FROM bARRT WHERE @ARCo = ARCo AND @RecType = RecType)
                   			BEGIN
                   			SELECT @errmsg = 'Invalid Receivable Type'
                   			GOTO error
                   			END
   						END
   
                 		-- Validate Line Type for Invoices,Credit memos,Adjustments, WriteOffs
                 		IF @ARTransType in ('I','C','A','W') AND @LineType not in ('M','C','O','E','R', 'F')
                   		BEGIN
                   		SELECT @errmsg = 'LineType is Invalid, use (M)aterial, (C)ontract, (E)quipment, (R)etainage, (O)ther, (F)inChg'
                   		GOTO error
                   		END
   
                		-- Validate GLAcct
                		If @ARTransType not in ('P','R','V')
                  			begin
                  			select @subtype = null
                  			if @Contract is not null select @subtype =  'J'
                  			exec @rcode=bspGLACfPostable @GLCo, @GLAcct, @subtype, @errmsg output
                  			IF @rcode <> 0 GOTO error
                  			end
   
             			-- Validate TaxCode
               		IF NOT EXISTS (SELECT * FROM bHQTX WHERE @TaxGroup = TaxGroup AND @TaxCode = TaxCode)
                              	AND @TaxCode IS NOT NULL
                 			BEGIN
                 			SELECT @errmsg = 'TaxCode is Invalid '
                 			GOTO error
                 			END
               		IF @TaxCode IS NULL AND @TaxAmount<>0
                 			BEGIN
                 			SELECT @errmsg = 'Tax Amount not allowed without a Tax Code'
                 			GOTO error
                 			END
   
               		-- Validate ApplyLine
               		-- Validate Contract Item on Invoices
               		IF NOT EXISTS (SELECT * FROM bJCCI WHERE @JCCo=JCCo AND @Contract=Contract AND @Item=Item)
                              	AND  @ARTransType = 'I' AND @Item IS NOT NULL
                 			BEGIN
                 			SELECT @errmsg = 'Invalid Contract or Contract Item'
                 			GOTO error
                 			END
   
               		-- Validate Job on Misc Cash Receipt
               		IF @ARTransType='M' AND @LineType = 'J' AND (@Job IS NOT NULL)
                 			BEGIN
            	  			select @CostTypeAbbrev=str(@CostType,3)
   						-- Issue #15923: Adding PhaseGroup in the format below caused errors
                 			--exec @rcode=bspJCVCOSTTYPE @jcco=@JCCo, @job=@Job, @PhaseGroup=@PhaseGroup,@phase=@Phase,
                      		--	@costtype=@CostTypeAbbrev, @override = 'N',@msg=@errmsg output
      						exec @rcode=bspJCVCOSTTYPE @JCCo, @Job, @PhaseGroup, @Phase, @CostTypeAbbrev, null,
   							null,null,null,null,null,null,null,null,null,@errmsg output
                 			IF @rcode<>0 GOTO error
                 			END
   
               		-- Validate Equipment on Misc Cash Receipt
   					IF @ARTransType='M' AND @LineType = 'E' 
   	  					BEGIN
   	  					-- validate EM Company
   						SELECT @validcnt = count(*) FROM bEMCO where EMCo = @EMCo
   						IF @validcnt = 0
   							BEGIN
   							SELECT @errmsg = 'Invalid EM Company'
   							GOTO error
   							END
   
   						-- validate Equipment
   						SELECT @validcnt = count(*) FROM bEMEM where EMCo = @EMCo and Equipment = @Equipment
   						IF @validcnt = 0
   							BEGIN
   							SELECT @errmsg = 'Invalid Equipment'
   							GOTO error
   							END
   
   						-- validate Cost Code
   						SELECT @validcnt = count(*) FROM bEMCC where EMGroup = @EMGroup and CostCode = @CostCode
   						IF @validcnt = 0
   							BEGIN
   							SELECT @errmsg = 'Invalid Cost Code'
   							GOTO error
   							END
   
   						-- validate EM Cost Type
   						SELECT @validcnt = count(*) FROM bEMCT where EMGroup = @EMGroup and CostType = @EMCType
   						IF @validcnt = 0
   							BEGIN
   							SELECT @errmsg = 'Invalid EM Cost Type'
   							GOTO error
   							END
   
   						-- validate EM CostType / EM CostCode combination
       					SELECT @validcnt = count(*) FROM bEMCH where EMCo = @EMCo and EMGroup = @EMGroup and  Equipment = @Equipment
   								and CostType = @EMCType and CostCode = @CostCode
       					IF @validcnt = 0
           					BEGIN
           					SELECT @validcnt = count(*) FROM bEMCX where EMGroup = @EMGroup and CostType = @EMCType
   		  							and CostCode = @CostCode
   	   		 				IF @validcnt = 0
   		  						BEGIN
   		  						SELECT @errmsg = 'Invalid cost type/cost code combination'
   		  						GOTO error
   		  						END
           					END
   	  					END
   
               		IF @ARTransType<>'M' AND (@Job IS NOT NULL or @Phase IS NOT NULL or @CostType IS NOT NULL)
                 			BEGIN
                 			SELECT @errmsg = 'Invalid Contract or Contract Item'
                 			GOTO error
                 			END
   
              			-- UM
             			IF NOT EXISTS (SELECT * FROM bHQUM WHERE UM=@UM) AND @UM IS NOT NULL
                			BEGIN
                			SELECT @errmsg = 'Invalid UM'
                			GOTO error
                			END
   
   					-- Validate rptApplyMth and rptApplyTrans.  If both have values,
   			   		-- then they must be valid to be useful.  Validate to assure this.
   					if isnull(@rptApplyMth, '') <> '' and isnull(@rptApplyTrans, 0) <> 0
   						begin
   						select ARCo, Mth, ARTrans
   						from bARTH
   						where ARCo = @ARCo and Mth = @rptApplyMth and ARTrans = @rptApplyTrans
   								and Mth = AppliedMth and ARTrans = AppliedTrans
   						if @@rowcount = 0
   							begin
   							select @errmsg = 'The original Mth: ' + convert(varchar(8), @rptApplyMth, 1)
   							select @errmsg = @errmsg + ' and Transaction: ' + convert(varchar(10), @rptApplyTrans)
   							select @errmsg = @errmsg + ' have been purged or is invalid.'
       		  				goto error
       		  				end 
   						end
   
             			-- UPDATE ARTH & ARMT
            			exec @rcode= bspARTHUpdate @ARCo,@Mth,@CustGroup,@Customer,
                  			@Amount,@Retainage, @FinanceChg, @DiscTaken,@ARTransType,@TransDate,
                  			@ApplyMth,@ApplyTrans,@errmsg output
             			if @rcode<>0 goto error
   
             	      	-- done with validation - get next line
             	      	SELECT @ARLine=MIN(ARLine) FROM inserted
             	      	WHERE ARCo=@ARCo AND Mth=@Mth AND ARTrans=@ARTrans AND ARLine>@ARLine
             	      	END		-- END OF LINES
   
   	   		GetNextTrans:
   	   			SELECT @ARTrans=MIN(ARTrans) FROM inserted
                   WHERE ARCo=@ARCo AND Mth=@Mth AND ARTrans>@ARTrans
                   END -- trans loop
   
         	SELECT @Mth=MIN(Mth) FROM inserted WHERE ARCo=@ARCo AND Mth>@Mth
          	END  -- mth loop
   
     	SELECT @ARCo=MIN(ARCo) FROM inserted WHERE ARCo>@ARCo
     	End -- Co loop
   */
   
   if @numrows > 1
   	begin
   	fetch next from bARTL_insert 
   	into @ARCo, @Mth, @ARTrans, @ARLine, @RecType, @LineType, @Description, @GLCo, @GLAcct, @TaxGroup, @TaxCode, 
   		 @Amount, @TaxBasis, @TaxAmount, @RetgPct, @Retainage, @DiscOffered, @DiscTaken, @ApplyMth, @ApplyTrans, 
   		 @ApplyLine, @JCCo, @Contract, @Item, @ContractUnits, @Job, @PhaseGroup, @Phase, @CostType, @UM, @JobUnits, 
   		 @JobHours, @INCo, @Loc, @MatlGroup, @Material, @UnitPrice, @MatlUnits, @CustJob, @CustPO, @EMCo, @Equipment, 
   		 @EMGroup, @CostCode, @EMCType, @CompType, @Component, @FinanceChg, @rptApplyMth, @rptApplyTrans
   	if @@fetch_status = 0
   		goto insert_check
   	else
   		begin
   		close bARTL_insert
   		deallocate bARTL_insert
   		end
   	end
   
   -- Audit inserts
   insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   select 'bARTL','ARCo: ' + convert(varchar(3),i.ARCo) + ' Mth: ' + convert(varchar(8), i.Mth,1)
       	+ ' ARTrans: ' + convert(varchar(6), i.ARTrans)
       	+ ' ARLine: ' + convert(varchar(3),i.ARLine), i.ARCo, 'A',
       	NULL, NULL, NULL, getdate(), SUSER_SNAME() FROM inserted i
   join bARCO c with (nolock) on c.ARCo = i.ARCo
   where i.ARCo = c.ARCo and c.AuditTrans = 'Y'
   
   Return
   
   error:
   	SELECT @errmsg = 'Trans ' + convert(varchar(10),@ARTrans) + ' Line ' + convert(varchar(10),@ARLine) +' ' + @errmsg
   	SELECT @errmsg = @errmsg + ' - cannot INSERT INTO ARTL'
   
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
  
  
 





GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
  
  /****** Object:  Trigger dbo.btARTLu    Script Date: 8/28/99 9:38:20 AM ******/
   CREATE trigger [dbo].[btARTLu] on [dbo].[bARTL] for UPDATE as
   

/*----------------------------------------------------------------------------------------------------------------------------------------------
   *
   *  Update trigger for ARTL
   *  Created By: JRE
   *  Date: bc 12/10/98
   *  Revised:  JM 8/19/98 - added condition to skip GLAcct validation if a receipt (per Jim, Issue 2760)
   *		    JM 6/21/99 - Added HQMA inserts.  Ref Issue 3852.
   *      		bc 02/02/00 - remmed out IN Location validation
   *        	bc 02/24/00 - added line type 'R' to orig. inv check
   *         	bc 07/11/00 - the original invoice can have a different tax code then the apply trans
   *                     	when the apply trans is an adjustment or write off
   *        	GG 04/10/01 - changed GL Account validation to use bspGLACfPostable
   *	        TJL 07/23/01 - Issue #13833, Don't Validate RecType IF ARTransType = 'M' and RecType is NULL
   *	        TJL 08/17/01 - Validate JC CostType for Misc Receipt only if LineType = 'J'
   *			         	Add validation for Misc Receipt LineType 'E' equipment
   *	        TJL 08/28/01 - Allow Detail LineType changes on Adjustments and Credits per Issue #13448
   *	        TJL 09/10/01 - If an update occurs that is associated with an imminent purge, we will not run the
   *	 		            bspARTHUpdate script nor will we update the audit master HQMA.
   *	        TJL 09/12/01 - Issue #14589, modified to update HQMA entries correctly for each bARTL update
   *	        TJL 09/24/01 - Issue #14610,  Minor change to Compare orig TaxGroup and TaxCode for 'A' and 'W' as well as 'C' types.
   *	        TJL 09/27/01 - Related to Issue 13104,  We do not need to Validate GL Acct when processing a Retainage Line.
   *	        TJL 10/02/01 - Issue #13104, Supercedes Issue #13448, Remove all LineType validation completely
   *			TJL 03/01/02 - Issue #14171, Add FinanceChg, rptApplyMth, rptApplyTrans columns
   *			SR 07/09/02 - 17738 pass @phasegroup to bspJCVCOSTTYPE
   *			TJL 08/09/02 - Issue #15923, Among much else, fixed bspJCVCOSTTYPE error occuring here.
   *			TJL 10/23/02 - Issue #18598, JB must be allowed to Change TaxCode on an Item
   *			TJL 04/30/03 - Issue #20936, Reverse Release Retainage
   *			TJL 05/05/03 - Issue #21203, Arithmetic errors when inserting large dollar values into HQMA
   *			GF 07/15/2003 - issue #21828 - speed improvements nolocks, select top 1 1, use FAST_FORWARD cursor
   *			TJL 08/11/03 - Issue #22102, If TaxCode has Changed on item, update original ARTL line
   *			TJL 02/04/04 - Issue #23642, TaxCode validation errmsg should include ' or TaxGroup'
   *			TJL 12/29/04 - Issue #26488, Not auditing some fields going from NULL to Something or Something to NULL
   *			TJL 09/11/06 - Issue #30663, Don't Validate GLRevAcct (Form GLAcct) on 0.00 value lines
   *			TJL 05/29/08 - Issue #128286, International Sales Tax
   *			TJL 11/13/09 - Issue #136580, Modified only to be consistent with bspARBHVal
   *			AMR 01/17/11 - #142350, making case insensitive by removing unused vars and renaming same named variables
   *
   *--------------------------------------------------------------------------------------------------------------------------------------------------*/
   
   DECLARE @numrows int, @errmsg varchar(255), @validcnt int, @validcnt2 int, @rcode int, @CostTypeAbbrev varchar(3)
   
   SELECT @numrows = @@rowcount
   IF @numrows = 0 RETURN
   SET nocount ON
   
	--#142350 - removing @phasegroup tinyint
	DECLARE @ARCo bCompany,
			@Mth bMonth,
			@ARTrans bTrans,
			@ARLine smallint,
			@RecType tinyint,
			@LineType char(1),
			@Description bDesc,
			@GLCo bCompany,
			@GLAcct bGLAcct,
			@TaxGroup bGroup,
			@TaxCode bTaxCode,
			@Amount bDollar,
			@TaxBasis bDollar,
			@TaxAmount bDollar,
			@RetgPct bPct,
			@Retainage bDollar,
			@DiscOffered bDollar,
			@DiscTaken bDollar,
			@ApplyMth bMonth,
			@ApplyTrans bTrans,
			@ApplyLine smallint,
			@JCCo bCompany,
			@Contract bContract,
			@Item bContractItem,
			@ContractUnits bUnits,
			@Job bJob,
			@PhaseGroup bGroup,
			@Phase bPhase,
			@CostType bJCCType,
			@UM bUM,
			@JobUnits bUnits,
			@JobHours bHrs,
			@INCo bCompany,
			@Loc bLoc,
			@MatlGroup bGroup,
			@Material bMatl,
			@UnitPrice bUnitCost,
			@MatlUnits bUnits,
			@CustJob varchar(20),
			@CustPO varchar(20),
			@EMCo bCompany,
			@Equipment bEquip,
			@EMGroup bGroup,
			@CostCode bCostCode,
			@EMCType bEMCType,
			@CompType varchar(10),
			@Component bEquip,
			@ARTransType char(1),
			@subtype char(1),
			@InvoiceAmount bDollar,
			@PaidAmount bDollar,
			@CustGroup bGroup,
			@Customer bCustomer,
			@Invoiced bDollar,
			@Paid bDollar,
			@LastInvDate bDate,
			@LastPayDate bDate,
			@TransDate bDate,
			@HighestCredit bDollar,
			@PrevAmtDue bDollar,
			@AmountDue bDollar,
			@PayFullDate bDate,
			@PrevPayFullDate bDate,
			@ApplyARTransType char(1),
			@audittrans bYN,
			@PurgeFlag bYN,
			@FinanceChg bDollar,
			@rptApplyMth bMonth,
			@rptApplyTrans bTrans
   
   
   -- check for primary key changes
   if update(ARCo) or update(Mth) or update (ARTrans) or update (ARLine)
   	BEGIN
   	SELECT @errmsg = 'Updates are not allowed to ARCo,Month or ARTrans #'
   	GOTO error
   	END
   
   if update(ApplyMth) or update(ApplyTrans) or update(ApplyLine)
   	BEGIN
   	SELECT @errmsg =  'Updates are not allowed to ApplyMth,ApplyTrans or ApplyLine #'
   	GOTO error
   	END
   
   -- create cursor to loop throught the records
   -- validate for various line types
   if @numrows = 1
   	select @ARCo = i.ARCo, @Mth = i.Mth, @ARTrans = i.ARTrans, @ARLine = i.ARLine, @RecType = i.RecType, 
   		   @LineType = i.LineType, @Description = i.Description, @GLCo = i.GLCo, @GLAcct = i.GLAcct, 
   		   @TaxGroup = i.TaxGroup, @TaxCode = i.TaxCode, 
   		   @Amount = i.Amount - d.Amount, @TaxBasis = i.TaxBasis - d.TaxBasis, 
   		   @TaxAmount = i.TaxAmount, @RetgPct = i.RetgPct, 
   		   @Retainage = i.Retainage - d.Retainage, @DiscOffered = i.DiscOffered - d.DiscOffered,
   		   @DiscTaken = i.DiscTaken - d.DiscTaken, @ApplyMth = i.ApplyMth, @ApplyTrans = i.ApplyTrans,
   		   @ApplyLine = i.ApplyLine, @JCCo = i.JCCo, @Contract = i.Contract, @Item = i.Item, 
   		   @ContractUnits = i.ContractUnits, @Job = i.Job, @PhaseGroup = i.PhaseGroup, @Phase = i.Phase, 
   		   @CostType = i.CostType, @UM = i.UM, @JobUnits = i.JobUnits, @JobHours = i.JobHours, @INCo = i.INCo, 
   		   @Loc = i.Loc, @MatlGroup = i.MatlGroup, @Material = i.Material, @UnitPrice = i.UnitPrice, 
   		   @MatlUnits = i.MatlUnits, @CustJob = i.CustJob, @CustPO = i.CustPO, @EMCo = i.EMCo, 
   		   @Equipment = i.Equipment, @EMGroup = i.EMGroup, @CostCode = i.CostCode, @EMCType = i.EMCType, 
   		   @CompType = i.CompType, @Component = i.Component, @FinanceChg = i.FinanceChg - d.FinanceChg, 
   		   @rptApplyMth = i.rptApplyMth, @rptApplyTrans = i.rptApplyTrans, @PurgeFlag = i.PurgeFlag
   	from inserted i
   	JOIN deleted d ON i.ARCo=d.ARCo and i.Mth=d.Mth and i.ARTrans=d.ARTrans and i.ARLine=d.ARLine
   else
   	begin
   	-- use a cursor to process each inserted row
   	declare bARTL_insert cursor FAST_FORWARD
   	for select i.ARCo, i.Mth, i.ARTrans, i.ARLine, i.RecType, i.LineType, i.Description, i.GLCo, i.GLAcct, 
   			i.TaxGroup, i.TaxCode, i.Amount - d.Amount, i.TaxBasis - d.TaxBasis, 
   			i.TaxAmount, i.RetgPct, i.Retainage - d.Retainage, i.DiscOffered - d.DiscOffered, 
   			i.DiscTaken - d.DiscTaken, i.ApplyMth, i.ApplyTrans, i.ApplyLine, i.JCCo, i.Contract, i.Item, 
   			i.ContractUnits, i.Job, i.PhaseGroup, i.Phase, i.CostType, i.UM, i.JobUnits, i.JobHours, i.INCo, 
   			i.Loc, i.MatlGroup, i.Material, i.UnitPrice, i.MatlUnits, i.CustJob, i.CustPO, i.EMCo, i.Equipment, 
   			i.EMGroup, i.CostCode, i.EMCType, i.CompType, i.Component, i.FinanceChg - d.FinanceChg,
   			i.rptApplyMth, i.rptApplyTrans, i.PurgeFlag
   	from inserted i
   	JOIN deleted d ON i.ARCo=d.ARCo and i.Mth=d.Mth and i.ARTrans=d.ARTrans and i.ARLine=d.ARLine
   	-- open cursor
   	open bARTL_insert
   	fetch next from bARTL_insert 
   	into @ARCo, @Mth, @ARTrans, @ARLine, @RecType, @LineType, @Description, @GLCo, @GLAcct, @TaxGroup, @TaxCode, 
   		 @Amount, @TaxBasis, @TaxAmount, @RetgPct, @Retainage, @DiscOffered, @DiscTaken, @ApplyMth, @ApplyTrans, 
   		 @ApplyLine, @JCCo, @Contract, @Item, @ContractUnits, @Job, @PhaseGroup, @Phase, @CostType, @UM, @JobUnits, 
   		 @JobHours, @INCo, @Loc, @MatlGroup, @Material, @UnitPrice, @MatlUnits, @CustJob, @CustPO, @EMCo, @Equipment, 
   		 @EMGroup, @CostCode, @EMCType, @CompType, @Component, @FinanceChg, @rptApplyMth, @rptApplyTrans, @PurgeFlag
   	if @@fetch_status <> 0
   		begin
   		select @errmsg = 'Cursor error'
   		goto error
   		end
   	end
   
   insert_check:
   if @PurgeFlag = 'Y' goto ARTL_next
   
   -- Validate Transaction
   SELECT @ARTransType=ARTransType,@TransDate=TransDate,
   	@CustGroup=CustGroup,@Customer=Customer
   FROM bARTH with (nolock)
   WHERE @ARCo = ARCo AND Mth=@Mth AND ARTrans=@ARTrans
   IF @@rowcount<>1
   	BEGIN
   	SELECT @errmsg = 'Transaction Header not found'
   	GOTO error
   	END
   
   -- Validate Apply To information
   IF @ARTransType not in ('I','M','F','R','V')
   	BEGIN
   	IF NOT EXISTS (SELECT top 1 1 FROM bARTL with (nolock) WHERE @ARCo = ARCo AND Mth=@ApplyMth 
   					AND ARTrans=@ApplyTrans AND ARLine=@ApplyLine)
   		BEGIN
   		SELECT @errmsg = 'Apply to Transaction or Line not found'
   		GOTO error
   		END
   
	-- JB directly adjusts any released retainage amounts origianlly brought over from JB on a change to a reinterfaced bill
	IF @LineType <> 'R' and NOT EXISTS (SELECT top 1 1 
								FROM bARTL with (nolock) 
								WHERE @ARCo = ARCo AND Mth=@ApplyMth AND ARTrans=@ApplyTrans AND ARLine=@ApplyLine 
									AND RecType=@RecType
									AND IsNull(JCCo,0)=IsNull(@JCCo,0) AND IsNull(Contract,'')=IsNull(@Contract,'')
									AND IsNull(INCo,0)=IsNull(@INCo,0) AND IsNull(Loc,'')=IsNull(@Loc,'')
									AND ((@ARTransType in ('P')) 
										or (@ARTransType in ('A','C','W') and IsNull(@TaxGroup,0)=IsNull(TaxGroup,0)	--TaxGroup must always be same, Orig = Applied
											and IsNull(TaxCode,'') = IsNull(@TaxCode,IsNull(TaxCode,'')))))				--If Applied TaxCode exists, must be equal to Orig.  If Applied empty, Orig can be anything (??)
		BEGIN
		SELECT @errmsg = 'Information does not match the Original Invoice Line'
		GOTO error
		END
   	END
   
   -- Validate RecType
   IF @ARTransType <> 'M' or (@ARTransType = 'M' and @RecType is not NULL)
   	BEGIN
   	IF NOT EXISTS (SELECT top 1 1 FROM bARRT with (nolock) WHERE @ARCo = ARCo AND @RecType = RecType)
   		BEGIN
   		SELECT @errmsg = 'Invalid Receivable Type'
   		GOTO error
   		END
   	END
   
   -- Validate Line Type for Invoices,Credit memos,Adjustments, WriteOffs
   IF @ARTransType in ('I','C','A','W') AND @LineType not in ('M','C','O','E','R', 'F')
   	BEGIN
   	SELECT @errmsg = 'LineType is Invalid, use (M)aterial, (C)ontract, (E)quipment, (R)etainage, (O)ther, (F)inChg'
   	GOTO error
   	END
   
   -- Validate GLAcct - skip if a Receipt (Issue 2760 per Jim 8/19/98)
   if @Amount <> 0 and @ARTransType not in ('P', 'R', 'V')
   	begin
   	select @subtype = null
   	if @Contract is not null select @subtype = 'J'
   	exec @rcode=bspGLACfPostable @GLCo, @GLAcct, @subtype, @errmsg output
   	IF @rcode <> 0 GOTO error
   	end
   
   -- Validate TaxCode
   if update(TaxCode)
   BEGIN
   	if @TaxCode is not null
   		begin
   		IF not exists(SELECT top 1 1 FROM bHQTX with (nolock) WHERE @TaxGroup = TaxGroup AND @TaxCode = TaxCode)
   			BEGIN
   			SELECT @errmsg = 'TaxCode or TaxGroup is Invalid '
   			GOTO error
   			END
   		end
   END
   
   -- REM'D Issue #22102 for reasons specific to JB.  Rely on validation in AR to catch this.
   /*IF @TaxCode IS NULL AND @TaxAmount<>0
   	BEGIN
   	SELECT @errmsg = 'Tax Amount not allowed without a Tax Code'
   	GOTO error
   	END
   */
   
   -- Validate ApplyLine
   IF @ARTransType in ('I','M') AND (@ApplyTrans <> @ARTrans or @ApplyLine <> @ARLine)
   	BEGIN
   	SELECT @errmsg = 'Invoice or Misc Cash must apply to itself. Invalid ApplyTrans or ApplyLine'
   	GOTO error
   	END
   
   IF @ARTransType not in ('I','M') and not exists(SELECT top 1 1 FROM bARTL r with (nolock) where @ARCo = r.ARCo
   				AND @ApplyMth = r.Mth AND @ApplyTrans = r.ARTrans  AND @ApplyLine = r.ARLine)
   	BEGIN
   	SELECT @errmsg = 'Invalid ApplyTrans or ApplyLine'
   	GOTO error
   	END
   
   -- Contract Item
   if @ARTransType = 'I' and @Item is not null
   	begin
   	IF not exists(SELECT top 1 1 FROM bJCCI with (nolock) WHERE @JCCo=JCCo AND @Contract=Contract AND @Item=Item)
   		BEGIN
   		SELECT @errmsg = 'Invalid Contract or Contract Item'
   		GOTO error
   		END
   	end
   
   -- Validate Job on Misc Cash Receipt
   IF @ARTransType='M' AND @LineType = 'J' AND (@Job IS NOT NULL)
   	BEGIN
   	select @CostTypeAbbrev=str(@CostType,3)
   	exec @rcode=bspJCVCOSTTYPE @JCCo, @Job, @PhaseGroup, @Phase, @CostTypeAbbrev, null,
   						null, null, null, null, null, null, null, null, null, @errmsg output
   	IF @rcode<>0 GOTO error
   	END
   
   -- Validate Equipment on Misc Cash Receipt
   IF @ARTransType='M' AND @LineType = 'E'
   	BEGIN
   	-- validate EM Company
   	if update(EMCo)
   		begin
   		if not exists(select top 1 1 from bEMCO with (nolock) where EMCo=@EMCo)
   			begin
   			SELECT @errmsg = 'Invalid EM Company'
   			GOTO error
   			END
   		end
   
   	-- validate Equipment
   	if update(Equipment)
   		begin
   		if not exists(select top 1 1 from bEMEM with (nolock) where EMCo=@EMCo and Equipment=@Equipment)
   			begin
   			SELECT @errmsg = 'Invalid Equipment'
   			GOTO error
   			END
   		end
   
   	-- validate Cost Code
   	if update(CostCode)
   		begin
   		if not exists(select top 1 1 from bEMCC with (nolock) where EMGroup=@EMGroup and CostCode=@CostCode)
   			BEGIN
   			SELECT @errmsg = 'Invalid Cost Code'
   			GOTO error
   			END
   		end
   
   	-- validate EM Cost Type
   	if update(EMCType)
   		begin
   		if not exists(select top 1 1 from bEMCT with (nolock) where EMGroup=@EMGroup and CostType=@EMCType)
   			BEGIN
   			SELECT @errmsg = 'Invalid EM Cost Type'
   			GOTO error
   			END
   		end
   
   	-- validate EM CostType / EM CostCode combination
   	if update(CostCode) or update(EMCType)
   		begin
   		if not exists(select top 1 1 from bEMCH with (nolock) where EMCo=@EMCo and EMGroup = @EMGroup 
   						and Equipment = @Equipment and CostType = @EMCType and CostCode = @CostCode)
   			begin
   			if not exists(select top 1 1 from bEMCX with (nolock) where EMGroup=@EMGroup and CostType=@EMCType and CostCode=@CostCode)
   				BEGIN
   				SELECT @errmsg = 'Invalid cost type/cost code combination'
   				GOTO error
   				END
   			end
   		end
   	END
   
   IF @ARTransType<>'M' AND (@Job IS NOT NULL or @Phase IS NOT NULL or @CostType IS NOT NULL)
   	BEGIN
   	SELECT @errmsg = 'Invalid Contract or Contract Item'
   	GOTO error
   	END
   
   -- UM
   if update(UM)
   	begin
   	if @UM is not null
   		begin
   		IF NOT EXISTS(SELECT top 1 1 FROM bHQUM with (nolock) WHERE UM=@UM)
   			BEGIN
   			SELECT @errmsg = 'Invalid UM'
   			GOTO error
   			END
   		end
   	end
   
   -- Validate rptApplyMth and rptApplyTrans.  If both have values,
   -- then they must be valid to be useful.  Validate to assure this.
   if isnull(@rptApplyMth, '') <> '' and isnull(@rptApplyTrans, 0) <> 0
   	begin
   	if not exists(select top 1 1 from bARTH with (nolock) where ARCo=@ARCo and Mth = @rptApplyMth 
   				and ARTrans = @rptApplyTrans and Mth = AppliedMth and ARTrans = AppliedTrans)
   		begin
   		select @errmsg = 'The original Mth: ' + isnull(convert(varchar(8), @rptApplyMth, 1),'')
   		select @errmsg = @errmsg + ' and Transaction: ' + isnull(convert(varchar(10), @rptApplyTrans),'')
   		select @errmsg = @errmsg + ' have been purged or is invalid.'
   		goto error
   		end
   	end
   
   -- UPDATE ARTH & ARMT
   exec @rcode= bspARTHUpdate @ARCo, @Mth, @CustGroup, @Customer, @Amount, @Retainage, @FinanceChg, 
   						   @DiscTaken, @ARTransType, @TransDate, @ApplyMth, @ApplyTrans, @errmsg output
   if @rcode<>0 goto error
   
   
   ARTL_next:
   if @numrows > 1
   	begin
   	fetch next from bARTL_insert 
   	into @ARCo, @Mth, @ARTrans, @ARLine, @RecType, @LineType, @Description, @GLCo, @GLAcct, @TaxGroup, @TaxCode, 
   		 @Amount, @TaxBasis, @TaxAmount, @RetgPct, @Retainage, @DiscOffered, @DiscTaken, @ApplyMth, @ApplyTrans, 
   		 @ApplyLine, @JCCo, @Contract, @Item, @ContractUnits, @Job, @PhaseGroup, @Phase, @CostType, @UM, @JobUnits, 
   		 @JobHours, @INCo, @Loc, @MatlGroup, @Material, @UnitPrice, @MatlUnits, @CustJob, @CustPO, @EMCo, @Equipment, 
   		 @EMGroup, @CostCode, @EMCType, @CompType, @Component, @FinanceChg, @rptApplyMth, @rptApplyTrans, @PurgeFlag
   	if @@fetch_status = 0
   		goto insert_check
   	else
   		begin
   		close bARTL_insert
   		deallocate bARTL_insert
   		end
   	end
   
   
   /* OLD CODE
   -- loop throught the records
  
   -- get the first Company
   SELECT @ARCo=MIN(ARCo) FROM inserted
   WHILE @ARCo IS NOT NULL
   	begin
   	-- get the first month for this company
   	SELECT @Mth=MIN(Mth) FROM inserted WHERE ARCo=@ARCo
   	WHILE @Mth IS NOT NULL
       	BEGIN
          	-- get the first transaction for this Company & Mth
          	SELECT @ARTrans=MIN(ARTrans) FROM inserted WHERE ARCo=@ARCo AND Mth=@Mth
          	WHILE @ARTrans IS NOT NULL
            	BEGIN
            	-- Validate Transaction
            	SELECT @ARTransType=ARTransType,@TransDate=TransDate,
                   	@CustGroup=CustGroup,@Customer=Customer
            	FROM bARTH
            	WHERE @ARCo = ARCo AND Mth=@Mth AND ARTrans=@ARTrans
            	IF @@rowcount<>1
              		BEGIN
              		SELECT @errmsg = 'Transaction Header not found'
              		GOTO error
              		END
   
            	SELECT @ARLine=MIN(ARLine) FROM inserted WHERE ARCo=@ARCo AND Mth=@Mth AND ARTrans=@ARTrans
            	WHILE @ARLine IS NOT NULL
              		BEGIN
   	       		-- if this update is relative to a purging process, dont validate or update ARTH or ARMT for this
   	       		-- line soon to be purged. This code is necessary because some updating occurs before the delete
   	       		-- trigger fires.
              		SELECT @PurgeFlag = PurgeFlag FROM inserted
              		WHERE ARCo=@ARCo AND Mth=@Mth AND ARTrans=@ARTrans AND ARLine = @ARLine
              		IF @PurgeFlag = 'Y' goto GetNextLine
   
              		SELECT @RecType = i.RecType, @LineType = i.LineType, @Description = i.Description,
                     	@GLCo = i.GLCo, @GLAcct = i.GLAcct, @TaxGroup = i.TaxGroup, @TaxCode = i.TaxCode,
                     	@Amount = i.Amount-d.Amount, @TaxBasis = i.TaxBasis-d.TaxBasis,
                     	@TaxAmount = i.TaxAmount,
                     	@RetgPct = i.RetgPct,
                     	@Retainage = i.Retainage-d.Retainage,
                     	@DiscOffered = i.DiscOffered-d.DiscOffered,
                     	@DiscTaken = i.DiscTaken-d.DiscTaken,
                     	@ApplyMth = i.ApplyMth, @ApplyTrans = i.ApplyTrans,
                     	@ApplyLine = i.ApplyLine, @JCCo = i.JCCo, @Contract = i.Contract,
                     	@Item = i.Item, @ContractUnits = i.ContractUnits, @Job = i.Job,
                     	@PhaseGroup = i.PhaseGroup, @Phase = i.Phase, @CostType = i.CostType,
                     	@UM = i.UM, @JobUnits = i.JobUnits, @JobHours = i.JobHours, @INCo = i.INCo,
                     	@Loc = i.Loc, @MatlGroup = i.MatlGroup, @Material = i.Material,
                     	@UnitPrice = i.UnitPrice, @MatlUnits = i.MatlUnits,
                     	@CustJob = i.CustJob, @CustPO = i.CustPO, @EMCo = i.EMCo, @Equipment = i.Equipment,
                     	@EMGroup = i.EMGroup, @CostCode = i.CostCode, @EMCType = i.EMCType,
   	              	@CompType = i.CompType, @Component = i.Component,
   					@FinanceChg = i.FinanceChg-d.FinanceChg,
   					@rptApplyMth = i.rptApplyMth, @rptApplyTrans = i.rptApplyTrans
              		FROM inserted i
              		JOIN deleted d ON i.ARCo=d.ARCo and i.Mth=d.Mth and i.ARTrans=d.ARTrans and i.ARLine=d.ARLine
              		WHERE i.ARCo=@ARCo AND i.Mth=@Mth AND i.ARTrans=@ARTrans and i.ARLine=@ARLine
   
              		-- Validate Apply To information
             		IF @ARTransType not in ('I','M','F','R','V')
                		BEGIN
                		IF NOT EXISTS (SELECT * FROM bARTL
                               WHERE @ARCo = ARCo AND Mth=@ApplyMth AND ARTrans=@ApplyTrans AND ARLine=@ApplyLine)
                  			BEGIN
                  			SELECT @errmsg = 'Apply to Transaction or Line not found'
                  			GOTO error
                  			END
   
                		-- JB directly adjusts any released retainage amounts origianlly brought over from JB on a change to a reinterfaced bill
                		IF @LineType <> 'R' and
                   			NOT EXISTS (SELECT * FROM bARTL
                               	WHERE @ARCo = ARCo AND Mth=@ApplyMth AND ARTrans=@ApplyTrans AND ARLine=@ApplyLine
                               		AND RecType=@RecType
   -- Mod Per Issue #13104              	AND IsNull(LineType, '') = case when @ARTransType = 'W' then IsNull(@LineType, '') else IsNull(LineType, '') end
   -- Mod Per Issue #13448	 				AND IsNull(LineType,'')=IsNull(@LineType,'')
                       	        	AND IsNull(JCCo,0)=IsNull(@JCCo,0) AND IsNull(Contract,'')=IsNull(@Contract,'')
                               		AND ((@ARTransType in ('P')) or (@ARTransType in ('A','C','W') and IsNull(@TaxGroup,0)=IsNull(TaxGroup,0)
   -- Mod Per Issue #18598            	and IsNull(TaxCode,'') = IsNull(@TaxCode,IsNull(TaxCode,''))
   									)))
                       	BEGIN
                       	SELECT @errmsg = 'Information does not match the Original Invoice Line'
                       	GOTO error
                       	END
                 		END
   
              		-- Validate RecType
   	       		IF @ARTransType <> 'M' or (@ARTransType = 'M' and @RecType is not NULL)
   		      		BEGIN
              	  		IF NOT EXISTS (SELECT * FROM bARRT WHERE @ARCo = ARCo AND @RecType = RecType)
                   		BEGIN
                			SELECT @errmsg = 'Invalid Receivable Type'
                			GOTO error
                			END
   		      		END
   
              		-- Validate Line Type for Invoices,Credit memos,Adjustments, WriteOffs
              		IF @ARTransType in ('I','C','A','W') AND @LineType not in ('M','C','O','E','R', 'F')
                		BEGIN
                		SELECT @errmsg = 'LineType is Invalid, use (M)aterial, (C)ontract, (E)quipment, (R)etainage, (O)ther, (F)inChg'
                		GOTO error
                		END
   
              		-- Validate GLAcct - skip if a Receipt (Issue 2760 per Jim 8/19/98)
              		if @ARTransType not in ('P', 'R', 'V')
      	         		begin
                		select @subtype = null
                		if @Contract is not null select @subtype = 'J'
                		exec @rcode=bspGLACfPostable @GLCo, @GLAcct, @subtype, @errmsg output
                		IF @rcode <> 0 GOTO error
                		end
   
              		-- Validate TaxCode
              		IF NOT EXISTS (SELECT * FROM bHQTX WHERE @TaxGroup = TaxGroup AND @TaxCode = TaxCode)
                             AND @TaxCode IS NOT NULL
                		BEGIN
                		SELECT @errmsg = 'TaxCode is Invalid '
                		GOTO error
                		END
              		IF @TaxCode IS NULL AND @TaxAmount<>0
                		BEGIN
               		SELECT @errmsg = 'Tax Amount not allowed without a Tax Code'
                		GOTO error
                		END
   
              		-- Validate ApplyLine
              		IF @ARTransType in ('I','M') AND
                			(@ApplyTrans <> @ARTrans or @ApplyLine <> @ARLine)
                		BEGIN
                		SELECT @errmsg = 'Invoice or Misc Cash must apply to itself. Invalid ApplyTrans or ApplyLine'
                		GOTO error
                		END
              		IF @ARTransType not in ('I','M') AND NOT EXISTS
                			(SELECT * FROM bARTL r
                  				WHERE @ARCo = r.ARCo  AND @ApplyMth = r.Mth
                  					AND @ApplyTrans = r.ARTrans  AND @ApplyLine = r.ARLine)
                		BEGIN
                		SELECT @errmsg = 'Invalid ApplyTrans or ApplyLine'
                		GOTO error
                		END
   
              		-- Contract Item
              		IF NOT EXISTS (SELECT * FROM bJCCI WHERE @JCCo=JCCo AND @Contract=Contract AND @Item=Item)
                			AND  @ARTransType = 'I' AND @Item IS NOT NULL
                		BEGIN
                		SELECT @errmsg = 'Invalid Contract or Contract Item'
                		GOTO error
                		END
   
               	-- Validate Job on Misc Cash Receipt
               	IF @ARTransType='M' AND @LineType = 'J' AND (@Job IS NOT NULL)
                 		BEGIN
            	  		select @CostTypeAbbrev=str(@CostType,3)
   					-- Issue #15923, This format (with phasegroup) was causing troubles
                 		--exec @rcode=bspJCVCOSTTYPE @jcco=@JCCo, @job=@Job, @phasegroup=@PhaseGroup,@phase=@Phase,
                      	--	@costtype=@CostTypeAbbrev, @override = 'N',@msg=@errmsg output
      					exec @rcode=bspJCVCOSTTYPE @JCCo, @Job, @PhaseGroup, @Phase, @CostTypeAbbrev, null,
   						null,null,null,null,null,null,null,null,null,@errmsg output
                 		IF @rcode<>0 GOTO error
                 		END
   
               	-- Validate Equipment on Misc Cash Receipt
   	        	IF @ARTransType='M' AND @LineType = 'E'
   	  	        	BEGIN
   	  	        	-- validate EM Company
   		        	SELECT @validcnt = count(*) FROM bEMCO where EMCo = @EMCo
   		        	IF @validcnt = 0
   
   			         	BEGIN
   			         	SELECT @errmsg = 'Invalid EM Company'
   			         	GOTO error
   			         	END
   
   		        	-- validate Equipment
   		      		SELECT @validcnt = count(*) FROM bEMEM where EMCo = @EMCo and Equipment = @Equipment
   		        	IF @validcnt = 0
   			         	BEGIN
   			         	SELECT @errmsg = 'Invalid Equipment'
   			         	GOTO error
   			         	END
   
   		     		-- validate Cost Code
               		SELECT @validcnt = count(*) FROM bEMCC where EMGroup = @EMGroup and CostCode = @CostCode
   		        	IF @validcnt = 0
   			         	BEGIN
   			         	SELECT @errmsg = 'Invalid Cost Code'
   			         	GOTO error
   			         	END
   
   		        	-- validate EM Cost Type
   		        	SELECT @validcnt = count(*) FROM bEMCT where EMGroup = @EMGroup and CostType = @EMCType
   		        	IF @validcnt = 0
   			         	BEGIN
   			         	SELECT @errmsg = 'Invalid EM Cost Type'
   			         	GOTO error
   			         	END
   
   		        	-- validate EM CostType / EM CostCode combination
       		    	SELECT @validcnt = count(*) FROM bEMCH where EMCo = @EMCo and EMGroup = @EMGroup and  Equipment = @Equipment
   			         		and CostType = @EMCType and CostCode = @CostCode
       		    	IF @validcnt = 0
           			 	BEGIN
           			 	SELECT @validcnt = count(*) FROM bEMCX where EMGroup = @EMGroup and CostType = @EMCType
   		  		          	and CostCode = @CostCode
   
   	   		         	IF @validcnt = 0
   		  		          	BEGIN
   		  		          	SELECT @errmsg = 'Invalid cost type/cost code combination'
   		  		          	GOTO error
   		  		          	END
           			 	END
   	  	        	END
   
              		IF @ARTransType<>'M' AND (@Job IS NOT NULL or @Phase IS NOT NULL or @CostType IS NOT NULL)
                		BEGIN
                		SELECT @errmsg = 'Invalid Contract or Contract Item'
                		GOTO error
                		END
   
              		-- UM
              		IF NOT EXISTS (SELECT * FROM bHQUM WHERE UM=@UM) AND @UM IS NOT NULL
                		BEGIN
                		SELECT @errmsg = 'Invalid UM'
                		GOTO error
                		END
   
   				-- Validate rptApplyMth and rptApplyTrans.  If both have values,
   			   	-- then they must be valid to be useful.  Validate to assure this.
   				if isnull(@rptApplyMth, '') <> '' and isnull(@rptApplyTrans, 0) <> 0
   					begin
   					select ARCo, Mth, ARTrans
   					from bARTH
   					where ARCo = @ARCo and Mth = @rptApplyMth and ARTrans = @rptApplyTrans
   							and Mth = AppliedMth and ARTrans = AppliedTrans
   					if @@rowcount = 0
   						begin
   						select @errmsg = 'The original Mth: ' + convert(varchar(8), @rptApplyMth, 1)
   						select @errmsg = @errmsg + ' and Transaction: ' + convert(varchar(10), @rptApplyTrans)
   						select @errmsg = @errmsg + ' have been purged or is invalid.'
       		  			goto error
       		  			end
   					end
   
              		-- UPDATE ARTH & ARMT
              		exec @rcode= bspARTHUpdate @ARCo,@Mth,@CustGroup,@Customer,
                 		@Amount,@Retainage, @FinanceChg, @DiscTaken,@ARTransType,@TransDate,
                 		@ApplyMth,@ApplyTrans,@errmsg output
   
              		if @rcode<>0 goto error
   
              		-- done with validation - get next line
            	GetNextLine:
              		SELECT @ARLine=MIN(ARLine) FROM inserted
              		WHERE ARCo=@ARCo AND Mth=@Mth AND ARTrans=@ARTrans AND ARLine>@ARLine
              		END		-- END OF LINES
   
      		GetNextTrans:
            	SELECT @ARTrans=MIN(ARTrans) FROM inserted
            	WHERE ARCo=@ARCo AND Mth=@Mth AND ARTrans>@ARTrans
          		END -- trans loop
   
       	SELECT @Mth=MIN(Mth) FROM inserted WHERE ARCo=@ARCo AND Mth>@Mth
        	END  -- mth loop
   
     	SELECT @ARCo=MIN(ARCo) FROM inserted WHERE ARCo>@ARCo
   	End -- Co loop
   */ -- END OLD
   
   -- HQMA Audit Updates
   -- skip if auditing turned off or purging records
   if not exists (select top 1 1 from inserted i join bARCO a with (nolock) on i.ARCo=a.ARCo where i.ARCo=a.ARCo 
   			and a.AuditTrans = 'Y' and i.PurgeFlag = 'N')
      	return
   
   
   if update(RecType)
   BEGIN
   	insert into bHQMA select 'bARTL', 'ARCo: ' + convert(varchar(3),i.ARCo)
   	+ ' Mth: ' + convert(varchar(8), i.Mth,1)
   	+ ' ARTrans: ' + convert(varchar(6), i.ARTrans)
   	+ ' ARLine: ' + convert(varchar(5),i.ARLine), i.ARCo, 'C',
   	'RecType', convert(varchar(12),d.RecType), convert(varchar(12),i.RecType), getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.ARCo = i.ARCo and d.Mth = i.Mth and d.ARTrans = i.ARTrans and d.ARLine = i.ARLine
   	join bARCO a with (nolock) on a.ARCo = i.ARCo
   	where isnull(d.RecType, 0) <> isnull(i.RecType, 0)  and a.AuditTrans = 'Y' and i.PurgeFlag = 'N'
   END
   
   if update(LineType)
   BEGIN
   	insert into bHQMA select 'bARTL', 'ARCo: ' + convert(varchar(3),i.ARCo)
   	+ ' Mth: ' + convert(varchar(8), i.Mth,1)
   	+ ' ARTrans: ' + convert(varchar(6), i.ARTrans)
   	+ ' ARLine: ' + convert(varchar(5),i.ARLine), i.ARCo, 'C',
   	'LineType', d.LineType, i.LineType, getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.ARCo = i.ARCo and d.Mth = i.Mth and d.ARTrans = i.ARTrans and d.ARLine = i.ARLine
   	join bARCO a with (nolock) on a.ARCo = i.ARCo
   	where isnull(d.LineType, '') <> isnull(i.LineType, '') and a.AuditTrans = 'Y' and i.PurgeFlag = 'N'
   END
   
   if update(Description)
   BEGIN
   	insert into bHQMA select 'bARTL', 'ARCo: ' + convert(varchar(3),i.ARCo)
   	+ ' Mth: ' + convert(varchar(8), i.Mth,1)
   	+ ' ARTrans: ' + convert(varchar(6), i.ARTrans)
   	+ ' ARLine: ' + convert(varchar(5),i.ARLine), i.ARCo, 'C',
   	'Description', d.Description, i.Description, getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.ARCo = i.ARCo and d.Mth = i.Mth and d.ARTrans = i.ARTrans and d.ARLine = i.ARLine
   	join bARCO a with (nolock) on a.ARCo = i.ARCo
   	where isnull(d.Description, '') <> isnull(i.Description, '') and a.AuditTrans = 'Y' and i.PurgeFlag = 'N'
   END
   
   if update(GLCo)
   BEGIN
   	insert into bHQMA select 'bARTL', 'ARCo: ' + convert(varchar(3),i.ARCo)
   	+ ' Mth: ' + convert(varchar(8), i.Mth,1)
   	+ ' ARTrans: ' + convert(varchar(6), i.ARTrans)
   	+ ' ARLine: ' + convert(varchar(5),i.ARLine), i.ARCo, 'C',
   	'GLCo', convert(varchar(12),d.GLCo), convert(varchar(12),i.GLCo), getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.ARCo = i.ARCo and d.Mth = i.Mth and d.ARTrans = i.ARTrans and d.ARLine = i.ARLine
   	join bARCO a with (nolock) on a.ARCo = i.ARCo
   	where isnull(d.GLCo, 0) <> isnull(i.GLCo, 0) and a.AuditTrans = 'Y' and i.PurgeFlag = 'N'
   END
   
   if update(GLAcct)
   BEGIN
   	insert into bHQMA select 'bARTL', 'ARCo: ' + convert(varchar(3),i.ARCo)
   	+ ' Mth: ' + convert(varchar(8), i.Mth,1)
   	+ ' ARTrans: ' + convert(varchar(6), i.ARTrans)
   	+ ' ARLine: ' + convert(varchar(5),i.ARLine), i.ARCo, 'C',
   	'GLAcct', d.GLAcct, i.GLAcct, getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.ARCo = i.ARCo and d.Mth = i.Mth and d.ARTrans = i.ARTrans and d.ARLine = i.ARLine
   	join bARCO a with (nolock) on a.ARCo = i.ARCo and a.AuditTrans = 'Y' and i.PurgeFlag = 'N'
   	where isnull(d.GLAcct, '') <> isnull(i.GLAcct, '') and a.AuditTrans = 'Y' and i.PurgeFlag = 'N'
   END
   
   if update(TaxGroup)
   BEGIN	
   	insert into bHQMA select 'bARTL', 'ARCo: ' + convert(varchar(3),i.ARCo)
   	+ ' Mth: ' + convert(varchar(8), i.Mth,1)
   	+ ' ARTrans: ' + convert(varchar(6), i.ARTrans)
   	+ ' ARLine: ' + convert(varchar(5),i.ARLine), i.ARCo, 'C',
   	'TaxGroup', convert(varchar(12),d.TaxGroup), convert(varchar(12),i.TaxGroup), getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.ARCo = i.ARCo and d.Mth = i.Mth and d.ARTrans = i.ARTrans and d.ARLine = i.ARLine
   	join bARCO a with (nolock) on a.ARCo = i.ARCo
   	where isnull(d.TaxGroup, 0) <> isnull(i.TaxGroup, 0) and a.AuditTrans = 'Y' and i.PurgeFlag = 'N'
   END
   
   if update(TaxCode)
   BEGIN
   	insert into bHQMA select 'bARTL', 'ARCo: ' + convert(varchar(3),i.ARCo)
   	+ ' Mth: ' + convert(varchar(8), i.Mth,1)
   	+ ' ARTrans: ' + convert(varchar(6), i.ARTrans)
   	+ ' ARLine: ' + convert(varchar(5),i.ARLine), i.ARCo, 'C',
   	'TaxCode', d.TaxCode, i.TaxCode, getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.ARCo = i.ARCo and d.Mth = i.Mth and d.ARTrans = i.ARTrans and d.ARLine = i.ARLine
   	join bARCO a with (nolock) on a.ARCo = i.ARCo
   	where isnull(d.TaxCode, '') <> isnull(i.TaxCode, '') and a.AuditTrans = 'Y' and i.PurgeFlag = 'N'
   END
   
   if update(Amount)
   BEGIN
   	insert into bHQMA select 'bARTL', 'ARCo: ' + convert(varchar(3),i.ARCo)
   	+ ' Mth: ' + convert(varchar(8), i.Mth,1)
   	+ ' ARTrans: ' + convert(varchar(6), i.ARTrans)
   	+ ' ARLine: ' + convert(varchar(5),i.ARLine), i.ARCo, 'C',
   	'Amount', convert(varchar(16),d.Amount), convert(varchar(16),i.Amount), getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.ARCo = i.ARCo and d.Mth = i.Mth and d.ARTrans = i.ARTrans and d.ARLine = i.ARLine
   	join bARCO a with (nolock) on a.ARCo = i.ARCo
   	where d.Amount <> i.Amount and a.AuditTrans = 'Y' and i.PurgeFlag = 'N'
   END
   
   if update(TaxBasis)
   BEGIN
   	insert into bHQMA select 'bARTL', 'ARCo: ' + convert(varchar(3),i.ARCo)
   	+ ' Mth: ' + convert(varchar(8), i.Mth,1)
   	+ ' ARTrans: ' + convert(varchar(6), i.ARTrans)
   	+ ' ARLine: ' + convert(varchar(5),i.ARLine), i.ARCo, 'C',
   	'TaxBasis', convert(varchar(16),d.TaxBasis), convert(varchar(16),i.TaxBasis), getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.ARCo = i.ARCo and d.Mth = i.Mth and d.ARTrans = i.ARTrans and d.ARLine = i.ARLine
   	join bARCO a with (nolock) on a.ARCo = i.ARCo
   	where d.TaxBasis <> i.TaxBasis and a.AuditTrans = 'Y' and i.PurgeFlag = 'N'
   END
   
   if update(TaxAmount)
   BEGIN	
   	insert into bHQMA select 'bARTL', 'ARCo: ' + convert(varchar(3),i.ARCo)
   	+ ' Mth: ' + convert(varchar(8), i.Mth,1)
   	+ ' ARTrans: ' + convert(varchar(6), i.ARTrans)
   	+ ' ARLine: ' + convert(varchar(5),i.ARLine), i.ARCo, 'C',
   	'TaxAmount', convert(varchar(16),d.TaxAmount), convert(varchar(16),i.TaxAmount), getdate(), SUSER_SNAME()
     	from inserted i
     	join deleted d on d.ARCo = i.ARCo and d.Mth = i.Mth and d.ARTrans = i.ARTrans and d.ARLine = i.ARLine
     	join bARCO a with (nolock) on a.ARCo = i.ARCo
   	where d.TaxAmount <> i.TaxAmount and a.AuditTrans = 'Y' and i.PurgeFlag = 'N'
   END
   
   if update(RetgPct)
   BEGIN
   	insert into bHQMA select 'bARTL', 'ARCo: ' + convert(varchar(3),i.ARCo)
   	+ ' Mth: ' + convert(varchar(8), i.Mth,1)
   	+ ' ARTrans: ' + convert(varchar(6), i.ARTrans)
   	+ ' ARLine: ' + convert(varchar(5),i.ARLine), i.ARCo, 'C',
   	'RetgPct', convert(varchar(12),d.RetgPct), convert(varchar(12),i.RetgPct), getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.ARCo = i.ARCo and d.Mth = i.Mth and d.ARTrans = i.ARTrans and d.ARLine = i.ARLine
   	join bARCO a with (nolock) on a.ARCo = i.ARCo
   	where d.RetgPct <> i.RetgPct and a.AuditTrans = 'Y' and i.PurgeFlag = 'N'
   END
   
   if update(Retainage)
   BEGIN
   	insert into bHQMA select 'bARTL', 'ARCo: ' + convert(varchar(3),i.ARCo)
   	+ ' Mth: ' + convert(varchar(8), i.Mth,1)
   	+ ' ARTrans: ' + convert(varchar(6), i.ARTrans)
   	+ ' ARLine: ' + convert(varchar(5),i.ARLine), i.ARCo, 'C',
   	'Retainage', convert(varchar(16),d.Retainage), convert(varchar(16),i.Retainage), getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.ARCo = i.ARCo and d.Mth = i.Mth and d.ARTrans = i.ARTrans and d.ARLine = i.ARLine
   	join bARCO a with (nolock) on a.ARCo = i.ARCo
   	where d.Retainage <> i.Retainage and a.AuditTrans = 'Y' and i.PurgeFlag = 'N'
   END
   
   if update(DiscOffered)
   BEGIN
   	insert into bHQMA select 'bARTL', 'ARCo: ' + convert(varchar(3),i.ARCo)
   	+ ' Mth: ' + convert(varchar(8), i.Mth,1)
   	+ ' ARTrans: ' + convert(varchar(6), i.ARTrans)
   	+ ' ARLine: ' + convert(varchar(5),i.ARLine), i.ARCo, 'C',
   	'DiscOffered', convert(varchar(16),d.DiscOffered), convert(varchar(16),i.DiscOffered), getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.ARCo = i.ARCo and d.Mth = i.Mth and d.ARTrans = i.ARTrans and d.ARLine = i.ARLine
   	join bARCO a with (nolock) on a.ARCo = i.ARCo
   	where d.DiscOffered <> i.DiscOffered and a.AuditTrans = 'Y' and i.PurgeFlag = 'N'
   END
   
   if update(DiscTaken)
   BEGIN
   	insert into bHQMA select 'bARTL', 'ARCo: ' + convert(varchar(3),i.ARCo)
   	+ ' Mth: ' + convert(varchar(8), i.Mth,1)
   	+ ' ARTrans: ' + convert(varchar(6), i.ARTrans)
   	+ ' ARLine: ' + convert(varchar(5),i.ARLine), i.ARCo, 'C',
   	'DiscTaken', convert(varchar(16),d.DiscTaken), convert(varchar(16),i.DiscTaken), getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.ARCo = i.ARCo and d.Mth = i.Mth and d.ARTrans = i.ARTrans and d.ARLine = i.ARLine
   	join bARCO a with (nolock) on a.ARCo = i.ARCo
   	where d.DiscTaken <> i.DiscTaken and a.AuditTrans = 'Y' and i.PurgeFlag = 'N'
   END
   
   if update(ApplyMth)
   BEGIN
   	insert into bHQMA select 'bARTL', 'ARCo: ' + convert(varchar(3),i.ARCo)
   	+ ' Mth: ' + convert(varchar(8), i.Mth,1)
   	+ ' ARTrans: ' + convert(varchar(6), i.ARTrans)
   	+ ' ARLine: ' + convert(varchar(5),i.ARLine), i.ARCo, 'C',
   	'ApplyMth', convert(varchar(12),d.ApplyMth), convert(varchar(12),i.ApplyMth), getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.ARCo = i.ARCo and d.Mth = i.Mth and d.ARTrans = i.ARTrans and d.ARLine = i.ARLine
   	join bARCO a with (nolock) on a.ARCo = i.ARCo
   	where isnull(d.ApplyMth, '') <> isnull(i.ApplyMth, '') and a.AuditTrans = 'Y' and i.PurgeFlag = 'N'
   END
   
   if update(ApplyTrans)
   BEGIN
   	insert into bHQMA select 'bARTL', 'ARCo: ' + convert(varchar(3),i.ARCo)
   	+ ' Mth: ' + convert(varchar(8), i.Mth,1)
   	+ ' ARTrans: ' + convert(varchar(6), i.ARTrans)
   	+ ' ARLine: ' + convert(varchar(5),i.ARLine), i.ARCo, 'C',
   	'ApplyTrans', convert(varchar(12),d.ApplyTrans), convert(varchar(12),i.ApplyTrans), getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.ARCo = i.ARCo and d.Mth = i.Mth and d.ARTrans = i.ARTrans and d.ARLine = i.ARLine
   	join bARCO a with (nolock) on a.ARCo = i.ARCo
   	where isnull(d.ApplyTrans, 0) <> isnull(i.ApplyTrans, 0) and a.AuditTrans = 'Y' and i.PurgeFlag = 'N'
   END
   
   if update(ApplyLine)
   BEGIN
   	insert into bHQMA select 'bARTL', 'ARCo: ' + convert(varchar(3),i.ARCo)
   	+ ' Mth: ' + convert(varchar(8), i.Mth,1)
   	+ ' ARTrans: ' + convert(varchar(6), i.ARTrans)
   	+ ' ARLine: ' + convert(varchar(5),i.ARLine), i.ARCo, 'C',
   	'ApplyLine', convert(varchar(12),d.ApplyLine), convert(varchar(12),i.ApplyLine), getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.ARCo = i.ARCo and d.Mth = i.Mth and d.ARTrans = i.ARTrans and d.ARLine = i.ARLine
   	join bARCO a with (nolock) on a.ARCo = i.ARCo
   	where isnull(d.ApplyLine, 0) <> isnull(i.ApplyLine, 0) and a.AuditTrans = 'Y' and i.PurgeFlag = 'N'
   END
   
   if update(JCCo)
   BEGIN
   	insert into bHQMA select 'bARTL', 'ARCo: ' + convert(varchar(3),i.ARCo)
   	+ ' Mth: ' + convert(varchar(8), i.Mth,1)
   	+ ' ARTrans: ' + convert(varchar(6), i.ARTrans)
   	+ ' ARLine: ' + convert(varchar(5),i.ARLine), i.ARCo, 'C',
   	'JCCo', convert(varchar(12),d.JCCo), convert(varchar(12),i.JCCo), getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.ARCo = i.ARCo and d.Mth = i.Mth and d.ARTrans = i.ARTrans and d.ARLine = i.ARLine
   	join bARCO a with (nolock) on a.ARCo = i.ARCo
   	where isnull(d.JCCo, 0) <> isnull(i.JCCo, 0) and a.AuditTrans = 'Y' and i.PurgeFlag = 'N'
   END
   
   if update(Contract)
   BEGIN
   	insert into bHQMA select 'bARTL', 'ARCo: ' + convert(varchar(3),i.ARCo)
   	+ ' Mth: ' + convert(varchar(8), i.Mth,1)
   	+ ' ARTrans: ' + convert(varchar(6), i.ARTrans)
   	+ ' ARLine: ' + convert(varchar(5),i.ARLine), i.ARCo, 'C',
   	'Contract', d.Contract, i.Contract, getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.ARCo = i.ARCo and d.Mth = i.Mth and d.ARTrans = i.ARTrans and d.ARLine = i.ARLine
   	join bARCO a with (nolock) on a.ARCo = i.ARCo
   	where isnull(d.Contract, '') <> isnull(i.Contract, '') and a.AuditTrans = 'Y' and i.PurgeFlag = 'N'
   END
   
   if update(Item)
   BEGIN
   	insert into bHQMA select 'bARTL', 'ARCo: ' + convert(varchar(3),i.ARCo)
   	+ ' Mth: ' + convert(varchar(8), i.Mth,1)
   	+ ' ARTrans: ' + convert(varchar(6), i.ARTrans)
   	+ ' ARLine: ' + convert(varchar(5),i.ARLine), i.ARCo, 'C',
   	'Item', d.Item, i.Item, getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.ARCo = i.ARCo and d.Mth = i.Mth and d.ARTrans = i.ARTrans and d.ARLine = i.ARLine
   	join bARCO a with (nolock) on a.ARCo = i.ARCo
   	where isnull(d.Item, '') <> isnull(i.Item, '') and a.AuditTrans = 'Y' and i.PurgeFlag = 'N'
   END
   
   if update(ContractUnits)
   BEGIN
   	insert into bHQMA select 'bARTL', 'ARCo: ' + convert(varchar(3),i.ARCo)
   	+ ' Mth: ' + convert(varchar(8), i.Mth,1)
   	+ ' ARTrans: ' + convert(varchar(6), i.ARTrans)
   	+ ' ARLine: ' + convert(varchar(5),i.ARLine), i.ARCo, 'C',
   	'ContractUnits', convert(varchar(16),d.ContractUnits), convert(varchar(16),i.ContractUnits), getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.ARCo = i.ARCo and d.Mth = i.Mth and d.ARTrans = i.ARTrans and d.ARLine = i.ARLine
   	join bARCO a with (nolock) on a.ARCo = i.ARCo
   	where isnull(d.ContractUnits, 0) <> isnull(i.ContractUnits, 0) and a.AuditTrans = 'Y' and i.PurgeFlag = 'N'
   END
   
   if update(Job)
   BEGIN
   	insert into bHQMA select 'bARTL', 'ARCo: ' + convert(varchar(3),i.ARCo)
   	+ ' Mth: ' + convert(varchar(8), i.Mth,1)
   	+ ' ARTrans: ' + convert(varchar(6), i.ARTrans)
   	+ ' ARLine: ' + convert(varchar(5),i.ARLine), i.ARCo, 'C',
   	'Job', d.Job, i.Job, getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.ARCo = i.ARCo and d.Mth = i.Mth and d.ARTrans = i.ARTrans and d.ARLine = i.ARLine
   	join bARCO a with (nolock) on a.ARCo = i.ARCo
   	where isnull(d.Job, '') <> isnull(i.Job, '') and a.AuditTrans = 'Y' and i.PurgeFlag = 'N'
   END
   
   if update(PhaseGroup)
   BEGIN
   	insert into bHQMA select 'bARTL', 'ARCo: ' + convert(varchar(3),i.ARCo)
   	+ ' Mth: ' + convert(varchar(8), i.Mth,1)
   	+ ' ARTrans: ' + convert(varchar(6), i.ARTrans)
   	+ ' ARLine: ' + convert(varchar(5),i.ARLine), i.ARCo, 'C',
   	  			'PhaseGroup', convert(varchar(12),d.PhaseGroup), convert(varchar(12),i.PhaseGroup), getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.ARCo = i.ARCo and d.Mth = i.Mth and d.ARTrans = i.ARTrans and d.ARLine = i.ARLine
   	join bARCO a with (nolock) on a.ARCo = i.ARCo
   	where isnull(d.PhaseGroup, 0) <> isnull(i.PhaseGroup, 0) and a.AuditTrans = 'Y' and i.PurgeFlag = 'N'
   END
   
   if update(Phase)
   BEGIN
   	insert into bHQMA select 'bARTL', 'ARCo: ' + convert(varchar(3),i.ARCo)
   	+ ' Mth: ' + convert(varchar(8), i.Mth,1)
   	+ ' ARTrans: ' + convert(varchar(6), i.ARTrans)
   	+ ' ARLine: ' + convert(varchar(5),i.ARLine), i.ARCo, 'C',
   	'Phase', d.Phase, i.Phase, getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.ARCo = i.ARCo and d.Mth = i.Mth and d.ARTrans = i.ARTrans and d.ARLine = i.ARLine
   	join bARCO a with (nolock) on a.ARCo = i.ARCo
   	where isnull(d.Phase, '') <> isnull(i.Phase, '') and a.AuditTrans = 'Y' and i.PurgeFlag = 'N'
   END
   
   if update(CostType)
   BEGIN
   	insert into bHQMA select 'bARTL', 'ARCo: ' + convert(varchar(3),i.ARCo)
   	+ ' Mth: ' + convert(varchar(8), i.Mth,1)
   	+ ' ARTrans: ' + convert(varchar(6), i.ARTrans)
   	+ ' ARLine: ' + convert(varchar(5),i.ARLine), i.ARCo, 'C',
   	'CostType', convert(varchar(12),d.CostType), convert(varchar(12),i.CostType), getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.ARCo = i.ARCo and d.Mth = i.Mth and d.ARTrans = i.ARTrans and d.ARLine = i.ARLine
   	join bARCO a with (nolock) on a.ARCo = i.ARCo
   	where isnull(d.CostType, 0) <> isnull(i.CostType, 0) and a.AuditTrans = 'Y' and i.PurgeFlag = 'N'
   END
   
   if update(UM)
   BEGIN
   	insert into bHQMA select 'bARTL', 'ARCo: ' + convert(varchar(3),i.ARCo)
   	+ ' Mth: ' + convert(varchar(8), i.Mth,1)
   	+ ' ARTrans: ' + convert(varchar(6), i.ARTrans)
   	+ ' ARLine: ' + convert(varchar(5),i.ARLine), i.ARCo, 'C',
   	'UM', d.UM, i.UM, getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.ARCo = i.ARCo and d.Mth = i.Mth and d.ARTrans = i.ARTrans and d.ARLine = i.ARLine
   	join bARCO a with (nolock) on a.ARCo = i.ARCo
   	where isnull(d.UM, '') <> isnull(i.UM, '') and a.AuditTrans = 'Y' and i.PurgeFlag = 'N'
   END
   
   if update(JobUnits)
   BEGIN
   	insert into bHQMA select 'bARTL', 'ARCo: ' + convert(varchar(3),i.ARCo)
   	+ ' Mth: ' + convert(varchar(8), i.Mth,1)
   	+ ' ARTrans: ' + convert(varchar(6), i.ARTrans)
   	+ ' ARLine: ' + convert(varchar(5),i.ARLine), i.ARCo, 'C',
   	'JobUnits', convert(varchar(16),d.JobUnits), convert(varchar(16),i.JobUnits), getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.ARCo = i.ARCo and d.Mth = i.Mth and d.ARTrans = i.ARTrans and d.ARLine = i.ARLine
   	join bARCO a with (nolock) on a.ARCo = i.ARCo
   	where isnull(d.JobUnits, 0) <> isnull(i.JobUnits, 0) and a.AuditTrans = 'Y' and i.PurgeFlag = 'N'
   END
   
   if update(JobHours)
   BEGIN
   	insert into bHQMA select 'bARTL', 'ARCo: ' + convert(varchar(3),i.ARCo)
   	+ ' Mth: ' + convert(varchar(8), i.Mth,1)
   	+ ' ARTrans: ' + convert(varchar(6), i.ARTrans)
   	+ ' ARLine: ' + convert(varchar(5),i.ARLine), i.ARCo, 'C',
   	'JobHours', convert(varchar(12),d.JobHours), convert(varchar(12),i.JobHours), getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.ARCo = i.ARCo and d.Mth = i.Mth and d.ARTrans = i.ARTrans and d.ARLine = i.ARLine
   	join bARCO a with (nolock) on a.ARCo = i.ARCo
   	where isnull(d.JobHours, 0) <> isnull(i.JobHours, 0) and a.AuditTrans = 'Y' and i.PurgeFlag = 'N'
   END
   
   if update(ActDate)
   BEGIN
   
   	insert into bHQMA select 'bARTL', 'ARCo: ' + convert(varchar(3),i.ARCo)
   	+ ' Mth: ' + convert(varchar(8), i.Mth,1)
   	+ ' ARTrans: ' + convert(varchar(6), i.ARTrans)
   	+ ' ARLine: ' + convert(varchar(5),i.ARLine), i.ARCo, 'C',
   	'ActDate', convert(varchar(12),d.ActDate), convert(varchar(12),i.ActDate), getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.ARCo = i.ARCo and d.Mth = i.Mth and d.ARTrans = i.ARTrans and d.ARLine = i.ARLine
   	join bARCO a with (nolock) on a.ARCo = i.ARCo
   	where isnull(d.ActDate, '') <> isnull(i.ActDate, '') and a.AuditTrans = 'Y' and i.PurgeFlag = 'N'
   END
   
   if update(INCo)
   BEGIN
   	insert into bHQMA select 'bARTL', 'ARCo: ' + convert(varchar(3),i.ARCo)
   	+ ' Mth: ' + convert(varchar(8), i.Mth,1)
   	+ ' ARTrans: ' + convert(varchar(6), i.ARTrans)
   	+ ' ARLine: ' + convert(varchar(5),i.ARLine), i.ARCo, 'C',
   	'INCo', convert(varchar(12),d.INCo), convert(varchar(12),i.INCo), getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.ARCo = i.ARCo and d.Mth = i.Mth and d.ARTrans = i.ARTrans and d.ARLine = i.ARLine
   	join bARCO a with (nolock) on a.ARCo = i.ARCo
   	where isnull(d.INCo, 0) <> isnull(i.INCo, 0) and a.AuditTrans = 'Y' and i.PurgeFlag = 'N'
   END
   
   if update(Loc)
   BEGIN
   	insert into bHQMA select 'bARTL', 'ARCo: ' + convert(varchar(3),i.ARCo)
   	+ ' Mth: ' + convert(varchar(8), i.Mth,1)
   	+ ' ARTrans: ' + convert(varchar(6), i.ARTrans)
   	+ ' ARLine: ' + convert(varchar(5),i.ARLine), i.ARCo, 'C',
   	'Loc', d.Loc, i.Loc, getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.ARCo = i.ARCo and d.Mth = i.Mth and d.ARTrans = i.ARTrans and d.ARLine = i.ARLine
   	join bARCO a with (nolock) on a.ARCo = i.ARCo
   	where isnull(d.Loc, '') <> isnull(i.Loc, '') and a.AuditTrans = 'Y' and i.PurgeFlag = 'N'
   END
   
   if update(MatlGroup)
   BEGIN
   	insert into bHQMA select 'bARTL', 'ARCo: ' + convert(varchar(3),i.ARCo)
   	+ ' Mth: ' + convert(varchar(8), i.Mth,1)
   	+ ' ARTrans: ' + convert(varchar(6), i.ARTrans)
   	+ ' ARLine: ' + convert(varchar(5),i.ARLine), i.ARCo, 'C',
   	'MatlGroup', convert(varchar(12),d.MatlGroup), convert(varchar(12),i.MatlGroup), getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.ARCo = i.ARCo and d.Mth = i.Mth and d.ARTrans = i.ARTrans and d.ARLine = i.ARLine
   	join bARCO a with (nolock) on a.ARCo = i.ARCo
   	where isnull(d.MatlGroup, 0) <> isnull(i.MatlGroup, 0) and a.AuditTrans = 'Y' and i.PurgeFlag = 'N'
   END
   
   if update(Material)
   BEGIN
   	insert into bHQMA select 'bARTL', 'ARCo: ' + convert(varchar(3),i.ARCo)
   	+ ' Mth: ' + convert(varchar(8), i.Mth,1)
   	+ ' ARTrans: ' + convert(varchar(6), i.ARTrans)
   	+ ' ARLine: ' + convert(varchar(5),i.ARLine), i.ARCo, 'C',
   	'Material', d.Material, i.Material, getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.ARCo = i.ARCo and d.Mth = i.Mth and d.ARTrans = i.ARTrans and d.ARLine = i.ARLine
   	join bARCO a with (nolock) on a.ARCo = i.ARCo
   	where isnull(d.Material, '') <> isnull(i.Material, '') and a.AuditTrans = 'Y' and i.PurgeFlag = 'N'
   END
   
   if update(UnitPrice)
   BEGIN
   	insert into bHQMA select 'bARTL', 'ARCo: ' + convert(varchar(3),i.ARCo)
   	+ ' Mth: ' + convert(varchar(8), i.Mth,1)
   	+ ' ARTrans: ' + convert(varchar(6), i.ARTrans)
   	+ ' ARLine: ' + convert(varchar(5),i.ARLine), i.ARCo, 'C',
   	'UnitPrice', convert(varchar(16),d.UnitPrice), convert(varchar(16),i.UnitPrice), getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.ARCo = i.ARCo and d.Mth = i.Mth and d.ARTrans = i.ARTrans and d.ARLine = i.ARLine
   	join bARCO a with (nolock) on a.ARCo = i.ARCo
   	where isnull(d.UnitPrice, 0) <> isnull(i.UnitPrice, 0) and a.AuditTrans = 'Y' and i.PurgeFlag = 'N'
   END
   
   if update(ECM)
   BEGIN
   	insert into bHQMA select 'bARTL', 'ARCo: ' + convert(varchar(3),i.ARCo)
   	+ ' Mth: ' + convert(varchar(8), i.Mth,1)
   
   	+ ' ARTrans: ' + convert(varchar(6), i.ARTrans)
   	+ ' ARLine: ' + convert(varchar(5),i.ARLine), i.ARCo, 'C',
   	'ECM', d.ECM, i.ECM, getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.ARCo = i.ARCo and d.Mth = i.Mth and d.ARTrans = i.ARTrans and d.ARLine = i.ARLine
   	join bARCO a with (nolock) on a.ARCo = i.ARCo
   	where isnull(d.ECM, '') <> isnull(i.ECM, '') and a.AuditTrans = 'Y' and i.PurgeFlag = 'N'
   END
   
   if update(MatlUnits)
   BEGIN
   	insert into bHQMA select 'bARTL', 'ARCo: ' + convert(varchar(3),i.ARCo)
   	+ ' Mth: ' + convert(varchar(8), i.Mth,1)
   	+ ' ARTrans: ' + convert(varchar(6), i.ARTrans)
   	+ ' ARLine: ' + convert(varchar(5),i.ARLine), i.ARCo, 'C',
   	'MatlUnits', convert(varchar(16),d.MatlUnits), convert(varchar(16),i.MatlUnits), getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.ARCo = i.ARCo and d.Mth = i.Mth and d.ARTrans = i.ARTrans and d.ARLine = i.ARLine
   	join bARCO a with (nolock) on a.ARCo = i.ARCo
   	where isnull(d.MatlUnits, 0) <> isnull(i.MatlUnits, 0) and a.AuditTrans = 'Y' and i.PurgeFlag = 'N'
   END
   
   if update(CustJob)
   BEGIN
   	insert into bHQMA select 'bARTL', 'ARCo: ' + convert(varchar(3),i.ARCo)
   	+ ' Mth: ' + convert(varchar(8), i.Mth,1)
   	+ ' ARTrans: ' + convert(varchar(6), i.ARTrans)
   	+ ' ARLine: ' + convert(varchar(5),i.ARLine), i.ARCo, 'C',
   	'CustJob', d.CustJob, i.CustJob, getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.ARCo = i.ARCo and d.Mth = i.Mth and d.ARTrans = i.ARTrans and d.ARLine = i.ARLine
   	join bARCO a with (nolock) on a.ARCo = i.ARCo
   	where isnull(d.CustJob, '') <> isnull(i.CustJob, '') and a.AuditTrans = 'Y' and i.PurgeFlag = 'N'
   END
   
   if update(CustPO)
   BEGIN
   	insert into bHQMA select 'bARTL', 'ARCo: ' + convert(varchar(3),i.ARCo)
   	+ ' Mth: ' + convert(varchar(8), i.Mth,1)
   	+ ' ARTrans: ' + convert(varchar(6), i.ARTrans)
   	+ ' ARLine: ' + convert(varchar(5),i.ARLine), i.ARCo, 'C',
   	'CustPO', d.CustPO, i.CustPO, getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.ARCo = i.ARCo and d.Mth = i.Mth and d.ARTrans = i.ARTrans and d.ARLine = i.ARLine
   	join bARCO a with (nolock) on a.ARCo = i.ARCo
   	where isnull(d.CustPO, '') <> isnull(i.CustPO, '') and a.AuditTrans = 'Y' and i.PurgeFlag = 'N'
   END
   
   if update(EMCo)
   BEGIN
   	insert into bHQMA select 'bARTL', 'ARCo: ' + convert(varchar(3),i.ARCo)
   	+ ' Mth: ' + convert(varchar(8), i.Mth,1)
   	+ ' ARTrans: ' + convert(varchar(6), i.ARTrans)
   	+ ' ARLine: ' + convert(varchar(5),i.ARLine), i.ARCo, 'C',
   	'EMCo', convert(varchar(12),d.EMCo), convert(varchar(12),i.EMCo), getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.ARCo = i.ARCo and d.Mth = i.Mth and d.ARTrans = i.ARTrans and d.ARLine = i.ARLine
   	join bARCO a with (nolock) on a.ARCo = i.ARCo
   	where isnull(d.EMCo, 0) <> isnull(i.EMCo, 0) and a.AuditTrans = 'Y' and i.PurgeFlag = 'N'
   END
   
   if update(Equipment)
   BEGIN
   	insert into bHQMA select 'bARTL', 'ARCo: ' + convert(varchar(3),i.ARCo)
   	+ ' Mth: ' + convert(varchar(8), i.Mth,1)
   	+ ' ARTrans: ' + convert(varchar(6), i.ARTrans)
   	+ ' ARLine: ' + convert(varchar(5),i.ARLine), i.ARCo, 'C',
   	'Equipment', d.Equipment, i.Equipment, getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.ARCo = i.ARCo and d.Mth = i.Mth and d.ARTrans = i.ARTrans and d.ARLine = i.ARLine
   	join bARCO a with (nolock) on a.ARCo = i.ARCo
   	where isnull(d.Equipment, '') <> isnull(i.Equipment, '') and a.AuditTrans = 'Y' and i.PurgeFlag = 'N'
   END
   
   if update(EMGroup)
   BEGIN
   	insert into bHQMA select 'bARTL', 'ARCo: ' + convert(varchar(3),i.ARCo)
   	+ ' Mth: ' + convert(varchar(8), i.Mth,1)
   	+ ' ARTrans: ' + convert(varchar(6), i.ARTrans)
   	+ ' ARLine: ' + convert(varchar(5),i.ARLine), i.ARCo, 'C',
   	'EMGroup', convert(varchar(12),d.EMGroup), convert(varchar(12),i.EMGroup), getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.ARCo = i.ARCo and d.Mth = i.Mth and d.ARTrans = i.ARTrans and d.ARLine = i.ARLine
   	join bARCO a with (nolock) on a.ARCo = i.ARCo
   	where isnull(d.EMGroup, 0) <> isnull(i.EMGroup, 0) and a.AuditTrans = 'Y' and i.PurgeFlag = 'N'
   END
   
   if update(CostCode)
   BEGIN
   	insert into bHQMA select 'bARTL', 'ARCo: ' + convert(varchar(3),i.ARCo)
   	+ ' Mth: ' + convert(varchar(8), i.Mth,1)
   	+ ' ARTrans: ' + convert(varchar(6), i.ARTrans)
   	+ ' ARLine: ' + convert(varchar(5),i.ARLine), i.ARCo, 'C',
   	'CostCode', d.CostCode, i.CostCode, getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.ARCo = i.ARCo and d.Mth = i.Mth and d.ARTrans = i.ARTrans and d.ARLine = i.ARLine
   	join bARCO a with (nolock) on a.ARCo = i.ARCo
   	where isnull(d.CostCode, '') <> isnull(i.CostCode, '') and a.AuditTrans = 'Y' and i.PurgeFlag = 'N'
   END
   
   if update(EMCType)
   BEGIN
   	insert into bHQMA select 'bARTL', 'ARCo: ' + convert(varchar(3),i.ARCo)
   	+ ' Mth: ' + convert(varchar(8), i.Mth,1)
   	+ ' ARTrans: ' + convert(varchar(6), i.ARTrans)
   	+ ' ARLine: ' + convert(varchar(5),i.ARLine), i.ARCo, 'C',
   	'EMCType', convert(varchar(12),d.EMCType), convert(varchar(12),i.EMCType), getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.ARCo = i.ARCo and d.Mth = i.Mth and d.ARTrans = i.ARTrans and d.ARLine = i.ARLine
   	join bARCO a with (nolock) on a.ARCo = i.ARCo
   	where isnull(d.EMCType, 0) <> isnull(i.EMCType, 0) and a.AuditTrans = 'Y' and i.PurgeFlag = 'N'
   END
   
   if update(FinanceChg)
   BEGIN
   	insert into bHQMA select 'bARTL', 'ARCo: ' + convert(varchar(3),i.ARCo)
   	+ ' Mth: ' + convert(varchar(8), i.Mth,1)
   	+ ' ARTrans: ' + convert(varchar(6), i.ARTrans)
   	+ ' ARLine: ' + convert(varchar(5),i.ARLine), i.ARCo, 'C',
   	'FinanceChg', convert(varchar(16),d.FinanceChg), convert(varchar(16),i.FinanceChg), getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.ARCo = i.ARCo and d.Mth = i.Mth and d.ARTrans = i.ARTrans and d.ARLine = i.ARLine
   	join bARCO a with (nolock) on a.ARCo = i.ARCo
   	where d.FinanceChg <> i.FinanceChg and a.AuditTrans = 'Y' and i.PurgeFlag = 'N'
   END
   
   if update(rptApplyMth)
   BEGIN
   	insert into bHQMA select 'bARTL', 'ARCo: ' + convert(varchar(3),i.ARCo)
   	+ ' Mth: ' + convert(varchar(8), i.Mth,1)
   	+ ' ARTrans: ' + convert(varchar(6), i.ARTrans)
   	+ ' ARLine: ' + convert(varchar(5),i.ARLine), i.ARCo, 'C',
   	'rptApplyMth', convert(varchar(12),d.rptApplyMth), convert(varchar(12),i.rptApplyMth), getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.ARCo = i.ARCo and d.Mth = i.Mth and d.ARTrans = i.ARTrans and d.ARLine = i.ARLine
   	join bARCO a with (nolock) on a.ARCo = i.ARCo
   	where isnull(d.rptApplyMth, '') <> isnull(i.rptApplyMth, '') and a.AuditTrans = 'Y' and i.PurgeFlag = 'N'
   END
   
   if update(rptApplyTrans)
   BEGIN
   	insert into bHQMA select 'bARTL', 'ARCo: ' + convert(varchar(3),i.ARCo)
   	+ ' Mth: ' + convert(varchar(8), i.Mth,1)
   	+ ' ARTrans: ' + convert(varchar(6), i.ARTrans)
   	+ ' ARLine: ' + convert(varchar(5),i.ARLine), i.ARCo, 'C',
   	'rptApplyTrans', convert(varchar(12),d.rptApplyTrans), convert(varchar(12),i.rptApplyTrans), getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.ARCo = i.ARCo and d.Mth = i.Mth and d.ARTrans = i.ARTrans and d.ARLine = i.ARLine
   	join bARCO a with (nolock) on a.ARCo = i.ARCo
   	where isnull(d.rptApplyTrans, 0) <> isnull(i.rptApplyTrans, 0) and a.AuditTrans = 'Y' and i.PurgeFlag = 'N'
   END
   
   if update(RetgTax)
   BEGIN	
   	insert into bHQMA select 'bARTL', 'ARCo: ' + convert(varchar(3),i.ARCo)
   	+ ' Mth: ' + convert(varchar(8), i.Mth,1)
   	+ ' ARTrans: ' + convert(varchar(6), i.ARTrans)
   	+ ' ARLine: ' + convert(varchar(5),i.ARLine), i.ARCo, 'C',
   	'RetgTax', convert(varchar(16),d.RetgTax), convert(varchar(16),i.RetgTax), getdate(), SUSER_SNAME()
     	from inserted i
     	join deleted d on d.ARCo = i.ARCo and d.Mth = i.Mth and d.ARTrans = i.ARTrans and d.ARLine = i.ARLine
     	join bARCO a with (nolock) on a.ARCo = i.ARCo
   	where d.RetgTax <> i.RetgTax and a.AuditTrans = 'Y' and i.PurgeFlag = 'N'
   END

   Return
   
   error:
   	SELECT @errmsg = 'Trans ' + convert(varchar(10),@ARTrans) + ' Line ' + convert(varchar(10),@ARLine) + ' ' + @errmsg
   	SELECT @errmsg = @errmsg + ' - cannot UPDATE ARTL'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
  
  
 





GO
ALTER TABLE [dbo].[bARTL] WITH NOCHECK ADD CONSTRAINT [CK_bARTL_ECM] CHECK (([ECM]='E' OR [ECM]='C' OR [ECM]='M' OR [ECM] IS NULL))
GO
ALTER TABLE [dbo].[bARTL] WITH NOCHECK ADD CONSTRAINT [CK_bARTL_PurgeFlag] CHECK (([PurgeFlag]='Y' OR [PurgeFlag]='N'))
GO
CREATE UNIQUE NONCLUSTERED INDEX [biARTLApplied] ON [dbo].[bARTL] ([ARCo], [ApplyMth], [ApplyTrans], [ApplyLine], [Mth], [ARTrans], [ARLine]) WITH (FILLFACTOR=90, STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biARTL] ON [dbo].[bARTL] ([ARCo], [Mth], [ARTrans], [ARLine]) WITH (FILLFACTOR=90, STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [biARTLContract] ON [dbo].[bARTL] ([JCCo], [Contract], [Item]) WITH (FILLFACTOR=90, STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bARTL] ([KeyID]) WITH (FILLFACTOR=90, STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [iARTLudARTOPDID] ON [dbo].[bARTL] ([udARTOPDID]) WITH (FILLFACTOR=90, STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO
