CREATE TABLE [dbo].[bPRDT]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[PRGroup] [dbo].[bGroup] NOT NULL,
[PREndDate] [dbo].[bDate] NOT NULL,
[Employee] [dbo].[bEmployee] NOT NULL,
[PaySeq] [tinyint] NOT NULL,
[EDLType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[EDLCode] [dbo].[bEDLCode] NOT NULL,
[Hours] [dbo].[bHrs] NOT NULL,
[Amount] [dbo].[bDollar] NOT NULL,
[SubjectAmt] [dbo].[bDollar] NOT NULL,
[EligibleAmt] [dbo].[bDollar] NOT NULL,
[UseOver] [dbo].[bYN] NOT NULL,
[OverAmt] [dbo].[bDollar] NOT NULL,
[OverProcess] [dbo].[bYN] NOT NULL,
[VendorGroup] [dbo].[bGroup] NULL,
[Vendor] [dbo].[bVendor] NULL,
[APDesc] [dbo].[bDesc] NULL,
[OldHours] [dbo].[bHrs] NOT NULL,
[OldAmt] [dbo].[bDollar] NOT NULL,
[OldSubject] [dbo].[bDollar] NOT NULL,
[OldEligible] [dbo].[bDollar] NOT NULL,
[OldMth] [dbo].[bMonth] NULL,
[OldVendor] [dbo].[bVendor] NULL,
[OldAPMth] [dbo].[bMonth] NULL,
[OldAPAmt] [dbo].[bDollar] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[PaybackAmt] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bPRDT_PaybackAmt] DEFAULT ((0)),
[PaybackOverAmt] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bPRDT_PaybackOverAmt] DEFAULT ((0)),
[PaybackOverYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRDT_PaybackOverYN] DEFAULT ('N'),
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[udPaidDate] [smalldatetime] NULL,
[udSource] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[udConv] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[udCMCo] [tinyint] NULL,
[udCMAcct] [int] NULL,
[udCMRef] [varchar] (15) COLLATE Latin1_General_BIN NULL,
[udCGCTable] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[udCGCTableID] [decimal] (12, 0) NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   CREATE   trigger [dbo].[btPRDTd] on [dbo].[bPRDT] for DELETE as
   

/*-----------------------------------------------------------------
   *  Created: GG 08/12/02
   *  Modified:	EN 02/12/03 - issue 23061  added isnull check, with (nolock), and dbo
   *
   *  Delete trigger for PR Pay Period Detail (bPRDT)
   *
   */----------------------------------------------------------------
    declare @errmsg varchar(255), @numrows int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   -- prevent removal if Pay Period is 'open' and interfaced values exist
   if exists(select 1 from dbo.bPRPC p with (nolock)
   			join deleted d on p.PRCo = d.PRCo and p.PRGroup = d.PRGroup	and p.PREndDate = d.PREndDate
   			where p.Status = 0 and (d.OldHours <> 0.00 or d.OldAmt <> 0.00 or d.OldSubject <> 0.00
   				or d.OldEligible <> 0.00 or d.OldAPAmt <> 0.00))
    	begin
    	select @errmsg = 'Previously interfaced amounts exist'
    	goto error
    	end
   
   return
   
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot delete PR Pay Period Detail (PRDT)!'
        RAISERROR(@errmsg, 11, -1);
        rollback transaction
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
   /****** Object:  Trigger dbo.btPRDTi    Script Date: 8/28/99 9:38:11 AM ******/
   CREATE   trigger [dbo].[btPRDTi] on [dbo].[bPRDT] for INSERT as
   
/*-----------------------------------------------------------------
    *  Created: GG 08/01/98
    *  Modified: GG 08/01/98
    *            GG 01/10/00 - Added consistency check for old values
    *				EN 10/9/02 - issue 18877 change double quotes to single
    *			DAN SO 08/10/12 - TK-16692 - Update PRSQ.Processed when new field, PaybackYN, is 'Y'
    *
    * Validates new PR Pay Sequence Total entries.  Updates 'Processed'
    * flag in PR Sequence Control if using an Override Amount.
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @validcnt int, @cnt int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   -- validate PR Sequence Control
   select @validcnt = count(*) from inserted i
   join bPRSQ s on s.PRCo = i.PRCo and s.PRGroup = i.PRGroup and s.PREndDate = i.PREndDate
       and s.Employee = i.Employee and s.PaySeq = i.PaySeq
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Missing PR Sequence Control entry'
   	goto error
   	end
   
   -- validate EDL Type
   select @validcnt = count(*) from inserted
       where EDLType in ('E','D','L')
   if @validcnt <> @numrows
       begin
   	select @errmsg = 'Invalid Type.  Must be ''E'',''D'', or ''L'''
   	goto error
   	end
   
   -- validate Earnings Codes
   select @cnt = count(*) from inserted where EDLType = 'E'
   select @validcnt = count(*) from inserted i
   join dbo.bPREC e with (nolock) on e.PRCo = i.PRCo and e.EarnCode = i.EDLCode
   where i.EDLType = 'E'
   if @validcnt <> @cnt
       begin
   	select @errmsg = 'Invalid Earnings code'
   	goto error
   	end
   
   -- validate Dedn/Liab Codes
   select @cnt = count(*) from inserted where EDLType in ('D','L')
   select @validcnt = count(*) from inserted i
   join dbo.bPRDL d with (nolock) on d.PRCo = i.PRCo and d.DLCode = i.EDLCode
   where i.EDLType in ('D','L')
   if @validcnt <> @cnt
       begin
   	select @errmsg = 'Invalid Deduction/Liability code'
   	goto error
   	end
   
   -- check for old info consistency
   if exists(select * from inserted
       where OldMth is null and (OldHours <> 0 or OldAmt <> 0 or OldSubject <> 0 or OldEligible <> 0))
       begin
       select @errmsg = 'Previously updated Month for accumulations is null, but amounts are not'
       goto error
       end
   if exists(select * from inserted
       where OldAPMth is null and (OldVendor is not null or OldAPAmt <> 0))
       begin
       select @errmsg = 'Previously updated Month for AP expense is null, but amounts are not'
       goto error
       end
   
   -- reset Processed flag in PR Sequence Control if new entry using an Override
   update dbo.bPRSQ set Processed = 'N'
   from inserted i
   join dbo.bPRSQ on bPRSQ.PRCo = i.PRCo and bPRSQ.PRGroup = i.PRGroup and bPRSQ.PREndDate = i.PREndDate
       and bPRSQ.Employee = i.Employee and bPRSQ.PaySeq = i.PaySeq
   where i.UseOver = 'Y'
      OR i.PaybackOverYN = 'Y'	-- TK-16692 --
   
   return
   
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot insert PR Pay Sequence Total! - (bPRDT)'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
   
   /****** Object:  Trigger dbo.btPRDTu    Script Date: 8/28/99 9:38:11 AM ******/
   CREATE    trigger [dbo].[btPRDTu] on [dbo].[bPRDT] for UPDATE as
   
/*-----------------------------------------------------------------
    *  Created: GG 08/01/98
    *  Modified: GG 08/01/98
    *              GG 01/10/00 - Added check for old amount consistency
    *		EN 10/9/02 - issue 18877 change double quotes to single
    *		EN 02/12/03 - issue 23061  added isnull check, with dbo
    *		JE 10/08/04 - issue 25735  performance enhancements
    *		DAN SO 08/10/12 - TK-16692 - Update PRSQ.Processed when new field, PaybackYN, is 'Y'
    *
    * Validates changes to PR Pay Sequence Total entries.  Updates 'Processed'
    * flag in PR Sequence Control if UseOver or Override Amount changes.
    */----------------------------------------------------------------
   
   declare @errmsg varchar(255), @numrows int, @validcnt int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   -- check for index changes
   if update(PRCo) or update(PRGroup) or update(PREndDate) or update(Employee) --issue 25735
      or update(PaySeq) or update(EDLType) or update(EDLCode)
   begin
   	select @validcnt = count(*) from deleted d
   	join inserted i on d.PRCo = i.PRCo and d.PRGroup = i.PRGroup and d.PREndDate = i.PREndDate
   	    and d.Employee = i.Employee and d.PaySeq = i.PaySeq and d.EDLType = i.EDLType and d.EDLCode = i.EDLCode
   	if @validcnt <> @numrows
   		begin
   		select @errmsg = 'Cannot change PR Co#, PR Group, PR End Date, Employee, Pay Seq, Type, or Code'
   		goto error
   		end
   end
   
   -- check for old info consistency
   if exists(select top 1 1 from inserted   --issue 25735
       where OldMth is null and (OldHours <> 0 or OldAmt <> 0 or OldSubject <> 0 or OldEligible <> 0))
       begin
       select @errmsg = 'Previously updated Month for accumulations is null, but amounts are not'
       goto error
       end
   if exists(select top 1 1  from inserted  --issue 25735
       where OldAPMth is null and (OldVendor is not null or OldAPAmt <> 0))
       begin
       select @errmsg = 'Previously updated Month for AP expense is null, but amounts are not'
       goto error
       end
   
   -- reset Processed flag in PR Sequence Control if UseOver or OverAmt changes
   update dbo.bPRSQ set Processed = 'N'
   from inserted i
   join deleted d on d.PRCo = i.PRCo and d.PRGroup = i.PRGroup and d.PREndDate = i.PREndDate
       and d.Employee = i.Employee and d.PaySeq = i.PaySeq and d.EDLType = i.EDLType and d.EDLCode = i.EDLCode
   join dbo.bPRSQ on bPRSQ.PRCo = i.PRCo and bPRSQ.PRGroup = i.PRGroup and bPRSQ.PREndDate = i.PREndDate
       and bPRSQ.Employee = i.Employee and bPRSQ.PaySeq = i.PaySeq
   where isnull(Processed,'') <> 'N'  
	 and   --issue 25735 dont update if not necessary
   	     ((i.UseOver <> d.UseOver or i.OverAmt <> d.OverAmt)  -- override amt should only change if useover = 'Y'
   	  OR
   	      (i.PaybackOverYN <> d.PaybackOverYN or i.PaybackOverAmt <> d.PaybackOverAmt))  -- TK-16692 --
   
   return
   
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot update PR Pay Sequence Totals (bPRDT)!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
  
 



GO
CREATE NONCLUSTERED INDEX [biPRDTEmployee] ON [dbo].[bPRDT] ([Employee], [PRCo], [PRGroup]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_bPRDT_PrcoEmpEDLOldAmt_PrintCheck] ON [dbo].[bPRDT] ([PRCo], [Employee], [EDLType], [EDLCode], [OldMth], [PREndDate], [PaySeq]) INCLUDE ([OldAmt]) WITH (FILLFACTOR=80) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPRDT] ON [dbo].[bPRDT] ([PRCo], [PRGroup], [PREndDate], [Employee], [PaySeq], [EDLType], [EDLCode]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPRDT].[Hours]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPRDT].[Amount]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPRDT].[SubjectAmt]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPRDT].[EligibleAmt]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPRDT].[UseOver]'
GO
EXEC sp_bindefault N'[dbo].[bdNo]', N'[dbo].[bPRDT].[UseOver]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPRDT].[OverAmt]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPRDT].[OverProcess]'
GO
EXEC sp_bindefault N'[dbo].[bdNo]', N'[dbo].[bPRDT].[OverProcess]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPRDT].[OldHours]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPRDT].[OldAmt]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPRDT].[OldSubject]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPRDT].[OldEligible]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPRDT].[OldAPAmt]'
GO
