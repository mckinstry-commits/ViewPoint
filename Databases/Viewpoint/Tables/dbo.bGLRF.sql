CREATE TABLE [dbo].[bGLRF]
(
[GLCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[Jrnl] [dbo].[bJrnl] NOT NULL,
[GLRef] [dbo].[bGLRef] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[Adjust] [dbo].[bYN] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biGLRF] ON [dbo].[bGLRF] ([GLCo], [Mth], [Jrnl], [GLRef]) WITH (FILLFACTOR=85, STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]

ALTER TABLE [dbo].[bGLRF] ADD CONSTRAINT [PK_bGLRF] PRIMARY KEY NONCLUSTERED  ([KeyID]) WITH (FILLFACTOR=85, STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]

ALTER TABLE [dbo].[bGLRF] WITH NOCHECK ADD
CONSTRAINT [FK_bGLRF_bGLJR_GLCoJrnl] FOREIGN KEY ([GLCo], [Jrnl]) REFERENCES [dbo].[bGLJR] ([GLCo], [Jrnl])
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btGLRFd    Script Date: 8/28/99 9:37:32 AM ******/
   CREATE  trigger [dbo].[btGLRFd] on [dbo].[bGLRF] for DELETE as
   

/*-----------------------------------------------------------------
    *	This trigger rejects delete in bGLRF (Journal References) if  
    *	the following error condition exists:
    *
    *		Account Summary entries exist
    *
    */----------------------------------------------------------------
   
   declare @errmsg varchar(255)
   
   if @@rowcount = 0 return
   set nocount on
   
   /* check Account Summary */
   if exists (select * from deleted d,bGLAS g
   	where g.GLCo = d.GLCo and g.Mth = d.Mth and g.Jrnl = d.Jrnl and g.GLRef = d.GLRef)
   	begin
   	select @errmsg = 'Account Summary entries exist'
   	goto error
   	end
   
   return
   
   error:
       select @errmsg = @errmsg + ' - cannot delete GL Reference!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
  

CREATE  trigger [dbo].[btGLRFi] on [dbo].[bGLRF] for INSERT AS
/************************************************************************
* CREATED:	
* MODIFIED:	AR 2/7/2011  - #142311 - adding foreign keys and check constraints, removing trigger look ups
*
* Purpose:	This trigger rejects insertion in bGLRF (Journal Reference)  
*			if any of the following error conditions exist:
*
*		Invalid Journal
*		Adjustments must be made in a Fiscal Year ending month
*
* returns 1 and error msg if failed
*
*************************************************************************/

declare @adjcnt int, @errmsg varchar(255), @numrows int, @validcnt int 

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

/* validate Journal */
--#142311 - replacing with FK
   		
-- make sure Month uses 1st day - added to troubleshoot entries added with improperly formatted Months
if exists(select top 1 1 from inserted where DATEPART(dd , Mth)<>1)
	begin
	select @errmsg = 'Invalid Month - must use first day of month'
	goto error
	end

/* validate Adjustment entry */
select @adjcnt = count(*) from inserted where Adjust = 'Y'
select @validcnt = count(*)
from bGLFY f (nolock)
join inserted i on f.GLCo = i.GLCo and f.FYEMO = i.Mth
where i.Adjust = 'Y'
if @adjcnt <> @validcnt
	begin
	select @errmsg = 'Adjustments must be made in a Fiscal Year ending month'
	goto error
	end
   		
return
   
error:
   	select @errmsg = @errmsg + ' - cannot insert GL Reference entry!'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
   
   
  
 




GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btGLRFu    Script Date: 8/28/99 9:37:32 AM ******/
   CREATE  trigger [dbo].[btGLRFu] on [dbo].[bGLRF] for UPDATE as
   

/*-----------------------------------------------------------------
    *	This trigger rejects update in bGLRF (Journal References) if
    *
    *		Cannot change primary key
    *		Cannot change Adjustment flag if Account Summary exists
    *
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @validcount int 
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   /* check for key changes */
   select @validcount = count(*) from deleted d, inserted i
   	where d.GLCo = i.GLCo and d.Mth = i.Mth and d.Jrnl = i.Jrnl and
   		d.GLRef = i.GLRef
   
   if @validcount <> @numrows
   	begin
   	select @errmsg = 'Cannot change GL Company, Month, Journal, or GL Reference'
   	goto error
   	end
   
   /* cannot change Adjustment flag if detail exists */
   if exists(select * from bGLAS a, inserted i where a.GLCo = i.GLCo and a.Mth = i.Mth 
   		and a.Jrnl = i.Jrnl and a.GLRef = i.GLRef and a.Adjust <> i.Adjust)
   	begin
   	select @errmsg = 'Cannot change Adjustment flag if Account Summary exists'
   	goto error
   	end
   	
   return
   
   error:
   	select @errmsg = @errmsg + ' - cannot update GL Reference entry!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
  
 



GO

EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bGLRF].[Adjust]'
GO
