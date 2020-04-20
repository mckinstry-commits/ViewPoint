CREATE TABLE [dbo].[bPRPC]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[PRGroup] [dbo].[bGroup] NOT NULL,
[PREndDate] [dbo].[bDate] NOT NULL,
[BeginDate] [dbo].[bDate] NOT NULL,
[MultiMth] [dbo].[bYN] NOT NULL,
[BeginMth] [dbo].[bMonth] NOT NULL,
[EndMth] [dbo].[bMonth] NULL,
[CutoffDate] [dbo].[bDate] NULL,
[LimitMth] [dbo].[bMonth] NOT NULL,
[Hrs] [smallint] NOT NULL,
[Days] [tinyint] NOT NULL,
[Wks] [tinyint] NOT NULL,
[Status] [tinyint] NOT NULL,
[DateClosed] [smalldatetime] NULL,
[JCInterface] [dbo].[bYN] NOT NULL,
[EMInterface] [dbo].[bYN] NOT NULL,
[GLInterface] [dbo].[bYN] NOT NULL,
[APInterface] [dbo].[bYN] NOT NULL,
[LeaveProcess] [dbo].[bYN] NOT NULL,
[InUseBy] [dbo].[bVPUserName] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[Conv] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRPC_Conv] DEFAULT ('N'),
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[MaxRegHrsInWeek1] [tinyint] NOT NULL CONSTRAINT [DF_bPRPC_MaxRegHrsInWeek1] DEFAULT ((0)),
[MaxRegHrsInWeek2] [tinyint] NOT NULL CONSTRAINT [DF_bPRPC_MaxRegHrsInWeek2] DEFAULT ((0)),
[udSource] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[udConv] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[udCGCTable] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[udCGCTableID] [decimal] (12, 0) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biPRPC] ON [dbo].[bPRPC] ([PRCo], [PRGroup], [PREndDate]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPRPC] ([KeyID]) ON [PRIMARY]

ALTER TABLE [dbo].[bPRPC] ADD
CONSTRAINT [CK_bPRPC_APInterface] CHECK (([APInterface]='Y' OR [APInterface]='N'))
ALTER TABLE [dbo].[bPRPC] ADD
CONSTRAINT [CK_bPRPC_Conv] CHECK (([Conv]='Y' OR [Conv]='N'))
ALTER TABLE [dbo].[bPRPC] ADD
CONSTRAINT [CK_bPRPC_EMInterface] CHECK (([EMInterface]='Y' OR [EMInterface]='N'))
ALTER TABLE [dbo].[bPRPC] ADD
CONSTRAINT [CK_bPRPC_GLInterface] CHECK (([GLInterface]='Y' OR [GLInterface]='N'))
ALTER TABLE [dbo].[bPRPC] ADD
CONSTRAINT [CK_bPRPC_JCInterface] CHECK (([JCInterface]='Y' OR [JCInterface]='N'))
ALTER TABLE [dbo].[bPRPC] ADD
CONSTRAINT [CK_bPRPC_LeaveProcess] CHECK (([LeaveProcess]='Y' OR [LeaveProcess]='N'))
ALTER TABLE [dbo].[bPRPC] ADD
CONSTRAINT [CK_bPRPC_MultiMth] CHECK (([MultiMth]='Y' OR [MultiMth]='N'))




GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btPRPCd    Script Date: 8/28/99 9:38:15 AM ******/
    CREATE   trigger [dbo].[btPRPCd] on [dbo].[bPRPC] for DELETE as
    

/*-----------------------------------------------------------------
     *  Created: EN 8/1/00
     *  Modified:	EN 02/18/03 - issue 23061  added isnull check, with (nolock), and dbo
     *											and corrected old syle joins
     *
     *  This trigger restricts deletion of any PRPC records if
     *  lines exist in PRAF, PRHD, PRPS, PRSQ, PRCA, PRCX, PRIA, PRDT,
     *  PRDS, PRVP, PRTH, PRTA, PRTL, PRAP, PRGL, PRJC, PREM, or PRER.
     */----------------------------------------------------------------
    declare @errmsg varchar(255), @numrows int, @validcnt int
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
   
   
    if exists(select * from dbo.bPRAF a with (nolock) join deleted d on a.PRCo = d.PRCo and a.PRGroup = d.PRGroup
    		and a.PREndDate = d.PREndDate)
    	begin
    	select @errmsg='Active frequency codes exist for this Pay Period'
    	goto error
    	end
   
    if exists(select * from dbo.bPRHD a with (nolock) join deleted d on a.PRCo = d.PRCo and a.PRGroup = d.PRGroup
    		and a.PREndDate = d.PREndDate)
    	begin
    	select @errmsg='Holidays exist for this Pay Period'
    	goto error
    	end
   
    if exists(select * from dbo.bPRPS a with (nolock) join deleted d on a.PRCo = d.PRCo and a.PRGroup = d.PRGroup
    		and a.PREndDate = d.PREndDate)
    	begin
    	select @errmsg='Pay sequences exist for this Pay Period'
    	goto error
    	end
   
    if exists(select * from dbo.bPRSQ a with (nolock) join deleted d on a.PRCo = d.PRCo and a.PRGroup = d.PRGroup
    		and a.PREndDate = d.PREndDate)
    	begin
    	select @errmsg='Employee pay sequences exist for this Pay Period'
    	goto error
    	end
   
    if exists(select * from dbo.bPRCA a with (nolock) join deleted d on a.PRCo = d.PRCo and a.PRGroup = d.PRGroup
    		and a.PREndDate = d.PREndDate)
    	begin
    	select @errmsg='Craft accumulations exist for this Pay Period'
    	goto error
    	end
   
    if exists(select * from dbo.bPRCX a with (nolock) join deleted d on a.PRCo = d.PRCo and a.PRGroup = d.PRGroup
    		and a.PREndDate = d.PREndDate)
    	begin
    	select @errmsg='Craft accumulation rate details exist for this Pay Period'
    	goto error
    	end
   
    if exists(select * from dbo.bPRIA a with (nolock) join deleted d on a.PRCo = d.PRCo and a.PRGroup = d.PRGroup
    		and a.PREndDate = d.PREndDate)
    	begin
    	select @errmsg='Insurance accumulations exist for this Pay Period.'
    	goto error
    	end
   
    if exists(select * from dbo.bPRDT a with (nolock) join deleted d on a.PRCo = d.PRCo and a.PRGroup = d.PRGroup
    		and a.PREndDate = d.PREndDate)
    	begin
    	select @errmsg='Pay sequence totals exist for this Pay Period'
    	goto error
    	end
   
    if exists(select * from dbo.bPRDS a with (nolock) join deleted d on a.PRCo = d.PRCo and a.PRGroup = d.PRGroup
    		and a.PREndDate = d.PREndDate)
    	begin
    	select @errmsg='Deposit sequences exist for this Pay Period'
    	goto error
    	end
   
    if exists(select * from dbo.bPRVP a with (nolock) join deleted d on a.PRCo = d.PRCo and a.PRGroup = d.PRGroup
    		and a.PREndDate = d.PREndDate)
    	begin
    	select @errmsg='Void payments exist for this Pay Period'
    	goto error
    	end
   
    if exists(select * from dbo.bPRTH a with (nolock) join deleted d on a.PRCo = d.PRCo and a.PRGroup = d.PRGroup
    		and a.PREndDate = d.PREndDate)
    	begin
    	select @errmsg='Timecard headers exist for this Pay Period'
    	goto error
    	end
   
    if exists(select * from dbo.bPRTA a with (nolock) join deleted d on a.PRCo = d.PRCo and a.PRGroup = d.PRGroup
    		and a.PREndDate = d.PREndDate)
    	begin
    	select @errmsg='Timecard addons exist for this Pay Period'
    	goto error
    	end
   
    if exists(select * from dbo.bPRTL a with (nolock) join deleted d on a.PRCo = d.PRCo and a.PRGroup = d.PRGroup
    		and a.PREndDate = d.PREndDate)
    	begin
    	select @errmsg='Liabilities exist for this Pay Period'
    	goto error
    	end
   
    if exists(select * from dbo.bPRAP a with (nolock) join deleted d on a.PRCo = d.PRCo and a.PRGroup = d.PRGroup
    		and a.PREndDate = d.PREndDate)
    	begin
    	select @errmsg='AP interface data exists for this Pay Period'
    	goto error
    	end
   
    if exists(select * from dbo.bPRGL a with (nolock) join deleted d on a.PRCo = d.PRCo and a.PRGroup = d.PRGroup
    		and a.PREndDate = d.PREndDate)
    	begin
    	select @errmsg='GL interface data exists for this Pay Period'
    	goto error
   	end
   
    if exists(select * from dbo.bPRJC a with (nolock) join deleted d on a.PRCo = d.PRCo and a.PRGroup = d.PRGroup
    		and a.PREndDate = d.PREndDate)
    	begin
    	select @errmsg='JC interface data exists for this Pay Period'
    	goto error
    	end
   
    if exists(select * from dbo.bPREM a with (nolock) join deleted d on a.PRCo = d.PRCo and a.PRGroup = d.PRGroup
    		and a.PREndDate = d.PREndDate)
    	begin
    	select @errmsg='EM cost distributions exist for this Pay Period'
    	goto error
    	end
   
    if exists(select * from dbo.bPRER a with (nolock) join deleted d on a.PRCo = d.PRCo and a.PRGroup = d.PRGroup
    		and a.PREndDate = d.PREndDate)
    	begin
    	select @errmsg='EM revenue distributions exist for this Pay Period'
    	goto error
    	end
   
   
    return
    error:
    	select @errmsg = isnull(@errmsg,'') + ' - cannot delete PRPC!'
        	RAISERROR(@errmsg, 11, -1);
        	rollback transaction
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   CREATE   trigger [dbo].[btPRPCi] on [dbo].[bPRPC] for INSERT as
   

/*-----------------------------------------------------------------
    * Created by: GG 03/23/01
    * Modified by: GG 11/13/01 - added date validation
    *				EN 02/18/03 - issue 23061  added isnull check, with (nolock), and dbo
	*				EN 10/1/2010 #141452  added condition to only auto insert seq #1 record into PRPS if it does not already exist
    *
    *	Insert trigger on bPRPC (Pay Period Control)
    *
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   -- validate PR Company
   select @validcnt = count(*) from dbo.bPRCO c with (nolock) join inserted i on c.PRCo = i.PRCo
   if @validcnt <> @numrows
       begin
    	select @errmsg = 'Invalid PR Company'
    	goto error
    	end
   -- validate PR Group
   select @validcnt = count(*) from dbo.bPRGR c with (nolock) join inserted i on c.PRCo = i.PRCo and c.PRGroup = i.PRGroup
    if @validcnt <> @numrows
    	begin
    	select @errmsg = 'Invalid PR Group'
    	goto error
    	end
   -- validate Beginning and Ending Dates
   if exists(select * from inserted where BeginDate > PREndDate)
   	begin
   	select @errmsg = 'Pay Period Beginning Date must be equal to or earlier than Ending Date'
   	goto error
   	end
   -- validate Multi Month info
   if exists(select * from inserted where MultiMth = 'Y' and (EndMth is null or CutoffDate is null))
       begin
       select @errmsg = 'Multi-month Pay Periods must have an Ending Month and Cutoff Date'
       goto error
       end
   if exists(select * from inserted where MultiMth = 'N' and (EndMth is not null or CutoffDate is not null))
       begin
       select @errmsg = 'Single month Pay Periods cannot have an Ending Month or Cutoff Date'
       goto error
       end
   -- validate Ending Month
   if exists(select * from inserted where MultiMth = 'Y' and datediff(m,BeginMth,EndMth)<> 1)
       begin
       select @errmsg = 'Multi-month Pay Period requires Ending Month be one month later than Beginning Month'
       goto error
       end
   
   -- auto add 1st Payment Sequence
   INSERT dbo.bPRPS(PRCo, PRGroup, PREndDate, PaySeq, Description, Bonus)
   SELECT i.PRCo, i.PRGroup, i.PREndDate, 1, 'Sequence #1', 'N'
   FROM INSERTED i
   WHERE NOT EXISTS (
					SELECT * FROM dbo.bPRPS 
					WHERE PRCo = i.PRCo 
					AND PRGroup = i.PRGroup 
					AND PREndDate = i.PREndDate
					AND PaySeq = 1
					)
   
   return
   error:
       select @errmsg = isnull(@errmsg,'') + ' - cannot insert PR Pay Period Control!'
    	RAISERROR(@errmsg, 11, -1);
    	rollback transaction
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
  

CREATE trigger [dbo].[btPRPCu] on [dbo].[bPRPC] for UPDATE as
/*-----------------------------------------------------------------
* Created: GG 08/13/07
* Modified: EN 9/25/07 issue 119734  Added HQMA audit for new column MaxRegHrsPerWeek
*			EN 12/29/2009 #136667 Added HQMA audit for columns Wks and InUseBy
*			KK 11/17/2011 TK-09036 #144495 Added HQMA audit for new columns MaxRegHrsInWeek (1 and 2)
*
*	This trigger rejects update in bPRPC (Pay Period Control) if any of the
*	following error conditions exist:
*
*		Cannot change PR Company, PR Group, PR Ending Date (primary key)
*		Beginnng date comes after ending date
*		Multi-month pay period is missing an ending month or cutoff date
*		Single month pay period has an ending month or cutoff date
*		Invalid ending month
*		Invalid Cash Offset Account
*
*	Adds old and updated values to HQ Master Audit where applicable.
*/----------------------------------------------------------------
declare @errmsg varchar(255), @numrows int, @validcnt int

select @numrows = @@rowcount
if @numrows = 0 return

set nocount on

--check for primary key change
select @validcnt = count(*)
from deleted d
join inserted i on d.PRCo = i.PRCo and d.PRGroup = i.PRGroup and d.PREndDate = i.PREndDate
if @numrows <> @validcnt
	begin
	select @errmsg = 'Cannot change PR Company, Group, or Ending Date'
	goto error
	end
-- validate Beginning and Ending Dates
if exists(select top 1 1 from inserted where BeginDate > PREndDate)
   	begin
   	select @errmsg = 'Pay Period Beginning Date must be equal to or earlier than Ending Date'
   	goto error
   	end
-- validate Multi Month info
if exists(select top 1 1 from inserted where MultiMth = 'Y' and (EndMth is null or CutoffDate is null))
	begin
    select @errmsg = 'Multi-month Pay Periods must have an Ending Month and Cutoff Date'
    goto error
    end
if exists(select top 1 1 from inserted where MultiMth = 'N' and (EndMth is not null or CutoffDate is not null))
    begin
    select @errmsg = 'Single month Pay Periods cannot have an Ending Month or Cutoff Date'
    goto error
    end
-- validate Ending Month
if exists(select top 1 1 from inserted where MultiMth = 'Y' and datediff(m,BeginMth,EndMth)<> 1)
    begin
    select @errmsg = 'Multi-month Pay Period requires Ending Month be one month later than Beginning Month'
    goto error
    end
   
-- HQ Audits
if update(BeginDate)
	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPRPC', 'PR Group: ' + convert(varchar,i.PRGroup) + ' PR End Date: ' + convert(varchar,i.PREndDate,1),
		i.PRCo, 'C', 'BeginDate', convert(varchar,d.BeginDate,1), convert(varchar,i.BeginDate,1),
		getdate(), SUSER_SNAME()
	from inserted i	join deleted d on i.PRCo = d.PRCo and i.PRGroup = d.PRGroup and i.PREndDate = d.PREndDate
	where i.BeginDate <> d.BeginDate 
if update(MultiMth)
	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPRPC', 'PR Group: ' + convert(varchar,i.PRGroup) + ' PR End Date: ' + convert(varchar,i.PREndDate,1),
		i.PRCo, 'C', 'MultiMth', d.MultiMth, i.MultiMth, getdate(), SUSER_SNAME()
	from inserted i	join deleted d on i.PRCo = d.PRCo and i.PRGroup = d.PRGroup and i.PREndDate = d.PREndDate
	where i.MultiMth <> d.MultiMth
if update(BeginMth)
	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPRPC', 'PR Group: ' + convert(varchar,i.PRGroup) + ' PR End Date: ' + convert(varchar,i.PREndDate,1),
		i.PRCo, 'C', 'BeginMth', convert(varchar,d.BeginMth,1), convert(varchar,i.BeginMth,1),
		getdate(), SUSER_SNAME()
	from inserted i	join deleted d on i.PRCo = d.PRCo and i.PRGroup = d.PRGroup and i.PREndDate = d.PREndDate
	where i.BeginMth <> d.BeginMth
 if update(EndMth)
	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPRPC', 'PR Group: ' + convert(varchar,i.PRGroup) + ' PR End Date: ' + convert(varchar,i.PREndDate,1),
		i.PRCo, 'C', 'EndMth', convert(varchar,d.EndMth,1), convert(varchar,i.EndMth,1),
		getdate(), SUSER_SNAME()
	from inserted i	join deleted d on i.PRCo = d.PRCo and i.PRGroup = d.PRGroup and i.PREndDate = d.PREndDate
	where isnull(i.EndMth,'01/01/00') <> isnull(d.EndMth,'01/01/00')
 if update(CutoffDate)
	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPRPC', 'PR Group: ' + convert(varchar,i.PRGroup) + ' PR End Date: ' + convert(varchar,i.PREndDate,1),
		i.PRCo, 'C', 'CutoffDate', convert(varchar,d.CutoffDate,1), convert(varchar,i.CutoffDate,1),
		getdate(), SUSER_SNAME()
	from inserted i	join deleted d on i.PRCo = d.PRCo and i.PRGroup = d.PRGroup and i.PREndDate = d.PREndDate
	where isnull(i.CutoffDate,'01/01/00') <> isnull(d.CutoffDate,'01/01/00')
if update(LimitMth)
	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPRPC', 'PR Group: ' + convert(varchar,i.PRGroup) + ' PR End Date: ' + convert(varchar,i.PREndDate,1),
		i.PRCo, 'C', 'LimitMth', convert(varchar,d.LimitMth,1), convert(varchar,i.LimitMth,1),
		getdate(), SUSER_SNAME()
	from inserted i	join deleted d on i.PRCo = d.PRCo and i.PRGroup = d.PRGroup and i.PREndDate = d.PREndDate
	where isnull(i.LimitMth,'01/01/00') <> isnull(d.LimitMth,'01/01/00')
if update(Hrs)
	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPRPC', 'PR Group: ' + convert(varchar,i.PRGroup) + ' PR End Date: ' + convert(varchar,i.PREndDate,1),
		i.PRCo, 'C', 'Hrs', convert(varchar,d.Hrs), convert(varchar,i.Hrs), getdate(), SUSER_SNAME()
	from inserted i	join deleted d on i.PRCo = d.PRCo and i.PRGroup = d.PRGroup and i.PREndDate = d.PREndDate
	where i.Hrs <> d.Hrs
if update(Days)
	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPRPC', 'PR Group: ' + convert(varchar,i.PRGroup) + ' PR End Date: ' + convert(varchar,i.PREndDate,1),
		i.PRCo, 'C', 'Days', convert(varchar,d.Days), convert(varchar,i.Days), getdate(), SUSER_SNAME()
	from inserted i	join deleted d on i.PRCo = d.PRCo and i.PRGroup = d.PRGroup and i.PREndDate = d.PREndDate
	where i.Days <> d.Days
if update(Wks)
	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPRPC', 'PR Group: ' + convert(varchar,i.PRGroup) + ' PR End Date: ' + convert(varchar,i.PREndDate,1),
		i.PRCo, 'C', 'Wks', convert(varchar,d.Wks), convert(varchar,i.Wks), getdate(), SUSER_SNAME()
	from inserted i	join deleted d on i.PRCo = d.PRCo and i.PRGroup = d.PRGroup and i.PREndDate = d.PREndDate
	where i.Wks <> d.Wks
if update(Status)
	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPRPC', 'PR Group: ' + convert(varchar,i.PRGroup) + ' PR End Date: ' + convert(varchar,i.PREndDate,1),
		i.PRCo, 'C', 'Status', convert(varchar,d.Status), convert(varchar,i.Status), getdate(), SUSER_SNAME()
	from inserted i	join deleted d on i.PRCo = d.PRCo and i.PRGroup = d.PRGroup and i.PREndDate = d.PREndDate
	where i.Status <> d.Status
if update(DateClosed)
	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPRPC', 'PR Group: ' + convert(varchar,i.PRGroup) + ' PR End Date: ' + convert(varchar,i.PREndDate,1),
		i.PRCo, 'C', 'DateClosed', convert(varchar,d.DateClosed,1), convert(varchar,i.DateClosed,1),
		getdate(), SUSER_SNAME()
	from inserted i	join deleted d on i.PRCo = d.PRCo and i.PRGroup = d.PRGroup and i.PREndDate = d.PREndDate
	where isnull(i.DateClosed,'01/01/00') <> isnull(d.DateClosed,'01/01/00')
if update(InUseBy)
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPRPC', 'PR Group: ' + convert(varchar,i.PRGroup) + ' PR End Date: ' + convert(varchar,i.PREndDate,1),
		i.PRCo, 'C', 'InUseBy', d.InUseBy, i.InUseBy, getdate(), SUSER_SNAME()
   	from inserted i join deleted d on i.PRCo = d.PRCo and i.PRGroup = d.PRGroup and i.PREndDate = d.PREndDate
   	where isnull(i.InUseBy,'') <> isnull(d.InUseBy,'')
if update(MaxRegHrsInWeek1)
    insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPRPC', 'PR Group: ' + convert(varchar,i.PRGroup) + ' PR End Date: ' + convert(varchar,i.PREndDate,1),
       	i.PRCo, 'C', 'Max Hrs In Week1', convert(varchar,d.MaxRegHrsInWeek1), convert(varchar,i.MaxRegHrsInWeek1),
       	getdate(), SUSER_SNAME()	
	from inserted i join deleted d on i.PRCo = d.PRCo and i.PRGroup = d.PRGroup and i.PREndDate = d.PREndDate
    where isnull(i.MaxRegHrsInWeek1,0) <> isnull(d.MaxRegHrsInWeek1,0)
if update(MaxRegHrsInWeek2)
    insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPRPC', 'PR Group: ' + convert(varchar,i.PRGroup) + ' PR End Date: ' + convert(varchar,i.PREndDate,1),
       	i.PRCo, 'C', 'Max Hrs In Week2', convert(varchar,d.MaxRegHrsInWeek2), convert(varchar,i.MaxRegHrsInWeek2),
       	getdate(), SUSER_SNAME()	
	from inserted i join deleted d on i.PRCo = d.PRCo and i.PRGroup = d.PRGroup and i.PREndDate = d.PREndDate
    where isnull(i.MaxRegHrsInWeek2,0) <> isnull(d.MaxRegHrsInWeek2,0)

-- no need to audit interface flags, they are updated by the system when the pay period status
-- is changed and/or final interfaces are run.

return

error:
	select @errmsg = @errmsg + ' - cannot update PR Pay Period Control!'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
    
    
   
   
   
   
   
  
 



GO
