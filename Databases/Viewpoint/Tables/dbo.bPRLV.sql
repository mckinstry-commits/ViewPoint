CREATE TABLE [dbo].[bPRLV]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[LeaveCode] [dbo].[bLeaveCode] NOT NULL,
[Description] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[UM] [dbo].[bUM] NOT NULL,
[AccType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[FixedUnits] [dbo].[bHrs] NULL,
[FixedFreq] [dbo].[bFreq] NULL,
[Cap1Freq] [dbo].[bFreq] NULL,
[Cap1Max] [dbo].[bHrs] NOT NULL,
[Cap2Freq] [dbo].[bFreq] NULL,
[Cap2Max] [dbo].[bHrs] NOT NULL,
[AvailBalFreq] [dbo].[bFreq] NULL,
[AvailBalMax] [dbo].[bHrs] NOT NULL,
[CarryOver] [dbo].[bHrs] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biPRLV] ON [dbo].[bPRLV] ([PRCo], [LeaveCode]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPRLV] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   /****** Object:  Trigger dbo.btPRLVd    Script Date: 8/28/99 9:38:13 AM ******/
   CREATE   trigger [dbo].[btPRLVd] on [dbo].[bPRLV] for DELETE as
   

/*-----------------------------------------------------------------
    * Modified by:	EN 10/9/02 - issue 18877 change double quotes to single
    *				EN 02/18/03 - issue 23061  added isnull check, with (nolock), and dbo
    *											and corrected old syle joins
    *
    *	This trigger restricts deletion of any PRLV records if 
    *	lines or detail exist in PREL, PRAU or PRLH.
    *
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int
   
   select @numrows = @@rowcount
   if @numrows = 0 return 
   
   set nocount on
   
   if exists(select * from dbo.PREL a with (nolock) join deleted d on a.PRCo=d.PRCo and a.LeaveCode=d.LeaveCode)
   
   	begin
   	select @errmsg='Employee Leave entries exist for this leave code'
   	goto error
   	end
   
   if exists(select * from dbo.PRAU a with (nolock) join deleted d on a.PRCo=d.PRCo and a.LeaveCode=d.LeaveCode)
   	begin
   	select @errmsg='Accrual/Usage details exist for this leave code'
   	goto error
   	end
   
   if exists(select * from dbo.PRLH a with (nolock) join deleted d on a.PRCo=d.PRCo and a.LeaveCode=d.LeaveCode)
   	begin
   	select @errmsg='Leave History details exist for this leave code'
   	goto error
   	end
   
   	
   return
   
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot delete PR Leave Code!'
       	RAISERROR(@errmsg, 11, -1);
       	rollback transaction
   
   
   
   
  
 



GO
