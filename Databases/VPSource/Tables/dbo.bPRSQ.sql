CREATE TABLE [dbo].[bPRSQ]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[PRGroup] [dbo].[bGroup] NOT NULL,
[PREndDate] [dbo].[bDate] NOT NULL,
[Employee] [dbo].[bEmployee] NOT NULL,
[PaySeq] [tinyint] NOT NULL,
[CMCo] [dbo].[bCompany] NOT NULL,
[CMAcct] [dbo].[bCMAcct] NOT NULL,
[PayMethod] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[CMRef] [dbo].[bCMRef] NULL,
[CMRefSeq] [tinyint] NULL,
[EFTSeq] [smallint] NULL,
[ChkType] [char] (1) COLLATE Latin1_General_BIN NULL,
[PaidDate] [dbo].[bDate] NULL,
[PaidMth] [dbo].[bMonth] NULL,
[Hours] [dbo].[bHrs] NOT NULL CONSTRAINT [DF_bPRSQ_Hours] DEFAULT ((0)),
[Earnings] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bPRSQ_Earnings] DEFAULT ((0)),
[Dedns] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bPRSQ_Dedns] DEFAULT ((0)),
[SUIEarnings] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bPRSQ_SUIEarnings] DEFAULT ((0)),
[PostToAll] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRSQ_PostToAll] DEFAULT ('N'),
[Processed] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRSQ_Processed] DEFAULT ('N'),
[CMInterface] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRSQ_CMInterface] DEFAULT ('N'),
[ChkSort] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[UniqueAttchID] [uniqueidentifier] NULL,
[udSource] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[udConv] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[udCGCTable] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[udCGCTableID] [decimal] (12, 0) NULL
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biPRSQ] ON [dbo].[bPRSQ] ([PRCo], [PRGroup], [PREndDate], [Employee], [PaySeq]) WITH (FILLFACTOR=90) ON [PRIMARY]

ALTER TABLE [dbo].[bPRSQ] ADD CONSTRAINT [PK_bPRSQ] PRIMARY KEY NONCLUSTERED  ([KeyID]) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [biPRSQEFT] ON [dbo].[bPRSQ] ([CMCo], [CMAcct], [PayMethod], [CMRef], [EFTSeq]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_bPRSQ_PaidDate] ON [dbo].[bPRSQ] ([PaidDate], [PRCo]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [biPRSQNoGroup] ON [dbo].[bPRSQ] ([PRCo], [PREndDate], [Employee], [CMCo], [CMAcct], [CMRef]) WITH (FILLFACTOR=90) ON [PRIMARY]

ALTER TABLE [dbo].[bPRSQ] ADD
CONSTRAINT [CK_bPRSQ_PostToAll] CHECK (([PostToAll]='Y' OR [PostToAll]='N'))
ALTER TABLE [dbo].[bPRSQ] ADD
CONSTRAINT [CK_bPRSQ_Processed] CHECK (([Processed]='Y' OR [Processed]='N'))
ALTER TABLE [dbo].[bPRSQ] ADD
CONSTRAINT [CK_bPRSQ_CMInterface] CHECK (([CMInterface]='Y' OR [CMInterface]='N'))
ALTER TABLE [dbo].[bPRSQ] ADD
CONSTRAINT [CK_bPRSQ_CMAcct] CHECK (([CMAcct]>(0) AND [CMAcct]<(10000)))










GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btPRSQd    Script Date: 8/28/99 9:38:13 AM ******/
   CREATE   trigger [dbo].[btPRSQd] on [dbo].[bPRSQ] for DELETE as
   

/*--------------------------------------------------------------
    * Created: 12/29/98 GG
    * Modified:	EN 10/9/02 - issue 18877 change double quotes to single
    *				EN 02/19/03 - issue 23061  added isnull check, with (nolock), and dbo
    *
    * Delete trigger on PR Sequence Control - reject if related
    * detail exists.
    *
    *--------------------------------------------------------------*/
   declare @numrows int, @errmsg varchar(255)
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   -- check for Timecards
   if exists(select * from dbo.bPRTH h with (nolock)
   		join deleted d on d.PRCo = h.PRCo and d.PRGroup = h.PRGroup and d.PREndDate = h.PREndDate
   			and d.Employee = h.Employee and d.PaySeq = h.PaySeq)
   	begin
   	select @errmsg = 'Timecard detail exists.'
   	goto error
   	end
   -- check for Detail
   if exists(select * from dbo.bPRDT t with (nolock)
   		join deleted d on d.PRCo = t.PRCo and d.PRGroup = t.PRGroup and d.PREndDate = t.PREndDate
   			and d.Employee = t.Employee and d.PaySeq = t.PaySeq)
   	begin
   	select @errmsg = 'Earnings, deduction, and/or liability totals exist.'
   	goto error
   	end
   -- check for GL Distributions
   if exists(select * from dbo.bPRGL g with (nolock)
   		join deleted d on d.PRCo = g.PRCo and d.PRGroup = g.PRGroup and d.PREndDate = g.PREndDate
   			and d.Employee = g.Employee and d.PaySeq = g.PaySeq)
   	begin
   	select @errmsg = 'GL distributions already exist.'
   	goto error
   	end
   -- check for JC Distributions
   if exists(select * from dbo.bPRJC j with (nolock)
   		join deleted d on d.PRCo = j.PRCo and d.PRGroup = j.PRGroup and d.PREndDate = j.PREndDate
   			and d.Employee = j.Employee and d.PaySeq = j.PaySeq)
   	begin
   	select @errmsg = 'JC distributions already exist.'
   	goto error
   	end
   -- check for EM Distributions
   if exists(select * from dbo.bPREM e with (nolock)
   		join deleted d on d.PRCo = e.PRCo and d.PRGroup = e.PRGroup and d.PREndDate = e.PREndDate
   			and d.Employee = e.Employee and d.PaySeq = e.PaySeq)
   	begin
   	select @errmsg = 'EM distributions already exist.'
   	goto error
   	end
   
   return
   
   error:
      select @errmsg = isnull(@errmsg,'') + ' - cannot delete Employee Sequence Control.'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   CREATE   trigger [dbo].[btPRSQi] on [dbo].[bPRSQ] for INSERT as
   

/*-----------------------------------------------------------------
    *  Created: GG 01/26/01
    *  Modified: GG 05/03/01 - fixed validation
    *				EN 10/9/02 - issue 18877 change double quotes to single
    *				EN 02/19/03 - issue 23061  added isnull check, with (nolock), and dbo
    *
    * Validates new PR Employee Sequence Control entries.
    *
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @validcnt int, @cnt int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   -- validate PR Pay Period Sequence
   select @validcnt = count(*) from inserted i
   join dbo.bPRPS p with (nolock) on p.PRCo = i.PRCo and p.PRGroup = i.PRGroup and p.PREndDate = i.PREndDate
       and p.PaySeq = i.PaySeq
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Missing PR Pay Period Sequence Control entry'
   	goto error
   	end
   -- validate CM Company and Account
   select @validcnt = count(*) from inserted i
   join dbo.bCMAC c with (nolock) on c.CMCo = i.CMCo and c.CMAcct = i.CMAcct
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid CM Company and Account'
   	goto error
   	end
   -- validate Payment Method
   if exists(select * from inserted where PayMethod not in ('C','E','X'))
       begin
       select @errmsg = 'Invalid Payment Method, must be ''C'',''E'', or ''X'''
       goto error
       end
   -- validate Check Type
   if exists(select * from inserted where PayMethod = 'C' and ChkType not in ('C','M'))
       begin
       select @errmsg = 'Invalid Check Type, must be ''C'' or ''M'' when Payment Method is check.'
       goto error
       end
   if exists(select * from inserted where PayMethod <> 'C' and ChkType is not null)
       begin
       select @errmsg = 'Invalid Check Type, must be null if Payment Method is ''E'' or ''X'''
       goto error
       end
   -- validate Paid Date and Month
   if exists(select * from inserted where (PayMethod = 'X' or CMRef is not null)
       and (PaidDate is null or PaidMth is null))
       begin
       select @errmsg = 'Paid Date and Month are required when PayMethod is ''X'' or CM Reference has been assigned'
       goto error
       end
   if exists(select * from inserted where (PayMethod <> 'X' and CMRef is null)
       and (PaidDate is not null or PaidMth is not null))
       begin
       select @errmsg = 'Paid Date and Month must be null until payment is processed'
       goto error
       end
   
   return
   
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot insert PR Employee Sequence Control! - (bPRSQ)'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
  
  
  
  
  
  
  
  
  
  
  
  
  CREATE     trigger [dbo].[btPRSQu] on [dbo].[bPRSQ] for UPDATE as
   

/*-----------------------------------------------------------------
    *  Created: GG 01/26/01
    *  Modified: RM 04/12/01 - Changed check for changes per issue # 12976
    *				GG 10/01/01 - #13339 - added update of Processed flag if PayMethod changed
    *				GG 04/24/02 - #16988 - reset Processed flag in open Pay Pd only
    *				GG 05/23/02 - #17468 - corrected check for index change
    *				EN 02/19/03 - issue 23061  added isnull check, with (nolock), and dbo
	*				EN 2/20/09 #127159  create HQMA entry whenever a paid date is nulled ... this is not optional
    *
    * Validates changes to PR Employee Sequence Control entries.
    *
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @validcnt int, @cnt int, @opencursor tinyint

   -- PRSQ declares
   declare @prco bCompany, @prgroup bGroup, @prenddate bDate, @employee bEmployee, @payseq tinyint, 
     @oldpaiddate bDate, @newpaiddate bDate

   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   -- check for index changes
   select @validcnt = count(*) from deleted d
   join inserted i on d.PRCo = i.PRCo and d.PRGroup = i.PRGroup and d.PREndDate = i.PREndDate
       and d.Employee = i.Employee and d.PaySeq = i.PaySeq
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Cannot change PR Co#, PR Group, PR End Date, or Employee.'
   	goto error
   	end 
   
   -- validate CM Company and Account
   select @validcnt = count(*) from inserted i
   join dbo.bCMAC c with (nolock) on c.CMCo = i.CMCo and c.CMAcct = i.CMAcct
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid CM Company and Account.'
   	goto error
   	end
   -- validate Payment Method
   if exists(select * from inserted where PayMethod not in ('C','E','X'))
       begin
       select @errmsg = 'Invalid Payment Method, must be ''C'',''E'', or ''X''.'
       goto error
       end
   -- validate Check Type
   if exists(select * from inserted where PayMethod = 'C' and ChkType not in ('C','M'))
       begin
       select @errmsg = 'Invalid Check Type, must be ''C'' or ''M'' when Payment Method is check.'
       goto error
       end
   if exists(select * from inserted where PayMethod <> 'C' and ChkType is not null)
       begin
       select @errmsg = 'Invalid Check Type, must be null if Payment Method is ''E'' or ''X''.'
       goto error
       end
   -- validate Paid Date and Month
   if exists(select * from inserted where (PayMethod = 'X' or CMRef is not null)
       and (PaidDate is null or PaidMth is null))
       begin
       select @errmsg = 'Paid Date and Month are required when PayMethod is ''X'' or CM Reference has been assigned.'
       goto error
       end
   if exists(select * from inserted where (PayMethod <> 'X' and CMRef is null)
       and (PaidDate is not null or PaidMth is not null))
       begin
       select @errmsg = 'Paid Date and Month must be null until payment is processed.'
       goto error
       end
   
   -- reset Processed flag if Payment Method is changed
   update dbo.bPRSQ set Processed = 'N'
   from inserted i
   join dbo.bPRSQ s on s.PRCo = i.PRCo and s.PRGroup = i.PRGroup and s.PREndDate = i.PREndDate
       and s.Employee = i.Employee and s.PaySeq = i.PaySeq
   join deleted d on d.PRCo = i.PRCo and d.PRGroup = i.PRGroup and d.PREndDate = i.PREndDate
       and d.Employee = i.Employee and d.PaySeq = i.PaySeq
   join dbo.bPRPC p on i.PRCo = p.PRCo and i.PRGroup = p.PRGroup and i.PREndDate = p.PREndDate
   where d.PayMethod <> i.PayMethod and p.Status = 0	-- Pay Pd must be open
   
   -- remove Direct Deposit distributions if PayMethod not EFT
   delete dbo.bPRDS
   from inserted i
   join dbo.bPRDS d on d.PRCo = i.PRCo and d.PRGroup = i.PRGroup and d.PREndDate = i.PREndDate
       and d.Employee = i.Employee and d.PaySeq = i.PaySeq
   where i.PayMethod <> 'E' and i.CMRef is null
   
   -- #127159 use a psuedo cursor to locate each case where the paid date is being cleared
   -- and create an HQMA entry in those cases
   if update(PaidDate)
	begin
	   if exists(select top 1 1 from inserted i where i.PaidDate is null)
		begin
		declare bHQMA_insert cursor local fast_forward for
		select i.PRCo, i.PRGroup, i.PREndDate, i.Employee, 
			i.PaySeq, d.PaidDate, i.PaidDate 
		from inserted i
		join deleted d on d.PRCo = i.PRCo and d.PRGroup = i.PRGroup and d.PREndDate = i.PREndDate
		   and d.Employee = i.Employee and d.PaySeq = i.PaySeq
		where d.PaidDate is not null and i.PaidDate is null

		open bHQMA_insert
		select @opencursor = 1  -- open cursor flag

		fetch next from bHQMA_insert into @prco, @prgroup, @prenddate, @employee, @payseq, @oldpaiddate, @newpaiddate
		if @@fetch_status <> 0
			begin
			select @errmsg = 'Cursor error'
			goto error
			end

		insert_HQMA:
   		insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		values ('bPRSQ', 'PR Co#: ' + convert(varchar,@prco) + ' PRGroup: ' + convert(varchar,@prgroup) 
			+ ' PR Ending Date: ' + convert(varchar,@prenddate,101) + ' Employee: ' + convert(varchar,@employee) 
			+ ' Pay Seq: ' + convert(varchar,@payseq), @prco, 'C', 'PaidDate', convert(varchar,@oldpaiddate,101), 
			convert(varchar,@newpaiddate,101), getdate(), SUSER_SNAME())

		if @opencursor = 1
			begin
			fetch next from bHQMA_insert into @prco, @prgroup, @prenddate, @employee, @payseq, @oldpaiddate, @newpaiddate
			if @@fetch_status = 0
				goto insert_HQMA
			else
				begin
				close bHQMA_insert
				deallocate bHQMA_insert
				select @opencursor = 0
				end
			end
		end
	end
   return
   
   error:
    if @opencursor = 1
     begin
     close bHQMA_insert
     deallocate bHQMA_insert
     end

   	select @errmsg = isnull(@errmsg,'') + ' - cannot update PR Employee Sequence Control! - (bPRSQ)'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
   
   
   
   
   
   
   
   
  
  
 



GO

EXEC sp_bindrule N'[dbo].[brCMAcct]', N'[dbo].[bPRSQ].[CMAcct]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPRSQ].[Hours]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPRSQ].[Earnings]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPRSQ].[Dedns]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPRSQ].[SUIEarnings]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPRSQ].[PostToAll]'
GO
EXEC sp_bindefault N'[dbo].[bdNo]', N'[dbo].[bPRSQ].[PostToAll]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPRSQ].[Processed]'
GO
EXEC sp_bindefault N'[dbo].[bdNo]', N'[dbo].[bPRSQ].[Processed]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPRSQ].[CMInterface]'
GO
EXEC sp_bindefault N'[dbo].[bdNo]', N'[dbo].[bPRSQ].[CMInterface]'
GO
