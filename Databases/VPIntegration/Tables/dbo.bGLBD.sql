CREATE TABLE [dbo].[bGLBD]
(
[GLCo] [dbo].[bCompany] NOT NULL,
[GLAcct] [dbo].[bGLAcct] NOT NULL,
[BudgetCode] [dbo].[bBudgetCode] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BudgetAmt] [dbo].[bDollar] NOT NULL,
[udSource] [varchar] (305) COLLATE Latin1_General_BIN NULL,
[udConv] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[udCGCTable] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[udCGCTableID] [decimal] (12, 0) NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btGLBDd    Script Date: 8/28/99 9:37:28 AM ******/
   CREATE  trigger [dbo].[btGLBDd] on [dbo].[bGLBD] for DELETE as
   

/*-----------------------------------------------------------------
    *	This trigger rejects deletion from bGLBD if the following
    *	error condition exists:
    *
    *		None
    *
    *	Adds HQ Master Audit entry if AuditBudgets in bGLCO is 'Y'.
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   /* Audit GL Monthly Budget deletions */
   insert into bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bGLBD', 'GL Acct: ' + d.GLAcct + ' Bdgt: ' + d.BudgetCode + ' Mth: ' + convert(varchar(12),d.Mth,1),
   		d.GLCo, 'D', null, null, null, getdate(), SUSER_SNAME()
   		from deleted d, bGLCO c
   		where d.GLCo = c.GLCo and c.AuditBudgets = 'Y'
   return
   error:
   	select @errmsg = @errmsg + ' - cannot delete Monthly Budget Entry!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btGLBDi    Script Date: 8/28/99 9:38:21 AM ******/
CREATE   trigger [dbo].[btGLBDi] on [dbo].[bGLBD] for INSERT as
/************************************************************************
* CREATED:	
* MODIFIED:	issue 25163 remove unnessary cursor for performance JRE 9/1/04
*			AR 2/4/2011  - #142311 - adding foreign keys and check constraints, removing trigger look ups
*			CHS	11/02/2011	D-03060	insert header into GLBR when it doesn't exist		
*			CHS	11/02/2011	D-03060	updated per code review by GG
*
* Purpose:	This trigger rejects insertion in bGLBD (Monthly Budgets) if  
*	any of the following error conditions exist:
*
*		Invalid Budget Code 
*		Invalid GL Account
*
*	Adds HQ Master Audit entry,
* 

* returns 1 and error msg if failed
*
*************************************************************************/

declare @numrows int, @FYEMO varchar(20), @errmsg varchar(255), @errno int

   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   
   /* issue 25163 remove unnessary cursor for performance*/
	--#142311 - removing lookups because of FKs now
   
   select @errmsg=null  --clear out error flag
   select top 1 @errmsg='Invalid GLAcct: ' + isnull(i.GLAcct,'null')
   	from inserted i 
   	where not exists (select * from bGLAC g 
   			  where g.GLCo=i.GLCo and g.GLAcct=i.GLAcct)

   	
   	-- begin CHS	11/02/2011	D-03060
	-- validate fiscal year in bGLFY - required - #139564
	 SELECT TOP 1 @errmsg = 'Missing Fiscal Year - cannot add budgets for ' + CAST(MONTH(Mth) AS VARCHAR(20)) + '/' + CAST(RIGHT(YEAR(Mth), 2) AS VARCHAR(20))
	 FROM inserted  WHERE Mth NOT IN (SELECT i.Mth
			FROM inserted i
			JOIN dbo.bGLFY f ON f.GLCo = i.GLCo AND i.Mth >= f.BeginMth AND i.Mth <= f.FYEMO)
	 
	-- if not exists, add fiscal year entry for budget code in bGLBR - #139564 
	INSERT dbo.bGLBR (GLCo, FYEMO, BudgetCode, GLAcct, BeginBalance)
	SELECT i.GLCo, f.FYEMO, i.BudgetCode, i.GLAcct, 0.0		-- init begin balance as 0.00
	FROM inserted i
	JOIN dbo.bGLFY f ON f.GLCo = i.GLCo AND i.Mth >= f.BeginMth AND i.Mth <= f.FYEMO WHERE NOT EXISTS (SELECT 1
			FROM dbo.bGLBR r
			WHERE r.GLCo = f.GLCo AND r.FYEMO = f.FYEMO AND r.BudgetCode = i.BudgetCode AND r.GLAcct = i.GLAcct)							
   	-- end CHS	11/02/2011	D-03060
   	
   if @errmsg is not null
   	goto error
   
   insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   select 'bGLBD', 'GL Acct: ' + i.GLAcct + ' Bdgt: ' + i.BudgetCode + ' Mth: ' + 
   	convert(char(12),i.Mth, 1),i.GLCo,'A', null, null, null, getdate(), SUSER_SNAME()
   	from inserted i 
   	join GLCO g on i.GLCo=g.GLCo
   
   

   return
   
   error:

       
   	select @errmsg = @errmsg + ' - cannot insert Monthly Budget entry!'
       	RAISERROR(@errmsg, 11, -1);
       	rollback transaction
   
   
   
   
  
 


GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
CREATE  trigger [dbo].[btGLBDu] on [dbo].[bGLBD] for UPDATE as
/*-----------------------------------------------------------------
* Created: ??
* Modified: GG 03/17/08 - #126924 - fix overflow error, remove cursor
*
*	This trigger rejects update in bGLBD (Monthly Budgets) if
*	any of the following error conditions exist:
*
*		Cannot change GL Company
*		Cannot change GL Account
*		Cannot change Budget Code
*		Cannot change Month
*
*	Adds a record to HQ Master Audit as necessary.
*----------------------------------------------------------------*/
    
declare @numrows int, @validcnt int, @errmsg varchar(255)    
   
select @numrows = @@rowcount
if @numrows = 0 return
   
set nocount on
   
--check for primary key change
select @validcnt = count(*)
from deleted d
join inserted i on d.GLCo = i.GLCo and d.GLAcct = i.GLAcct and
   	d.BudgetCode = i.BudgetCode and d.Mth = i.Mth
if @numrows <> @validcnt
	begin
	select @errmsg = 'Cannot change GL Company, GL Account, Budget Code, or Month'
	goto error
	end
   
-- HQ Auditing   
if update(BudgetAmt)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bGLBD', 'GL Acct: ' + i.GLAcct + ' Bdgt: ' + i.BudgetCode + ' Mth: ' + convert(varchar,i.Mth, 1),
		i.GLCo, 'C', 'BudgetAmt', convert(varchar,d.BudgetAmt), convert(varchar,i.BudgetAmt),
		getdate(), SUSER_SNAME()
	from inserted i
	join deleted d on d.GLCo = i.GLCo and d.GLAcct = i.GLAcct and d.BudgetCode = i.BudgetCode and d.Mth = i.Mth
	join dbo.bGLCO g (nolock) on i.GLCo = g.GLCo
	where i.BudgetAmt <> d.BudgetAmt and g.AuditBudgets = 'Y'
	
   
return
   
 error:
   	select @errmsg = @errmsg + ' - cannot update GL Monthly Budgets!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biGLBD] ON [dbo].[bGLBD] ([GLCo], [GLAcct], [BudgetCode], [Mth]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [biGLBD2] ON [dbo].[bGLBD] ([GLCo], [Mth], [BudgetCode], [GLAcct]) INCLUDE ([BudgetAmt]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bGLBD] WITH NOCHECK ADD CONSTRAINT [FK_bGLBR_bGLBD_GLCoBudgetCode] FOREIGN KEY ([GLCo], [BudgetCode]) REFERENCES [dbo].[bGLBC] ([GLCo], [BudgetCode])
GO
