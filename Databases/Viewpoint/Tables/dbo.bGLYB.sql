CREATE TABLE [dbo].[bGLYB]
(
[GLCo] [dbo].[bCompany] NOT NULL,
[FYEMO] [dbo].[bMonth] NOT NULL,
[GLAcct] [dbo].[bGLAcct] NOT NULL,
[BeginBal] [dbo].[bDollar] NOT NULL,
[NetAdj] [dbo].[bDollar] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[udSource] [varchar] (305) COLLATE Latin1_General_BIN NULL,
[udConv] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[udCGCTable] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[udCGCTableID] [decimal] (12, 0) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biGLYB] ON [dbo].[bGLYB] ([GLCo], [FYEMO], [GLAcct]) WITH (FILLFACTOR=85, STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]

ALTER TABLE [dbo].[bGLYB] ADD CONSTRAINT [PK_bGLYB] PRIMARY KEY NONCLUSTERED  ([KeyID]) WITH (FILLFACTOR=85, STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]

ALTER TABLE [dbo].[bGLYB] WITH NOCHECK ADD
CONSTRAINT [FK_bGLYB_bGLFY_GLCoFYEMO] FOREIGN KEY ([GLCo], [FYEMO]) REFERENCES [dbo].[bGLFY] ([GLCo], [FYEMO])
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE  trigger [dbo].[btGLYBd] on [dbo].[bGLYB] for DELETE as

/*-----------------------------------------------------------------
* Created: ??
* Modified: GG 12/03/01 - #15458 - correct delete logic
*			GG 03/01/06 - #29498 - audit deletes
*
*	This trigger rejects delete in bGLYB (Fiscal Year Balances) 
*	if the following error condition exists:
*
*		Account Summary adjustment entries exist
*
*/----------------------------------------------------------------
   
declare @errmsg varchar(255)

if @@rowcount = 0 return
set nocount on

-- check for Account Summary adjustments
if exists(select * from deleted d join bGLAS s on d.GLCo = s.GLCo and d.GLAcct = s.GLAcct
			join bGLFY y on d.GLCo = y.GLCo and d.FYEMO = y.FYEMO 
			where s.Mth >= y.BeginMth and s.Mth <= y.FYEMO and s.Adjust = 'Y')
	begin
	select @errmsg = 'Account Summary entries posted as Adjustments exist'
	goto error
	end

-- add HQ Master Audit entry 
insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bGLYB',  'FYEMO: ' + convert(varchar,d.FYEMO,1) + ' GL Acct:' + d.GLAcct,
   		d.GLCo, 'D', null, null, null, getdate(), SUSER_SNAME()
from deleted d
join dbo.bGLCO g on d.GLCo = g.GLCo
where g.AuditBals = 'Y'

return
   
error:
   select @errmsg = @errmsg + ' - cannot delete Fiscal Year Balance!'
   RAISERROR(@errmsg, 11, -1);
   rollback transaction
   
   
  
 





GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
   
   /****** Object:  Trigger dbo.btGLYBi    Script Date: 8/28/99 9:37:32 AM ******/
   CREATE  trigger [dbo].[btGLYBi] on [dbo].[bGLYB] for INSERT as
   
/*-----------------------------------------------------------------
* CREATED:	
* MODIFIED:	AR 02/10/2010 - Issue 143291 - replacing trigger code with FKs
*		    JayR 06/26/2012  TK-16020  Need to back out a FK as delete on GLAC need to
*                  be handled with more complex logic.
			JayR 07/16/2012 Tk-16020 Change to use more closely match newer coding standards.
*
*	This trigger rejects insertion in bGLYB (Fiscal Year Balance)
*	if any of the following error conditions exist:
*
*		Missing Fiscal Year entry
*		Invalid GL Account
*
*	Adds HQ Master Audit entry if auditing balances.
*/----------------------------------------------------------------
   declare @errmsg varchar(255)

   if @@rowcount = 0 return
   set nocount on
   /* validate GL Company and Fiscal Year */
   -- 143291 - replacing with FK
   
   /* validate GL Account - any account can have a bGLFY entry */
   IF EXISTS
     (
     SELECT 1
     FROM inserted i 
     WHERE NOT EXISTS
		(
		SELECT 1
		FROM bGLAC g
		WHERE i.GLCo = g.GLCo  and i.GLAcct = g.GLAcct 
		)
	)
   	BEGIN
   		select @errmsg = 'Invalid GL Account - cannot insert Fiscal Year Balance entry!'
      	RAISERROR(@errmsg, 11, -1);
       	rollback transaction
   	END
   	
   /* add HQ Master Audit entry */
   insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bGLYB',  'FYEMO: ' + convert(varchar(12),i.FYEMO,1) + ' GL Acct:' + i.GLAcct,
   		i.GLCo, 'A', null, null, null, getdate(), SUSER_SNAME() from inserted i, bGLCO g
   		where i.GLCo = g.GLCo and g.AuditBals = 'Y'
   return


GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE  trigger [dbo].[btGLYBu] on [dbo].[bGLYB] for UPDATE as

/*-----------------------------------------------------------------
* Created: ??
* Modified: GG 03/01/06 - #29498 - audit net adj changes, cleanup
*
*	This trigger rejects update in bGLYB (Fiscal Year Balances) if
*
*		Cannot change GL Company
*		Cannot Fiscal Year ending month
*		Cannot change GL Account
*
* 	Adds record to HQ Master Audit where necessary.
*/----------------------------------------------------------------
   
declare @errmsg varchar(255), @numrows int, @validcnt int
   
select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

/* check for changes to table keys */
select @validcnt = count(*) from inserted i, deleted d
where d.GLCo = i.GLCo and d.FYEMO = i.FYEMO and d.GLAcct = i.GLAcct
if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Cannot change GL Company, Fiscal Year ending month, or GL Account'
   	goto error
   	end
   
-- HQ Audit
if update(BeginBal)
	begin
   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bGLYB', 'FYEMO: ' + convert(varchar(12),i.FYEMO,1) + ' GL Acct:' + i.GLAcct,
   		i.GLCo, 'C', 'Begin Balance', convert(varchar,d.BeginBal), convert(varchar,i.BeginBal),
   	 	getdate(), SUSER_SNAME()
   	from inserted i
	join deleted d on i.GLCo = d.GLCo and i.FYEMO = d.FYEMO and i.GLAcct = d.GLAcct
	join dbo.bGLCO g (nolock) on g.GLCo = i.GLCo
   	where i.BeginBal <> d.BeginBal and g.AuditBals = 'Y'
	end

if update(NetAdj)
	begin 
   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bGLYB', 'FYEMO: ' + convert(varchar(12),i.FYEMO,1) + ' GL Acct:' + i.GLAcct,
   	 	i.GLCo, 'C', 'Net Adjustments', convert(varchar,d.NetAdj), convert(varchar,i.NetAdj),
   	 	getdate(), SUSER_SNAME()
   	from inserted i
	join deleted d on i.GLCo = d.GLCo and i.FYEMO = d.FYEMO and i.GLAcct = d.GLAcct
	join dbo.bGLCO g (nolock) on g.GLCo = i.GLCo
   	where i.NetAdj <> d.NetAdj and i.FYEMO <= g.LastMthGLClsd -- audit changes in closed months only to avoid system updates
		and g.AuditBals = 'Y'
	end

return

error:
   	select @errmsg = @errmsg + ' - cannot update Fiscal Year Balance entry!'
    RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
 


GO

EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bGLYB].[BeginBal]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bGLYB].[NetAdj]'
GO
