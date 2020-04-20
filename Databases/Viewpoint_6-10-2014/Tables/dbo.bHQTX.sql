CREATE TABLE [dbo].[bHQTX]
(
[TaxGroup] [dbo].[bGroup] NOT NULL,
[TaxCode] [dbo].[bTaxCode] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[MultiLevel] [dbo].[bYN] NOT NULL,
[OldRate] [dbo].[bRate] NULL,
[NewRate] [dbo].[bRate] NULL,
[EffectiveDate] [dbo].[bDate] NULL,
[GLAcct] [dbo].[bGLAcct] NULL,
[Phase] [dbo].[bPhase] NULL,
[JCCostType] [dbo].[bJCCType] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[ValueAdd] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bHQTX_ValueAdd] DEFAULT ('N'),
[GST] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bHQTX_GST] DEFAULT ('N'),
[ExpenseTax] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bHQTX_ExpenseTax] DEFAULT ('N'),
[InclGSTinPST] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bHQTX_InclGSTinPST] DEFAULT ('N'),
[RetgGLAcct] [dbo].[bGLAcct] NULL,
[DbtGLAcct] [dbo].[bGLAcct] NULL,
[DbtRetgGLAcct] [dbo].[bGLAcct] NULL,
[CrdRetgGSTGLAcct] [dbo].[bGLAcct] NULL,
[udIsActive] [dbo].[bYN] NULL CONSTRAINT [DF__bHQTX__udIsActive__DEFAULT] DEFAULT ('Y'),
[udReportingCode] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[udCityId] [varchar] (6) COLLATE Latin1_General_BIN NULL,
[udStateSpecTax] [varchar] (10) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   
   
   /****** Object:  Trigger dbo.btHQTXd    Script Date: 8/28/99 9:37:36 AM ******/
   CREATE      trigger [dbo].[btHQTXd] on [dbo].[bHQTX] for DELETE as
   

/*----------------------------------------------------------
    *  Created by ??
    *  Modified by:  CMW 04/10/02 - Replaced NULL for HQMA.Company with MaterialGroup (issue # 16840).
    *                CMW 07/12/02 - Fixed multiple entry problem (issue # 17902).
    *                CMW 08/12/02 - Fixed string/integer problem (issue # 18249).
    *                CMW 08/16/02 - Fixed HQMA description format (issue # 18279).
    *
    *	This trigger rejects delete in bHQTX (HQ Tax Codes)
    *	if a dependent record is found in:
    *
    *		HQTL - Tax Links
    *
    *	Audit deletions if any HQ Company using the Tax Code has the
    *	AuditTax option set.
    */---------------------------------------------------------
   declare @errmsg varchar(255), @numrows int
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   /* check HQ Tax Links */
   if exists(select * from bHQTL g, deleted d where
   	(g.TaxGroup = d.TaxGroup and g.TaxCode = d.TaxCode)
   	or (g.TaxGroup = d.TaxGroup and g.TaxLink = d.TaxCode))
   	begin
   	select @errmsg = 'Tax Code is linked with others'
   	goto error
   	end
   
   /* Audit HQ Tax deletions */
   insert into bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bHQTX', 'TaxGroup: ' + convert(varchar(3),d.TaxGroup) + '  Tax Code: ' + min(d.TaxCode),
           d.TaxGroup, 'D', null, null, null, getdate(), SUSER_SNAME()
   		from deleted d, bHQCO c
   		where d.TaxGroup = c.TaxGroup and c.AuditTax = 'Y'
           group by d.TaxGroup
   return
   error:
   	select @errmsg = @errmsg + ' - cannot delete HQ Tax Code!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btHQTXi    Script Date: 8/28/99 9:37:36 AM ******/
CREATE trigger [dbo].[btHQTXi] on [dbo].[bHQTX] for INSERT as
   
/*-----------------------------------------------------------------
*  Created ??
*  Modified by: CMW 04/10/02 - Replaced NULL for HQMA.Company with MaterialGroup.
*                            - Changed ' to '.  (issue # 16840)
*               CMW 07/12/02 - fixed multiple entry problem (issue # 17902).
*               CMW 08/12/02 - Fixed string/integer problem (issue # 18249).
*               CMW 08/16/02 - Fixed description format (issue # 18279).
*		TJL 07/09/08 - Issue #127263, International Sales Tax
*
*	This trigger rejects insertion in bHQTX (Tax Codes)
*	if any of the following error conditions exist:
*
*		Invalid TaxGroup
*		Rates and Effective Date must be null if MultiLevel = 'Y'
*
*	Audit inserts if any HQ Company has the AuditTax option set.
*/----------------------------------------------------------------
declare @numrows int, @validcnt int, @validcnt2 int, @validcnt3 int, @nullcnt int, @errmsg varchar(255)

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

/* validate TaxGroup */
select @validcnt = count(*) 
from bHQGP g, inserted i
where g.Grp = i.TaxGroup
if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid Tax Group'
   	goto error
   	end

if exists(select * from inserted where MultiLevel = 'Y' and ((OldRate is not null) or (NewRate is not null)
   	or (EffectiveDate is not null)))
   	begin
   	select @errmsg = 'Multi-level Tax codes cannot have Rates or Effective Date'
   	goto error
   	end

/* Validate MultiLevel, VAT, GST must be set correctly to allow ExpenseTax */
select @nullcnt = count(1)
from inserted i
where i.MultiLevel = 'Y' and ExpenseTax = 'N'

select @validcnt = count(1)
from inserted i
where i.MultiLevel = 'N' and (i.ValueAdd = 'Y' and i.GST = 'Y') and ExpenseTax = 'N'

select @validcnt2 = count(1)
from inserted i
where i.MultiLevel = 'N' and (i.ValueAdd = 'Y' and i.GST = 'Y') and ExpenseTax = 'Y'

select @validcnt3 = count(1)
from inserted i
where i.MultiLevel = 'N' and (i.ValueAdd = 'N' or i.GST = 'N') and ExpenseTax = 'N'

if @nullcnt + @validcnt + @validcnt2 + @validcnt3 <> @numrows
	begin
	select @errmsg = 'Expense Tax Paid cannot be selected when MultiLevel, ValueAdd, and GST are not setup properly'
	goto error
	end

/*  Validate ExpenseTax when 'N' make sure Debit GL Account and Debit Retg GL Account are empty */
select @validcnt = count(1)
from inserted i
where i.ExpenseTax = 'Y'

select @validcnt2 = count(1)
from inserted i
where i.ExpenseTax = 'N' and (i.DbtGLAcct is null and i.DbtRetgGLAcct is null)

if @validcnt + @validcnt2 <> @numrows
	begin
	select @errmsg = 'Debit GL Account and Debit Retg GL Account cannot exist when Expense Tax Paid has not been selected'
	goto error
	end

/* Validate ExpenseTax when 'Y' make sure that a Debit GL Account is present */
select @validcnt = count(1)
from inserted i
where i.ExpenseTax = 'N'

select @validcnt2 = count(1)
from inserted i
where i.ExpenseTax = 'Y' and i.DbtGLAcct is not null

if @validcnt + @validcnt2 <> @numrows
	begin
	select @errmsg = 'Debit GL Account is required when Expense Tax Paid has been selected'
	goto error
	end

/**************************** Validate GL Accounts ********************************/
-- Because HQTX is TaxGroup based (No GLCo to work with), GL Account validation will be
-- limited to the presence of the GL Account value somewhere in bGLAC table.  We are not 
-- able to specifically validate the account against a specific GLCo and therefore cannot 
-- validate "Account Type", "Active Status", or "SubType" values.

/* Validate Credit GL Account */
select @validcnt = count(distinct g.GLAcct) -- GLAcct might be used by more then one Company
from dbo.bGLAC (nolock) g
join inserted i on i.GLAcct = g.GLAcct
select @nullcnt = count(1) from inserted where GLAcct is null
if @validcnt + @nullcnt <> @numrows
	begin
	select @errmsg = 'Invalid Credit GL Account'
	goto error
	end

/* Validate Credit Retg GL Account */
select @validcnt = count(distinct g.GLAcct) -- GLAcct might be used by more then one Company
from dbo.bGLAC (nolock) g
join inserted i on i.RetgGLAcct = g.GLAcct
select @nullcnt = count(1) from inserted where RetgGLAcct is null
if @validcnt + @nullcnt <> @numrows
	begin
	select @errmsg = 'Invalid Credit Retainage GL Account'
	goto error
	end

/* Validate Debit GL Account */
select @validcnt = count(distinct g.GLAcct) -- GLAcct might be used by more then one Company
from dbo.bGLAC (nolock) g
join inserted i on i.DbtGLAcct = g.GLAcct
select @nullcnt = count(1) from inserted where DbtGLAcct is null
if @validcnt + @nullcnt <> @numrows
	begin
	select @errmsg = 'Invalid Debit GL Account'
	goto error
	end

/* Validate Debit Retg GL Account */
select @validcnt = count(distinct g.GLAcct) -- GLAcct might be used by more then one Company
from dbo.bGLAC (nolock) g
join inserted i on i.DbtRetgGLAcct = g.GLAcct
select @nullcnt = count(1) from inserted where DbtRetgGLAcct is null
if @validcnt + @nullcnt <> @numrows
	begin
	select @errmsg = 'Invalid Debit Retainage GL Account'
	goto error
	end
 
/* add HQ Master Audit entry */
insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bHQTX',  'TaxGroup: ' + convert(varchar(3), i.TaxGroup) + ' Tax Code: ' + min(i.TaxCode),
	i.TaxGroup, 'A', null, null, null, getdate(), SUSER_SNAME() from inserted i, bHQCO h
where i.TaxGroup = h.TaxGroup and AuditTax = 'Y'
group by i.TaxGroup

return
error:
select @errmsg = @errmsg + ' - cannot insert Tax Code!'
RAISERROR(@errmsg, 11, -1);
rollback transaction
   
   
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
/****** Object:  Trigger dbo.btHQTXu    Script Date: 8/28/99 9:37:36 AM ******/
CREATE   trigger [dbo].[btHQTXu] on [dbo].[bHQTX] for UPDATE as
   

/*-----------------------------------------------------------------
*  Created by:  ??
*  Modified by: CMW 04/10/02 - Replaced NULL for HQMA.Company with MaterialGroup (issue # 16840).
*               CMW 08/12/02 - Fixed string/integer problem (issue # 18249).
*               CMW 08/16/02 - Fixed HQMA description format (issue # 18279).
*		TJL 05/15/08 - Issue #127263, International Sales Tax
*
*	This trigger rejects update in bHQTX (HQ Tax Codes)
*	if any of the following error conditions exist:
*
*		Cannot change primary key - TaxGroup/TaxCode
*		Cannot change MultiLevel if exists in bHQTL
*
*	Audit inserts if any HQ Company has the AuditTax option set.
*/----------------------------------------------------------------

declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int, @validcnt3 int, @nullcnt int

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

/* reject key changes */
select @validcnt = count(*) from deleted d, inserted i
where d.TaxGroup = i.TaxGroup and d.TaxCode = i.TaxCode
if @numrows <> @validcnt
   	begin
   	select @errmsg = 'Cannot change Tax Group or Tax Code'
   	goto error
   	end

if exists(select * from inserted i, bHQTL t
   		where i.TaxGroup = t.TaxGroup and i.TaxCode = t.TaxCode
   		and i.MultiLevel = 'N')
   	begin
   	select @errmsg = 'Tax Code has links, cannot be changed to single-level'
   	goto error
   	end

if exists(select * from inserted i, bHQTL t
   	where i.TaxGroup = t.TaxGroup and i.TaxCode = t.TaxLink
   		and i.MultiLevel = 'Y')
   	begin
   	select @errmsg = 'Tax Code has been linked to another, cannot be changed to multi-level'
   	goto error
   	end

/* Validate MultiLevel, VAT, GST must be set correctly to allow ExpenseTax */
select @nullcnt = count(1)
from inserted i
where i.MultiLevel = 'Y' and ExpenseTax = 'N'

select @validcnt = count(1)
from inserted i
where i.MultiLevel = 'N' and (i.ValueAdd = 'Y' and i.GST = 'Y') and ExpenseTax = 'N'

select @validcnt2 = count(1)
from inserted i
where i.MultiLevel = 'N' and (i.ValueAdd = 'Y' and i.GST = 'Y') and ExpenseTax = 'Y'

select @validcnt3 = count(1)
from inserted i
where i.MultiLevel = 'N' and (i.ValueAdd = 'N' or i.GST = 'N') and ExpenseTax = 'N'

if @nullcnt + @validcnt + @validcnt2 + @validcnt3 <> @numrows
	begin
	select @errmsg = 'Expense Tax Paid cannot be selected when MultiLevel, ValueAdd, and GST are not setup properly'
	goto error
	end

/*  Validate ExpenseTax when 'N' make sure Debit GL Account and Debit Retg GL Account are empty */
select @validcnt = count(1)
from inserted i
where i.ExpenseTax = 'Y'

select @validcnt2 = count(1)
from inserted i
where i.ExpenseTax = 'N' and (i.DbtGLAcct is null and i.DbtRetgGLAcct is null)

if @validcnt + @validcnt2 <> @numrows
	begin
	select @errmsg = 'Debit GL Account and Debit Retg GL Account cannot exist when Expense Tax Paid has not been selected'
	goto error
	end

/* Validate ExpenseTax when 'Y' make sure that a Debit GL Account is present */
select @validcnt = count(1)
from inserted i
where i.ExpenseTax = 'N'

select @validcnt2 = count(1)
from inserted i
where i.ExpenseTax = 'Y' and i.DbtGLAcct is not null

if @validcnt + @validcnt2 <> @numrows
	begin
	select @errmsg = 'Debit GL Account is required when Expense Tax Paid has been selected'
	goto error
	end

/**************************** Validate GL Accounts ********************************/
-- Because HQTX is TaxGroup based (No GLCo to work with), GL Account validation will be
-- limited to the presence of the GL Account value somewhere in bGLAC table.  We are not 
-- able to specifically validate the account against a specific GLCo and therefore cannot 
-- validate "Account Type", "Active Status", or "SubType" values.

/* Validate Credit GL Account */
select @validcnt = count(distinct g.GLAcct) -- GLAcct might be used by more then one Company
from dbo.bGLAC (nolock) g
join inserted i on i.GLAcct = g.GLAcct
select @nullcnt = count(1) from inserted where GLAcct is null
if @validcnt + @nullcnt <> @numrows
	begin
	select @errmsg = 'Invalid Credit GL Account'
	goto error
	end

/* Validate Credit Retg GL Account */
select @validcnt = count(distinct g.GLAcct) -- GLAcct might be used by more then one Company
from dbo.bGLAC (nolock) g
join inserted i on i.RetgGLAcct = g.GLAcct
select @nullcnt = count(1) from inserted where RetgGLAcct is null
if @validcnt + @nullcnt <> @numrows
	begin
	select @errmsg = 'Invalid Credit Retainage GL Account'
	goto error
	end

/* Validate Debit GL Account */
select @validcnt = count(distinct g.GLAcct) -- GLAcct might be used by more then one Company
from dbo.bGLAC (nolock) g
join inserted i on i.DbtGLAcct = g.GLAcct
select @nullcnt = count(1) from inserted where DbtGLAcct is null
if @validcnt + @nullcnt <> @numrows
	begin
	select @errmsg = 'Invalid Debit GL Account'
	goto error
	end

/* Validate Debit Retg GL Account */
select @validcnt = count(distinct g.GLAcct) -- GLAcct might be used by more then one Company
from dbo.bGLAC (nolock) g
join inserted i on i.DbtRetgGLAcct = g.GLAcct
select @nullcnt = count(1) from inserted where DbtRetgGLAcct is null
if @validcnt + @nullcnt <> @numrows
	begin
	select @errmsg = 'Invalid Debit Retainage GL Account'
	goto error
	end

/* update HQ Master Audit if any company using this Tax Group has auditing turned on */
if not exists(select * from inserted i, bHQCO c where i.TaxGroup = c.TaxGroup
	and c.AuditTax = 'Y') return
insert into bHQMA select 'bHQTX', 'TaxGroup: ' + convert(varchar(3),i.TaxGroup) + ' Tax Code: ' + min(i.TaxCode),
	i.TaxGroup, 'C', 'Description', min(d.Description), min(i.Description), getdate(), SUSER_SNAME()
from inserted i, deleted d, bHQCO c
where i.TaxGroup = d.TaxGroup and i.TaxCode = d.TaxCode and i.Description <> d.Description
	and i.TaxGroup = c.TaxGroup and c.AuditTax = 'Y'
group by i.TaxGroup

insert into bHQMA select 'bHQTX', 'TaxGroup: ' + convert(varchar(3),i.TaxGroup) + ' Tax Code: ' + min(i.TaxCode),
	i.TaxGroup, 'C', 'MultiLevel', min(d.MultiLevel), min(i.MultiLevel), getdate(), SUSER_SNAME()
from inserted i, deleted d, bHQCO c
where i.TaxGroup = d.TaxGroup and i.TaxCode = d.TaxCode and i.MultiLevel <> d.MultiLevel
	and i.TaxGroup = c.TaxGroup and c.AuditTax = 'Y'
group by i.TaxGroup

insert into bHQMA select 'bHQTX', 'TaxGroup: ' + convert(varchar(3),i.TaxGroup) + ' Tax Code: ' + min(i.TaxCode),
	i.TaxGroup, 'C', 'Old Rate', convert(varchar(12),min(d.OldRate)), convert(varchar(12),min(i.OldRate)),
	getdate(), SUSER_SNAME()
from inserted i, deleted d, bHQCO c
where i.TaxGroup = d.TaxGroup and i.TaxCode = d.TaxCode and i.OldRate <> d.OldRate
	and i.TaxGroup = c.TaxGroup and c.AuditTax = 'Y'
group by i.TaxGroup

insert into bHQMA select 'bHQTX', 'TaxGroup: ' + convert(varchar(3),i.TaxGroup) + ' Tax Code: ' + min(i.TaxCode),
	i.TaxGroup, 'C', 'New Rate', convert(varchar(12),min(d.NewRate)), convert(varchar(12),min(i.NewRate)),
	getdate(), SUSER_SNAME()
from inserted i, deleted d, bHQCO c
where i.TaxGroup = d.TaxGroup and i.TaxCode = d.TaxCode and i.NewRate <> d.NewRate
	and i.TaxGroup = c.TaxGroup and c.AuditTax = 'Y'
group by i.TaxGroup

insert into bHQMA select 'bHQTX', 'TaxGroup: ' + convert(varchar(3),i.TaxGroup) + ' Tax Code: ' + min(i.TaxCode),
	i.TaxGroup, 'C', 'Effective Date', min(d.EffectiveDate), min(i.EffectiveDate), getdate(), SUSER_SNAME()
from inserted i, deleted d, bHQCO c
where i.TaxGroup = d.TaxGroup and i.TaxCode = d.TaxCode and i.EffectiveDate <> d.EffectiveDate
	and i.TaxGroup = c.TaxGroup and c.AuditTax = 'Y'
group by i.TaxGroup

insert into bHQMA select 'bHQTX', 'TaxGroup: ' + convert(varchar(3),i.TaxGroup) + ' Tax Code: ' + min(i.TaxCode),
	i.TaxGroup, 'C', 'GL Account', min(d.GLAcct), min(i.GLAcct), getdate(), SUSER_SNAME()
from inserted i, deleted d, bHQCO c
where i.TaxGroup = d.TaxGroup and i.TaxCode = d.TaxCode and i.GLAcct <> d.GLAcct
	and i.TaxGroup = c.TaxGroup and c.AuditTax = 'Y'
group by i.TaxGroup

insert into bHQMA select 'bHQTX', 'TaxGroup: ' + convert(varchar(3),i.TaxGroup) + ' Tax Code: ' + min(i.TaxCode),
	i.TaxGroup, 'C', 'Phase', min(d.Phase), min(i.Phase), getdate(), SUSER_SNAME()
from inserted i, deleted d, bHQCO c
where i.TaxGroup = d.TaxGroup and i.TaxCode = d.TaxCode and i.Phase <> d.Phase
	and i.TaxGroup = c.TaxGroup and c.AuditTax = 'Y'
group by i.TaxGroup

insert into bHQMA select 'bHQTX', 'TaxGroup: ' + convert(varchar(3),i.TaxGroup) + ' Tax Code: ' + min(i.TaxCode),
	i.TaxGroup, 'C', 'JC Cost Type', convert(varchar(3),min(d.JCCostType)), convert(varchar(3),min(i.JCCostType)),
getdate(), SUSER_SNAME()
from inserted i, deleted d, bHQCO c
where i.TaxGroup = d.TaxGroup and i.TaxCode = d.TaxCode and i.JCCostType <> d.JCCostType
	and i.TaxGroup = c.TaxGroup and c.AuditTax = 'Y'
group by i.TaxGroup

insert into bHQMA select 'bHQTX', 'TaxGroup: ' + convert(varchar(3),i.TaxGroup) + ' Tax Code: ' + min(i.TaxCode),
	i.TaxGroup, 'C', 'ValueAdd', min(d.ValueAdd), min(i.ValueAdd), getdate(), SUSER_SNAME()
from inserted i, deleted d, bHQCO c
where i.TaxGroup = d.TaxGroup and i.TaxCode = d.TaxCode and i.ValueAdd <> d.ValueAdd
	and i.TaxGroup = c.TaxGroup and c.AuditTax = 'Y'
group by i.TaxGroup

insert into bHQMA select 'bHQTX', 'TaxGroup: ' + convert(varchar(3),i.TaxGroup) + ' Tax Code: ' + min(i.TaxCode),
	i.TaxGroup, 'C', 'GST', min(d.GST), min(i.GST), getdate(), SUSER_SNAME()
from inserted i, deleted d, bHQCO c
where i.TaxGroup = d.TaxGroup and i.TaxCode = d.TaxCode and i.GST <> d.GST
	and i.TaxGroup = c.TaxGroup and c.AuditTax = 'Y'
group by i.TaxGroup

insert into bHQMA select 'bHQTX', 'TaxGroup: ' + convert(varchar(3),i.TaxGroup) + ' Tax Code: ' + min(i.TaxCode),
	i.TaxGroup, 'C', 'Expense Tax', min(d.ExpenseTax), min(i.ExpenseTax), getdate(), SUSER_SNAME()
from inserted i, deleted d, bHQCO c
where i.TaxGroup = d.TaxGroup and i.TaxCode = d.TaxCode and i.ExpenseTax <> d.ExpenseTax
	and i.TaxGroup = c.TaxGroup and c.AuditTax = 'Y'
group by i.TaxGroup

insert into bHQMA select 'bHQTX', 'TaxGroup: ' + convert(varchar(3),i.TaxGroup) + ' Tax Code: ' + min(i.TaxCode),
	i.TaxGroup, 'C', 'Include GST in PST', min(d.InclGSTinPST), min(i.InclGSTinPST), getdate(), SUSER_SNAME()
from inserted i, deleted d, bHQCO c
where i.TaxGroup = d.TaxGroup and i.TaxCode = d.TaxCode and i.InclGSTinPST <> d.InclGSTinPST
	and i.TaxGroup = c.TaxGroup and c.AuditTax = 'Y'
group by i.TaxGroup

insert into bHQMA select 'bHQTX', 'TaxGroup: ' + convert(varchar(3),i.TaxGroup) + ' Tax Code: ' + min(i.TaxCode),
	i.TaxGroup, 'C', 'Retainage GL Account', min(d.RetgGLAcct), min(i.RetgGLAcct), getdate(), SUSER_SNAME()
from inserted i, deleted d, bHQCO c
where i.TaxGroup = d.TaxGroup and i.TaxCode = d.TaxCode and i.RetgGLAcct <> d.RetgGLAcct
	and i.TaxGroup = c.TaxGroup and c.AuditTax = 'Y'
group by i.TaxGroup

insert into bHQMA select 'bHQTX', 'TaxGroup: ' + convert(varchar(3),i.TaxGroup) + ' Tax Code: ' + min(i.TaxCode),
	i.TaxGroup, 'C', 'Debit GL Account', min(d.DbtGLAcct), min(i.DbtGLAcct), getdate(), SUSER_SNAME()
from inserted i, deleted d, bHQCO c
where i.TaxGroup = d.TaxGroup and i.TaxCode = d.TaxCode and i.DbtGLAcct <> d.DbtGLAcct
	and i.TaxGroup = c.TaxGroup and c.AuditTax = 'Y'
group by i.TaxGroup

insert into bHQMA select 'bHQTX', 'TaxGroup: ' + convert(varchar(3),i.TaxGroup) + ' Tax Code: ' + min(i.TaxCode),
	i.TaxGroup, 'C', 'Debit Retainage GLAcct', min(d.DbtRetgGLAcct), min(i.DbtRetgGLAcct), getdate(), SUSER_SNAME()
from inserted i, deleted d, bHQCO c
where i.TaxGroup = d.TaxGroup and i.TaxCode = d.TaxCode and i.DbtRetgGLAcct <> d.DbtRetgGLAcct
	and i.TaxGroup = c.TaxGroup and c.AuditTax = 'Y'
group by i.TaxGroup

return
error:
select @errmsg = @errmsg + ' - cannot update Tax Code!'
RAISERROR(@errmsg, 11, -1);
rollback transaction
   
   
   
   
   
   
   
  
 



GO
ALTER TABLE [dbo].[bHQTX] WITH NOCHECK ADD CONSTRAINT [CK_bHQTX_MultiLevel] CHECK (([MultiLevel]='Y' OR [MultiLevel]='N'))
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bHQTX] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biHQTX] ON [dbo].[bHQTX] ([TaxGroup], [TaxCode]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
