CREATE TABLE [dbo].[bPREL]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[Employee] [dbo].[bEmployee] NOT NULL,
[LeaveCode] [dbo].[bLeaveCode] NOT NULL,
[EligibleDate] [dbo].[bDate] NOT NULL,
[FixedUnits] [dbo].[bHrs] NULL,
[FixedFreq] [dbo].[bFreq] NULL,
[Cap1Freq] [dbo].[bFreq] NULL,
[Cap1Max] [dbo].[bHrs] NULL,
[Cap1Accum] [dbo].[bHrs] NOT NULL,
[Cap1Date] [dbo].[bDate] NULL,
[Cap2Freq] [dbo].[bFreq] NULL,
[Cap2Max] [dbo].[bHrs] NULL,
[Cap2Accum] [dbo].[bHrs] NOT NULL,
[Cap2Date] [dbo].[bDate] NULL,
[AvailBalFreq] [dbo].[bFreq] NULL,
[AvailBalMax] [dbo].[bHrs] NULL,
[CarryOver] [dbo].[bHrs] NULL,
[AvailBal] [dbo].[bHrs] NOT NULL,
[AvailBalDate] [dbo].[bDate] NULL,
[InUseMth] [dbo].[bMonth] NULL,
[InUseBatchId] [dbo].[bBatchID] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
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
 
  
   
   
   
   
   
   /****** Object:  Trigger dbo.btPRELd    Script Date: 8/28/99 9:38:12 AM ******/
   CREATE   trigger [dbo].[btPRELd] on [dbo].[bPREL] for DELETE as
   

/*-----------------------------------------------------------------
    * Modified by: EN 10/9/02 - issue 18877 change double quotes to single
    *				EN 02/12/03 - issue 23061  added isnull check, with (nolock), and dbo
    *								and corrected old syle joins
    *
    *	This trigger restricts deletion of any PREL records if 
    *	lines or detail exist in PRLB or PRLH.
    *
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int
   
   select @numrows = @@rowcount
   if @numrows = 0 return 
   
   set nocount on
   
   if exists(select * from dbo.PRLB a with (nolock) join deleted d on a.PRCo=d.PRCo and a.Employee=d.Employee and a.LeaveCode=d.LeaveCode)
   	begin
   	select @errmsg='Accrual/Usage details exist for this leave code'
   	goto error
   	end
   
   if exists(select * from dbo.PRLH a with (nolock) join deleted d on a.PRCo=d.PRCo and a.Employee=d.Employee and a.LeaveCode=d.LeaveCode)
   	begin
   	select @errmsg='Leave history details exist for this leave code'
   	goto error
   	end
   
   	
   return
   
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot delete PR Employee Leave Code!'
       	RAISERROR(@errmsg, 11, -1);
       	rollback transaction
   
   
   
   
  
 



GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPREL] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPREL] ON [dbo].[bPREL] ([PRCo], [Employee], [LeaveCode]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
