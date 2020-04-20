CREATE TABLE [dbo].[bPRLH]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[Trans] [dbo].[bTrans] NOT NULL,
[Employee] [dbo].[bEmployee] NOT NULL,
[LeaveCode] [dbo].[bLeaveCode] NOT NULL,
[ActDate] [dbo].[bDate] NOT NULL,
[PostDate] [dbo].[bDate] NOT NULL,
[Type] [varchar] (1) COLLATE Latin1_General_BIN NOT NULL,
[Amt] [dbo].[bHrs] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[PRGroup] [dbo].[bGroup] NULL,
[PREndDate] [dbo].[bDate] NULL,
[PaySeq] [int] NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[InUseBatchId] [dbo].[bBatchID] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[Accum1Adj] [dbo].[bHrs] NULL CONSTRAINT [DF_bPRLH_Accum1Adj] DEFAULT ((0)),
[Accum2Adj] [dbo].[bHrs] NULL CONSTRAINT [DF_bPRLH_Accum2Adj] DEFAULT ((0)),
[AvailBalAdj] [dbo].[bHrs] NULL CONSTRAINT [DF_bPRLH_AvailBalAdj] DEFAULT ((0)),
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[udSource] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[udConv] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[udCGCTable] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[udCGCTableID] [decimal] (12, 0) NULL
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biPRLH] ON [dbo].[bPRLH] ([PRCo], [Mth], [Trans]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [biPRLHEmployee] ON [dbo].[bPRLH] ([Employee]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jonathan Paullin
-- Create date: 05/29/09
-- Description:	Issue 133439 - Adding this delete trigger to make sure attachments get cleaned up properly.
-- =============================================
CREATE TRIGGER [dbo].[btPRLHd] on [dbo].[bPRLH] for DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

-- Delete attachments if they exist. Make sure UniqueAttchID is not null
insert vDMAttachmentDeletionQueue (AttachmentID, UserName, DeletedFromRecord)
  select AttachmentID, suser_name(), 'Y' 
	  from bHQAT h join deleted d on h.UniqueAttchID = d.UniqueAttchID                  
	  where d.UniqueAttchID is not null    
	

END

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   /****** Object:  Trigger dbo.btPRLHi    Script Date: 8/28/99 9:38:13 AM ******/
    CREATE    trigger [dbo].[btPRLHi] on [dbo].[bPRLH] for INSERT as
    

/*-----------------------------------------------------------------
     *   	Created by: EN 2/3/99
     * 	Modified by: EN 2/15/99
     *                  EN 1/21/00 - removed code to update bPREL as that function is being moved to bspPRABPost
     *					 EN 4/10/02 - issue 15788  allow type 'R'
     *					EN 10/9/02 - issue 18877 change double quotes to single
     *					EN 02/18/03 - issue 23061  added isnull check, with (nolock), and dbo
     *												and corrected old syle joins
     *
     *	This trigger rejects insertion in bPRLH (PR Leave History) if the
     *	following error condition exists:
     *
     *	PR Company, Employee/Leave Code combination, PR Group, PR EndDate,
     *	or Payment Sequence are invalid.
     *	Type is not 'A' or 'U'.
     *	InUseBatch is not null
     *
     */----------------------------------------------------------------
   
    declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int
   
    declare @prco bCompany, @mth bMonth, @trans bTrans, @employee bEmployee, @leavecode bLeaveCode,
    	@actdate bDate, @type char(1), @amount bHrs
   
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
   
    /* validate PR Company */
    select @validcnt = count(*) from dbo.bHQCO c with (nolock) join inserted i on c.HQCo = i.PRCo
    if @validcnt <> @numrows
    	begin
    	select @errmsg = 'Invalid Company#'
    	goto error
    	end
   
    /* validate Employee/Leave Code */
    select @validcnt = count(*) from dbo.bPREL c with (nolock) join inserted i on c.PRCo = i.PRCo
    	and c.Employee = i.Employee and c.LeaveCode = i.LeaveCode
    if @validcnt <> @numrows
    	begin
    	select @errmsg = 'Employee/Leave Code combination is not set up'
    	goto error
    	end
   
    /* validate PR Group */
    select @validcnt = count(*) from inserted where PRGroup is not null
    select @validcnt2 = count(*) from dbo.bPRGR c with (nolock) join inserted i on c.PRCo = i.PRCo and c.PRGroup=i.PRGroup
   	where i.PRGroup is not null
    if @validcnt <> @validcnt2
    	begin
    	select @errmsg = 'Invalid PR Group'
    	goto error
    	end
   
    /* validate PR EndDate */
    select @validcnt = count(*) from inserted where PRGroup is not null and PREndDate is not null
    select @validcnt2 = count(*) from dbo.bPRPC c with (nolock) join inserted i on c.PRCo = i.PRCo and c.PRGroup=i.PRGroup
    	and c.PREndDate = i.PREndDate
   	where i.PRGroup is not null and i.PREndDate is not null
    if @validcnt <> @validcnt2
    	begin
    	select @errmsg = 'Invalid PR Period Ending Date'
    	goto error
    	end
   
    /* validate Type */
    select @validcnt = count(*) from inserted i where i.Type='A' or i.Type='U' or i.Type='R'
    if @validcnt <> @numrows
    	begin
    	select @errmsg = 'Type must be ''A'', ''U'' or ''R'''
    	goto error
    	end
   
    /* check InUseBatchId */
    select @validcnt = count(*) from inserted where InUseBatchId is null
    if @validcnt <> @numrows
    	begin
    	select @errmsg = 'InUseBatchId must be null.'
    	goto error
    	end
   
   
    return
   
    error:
    	select @errmsg = isnull(@errmsg,'') + ' - cannot insert PR Leave History!'
    	RAISERROR(@errmsg, 11, -1);
    	rollback transaction
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btPRLHu    Script Date: 8/28/99 9:38:13 AM ******/
   CREATE   trigger [dbo].[btPRLHu] on [dbo].[bPRLH] for UPDATE as
   

/*-----------------------------------------------------------------
    *   	Created by: EN 2/3/99
    * 	Modified by: EN 2/15/99
    *               EN 1/21/00 - removed code to update bPREL as that function is being moved to bspPRABPost
    *				EN 10/9/02 - issue 18877 change double quotes to single
    *				EN 02/18/03 - issue 23061  added isnull check
    *
    *	This trigger rejects update of bPRLH (PR Leave History) if the
    *	PRCo, Mth or Trans are being changed.
    *
    */----------------------------------------------------------------
   
   declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int
   
   declare @prco bCompany, @mth bMonth, @trans bTrans, @employee bEmployee, @leavecode bLeaveCode,
   	@actdate bDate, @type char(1), @amount bHrs
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   /* verify primary key not changed */
   select @validcnt = count(*) from inserted i
   	join deleted d on d.PRCo=i.PRCo and d.Mth=i.Mth and d.Trans=i.Trans
   if @validcnt <> @numrows
    	begin
    	select @errmsg = 'Cannot change Primary Key'
    	goto error
    	end
   
   
   return
   
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot update PR Leave History!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
   
  
 



GO
