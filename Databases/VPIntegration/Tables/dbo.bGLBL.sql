CREATE TABLE [dbo].[bGLBL]
(
[GLCo] [dbo].[bCompany] NOT NULL,
[GLAcct] [dbo].[bGLAcct] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[NetActivity] [dbo].[bDollar] NOT NULL,
[Debits] [dbo].[bDollar] NULL,
[Credits] [dbo].[bDollar] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btGLBLd    Script Date: 8/28/99 9:37:28 AM ******/
   CREATE  trigger [dbo].[btGLBLd] on [dbo].[bGLBL] for DELETE as
   

/*-----------------------------------------------------------------
    *	This trigger rejects delete in bGLBL (Monthly Balances) if
    *	the following error condition exists:
    *
    *		Account Summary exists
    *
    *	Adds HQ Master Audit entry if AuditBals in bGLCO is 'Y'.
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   /* check Account Summary */
   if exists(select * from bGLAS s, deleted d
   		where s.GLCo = d.GLCo and s.GLAcct = d.GLAcct and s.Mth = d.Mth)
   	begin
   	select @errmsg = 'Account Summary exists'
   	goto error
   	end
   /* Audit GL Account Balances deletions */
   insert into bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bGLBL', 'GL Acct: ' + d.GLAcct + ' Mth: ' + convert(varchar(12),d.Mth, 1),
   		d.GLCo, 'D', null, null, null, getdate(), SUSER_SNAME()
   		from deleted d, bGLCO c
   		where d.GLCo = c.GLCo and c.AuditBals = 'Y'
   return
   error:
   	select @errmsg = @errmsg + ' - cannot delete Monthly Balance!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
   
   /****** Object:  Trigger dbo.btGLBLi    Script Date: 8/28/99 9:37:28 AM ******/
   CREATE  trigger [dbo].[btGLBLi] on [dbo].[bGLBL] for INSERT as
   
/*-----------------------------------------------------------------
    * Created: ??
    * Modified: GG 06/06/00 - Added check for Net Activity
    *			AR 2/18/2011  - #143291 - adding foreign keys and check constraints removing trigger look ups
    *
    *		    JayR 06/26/2012 - TK-16020  The trigger on bGLAC needed more complex logic so 
	*                        it could not be replaced with FKs.  This trigger needed to unfixed to match.
	*			JayR 07/16/2012 Tk-16020 Change to use more closely match newer coding standards.
    * 
    *	This trigger rejects insertion in bGLBL (Monthly Balance) if
    *	any of the following error conditions exist:
    *
    *		Invalid GL Account
    *
    *	Adds HQ Master Audit entry if auditing balances and
    *	Month is less than or equal to Last Month Closed in GL.
    */----------------------------------------------------------------
   DECLARE  @errmsg varchar(255)

   if @@rowcount = 0 return
   set nocount ON
   
    /* validate GL Account */
   	IF EXISTS
   		(
   		SELECT 1
   		FROM inserted i 
   		WHERE NOT EXISTS
   			(
   			SELECT 1
   			FROM bGLAC g
   			WHERE i.GLCo = g.GLCo
   			AND i.GLAcct = g.GLAcct
   			)
   		)
   	BEGIN 
		SELECT @errmsg = 'Invalid GL Account - cannot insert Monthly Balance!'
		RAISERROR(@errmsg, 11, -1);
       	ROLLBACK TRANSACTION
    END 
    
   -- make sure NetActivity = Debits - Credits
   --#142311 - replacing with a check constraint
   /*
   if exists(select * from inserted where NetActivity <> (isnull(Debits,0) - isnull(Credits,0)))
   	begin
   	select @errmsg = 'Net Activity must equal Debits minus Credits'
   	goto error
   	end
	 */
   /* add HQ Master Audit entry */
   insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bGLBL', 'GL Acct:' + i.GLAcct + ' Mth: ' + convert(varchar(12),i.Mth, 1),
   	i.GLCo, 'A', null, null, null, getdate(), SUSER_SNAME() from inserted i, bGLCO g
   	where i.GLCo = g.GLCo and g.AuditBals = 'Y' and i.Mth <= g.LastMthGLClsd
   	
   RETURN 

   
   
  
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btGLBLu    Script Date: 8/28/99 9:37:28 AM ******/
   CREATE  trigger [dbo].[btGLBLu] on [dbo].[bGLBL] for UPDATE as
   

/*-----------------------------------------------------------------
    * Created: ??
    * Modified: GG 06/06/00 - added NetActivity validation
    *			AR 2/4/2011  - #143291 - adding foreign keys and check constraints, removing trigger look ups
    *
    *	This trigger rejects update in bGLBL (Monthly Balance) if
    *	any of the following error conditions exist:
    *
    *		Cannot change GL Company
    *		Cannot change GL Account
    *		Cannot change Month
    *
    * 	Adds record to HQ Master Audit if auditing balances and Month
    *	is equal to or less than Last Month Closed in GL.
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @validcnt int
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   /* check for changes to primary key */
   select @validcnt = count (*) from deleted d, inserted i
   	where d.GLCo = i.GLCo and d.GLAcct = i.GLAcct and d.Mth = i.Mth
   if @numrows <> @validcnt
   	begin
   	select @errmsg = 'Cannot change GL Company, GL Account, or Month'
   	goto error
   	end
   
   -- validate Net Activity
   /*
   if exists(select * from inserted where NetActivity <> (isnull(Debits,0) - isnull(Credits,0)))
       begin
       select @errmsg = 'Net Activity must equal Debits minus Credits'
       goto error
       end
	 */
   /* check for HQ auditing on bGLBL  */
   select @validcnt = count(*) from inserted i, bGLCO g
   	where i.GLCo = g.GLCo and g.AuditBals = 'Y'
   if @validcnt = 0 return
   /* Net Activity if Month less than or equal to Last Month Closed in GL */
   insert into bHQMA select 'bGLBL', 'GL Acct: ' + i.GLAcct + ' Mth: ' + convert(varchar(12),i.Mth, 1),
   	i.GLCo, 'C', 'Net Activity', convert(varchar(30),d.NetActivity), convert(varchar(30),i.NetActivity),
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d, bGLCO g
   	where i.GLCo = g.GLCo and g.AuditBals = 'Y'
   	and i.GLCo = d.GLCo and i.GLAcct = d.GLAcct and i.Mth = d.Mth and i.NetActivity <> d.NetActivity
   	and i.Mth <= g.LastMthGLClsd
   return
   error:
   	select @errmsg = @errmsg + ' - cannot update Monthly Balances!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
   
  
 



GO
ALTER TABLE [dbo].[bGLBL] ADD CONSTRAINT [CK_bGLBL_NetActivity] CHECK (([NetActivity]=(isnull([Debits],(0))-isnull([Credits],(0)))))
GO
ALTER TABLE [dbo].[bGLBL] ADD CONSTRAINT [PK_bGLBL] PRIMARY KEY NONCLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biGLBL] ON [dbo].[bGLBL] ([GLCo], [GLAcct], [Mth]) ON [PRIMARY]
GO
