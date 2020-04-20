CREATE TABLE [dbo].[bHRBB]
(
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[BatchSeq] [int] NOT NULL,
[HRRef] [dbo].[bHRRef] NULL,
[PRCo] [dbo].[bCompany] NULL,
[Employee] [dbo].[bEmployee] NULL,
[BenefitCode] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[BenefitSalaryFlag] [char] (1) COLLATE Latin1_General_BIN NULL,
[EffectiveDate] [dbo].[bDate] NULL,
[SalaryRateFlag] [char] (1) COLLATE Latin1_General_BIN NULL,
[SalaryAmt] [dbo].[bUnitCost] NULL,
[BatchTransType] [char] (1) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   
   /****** Object:  Trigger dbo.btHRBBd    Script Date: 2/3/2003 8:48:29 AM ******/
   /****** Object:  Trigger dbo.btHRBBd    Script Date: 8/28/99 9:37:37 AM ******/
   CREATE     trigger [dbo].[btHRBBd] on [dbo].[bHRBB] for DELETE as
   

/*-----------------------------------------------------------------
    *  Created: kb 7/27/99
    *  Modified by:  ae 10/2/99
    *                ae 1/16/00
    *					mh 6/6/03 Issue 21453.  See below
   		mh 8/9/2004 issue 25322
    *
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @validcnt int, @numrows int, @hrref bHRRef,
       @effectivedate bDate, @co bCompany, @mth bMonth, @batchid bBatchID,
       @batchseq int, @rcode int
   
   
   SELECT @numrows = @@rowcount
   
   IF @numrows = 0 return
   
   set nocount on
   
   select @co = min(Co) from deleted d
   while @co is not null
       begin
       select @mth = min(Mth) from deleted d where Co = @co
       while @mth is not null
           begin
           select @batchid = min(BatchId) from deleted d where Co = @co and Mth = @mth
           while @batchid is not null
               begin
   
   	    select @batchseq = min(BatchSeq) from deleted d where Co = @co and Mth = @mth
                 and BatchId = @batchid and BenefitSalaryFlag='S'
               while @batchseq is not null
                   begin
                   select @hrref = HRRef, @effectivedate = EffectiveDate from deleted d
                     where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq
                   update bHRSH set InUseBatchId = null, InUseMth = null
                     where HRCo = @co and HRRef = @hrref and EffectiveDate <= @effectivedate
   
                     select @batchseq = min(BatchSeq) from deleted d where Co = @co and
                     Mth = @mth and BatchId = @batchid and BatchSeq > @batchseq and BenefitSalaryFlag='S'
                   if @@rowcount = 0 select @batchseq = null
                   end
   
   	    select @batchseq = min(BatchSeq) from deleted d where Co = @co and Mth = @mth
                 and BatchId = @batchid and BenefitSalaryFlag='B'
               while @batchseq is not null
                   begin
   
   				/*Issue 21453:  The update needs to restrict by benefit code.  Should also include DependentSeq = 0
   				since entries into HRBB, BenefitSalaryFlag = 'B' are restricted to DependentSeq = 0
   
                   select @hrref = HRRef, @effectivedate = EffectiveDate from deleted d
                   where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq
   
                   update bHREB set InUseBatchId = null, InUseMth = null
                     where HRCo = @co and HRRef = @hrref and BenefitCode = @benefitcode and EffectDate <= @effectivedate
   				*/
   --issue 25322  When deleting a benefit and clearing out the InUseBatchID and InUseMth in
   --HREB we do not want to create an Employement History record.  Setting "UpdatedYN" and "HistSeq" to 
   --itself to keep the the HREB update trigger from writing the history record.  MH
   				--update bHREB set InUseBatchId = null, InUseMth = null
   				update bHREB set InUseBatchId = null, InUseMth = null, UpdatedYN = b.UpdatedYN, HistSeq = b.HistSeq
   				from deleted d
   				join bHREB b on d.Co = b.HRCo and b.HRRef = d.HRRef and b.BenefitCode = d.BenefitCode
   				where d.BatchSeq = @batchseq and b.DependentSeq = 0
   
                     select @batchseq = min(BatchSeq) from deleted d where Co = @co and
                     Mth = @mth and BatchId = @batchid and BatchSeq > @batchseq and BenefitSalaryFlag='B'
                   if @@rowcount = 0 select @batchseq = null
                   end
   
              select @batchid = min(BatchId) from deleted d where Co = @co and Mth = @mth
               and BatchId > @batchid
              if @@rowcount = 0 select @batchid = null
              end
          select @mth = min(Mth) from deleted d where Co = @co and Mth > @mth
          if @@rowcount = 0 select @mth = null
  
          end
      select @co = min(Co) from deleted d where Co > @co
      if @@rowcount = 0 select @co = null
      end
   
   return
   error:
       SELECT @errmsg = @errmsg +  ' - cannot delete HR Update Batch!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btHRBBi    Script Date: 2/3/2003 8:46:18 AM ******/
   /****** Object:  Trigger dbo.btHRBBi    Script Date: 8/28/99 9:37:37 AM ******/
    CREATE   trigger [dbo].[btHRBBi] on [dbo].[bHRBB] for INSERT as
    

/*-----------------------------------------------------------------
     *  Created: kb 7/27/99
     *  Modified by: ae 10/2/99
     *               ae 02/16/00
     *
     *
     *
     */----------------------------------------------------------------
    declare @errmsg varchar(255), @validcnt int, @numrows int, @hrref bHRRef,
        @effectivedate bDate, @co bCompany, @mth bMonth, @batchid bBatchID,
        @batchseq int, @benefitcode varchar(10), @rcode int
   
   
    SELECT @numrows = @@rowcount
   
    IF @numrows = 0 return
   
    set nocount on
   
    select @co = min(Co) from inserted i
    while @co is not null
        begin
          select @mth = min(Mth) from inserted i where Co = @co
           while @mth is not null
            begin
              select @batchid = min(BatchId) from inserted i where Co = @co and Mth = @mth
              while @batchid is not null
                 begin
                  select @batchseq = min(BatchSeq) from inserted i where Co = @co and Mth = @mth
                    and BatchId = @batchid and BenefitSalaryFlag='S'
                  while @batchseq is not null
                   begin
                   select @hrref = HRRef, @effectivedate = EffectiveDate from inserted i
                     where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq
                   update bHRSH set InUseBatchId = @batchid, InUseMth = @mth
                     where HRCo = @co and HRRef = @hrref and EffectiveDate <= @effectivedate
                   if @@rowcount = 0
                      begin
                      select @errmsg = 'Unable to flag Salary History as (In Use).', @rcode = 1
                      goto error
                      end
                    select @batchseq = min(BatchSeq) from inserted i where Co = @co and
                     Mth = @mth and BatchId = @batchid and BatchSeq > @batchseq and BenefitSalaryFlag='S'
                   if @@rowcount = 0 select @batchseq = null
                   end
    --------------
                  select @batchseq = min(BatchSeq) from inserted i where Co = @co and Mth = @mth
                    and BatchId = @batchid and BenefitSalaryFlag='B'
                  while @batchseq is not null
                    begin
   
                    select @hrref = HRRef, @effectivedate = EffectiveDate from inserted i
                      where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq
   
                   select @benefitcode = BenefitCode from inserted i where Co = @co and Mth = @mth
                       and BatchId = @batchid and BatchSeq = @batchseq and HRRef = @hrref and BenefitSalaryFlag = 'B'
   
                    update bHREB set InUseBatchId = @batchid, InUseMth = @mth
                      where HRCo = @co and HRRef = @hrref and BenefitCode = @benefitcode
                         and DependentSeq = 0 and EffectDate <= @effectivedate
   
                    if @@rowcount = 0
                       begin
                       select @errmsg = 'Unable to flag Benefit as (In Use).', @rcode = 1
                       goto error
                       end
                     select @batchseq = min(BatchSeq) from inserted i where Co = @co and
                      Mth = @mth and BatchId = @batchid and BatchSeq > @batchseq and BenefitSalaryFlag='B'
                    if @@rowcount = 0 select @batchseq = null
                    end
   
               select @batchid = min(BatchId) from inserted i where Co = @co and Mth = @mth
                and BatchId > @batchid
               if @@rowcount = 0 select @batchid = null
               end
           select @mth = min(Mth) from inserted i where Co = @co and Mth > @mth
           if @@rowcount = 0 select @mth = null
           end
       select @co = min(Co) from inserted i where Co > @co
       if @@rowcount = 0 select @co = null
       end
   
    return
    error:
        SELECT @errmsg = @errmsg +  ' - cannot insert HR Update Batch!'
        RAISERROR(@errmsg, 11, -1);
        rollback transaction
   
   
   
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biHRBB] ON [dbo].[bHRBB] ([Co], [Mth], [BatchId], [BatchSeq]) ON [PRIMARY]
GO
