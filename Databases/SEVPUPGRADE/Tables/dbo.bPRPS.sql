CREATE TABLE [dbo].[bPRPS]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[PRGroup] [dbo].[bGroup] NOT NULL,
[PREndDate] [dbo].[bDate] NOT NULL,
[PaySeq] [tinyint] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[Bonus] [dbo].[bYN] NOT NULL,
[OverrideDirDep] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRPS_OverrideDirDep] DEFAULT ('N'),
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[udSource] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[udConv] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[udCGCTable] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[udCGCTableID] [decimal] (12, 0) NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btPRPSd    Script Date: 9/17/2007 13:01:40 ******/
   CREATE  trigger [dbo].[btPRPSd] on [dbo].[bPRPS] for DELETE as
   

/*-----------------------------------------------------------------
    *	Created by: EN 9/17/07
    *	Modified by:	
    *
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on

	-- check for Timecards
	if (select count(*) from deleted d
		join dbo.bPRTH t with (nolock) on t.PRCo = d.PRCo and t.PRGroup = d.PRGroup and t.PREndDate = d.PREndDate 
			and t.PaySeq = d.PaySeq) > 0
	 begin
	 select @errmsg = 'Timecards have already been posted for this pay sequence'
	 goto error
	 end
 
	-- check for unposted Timecards
	if (select count(*) from deleted d
		join dbo.bHQBC b with (nolock) on b.Co = d.PRCo and b.PRGroup = d.PRGroup and b.PREndDate = d.PREndDate
		join dbo.bPRTB t with (nolock) on t.Co = d.PRCo and t.Mth = b.Mth and t.BatchId = b.BatchId and t.PaySeq = d.PaySeq) > 0
	 begin
	 select @errmsg = 'Timecard batch entries have already been posted for this pay sequence'
	 goto error
	 end
  
   
   return
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot delete Payment Sequence!'
       	RAISERROR(@errmsg, 11, -1);
       	rollback transaction
   
   
   
  
 




GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   CREATE   TRIGGER [dbo].[btPRPSi] ON [dbo].[bPRPS] FOR INSERT AS
   

/*-----------------------------------------------------------------
    * Created by: EN 10/01/2010
    * Modified by: 
    *
    *	Insert trigger on bPRPS (Pay Period Sequences)
    *
    */----------------------------------------------------------------
   DECLARE @errmsg VARCHAR(255), @numrows INT, @validcnt INT, @validcnt2 INT
   
   SELECT @numrows = @@rowcount
   IF @numrows = 0 RETURN
   SET NOCOUNT ON
   
   -- validate PR Company
   SELECT @validcnt = COUNT(*) FROM dbo.bPRCO c WITH (NOLOCK) JOIN INSERTED i ON c.PRCo = i.PRCo
   IF @validcnt <> @numrows
   BEGIN
    	SELECT @errmsg = 'Invalid PR Company'
    	GOTO error
   END
   -- validate PR Group
   SELECT @validcnt = COUNT(*) FROM dbo.bPRGR c WITH (NOLOCK) JOIN INSERTED i ON c.PRCo = i.PRCo AND c.PRGroup = i.PRGroup
   IF @validcnt <> @numrows
   BEGIN
    	SELECT @errmsg = 'Invalid PR Group'
    	GOTO error
   END
   -- validate existence of bPRPC record
   SELECT @validcnt = COUNT(*) FROM dbo.bPRPC c WITH (NOLOCK) 
   JOIN INSERTED i ON c.PRCo = i.PRCo AND c.PRGroup = i.PRGroup AND c.PREndDate = i.PREndDate
   IF @validcnt <> @numrows
   BEGIN
   		SELECT @errmsg = 'Pay Period does not exist'
   		GOTO error
   END
   
   
   RETURN
   error:
       SELECT @errmsg = ISNULL(@errmsg,'') + ' - cannot insert PR Pay Period Sequence!'
    	RAISERROR(@errmsg, 11, -1);
    	ROLLBACK TRANSACTION
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
  

CREATE TRIGGER [dbo].[btPRPSu] ON [dbo].[bPRPS] FOR UPDATE AS
/*-----------------------------------------------------------------
* Created: EN 10/01/2010
* Modified: 
*
*	Update trigger on bPRPS (Pay Period Sequences)
*
*/----------------------------------------------------------------
DECLARE @errmsg VARCHAR(255), @numrows INT, @validcnt INT

SELECT @numrows = @@ROWCOUNT
IF @numrows = 0 RETURN

SET NOCOUNT ON

--check for primary key change
SELECT @validcnt = COUNT(*)
FROM DELETED d
JOIN INSERTED i ON d.PRCo = i.PRCo AND d.PRGroup = i.PRGroup AND d.PREndDate = i.PREndDate AND d.PaySeq = i.PaySeq
IF @numrows <> @validcnt
BEGIN
	SELECT @errmsg = 'Cannot change PR Company, Group, Ending Date or Pay Sequence'
	GOTO error
END
   
RETURN

error:
	SELECT @errmsg = @errmsg + ' - cannot update PR Pay Period Sequence!'
    RAISERROR(@errmsg, 11, -1);
    ROLLBACK TRANSACTION
    
    
   
   
   
   
   
  
 




GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPRPS] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPRPS] ON [dbo].[bPRPS] ([PRCo], [PRGroup], [PREndDate], [PaySeq]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPRPS].[Bonus]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPRPS].[OverrideDirDep]'
GO
