CREATE TABLE [dbo].[bPRCI]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[Craft] [dbo].[bCraft] NOT NULL,
[EDLType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[EDLCode] [dbo].[bEDLCode] NOT NULL,
[Factor] [dbo].[bRate] NOT NULL,
[OldRate] [dbo].[bUnitCost] NOT NULL CONSTRAINT [DF_bPRCI_OldRate] DEFAULT ((0)),
[NewRate] [dbo].[bUnitCost] NOT NULL CONSTRAINT [DF_bPRCI_NewRate] DEFAULT ((0)),
[VendorGroup] [dbo].[bGroup] NULL,
[Vendor] [dbo].[bVendor] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btPRCId    Script Date: 8/28/99 9:38:10 AM ******/
   CREATE  trigger [dbo].[btPRCId] on [dbo].[bPRCI] for DELETE as
   

/*-----------------------------------------------------------------
    *  Created: EN 4/17/00
    *	Modified:	EN 01/28/03 - issue 23061  added isnull check, and dbo
    *
    * Inserts HQ Master Audit entry.
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int
   select @numrows = @@rowcount
   set nocount on
   if @numrows = 0 return
   
   /* Audit Craft Item deletions */
   insert into dbo.bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bPRCI', 'Craft: ' + d.Craft + ' EDLType:' + d.EDLType + ' EDLCode:' + convert(varchar(10),d.EDLCode) +
       ' Factor:' + convert(varchar(10),d.Factor),
       d.PRCo, 'D', null, null, null, getdate(), SUSER_SNAME()
   	from deleted d join dbo.PRCO p on d.PRCo = p.PRCo where p.AuditCraftClass = 'Y'
   
   return
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot delete PR Craft Items!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   /****** Object:  Trigger dbo.btPRCIi    Script Date: 8/28/99 9:38:10 AM ******/
   CREATE    trigger [dbo].[btPRCIi] on [dbo].[bPRCI] for INSERT as
   

/*-----------------------------------------------------------------
    * Created by: EN 4/17/00
    * Modified: GG 12/28/00 - fixed Factor validation
    * Modified by: MV 1/28/02 added calc category validation
    *				EN 01/28/03 - issue 23061  added isnull check, with (nolock), and dbo
    *											and corrected old syle joins
    *
    * Insert trigger on PR Craft Items
    *
    * Adds HQ Master Audit entry.
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   /* validate PR Company */
   select @validcnt = count(*) from dbo.bHQCO c with (nolock) join inserted i on c.HQCo = i.PRCo
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid Company# '
   	goto error
   	end
   
   /* validate PR Craft */
   select @validcnt = count(*) from dbo.bPRCM c with (nolock) join inserted i on c.PRCo = i.PRCo and c.Craft = i.Craft
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid Craft '
   	goto error
   	end
   
   /* validate EDLType */
   select @validcnt = count(*) from inserted where EDLType = 'E' or EDLType = 'D' or EDLType = 'L'
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid Earn/Dedn/Liab Type Code '
   	goto error
   	end
   
   /* validate EDLCode */
   select @validcnt = count(*) from inserted where EDLType = 'E'
   select @validcnt2 = count(*) from inserted i join dbo.PREC c with (nolock) on i.PRCo = c.PRCo and i.EDLCode = c.EarnCode
   	where i.EDLType = 'E'
   if @validcnt <> @validcnt2
   	begin
   	select @errmsg = 'Invalid Earnings Code '
   	goto error
   	end
   select @validcnt = count(*) from inserted where EDLType = 'D' or EDLType = 'L'
   select @validcnt2 = count(*) from inserted i join dbo.PRDL c with (nolock) on i.PRCo = c.PRCo and i.EDLCode = c.DLCode
   	where (i.EDLType = 'D' or i.EDLType = 'L')
   if @validcnt <> @validcnt2
   	begin
   	select @errmsg = 'Invalid Dedn/Liab Code '
   	goto error
   	end
   
   /* validate Factor */
   select @validcnt = count(*) from dbo.bPREC c with (nolock) join inserted i on c.PRCo = i.PRCo and c.EarnCode = i.EDLCode
   	where i.EDLType = 'E' and i.Factor <> 0 and Method <> 'V'
   if @validcnt <> 0
   	begin
   	select @errmsg = 'Factor must be 0.00 for non Variable Rate Earnings '
   	goto error
   	end
   select @validcnt = count(*) from dbo.bPREC c with (nolock) join inserted i on c.PRCo = i.PRCo and c.EarnCode = i.EDLCode
   	where i.EDLType = 'E' and i.Factor <= 0 and Method = 'V'
   if @validcnt <> 0
   	begin
   	select @errmsg = 'Factor must be greater than 0.00 for Variable Rate Earnings '
   	goto error
   	end
   select @validcnt = count(*) from dbo.bPRDL c with (nolock) join inserted i on c.PRCo = i.PRCo and i.EDLType = c.DLType and i.EDLCode = c.DLCode
       where i.EDLType <> 'E' and i.Factor <> 0 and Method <> 'V'
   if @validcnt <> 0
   	begin
   	select @errmsg = 'Factor must be 0.00 for non Variable Rate Deductions and Liabilities '
   	goto error
   	end
   select @validcnt = count(*) from dbo.bPRDL c with (nolock) join inserted i on c.PRCo = i.PRCo and i.EDLType = c.DLType and i.EDLCode = c.DLCode
       where i.EDLType <> 'E' and i.Factor = 0 and Method = 'V'
   if @validcnt <> 0
   	begin
   	select @errmsg = 'Factor must be greater than 0.00 for Variable Rate Deductions and Liabilities '
   	goto error
   	end
   
   /* validate Vendor Group */
   select @validcnt = count(*) from inserted i where i.VendorGroup is not null
   select @validcnt2 = count(*) from dbo.bHQGP c with (nolock) join inserted i on c.Grp = i.VendorGroup where i.VendorGroup is not null
   if @validcnt <> @validcnt2
   	begin
   	select @errmsg = 'Invalid Vendor Group '
   	goto error
 
   	end
   
   /*validate Vendor */
   select @validcnt = count(*) from inserted i where i.Vendor is not null
   select @validcnt2 = count(*) from dbo.bAPVM r with (nolock)
           JOIN inserted i on i.VendorGroup=r.VendorGroup and i.Vendor=r.Vendor where i.Vendor is not null
   if @validcnt <> @validcnt2
    	begin
    	select @errmsg = 'Invalid Vendor '
    	goto error
    	end
   
   /*validate CalCategory.*/
   select @validcnt = count(*) from dbo.bPRDL c with (nolock) join inserted i on c.PRCo = i.PRCo and i.EDLType = c.DLType and i.EDLCode = c.DLCode
       where i.PRCo = c.PRCo and i.EDLType in ('L', 'D') and c.CalcCategory not in ('C', 'A') 
   if @validcnt <> 0
   	begin
   	select @errmsg = 'DLCode calculation category must be C or A. '
   	goto error
   	end
   
   /* add HQ Master Audit entry */
   Insert into dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bPRCI', 'Craft:' + i.Craft + ' EDLType:' + i.EDLType + ' EDLCode:' + convert(varchar(10),i.EDLCode) +
       ' Factor:' + convert(varchar(10),i.Factor),
       i.PRCo, 'A', null, null, null, getdate(), SUSER_SNAME()
       from inserted i join dbo.PRCO p on i.PRCo = p.PRCo where p.AuditCraftClass = 'Y'
   
   
   return
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot insert PR Craft Items!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btPRCIu    Script Date: 8/28/99 9:38:10 AM ******/
   CREATE  trigger [dbo].[btPRCIu] on [dbo].[bPRCI] for UPDATE as
   

/*-----------------------------------------------------------------
    *  Created: EN 4/17/00
    *  Modified:	EN 10/09/00 - Checking for key changes incorrectly
    *				EN 01/28/03 - issue 23061  added isnull check, with (nolock), and dbo
    *
    * Cannot change primary key.
    * Validate VendorGroup and Vendor.
    * Inserts HQ Master Audit entry.
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   /* check for key changes */
   if update(PRCo)
       begin
       select @validcnt = count(*) from deleted d
            join inserted i on d.PRCo = i.PRCo
       if @validcnt <> @numrows
        	begin
        	select @errmsg = 'Cannot change PR Company '
        	goto error
        	end
       end
   if update(Craft)
       begin
       select @validcnt = count(*) from deleted d
            join inserted i on d.PRCo = i.PRCo and d.Craft = i.Craft
       if @validcnt <> @numrows
        	begin
        	select @errmsg = 'Cannot change Craft '
        	goto error
        	end
       end
   if update(EDLType)
       begin
       select @validcnt = count(*) from deleted d
            join inserted i on d.PRCo = i.PRCo and d.Craft = i.Craft and d.EDLType = i.EDLType
       if @validcnt <> @numrows
        	begin
        	select @errmsg = 'Cannot change EDLType '
        	goto error
        	end
       end
   if update(EDLCode)
       begin
       select @validcnt = count(*) from deleted d
            join inserted i on d.PRCo = i.PRCo and d.Craft = i.Craft and d.EDLType = i.EDLType and d.EDLCode = i.EDLCode
       if @validcnt <> @numrows
        	begin
        	select @errmsg = 'Cannot change EDLCode '
        	goto error
        	end
       end
   if update(Factor)
       begin
       select @validcnt = count(*) from deleted d
            join inserted i on d.PRCo = i.PRCo and d.Craft = i.Craft and d.EDLType = i.EDLType and d.EDLCode = i.EDLCode
               and d.Factor = i.Factor
       if @validcnt <> @numrows
        	begin
        	select @errmsg = 'Cannot change Factor '
        	goto error
        	end
       end
   
   /* validate Vendor Group */
   select @validcnt = count(*) from inserted i where i.VendorGroup is not null
   select @validcnt2 = count(*) from dbo.bHQGP c with (nolock) join inserted i on c.Grp = i.VendorGroup where i.VendorGroup is not null
   if @validcnt <> @validcnt2
   	begin
   	select @errmsg = 'Invalid Vendor Group '
   	goto error
   	end
   
   /*validate vendor */
   select @validcnt = count(*) from inserted i where i.Vendor is not null
   select @validcnt2 = count(*) from dbo.bAPVM r with (nolock)
           JOIN inserted i on i.VendorGroup=r.VendorGroup and i.Vendor=r.Vendor where i.Vendor is not null
   if @validcnt <> @validcnt2
    	begin
    	select @errmsg = 'Invalid Vendor '
    	goto error
    	end
   
   /* Insert records into HQMA for changes made to audited fields */
   if exists (select * from inserted i join dbo.bPRCO a on a.PRCo = i.PRCo where a.AuditCraftClass = 'Y')
   	begin
       insert into dbo.bHQMA select 'bPRCI',
       	'Craft:' + i.Craft + ' EDLType:' + i.EDLType +
           ' EDLCode:' + convert(varchar(10),i.EDLCode) + ' Factor:' + convert(varchar(10),i.Factor),
       	i.PRCo, 'C','Old Rate', convert(varchar(15),d.OldRate), Convert(varchar(15),i.OldRate),
       	getdate(), SUSER_SNAME()
       	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.Craft = d.Craft and i.EDLType = d.EDLType and
           i.EDLCode = d.EDLCode and i.Factor = d.Factor
           join dbo.PRCO p on i.PRCo = p.PRCo
           where i.OldRate <> d.OldRate and p.AuditCraftClass='Y'
       insert into dbo.bHQMA select 'bPRCI',
       	'Craft:' + i.Craft + ' EDLType:' + i.EDLType +
           ' EDLCode:' + convert(varchar(10),i.EDLCode) + ' Factor:' + convert(varchar(10),i.Factor),
       	i.PRCo, 'C','New Rate', convert(varchar(15),d.NewRate), Convert(varchar(15),i.NewRate),
       	getdate(), SUSER_SNAME()
       	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.Craft = d.Craft and i.EDLType = d.EDLType and
           i.EDLCode = d.EDLCode and i.Factor = d.Factor
           join dbo.PRCO p on i.PRCo = p.PRCo
           where i.NewRate <> d.NewRate and p.AuditCraftClass='Y'
       insert into dbo.bHQMA select 'bPRCI',
       	'Craft:' + i.Craft + ' EDLType:' + i.EDLType +
           ' EDLCode:' + convert(varchar(10),i.EDLCode) + ' Factor:' + convert(varchar(10),i.Factor),
       	i.PRCo, 'C','Vendor Group', convert(varchar(3),d.VendorGroup), convert(varchar(3),i.VendorGroup),
       	getdate(), SUSER_SNAME()
       	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.Craft = d.Craft and i.EDLType = d.EDLType and
           i.EDLCode = d.EDLCode and i.Factor = d.Factor
           join dbo.PRCO p on i.PRCo = p.PRCo
           where isnull(i.VendorGroup,0) <> isnull(d.VendorGroup,0) and p.AuditCraftClass='Y'
       insert into dbo.bHQMA select 'bPRCI',
       	'Craft:' + i.Craft + ' EDLType:' + i.EDLType +
           ' EDLCode:' + convert(varchar(10),i.EDLCode) + ' Factor:' + convert(varchar(10),i.Factor),
       	i.PRCo, 'C','Vendor', convert(varchar(6),d.Vendor), convert(varchar(6),i.Vendor),
       	getdate(), SUSER_SNAME()
       	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.Craft = d.Craft and i.EDLType = d.EDLType and
           i.EDLCode = d.EDLCode and i.Factor = d.Factor
           join dbo.PRCO p on i.PRCo = p.PRCo
           where isnull(i.Vendor,0) <> isnull(d.Vendor,0) and p.AuditCraftClass='Y'
       end
   
   
   return
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot update PR Craft Items!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
  
 



GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPRCI] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPRCI] ON [dbo].[bPRCI] ([PRCo], [Craft], [EDLType], [EDLCode], [Factor]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
