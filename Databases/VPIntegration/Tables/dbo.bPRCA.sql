CREATE TABLE [dbo].[bPRCA]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[PRGroup] [dbo].[bGroup] NOT NULL,
[PREndDate] [dbo].[bDate] NOT NULL,
[Employee] [dbo].[bEmployee] NOT NULL,
[PaySeq] [tinyint] NOT NULL,
[Craft] [dbo].[bCraft] NOT NULL,
[Class] [dbo].[bClass] NOT NULL,
[EDLType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[EDLCode] [dbo].[bEDLCode] NOT NULL,
[Basis] [dbo].[bDollar] NOT NULL,
[Amt] [dbo].[bDollar] NOT NULL,
[EligibleAmt] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bPRCA_EligibleAmt] DEFAULT ((0)),
[VendorGroup] [dbo].[bGroup] NULL,
[Vendor] [dbo].[bVendor] NULL,
[APDesc] [dbo].[bDesc] NULL,
[OldVendor] [dbo].[bVendor] NULL,
[OldAPMth] [dbo].[bMonth] NULL,
[OldAPAmt] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bPRCA_OldAPAmt] DEFAULT ((0)),
[udRate] [decimal] (5, 3) NULL,
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
 
  
   
   
   
   
   CREATE   trigger [dbo].[btPRCAd] on [dbo].[bPRCA] for DELETE as
   

/*-----------------------------------------------------------------
    *  Created by: GG 03/21/01
    *  Modified by:	EN 10/9/02 - issue 18877 change double quotes to single
    *					EN 12/10/03 - issue 23061  added isnull check, with (nolock), and dbo
    *
    *	Delete trigger on bPRCA Craft Accums - checks for existing Rate Detail
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   -- check for Craft Accums Rate Detail
   if exists(select * from dbo.bPRCX w with (nolock) join deleted d on w.PRCo = d.PRCo and w.PRGroup = d.PRGroup and w.PREndDate = d.PREndDate
   		and w.Employee = d.Employee and w.PaySeq = d.PaySeq and w.Craft = d.Craft and w.Class = d.Class
   		and w.EDLType = d.EDLType and w.EDLCode = d.EDLCode)
    	begin
   	select @errmsg = 'Craft report detail exists'
   	goto error
   	end
   
   return
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot delete Craft Accumulations!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biPRCA] ON [dbo].[bPRCA] ([PRCo], [PRGroup], [PREndDate], [Employee], [PaySeq], [Craft], [Class], [EDLType], [EDLCode]) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPRCA].[Basis]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPRCA].[Amt]'
GO
