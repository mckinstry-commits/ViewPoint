CREATE TABLE [dbo].[bMSLB]
(
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[BatchSeq] [int] NOT NULL,
[HaulLine] [smallint] NOT NULL,
[BatchTransType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[MSTrans] [dbo].[bTrans] NULL,
[FromLoc] [dbo].[bLoc] NOT NULL,
[VendorGroup] [dbo].[bGroup] NULL,
[MatlVendor] [dbo].[bVendor] NULL,
[MatlGroup] [dbo].[bGroup] NOT NULL,
[Material] [dbo].[bMatl] NOT NULL,
[UM] [dbo].[bUM] NOT NULL,
[SaleType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[CustGroup] [dbo].[bGroup] NULL,
[Customer] [dbo].[bCustomer] NULL,
[CustJob] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[CustPO] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[PaymentType] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[CheckNo] [dbo].[bCMRef] NULL,
[Hold] [dbo].[bYN] NOT NULL,
[JCCo] [dbo].[bCompany] NULL,
[Job] [dbo].[bJob] NULL,
[PhaseGroup] [dbo].[bGroup] NULL,
[HaulPhase] [dbo].[bPhase] NULL,
[HaulJCCType] [dbo].[bJCCType] NULL,
[INCo] [dbo].[bCompany] NULL,
[ToLoc] [dbo].[bLoc] NULL,
[TruckType] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[StartTime] [smalldatetime] NULL,
[StopTime] [smalldatetime] NULL,
[Loads] [smallint] NOT NULL,
[Miles] [dbo].[bUnits] NOT NULL,
[Hours] [dbo].[bHrs] NOT NULL,
[Zone] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[HaulCode] [dbo].[bHaulCode] NULL,
[HaulBasis] [dbo].[bUnits] NOT NULL,
[HaulRate] [dbo].[bUnitCost] NOT NULL,
[HaulTotal] [dbo].[bDollar] NOT NULL,
[PayCode] [dbo].[bPayCode] NULL,
[PayBasis] [dbo].[bUnits] NOT NULL,
[PayRate] [dbo].[bUnitCost] NOT NULL,
[PayTotal] [dbo].[bDollar] NOT NULL,
[RevCode] [dbo].[bRevCode] NULL,
[RevBasis] [dbo].[bUnits] NOT NULL,
[RevRate] [dbo].[bUnitCost] NOT NULL,
[RevTotal] [dbo].[bDollar] NOT NULL,
[TaxGroup] [dbo].[bGroup] NULL,
[TaxCode] [dbo].[bTaxCode] NULL,
[TaxType] [tinyint] NULL,
[TaxBasis] [dbo].[bDollar] NOT NULL,
[TaxTotal] [dbo].[bDollar] NOT NULL,
[DiscBasis] [dbo].[bUnits] NOT NULL,
[DiscRate] [dbo].[bUnitCost] NOT NULL,
[DiscOff] [dbo].[bDollar] NOT NULL,
[TaxDisc] [dbo].[bDollar] NOT NULL,
[OldFromLoc] [dbo].[bLoc] NULL,
[OldVendorGroup] [dbo].[bGroup] NULL,
[OldMatlVendor] [dbo].[bVendor] NULL,
[OldMatlGroup] [dbo].[bGroup] NULL,
[OldMaterial] [dbo].[bMatl] NULL,
[OldUM] [dbo].[bUM] NULL,
[OldSaleType] [char] (1) COLLATE Latin1_General_BIN NULL,
[OldCustGroup] [dbo].[bGroup] NULL,
[OldCustomer] [dbo].[bCustomer] NULL,
[OldCustJob] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[OldCustPO] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[OldPaymentType] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[OldCheckNo] [dbo].[bCMRef] NULL,
[OldHold] [dbo].[bYN] NULL,
[OldJCCo] [dbo].[bCompany] NULL,
[OldJob] [dbo].[bJob] NULL,
[OldPhaseGroup] [dbo].[bGroup] NULL,
[OldHaulPhase] [dbo].[bPhase] NULL,
[OldHaulJCCType] [dbo].[bJCCType] NULL,
[OldINCo] [dbo].[bCompany] NULL,
[OldToLoc] [dbo].[bLoc] NULL,
[OldTruckType] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[OldStartTime] [smalldatetime] NULL,
[OldStopTime] [smalldatetime] NULL,
[OldLoads] [smallint] NULL,
[OldMiles] [dbo].[bUnits] NULL,
[OldHours] [dbo].[bHrs] NULL,
[OldZone] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[OldHaulCode] [dbo].[bHaulCode] NULL,
[OldHaulBasis] [dbo].[bUnits] NULL,
[OldHaulRate] [dbo].[bUnitCost] NULL,
[OldHaulTotal] [dbo].[bDollar] NULL,
[OldPayCode] [dbo].[bPayCode] NULL,
[OldPayBasis] [dbo].[bUnits] NULL,
[OldPayRate] [dbo].[bUnitCost] NULL,
[OldPayTotal] [dbo].[bDollar] NULL,
[OldRevCode] [dbo].[bRevCode] NULL,
[OldRevBasis] [dbo].[bUnits] NULL,
[OldRevRate] [dbo].[bUnitCost] NULL,
[OldRevTotal] [dbo].[bDollar] NULL,
[OldTaxGroup] [dbo].[bGroup] NULL,
[OldTaxCode] [dbo].[bTaxCode] NULL,
[OldTaxType] [tinyint] NULL,
[OldTaxBasis] [dbo].[bDollar] NULL,
[OldTaxTotal] [dbo].[bDollar] NULL,
[OldDiscBasis] [dbo].[bUnits] NULL,
[OldDiscRate] [dbo].[bUnitCost] NULL,
[OldDiscOff] [dbo].[bDollar] NULL,
[OldTaxDisc] [dbo].[bDollar] NULL,
[OldMSInv] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[OldAPRef] [dbo].[bAPReference] NULL,
[HaulPayTaxCode] [dbo].[bTaxCode] NULL,
[OldHaulPayTaxCode] [dbo].[bTaxCode] NULL,
[HaulPayTaxRate] [dbo].[bUnitCost] NULL,
[OldHaulPayTaxRate] [dbo].[bUnitCost] NULL,
[HaulPayTaxAmt] [dbo].[bDollar] NULL,
[OldHaulPayTaxAmt] [dbo].[bDollar] NULL,
[HaulPayTaxType] [tinyint] NULL,
[OldHaulPayTaxType] [tinyint] NULL
) ON [PRIMARY]
ALTER TABLE [dbo].[bMSLB] ADD
CONSTRAINT [CK_bMSLB_Hold] CHECK (([Hold]='Y' OR [Hold]='N'))
ALTER TABLE [dbo].[bMSLB] ADD
CONSTRAINT [CK_bMSLB_OldHold] CHECK (([OldHold]='Y' OR [OldHold]='N' OR [OldHold] IS NULL))
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   CREATE   trigger [dbo].[btMSLBd] on [dbo].[bMSLB] for DELETE as
   

/*-----------------------------------------------------------------
    *  Created By:  GG 11/08/00
    *  Modified By: GF 07/20/01 - Set AuditYN to 'N'
    *
    *	Unlock any associated MS Detail - set InUseBatchId to null.
    *
    */----------------------------------------------------------------
   
   declare @errmsg varchar(255), @numrows int, @validcnt int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   select @validcnt = count(*) from deleted where MSTrans is not null
   
   -- 'unlock' existing MS Detail
   update bMSTD set InUseBatchId = null
   from bMSTD t
   join deleted d on d.Co = t.MSCo and d.Mth = t.Mth and d.MSTrans = t.MSTrans
   if @@rowcount <> @validcnt
       begin
       select @errmsg = 'Unable to unlock MS Transaction Detail'
       goto error
       end
   
   return
   
   
   
   error:
   	select @errmsg = @errmsg + ' - cannot delete MS Haul Line Batch!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
  
 



GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE   trigger [dbo].[btMSLBi] on [dbo].[bMSLB] for INSERT as
/*--------------------------------------------------------------
* Created: GG 11/08/00
* Modified: GG 03/12/01 - auto add Time Sheet detail for Equipment attachments
*           GG 03/21/01 - next BatchSeq and HaulLine could return null, added isnull fix
*			GG 03/25/03 - #20702 - init haul charges for attachments if haul code is revenue based
*			GF 06/08/2004 - issue #24722 duplicate index error adding attachment
*			GF 04/26/2013 TFS-48578 look for haul rate quote override for equipment attachments
*
* Performs validation on critical columns.
*
* Locks bMSTD entries pulled into batch
*
* Adds bHQCC entries as needed
*
*--------------------------------------------------------------*/
    declare @numrows int, @errmsg varchar(255), @validcnt int, @opencursor tinyint, @msglco bCompany,
        @co bCompany, @mth bMonth, @batchid bBatchID, @inco bCompany,  @jcco bCompany, @glco bCompany,
        @batchseq int, @haulline smallint, @saletype char(1), @job bJob, @revcode bRevCode, @freightbill varchar(10),
        @saledate bDate, @emco bCompany, @equipment bEquip, @emgroup bGroup, @prco bCompany, @employee bEmployee,
        @attachment bEquip, @attachpostrev bYN, @emcategory bCat, @equipctype bJCCType, @mstrucktype varchar(10),
        @emtranstype char(1), @revrate bDollar, @timeum bUM, @workum bUM, @msg varchar(255), @rcode tinyint, @seq int,
        @line smallint, @haulcode bHaulCode, @revbased bYN
		----TFS-48578
		,@FromLoc bLoc, @CustGroup bGroup, @Customer bCustomer, @CustJob VARCHAR(20) ,@CustPO VARCHAR(20)
		,@ToLoc bLoc, @MatlGroup bGroup, @Material bMatl, @UM bUM, @Zone VARCHAR(10), @PhaseGroup bGroup, @Phase bPhase
		,@Quote VARCHAR(10), @LocGroup bGroup, @Category VARCHAR(10), @OvrHaulRate bUnitCost, @HaulBasis TINYINT
		,@TempRCode INT, @TempMsg VARCHAR(255), @haulbased VARCHAR(1)

    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
    
    set @opencursor = 0
    
    -- validate batch
    select @validcnt = count(*)
    from bHQBC r
    join inserted i ON i.Co = r.Co and i.Mth = r.Mth and i.BatchId = r.BatchId
    where r.Status = 0  -- must be Open
    if @validcnt <> @numrows
    	begin
    	select @errmsg = 'Invalid or missing Batch, must be Open!'
    	goto error
    	end
    -- validate with Haul Batch Header
    select @validcnt = count(*)
    from bMSHB h
    join inserted i ON i.Co = h.Co and i.Mth = h.Mth and i.BatchId = h.BatchId and i.BatchSeq = h.BatchSeq
    if @validcnt <> @numrows
    	begin
    	select @errmsg = 'Haul Lines reference an invalid or missing Haul Batch Header!'
    	goto error
    	end
    -- validate BatchTransType
    if exists(select * from inserted where BatchTransType not in ('A','C','D'))
        begin
        select @errmsg = 'Invalid Batch Trans Type, must be (A, C, or D)!'
        goto error
        end
    -- validate MS Trans#
    if exists(select * from inserted where BatchTransType = 'A' and MSTrans is not null)
    	begin
    	select @errmsg = 'MS Trans # must be null for all type (A) entries!'
    	goto error
    	end
    if exists(select * from inserted where BatchTransType <> 'A' and MSTrans is null)
    	begin
    	select @errmsg = 'All type (C and D) entries must have an MS Trans #!'
    	goto error
    	end
    
    -- attempt to update InUseBatchId in MSTD
    select @validcnt = count(*) from inserted where BatchTransType <> 'A'
    
    update bMSTD
    set InUseBatchId = i.BatchId
    from bMSTD t join inserted i on i.Co = t.MSCo and i.Mth = t.Mth and i.MSTrans = t.MSTrans
    where t.InUseBatchId is null	-- must be unlocked
    if @validcnt <> @@rowcount
    	begin
    	select @errmsg = 'Unable to lock existing MS Transaction!'
    	goto error
    	end
    
    -- check for new Time Sheets posted with Equipment usage
    if exists(select * from inserted i
                join bMSHB h on h.Co = i.Co and h.Mth = i.Mth and h.BatchId = i.BatchId and h.BatchSeq = i.BatchSeq
                where h.BatchTransType = 'A' and h.Equipment is not null and i.RevCode is not null)
        begin
        -- add equipment usage entries for attachments
        if @numrows = 1
            select @co = i.Co, @mth = i.Mth, @batchid = i.BatchId, @batchseq = i.BatchSeq, @haulline = i.HaulLine,
                @saletype = i.SaleType, @jcco = i.JCCo, @job = i.Job, @revcode = i.RevCode, @freightbill = h.FreightBill,
                @saledate = SaleDate, @emco = h.EMCo, @equipment = h.Equipment, @emgroup = h.EMGroup, @prco = h.PRCo,
                @employee = h.Employee, @haulcode = i.HaulCode
				----TFS-48578
				,@FromLoc = i.FromLoc, @CustGroup = i.CustGroup, @Customer = i.Customer, @CustJob = i.CustJob
				,@CustPO = i.CustPO, @inco = i.INCo, @ToLoc = i.ToLoc, @MatlGroup = i.MatlGroup, @Material = i.Material
				,@UM = i.UM, @Zone = i.Zone, @PhaseGroup = i.PhaseGroup, @Phase = i.HaulPhase

          	from inserted i
            join bMSHB h on h.Co = i.Co and h.Mth = i.Mth and h.BatchId = i.BatchId and h.BatchSeq = i.BatchSeq
        else
            begin
    
     	    -- use a cursor to process each inserted row
     	    declare bMSLB_insert cursor LOCAL FAST_FORWARD
    		for select i.Co, i.Mth, i.BatchId, i.BatchSeq, i.HaulLine, i.SaleType, i.JCCo, i.Job, i.RevCode, 
    				h.FreightBill, h.SaleDate, h.EMCo, h.Equipment, h.EMGroup, h.PRCo, h.Employee, i.HaulCode
					----TFS-48578
					,i.FromLoc, i.CustGroup, i.Customer, i.CustJob, i.CustPO, i.INCo, i.ToLoc, i.MatlGroup
					,i.Material, i.UM, i.Zone, i.PhaseGroup, i.HaulPhase
            from inserted i
            join bMSHB h on h.Co = i.Co and h.Mth = i.Mth and h.BatchId = i.BatchId and h.BatchSeq = i.BatchSeq
            where h.BatchTransType = 'A' and h.Equipment is not null and i.RevCode is not null
    
            open bMSLB_insert
            set @opencursor = 1  -- open cursor flag
    
            fetch next from bMSLB_insert into @co, @mth, @batchid, @batchseq, @haulline, @saletype, @jcco, @job, @revcode,
					@freightbill, @saledate, @emco, @equipment, @emgroup, @prco, @employee, @haulcode
					----TFS-48578
					,@FromLoc, @CustGroup, @Customer, @CustJob, @CustPO, @inco, @ToLoc, @MatlGroup
					,@Material, @UM, @Zone, @PhaseGroup, @Phase
            if @@fetch_status <> 0
     		    begin
                select @errmsg = 'Cursor error'
                goto error
                end
            end
    
        attachment_check:
        -- check for Equipment Attachments
        if exists(select 1 from dbo.bEMEM where EMCo = @emco and AttachToEquip = @equipment and Status = 'A')
            BEGIN
            ---- get first Attachment
            select @attachment = min(Equipment)
            from bEMEM where EMCo = @emco and AttachToEquip = @equipment and Status = 'A'

            -- if posting revenue to Attachment - add Time Sheet detail
            while @attachment is not null
				BEGIN
                select @attachpostrev = AttachPostRevenue, @emcategory = Category, @equipctype = UsageCostType,
                        @mstrucktype = MSTruckType
                from dbo.bEMEM
                where EMCo = @emco and Equipment = @attachment

				SET @OvrHaulRate = NULL
				if @attachpostrev = 'Y'
					BEGIN
					----TFS-48578 check for haul rate override for attachment
					-- check for revenue based haul code
					set @revbased = 'N'
					select @revbased = RevBased from bMSHC with (nolock) where MSCo = @co and HaulCode = @haulcode

					-- check for haul based revenue code
					set @haulbased = 'N'
					select @haulbased = HaulBased from bEMRC with (nolock) where EMGroup = @emgroup and RevCode = @revcode

					----need location group                                          
					SELECT @LocGroup = LocGroup
					FROM dbo.bINLM WITH (NOLOCK)
					WHERE INCo = @co
						AND Loc = @FromLoc
					IF @@ROWCOUNT = 0 SET @LocGroup = NULL
					---- need material category
					SELECT @Category = Category
					FROM dbo.bHQMT WITH (NOLOCK)
					WHERE MatlGroup = @MatlGroup
						AND Material = @Material
					IF @@ROWCOUNT = 0 SET @Category = NULL
					---- need haul basis                                          
					SELECT @HaulBasis = HaulBasis
					from dbo.bMSHC WITH (NOLOCK)
					WHERE MSCo = @co
						AND HaulCode = @haulcode
					if @@rowcount = 0 SET @HaulBasis = NULL

					----check for quote for ticket
					EXEC @TempRCode = dbo.bspMSTicTemplateGet @co, @saletype, @CustGroup, @Customer, @CustJob, @CustPO, @jcco, @job, @inco, @ToLoc, @FromLoc,
									@Quote OUTPUT, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, @TempMsg OUTPUT
					IF @TempRCode <> 0 SET @Quote = NULL
                                                        
					---- get haul rate
					EXEC @TempRCode = dbo.bspMSTicHaulRateGet @co, @haulcode, @MatlGroup, @Material, @Category, @LocGroup,
									@FromLoc, @mstrucktype, @UM, @Quote, @Zone, @HaulBasis, @jcco, @PhaseGroup, @Phase,
									@OvrHaulRate OUTPUT, NULL, @TempMsg OUTPUT
					IF @TempRCode <> 0 SET @OvrHaulRate = NULL
					IF @OvrHaulRate = 0 SET @OvrHaulRate = NULL                                      

                    -- get default Revenue code rate for Attachment
					SET @emtranstype = CASE WHEN @saletype <> 'J' THEN 'X' ELSE 'J' END
                    ----if isnull(@emtranstype,'') <> 'J' select @emtranstype = 'X'
                    exec @rcode = bspEMRevRateUMDflt @emco, @emgroup, @emtranstype, @attachment, @emcategory, @revcode,
									@jcco, @job, @revrate output, @timeum output, @workum output, @msg output
                    if @rcode <> 0 SET @revrate = 0
    
                    -- check for Time Sheet Header posted to Attachment
                    select @seq = BatchSeq
                    from dbo.bMSHB
                    where Co = @co and Mth = @mth and BatchId = @batchid and BatchTransType = 'A'
                        and isnull(FreightBill,'') = isnull(@freightbill,'') and SaleDate = @saledate
                        and EMCo = @emco and Equipment = @attachment and isnull(PRCo,0) = isnull(@prco,0)
                        and isnull(Employee,0) = isnull(@employee,0)
                    if @@rowcount = 0
                        BEGIN
                        select @seq = isnull(max(BatchSeq),0) + 1 -- next available seq
                        from bMSHB where Co = @co and Mth = @mth and BatchId = @batchid
                        -- add Time Sheet Header for Attachment
                        insert bMSHB (Co, Mth, BatchId, BatchSeq, BatchTransType, HaulTrans, FreightBill, SaleDate,
								HaulerType, EMCo, Equipment, EMGroup, PRCo, Employee)
                        values (@co, @mth, @batchid, @seq, 'A', null, @freightbill, @saledate, 'E', @emco, @attachment,
								@emgroup, @prco, @employee)
                        END
    

					---- issue #24722 for attachments get next for bMSLB not inserted
					select @line = isnull(max(HaulLine),0) + 1 -- next available Haul Line
					from dbo.bMSLB where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
   
                    ---- add Haul Line to Time Sheet for Attachment
                    insert into bMSLB (Co, Mth, BatchId, BatchSeq, HaulLine, BatchTransType, FromLoc, VendorGroup,
                        MatlVendor, MatlGroup, Material, UM, SaleType, CustGroup, Customer, CustJob, CustPO, PaymentType,
                        CheckNo, Hold, JCCo, Job, PhaseGroup, HaulPhase, HaulJCCType, INCo, ToLoc, TruckType, StartTime,
                        StopTime, Loads, Miles, Hours, Zone, HaulCode, HaulBasis, HaulRate, HaulTotal, PayCode, PayBasis,
                        PayRate, PayTotal, RevCode, RevBasis, RevRate, RevTotal, TaxGroup, TaxCode, TaxType, TaxBasis, TaxTotal,
                        DiscBasis, DiscRate, DiscOff, TaxDisc)
                    select @co, @mth, @batchid, @seq, @line, 'A', FromLoc, VendorGroup,
                        MatlVendor, MatlGroup, Material, UM, SaleType, CustGroup, Customer, CustJob, CustPO, PaymentType,
                        CheckNo, Hold, @jcco, @job, PhaseGroup, HaulPhase,
                        (case SaleType when 'J' then @equipctype else null end), INCo, ToLoc, @mstrucktype, StartTime,
                        StopTime, Loads, Miles, Hours, Zone, HaulCode,
						-- #20702 - if haul code is revenue based, init haul charge using attachment revenue
						(case @revbased when 'Y' then RevBasis else 0 end),
						----TFS-48578
						(case @revbased when 'Y' then @revrate else ISNULL(@OvrHaulRate, HaulRate) end),		
						(case @revbased when 'Y' then (RevBasis * @revrate) else 0 end),	
						null, 0, 0, 0, RevCode,
						----if rev code is haul based, init rev charge using haul code
						(case @haulbased when 'Y' then 0 else RevBasis end),
						----TFS-48578
						(case @haulbased when 'Y' then ISNULL(@OvrHaulRate, HaulRate) else @revrate end),
						(case @haulbased when 'Y' then 0 else (RevBasis * @revrate) end),
						TaxGroup, TaxCode, TaxType, 0, 0, 0, DiscRate, 0, 0
                    from inserted
                    where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq and HaulLine = @haulline
                    END ----@attachpostrev = 'Y'

                -- get next Attachment
                select @attachment = min(Equipment)
                from bEMEM
                where EMCo = @emco and AttachToEquip = @equipment and Status = 'A' and Equipment > @attachment
                END ----@attachment is not null
			END		
			    
        if @opencursor = 1
            begin
            fetch next from bMSLB_insert into @co, @mth, @batchid, @batchseq, @haulline, @saletype, @jcco, @job, @revcode,
							@freightbill, @saledate, @emco, @equipment, @emgroup, @prco, @employee
							----TFS-48578
							,@FromLoc, @CustGroup, @Customer, @CustJob, @CustPO, @inco, @ToLoc, @MatlGroup
							,@Material, @UM, @Zone, @PhaseGroup, @Phase
            if @@fetch_status = 0
     			goto attachment_check
     		else
     			begin
     			close bMSLB_insert
     			deallocate bMSLB_insert
                set @opencursor = 0
     			end
     		end
	end
    


-- Add entries to HQ Close Control if needed.
if @numrows = 1
    select @co = i.Co, @mth = i.Mth, @batchid = i.BatchId, @jcco = JCCo, @inco = INCo, @msglco = c.GLCo
    from inserted i join bMSCO c on i.Co = c.MSCo
else
    begin
    -- use a cursor to process each inserted row
    declare bMSLB_insert cursor LOCAL FAST_FORWARD
    for select distinct i.Co, i.Mth, i.BatchId, i.JCCo, i.INCo, c.GLCo
    from inserted i join bMSCO c on i.Co = c.GLCo
    
    open bMSLB_insert
    set @opencursor = 1
    
    fetch next from bMSLB_insert into @co, @mth, @batchid,  @jcco, @inco, @msglco
    if @@fetch_status <> 0
    	begin
    	select @errmsg = 'Cursor error'
    	goto error
    	end
    end
    
insert_HQCC_check:
-- add entry to HQ Close Control for MS Company GLCo
if not exists(select top 1 1 from bHQCC where Co = @co and Mth = @mth and BatchId = @batchid and GLCo = @msglco)
    begin
    insert bHQCC (Co, Mth, BatchId, GLCo)
    values (@co, @mth, @batchid, @msglco)
    end
    
-- get GL Company for Job sales
if @jcco is not null
    begin
    select @glco = GLCo from bJCCO where JCCo = @jcco
    if @@rowcount <> 0
        begin
        -- add entry to HQ Close Control for Job Sale
        if not exists(select top 1 1 from bHQCC where Co = @co and Mth = @mth and BatchId = @batchid and GLCo = @glco)
            begin
            insert bHQCC (Co, Mth, BatchId, GLCo)
            values (@co, @mth, @batchid, @glco)
            end
        end
    end
    
-- get GL Company for Inventory sales
if @inco is not null
    begin
        select @glco = GLCo from bINCO where INCo = @inco
        if @@rowcount <> 0
    	begin
        -- add entry to HQ Close Control for Inventory Sale
    	if not exists(select * from bHQCC where Co = @co and Mth = @mth and BatchId = @batchid and GLCo = @glco)
            begin
            insert bHQCC (Co, Mth, BatchId, GLCo)
            values (@co, @mth, @batchid, @glco)
            end
    	end
    end
    
if @numrows > 1
    begin
    fetch next from bMSLB_insert into @co, @mth, @batchid,  @jcco, @inco, @msglco
    if @@fetch_status = 0 goto insert_HQCC_check
    
    close bMSLB_insert
    deallocate bMSLB_insert
    set @opencursor = 0
    end
    
    
return
    
    
    error:
       select @errmsg = @errmsg + ' - cannot insert MS Haul Line Batch'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
    
   
   
   
  
 




GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE   trigger [dbo].[btMSLBu] on [dbo].[bMSLB] for UPDATE as
   

/*-----------------------------------------------------------------
    * Created:  GG 11/08/00
    * Modified: GG 06/18/01 - added BatchTransType validation and allow MSTrans update on new entries
    *			 GF 10/09/2002 - changed dbl quotes to single quotes
    *			 GF 12/03/2003 - issue #23147 changes for ansi nulls
    *
    * Cannot change Company, Mth, BatchId, Seq, Haul Line
    *
    * Add HQCC (Close Control) as needed.
    *
    *----------------------------------------------------------------*/
   
   declare @numrows int, @validcount int, @co bCompany, @mth bMonth, @batchid bBatchID,
       @seq int, @errmsg varchar(255), @opencursor tinyint, @jcco bCompany, @inco bCompany,
       @msglco bCompany, @glco bCompany
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   set @opencursor = 0
   
   -- check for key changes
   select @validcount = count(*)
   from deleted d join inserted i on d.Co = i.Co and d.Mth = i.Mth and d.BatchId = i.BatchId
       and d.BatchSeq = i.BatchSeq and d.HaulLine = i.HaulLine
   if @numrows <> @validcount
   	begin
   	select @errmsg = 'Cannot change Company, Month, Batch ID #, Sequence #, or Haul Line #'
   	goto error
   	end
   -- check Batch Transaction Type
   select @validcount = count(*) from inserted i where i.BatchTransType in ('A','C','D')
   if @validcount <> @numrows
    	begin
    	select @errmsg = 'Batch Transaction Type must be (A, C, or D)'
    	goto error
    	end
   -- check for change
   select @validcount = count(*) from deleted d, inserted i
   where d.Co = i.Co and d.Mth = i.Mth and d.BatchId = i.BatchId and d.BatchSeq = i.BatchSeq
       and (d.BatchTransType = 'A' and i.BatchTransType in ('C','D'))
   if @validcount > 0
       begin
       select @errmsg = 'Cannot change Batch Transaction Type from (A to C or D)'
       goto error
       end
   select @validcount = count(*) from deleted d, inserted i
   where d.Co = i.Co and d.Mth = i.Mth and d.BatchId = i.BatchId and d.BatchSeq = i.BatchSeq
       and (i.BatchTransType = 'A' and d.BatchTransType in ('C','D'))
   if @validcount > 0
    	begin
    	select @errmsg = 'Cannot change Batch Transaction Type from (C or D to A)'
    	goto error
    	end
   -- check MS Transaction
   select @validcount = count(*) from deleted d, inserted i
   where d.Co = i.Co and d.Mth = i.Mth and d.BatchId = i.BatchId and d.BatchSeq = i.BatchSeq
       and i.BatchTransType in ('C','D') and ((i.MSTrans <> d.MSTrans) or i.MSTrans is null or d.MSTrans is null)
   if @validcount > 0
       begin
       select @errmsg = 'Cannot change MS Transaction # on (C or D) entries'
       goto error
       end
   
   -- update entries to HQ Close Control
   if @numrows = 1
       select @co = i.Co, @mth = i.Mth, @batchid = i.BatchId, @jcco = JCCo, @inco=INCo, @msglco = c.GLCo
       from inserted i join bMSCO c on i.Co = c.MSCo
   else
       begin
   	-- use a cursor to process each updated row
   	declare bMSLB_update cursor LOCAL FAST_FORWARD
   	for select distinct i.Co, i.Mth, i.BatchId, i.JCCo, i.INCo, c.GLCo
   	from inserted i join bMSCO c on i.Co = c.MSCo
   
   	open bMSLB_update
       	set @opencursor = 1
   
   	fetch next from bMSLB_update into @co, @mth, @batchid, @jcco, @inco, @msglco
   	if @@fetch_status <> 0
           begin
   		select @errmsg = 'Cursor error'
   		goto error
   		end
   	end
   
   insert_HQCC_check:
   -- add entry to HQ Close Control for MS Company GLCo
   if not exists(select top 1 1 from bHQCC where Co = @co and Mth = @mth and BatchId = @batchid and GLCo = @msglco)
   	begin
   	insert bHQCC (Co, Mth, BatchId, GLCo)
   	values (@co, @mth, @batchid, @msglco)
   	end
   
   -- get GL Company for Job sales
   if @jcco is not null
   	begin
   	select @glco = GLCo from bJCCO where JCCo = @jcco
   	if @@rowcount <> 0
   		begin
   		-- add entry to HQ Close Control for Job Sale
   		if not exists(select top 1 1 from bHQCC where Co = @co and Mth = @mth and BatchId = @batchid and GLCo = @glco)
   			begin
   			insert bHQCC (Co, Mth, BatchId, GLCo)
   			values (@co, @mth, @batchid, @glco)
   			end
   		end
   	end
   
   -- get GL Company for Inventory sales
   if @inco is not null
   	begin
   	select @glco = GLCo from bINCO where INCo = @inco
   	if @@rowcount <> 0
   		begin
   		-- add entry to HQ Close Control for Inventory Sale
   		if not exists(select top 1 1 from bHQCC where Co = @co and Mth = @mth and BatchId = @batchid and GLCo = @glco)
   			begin
   			insert bHQCC (Co, Mth, BatchId, GLCo)
   			values (@co, @mth, @batchid, @glco)
   			end
   		end
   	end
   
   
   if @numrows > 1
       begin
       fetch next from bMSLB_update into @co, @mth, @batchid, @jcco, @inco, @msglco
       if @@fetch_status = 0 goto insert_HQCC_check
   
   	close bMSLB_update
   	deallocate bMSLB_update
   	set @opencursor = 0
   	end
   
   
   
   return
   
   
   
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot update MS Haul Line Batch!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biMSLB] ON [dbo].[bMSLB] ([Co], [Mth], [BatchId], [BatchSeq], [HaulLine]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bMSLB].[Hold]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bMSLB].[OldHold]'
GO
