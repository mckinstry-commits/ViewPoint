CREATE TABLE [dbo].[bINLM]
(
[INCo] [dbo].[bCompany] NOT NULL,
[Loc] [dbo].[bLoc] NOT NULL,
[Description] [dbo].[bItemDesc] NULL,
[Active] [dbo].[bYN] NOT NULL,
[MailAddress] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[MailCity] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[MailState] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[MailZip] [dbo].[bZip] NULL,
[MailAddress2] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[ShipAddress] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[ShipCity] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[ShipState] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[ShipZip] [dbo].[bZip] NULL,
[ShipAddress2] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[LocGroup] [dbo].[bGroup] NOT NULL,
[TaxGroup] [dbo].[bGroup] NULL,
[TaxCode] [dbo].[bTaxCode] NULL,
[HaulTaxOpt] [tinyint] NOT NULL CONSTRAINT [DF_bINLM_HaulTaxOpt] DEFAULT ((0)),
[CostMethod] [tinyint] NULL,
[JCCo] [dbo].[bCompany] NULL,
[Job] [dbo].[bJob] NULL,
[EMCo] [dbo].[bCompany] NULL,
[Equipment] [dbo].[bEquip] NULL,
[RecType] [tinyint] NULL,
[PriceTemplate] [smallint] NULL,
[WghtOpt] [tinyint] NOT NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[InvGLAcct] [dbo].[bGLAcct] NOT NULL,
[AdjGLAcct] [dbo].[bGLAcct] NOT NULL,
[CostGLAcct] [dbo].[bGLAcct] NOT NULL,
[CostVarGLAcct] [dbo].[bGLAcct] NULL,
[MiscGLAcct] [dbo].[bGLAcct] NULL,
[TaxGLAcct] [dbo].[bGLAcct] NULL,
[CostProdGLAcct] [dbo].[bGLAcct] NULL,
[ValProdGLAcct] [dbo].[bGLAcct] NULL,
[ProdQtyGLAcct] [dbo].[bGLAcct] NULL,
[CustSalesGLAcct] [dbo].[bGLAcct] NULL,
[JobSalesGLAcct] [dbo].[bGLAcct] NULL,
[InvSalesGLAcct] [dbo].[bGLAcct] NULL,
[EquipSalesGLAcct] [dbo].[bGLAcct] NULL,
[CustQtyGLAcct] [dbo].[bGLAcct] NULL,
[JobQtyGLAcct] [dbo].[bGLAcct] NULL,
[InvQtyGLAcct] [dbo].[bGLAcct] NULL,
[CustHaulRevEquipGLAcct] [dbo].[bGLAcct] NULL,
[JobHaulRevEquipGLAcct] [dbo].[bGLAcct] NULL,
[InvHaulRevEquipGLAcct] [dbo].[bGLAcct] NULL,
[CustHaulRevOutGLAcct] [dbo].[bGLAcct] NULL,
[JobHaulRevOutGLAcct] [dbo].[bGLAcct] NULL,
[InvHaulRevOutGLAcct] [dbo].[bGLAcct] NULL,
[CustHaulExpEquipGLAcct] [dbo].[bGLAcct] NULL,
[JobHaulExpEquipGLAcct] [dbo].[bGLAcct] NULL,
[InvHaulExpEquipGLAcct] [dbo].[bGLAcct] NULL,
[CustHaulExpOutGLAcct] [dbo].[bGLAcct] NULL,
[JobHaulExpOutGLAcct] [dbo].[bGLAcct] NULL,
[InvHaulExpOutGLAcct] [dbo].[bGLAcct] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[ARDiscountGLAcct] [dbo].[bGLAcct] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[CMCo] [dbo].[bCompany] NULL,
[CMAcct] [dbo].[bCMAcct] NULL,
[InvReviewer] [char] (3) COLLATE Latin1_General_BIN NULL,
[PurReviewer] [char] (3) COLLATE Latin1_General_BIN NULL,
[CustMatlExpGLAcct] [dbo].[bGLAcct] NULL,
[JobMatlExpGLAcct] [dbo].[bGLAcct] NULL,
[InvMatlExpGLAcct] [dbo].[bGLAcct] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[ReviewerGroup] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[MailCountry] [char] (2) COLLATE Latin1_General_BIN NULL,
[ShipCountry] [char] (2) COLLATE Latin1_General_BIN NULL,
[CustSurchargeRevEquipGLAcct] [dbo].[bGLAcct] NULL,
[JobSurchargeRevEquipGLAcct] [dbo].[bGLAcct] NULL,
[InvSurchargeRevEquipGLAcct] [dbo].[bGLAcct] NULL,
[CustSurchargeRevOutGLAcct] [dbo].[bGLAcct] NULL,
[JobSurchargeRevOutGLAcct] [dbo].[bGLAcct] NULL,
[InvSurchargeRevOutGLAcct] [dbo].[bGLAcct] NULL,
[CustSurchargeExpOutGLAcct] [dbo].[bGLAcct] NULL,
[JobSurchargeExpOutGLAcct] [dbo].[bGLAcct] NULL,
[InvSurchargeExpOutGLAcct] [dbo].[bGLAcct] NULL,
[ServiceSalesGLAcct] [dbo].[bGLAcct] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE  trigger [dbo].[btINLMd] on [dbo].[bINLM] for DELETE as
   

/*--------------------------------------------------------------
    *  Created By: GG 03/06/00
    *  Modified:
    *
    *  Delete trigger for IN Location Master
    *
    *--------------------------------------------------------------*/
   declare @numrows int, @errmsg varchar(255)
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   -- check for use in other tables
   if exists(select * from deleted d
           join bINMT m on d.INCo = m.INCo and d.Loc = m.Loc)
       begin
       select @errmsg = 'Still has Materials'
       goto error
       end
   if exists(select * from deleted d
       join bINLO o on d.INCo = o.INCo and d.Loc = o.Loc)
       begin
       select @errmsg = 'Still has Category Overrides'
       goto error
       end
   if exists(select * from deleted d
       join bINLS s on d.INCo = s.INCo and d.Loc = s.Loc)
       begin
       select @errmsg = 'Still has Company Overrides'
       goto error
       end
   
   -- HQ Auditing
   insert bHQMA select 'bINLM','INCo:' + convert(varchar(3),d.INCo) + ' Loc:' + d.Loc,
       d.INCo, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
   from deleted d
   join bINCO c on d.INCo = c.INCo
   where c.AuditLoc = 'Y'   -- check audit
   
   return
   
   error:
      select @errmsg = @errmsg + ' - cannot delete IN Location'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

   
CREATE  trigger [dbo].[btINLMi] on [dbo].[bINLM] for INSERT as
/*--------------------------------------------------------------
* Created: GR 5/31/00
* Modified: GG 01/31/02 - #14177 - added CMCo and CMAcct, added validation
*			GG 04/20/07 - #30116 - data security review
*			Dan So 03/17/2008 - #127082 - country and state validation
*			GG 06/16/08 - #128324 - fix Country/State validation
*
* Insert trigger for IN Locations
* GL Accounts are not validated here, but will be checked when used.
*
* Adds to master audit table
*--------------------------------------------------------------*/
declare @numrows int, @errmsg varchar(255), @validcnt int, @validcnt2 int, @nullcnt int

select @numrows = @@rowcount
if @numrows = 0 return

set nocount on
   
-- validate IN Company
select @validcnt = count(*) from dbo.bINCO c (nolock) join inserted i on i.INCo = c.INCo
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid IN Company '
	goto error
	end
-- validate Location Group
select @validcnt = count(*) from dbo.bINLG g (nolock) join inserted i on i.INCo = g.INCo and i.LocGroup = g.LocGroup
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid Location Group '
	goto error
	end
--validate Tax Group and Code
select @nullcnt = count(*) from inserted where TaxCode is null
select @validcnt = count(*) from dbo.bHQTX t (nolock) join inserted i on i.TaxGroup = t.TaxGroup and i.TaxCode = t.TaxCode
if @validcnt + @nullcnt <> @numrows
	begin
	select @errmsg = 'Invalid Tax Group and Tax Code combination '
	goto error
	end 
-- validate Haul Tax option
select @validcnt = count(*) from inserted where HaulTaxOpt in (0,1,2) 
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid Haul Tax option must be 0, 1, or 2 '
	goto error
	end
-- validate Cost Method
select @validcnt = count(*) from inserted where CostMethod in (0,1,2,3) or CostMethod is null
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid Cost Method must be 0, 1, 2, 3, or null '
	goto error
	end
--validate JC Co# and Job
select @nullcnt = count(*) from inserted where Job is null
select @validcnt = count(*) from dbo.bJCJM j (nolock) join inserted i on i.JCCo = j.JCCo and i.Job = j.Job
if @validcnt + @nullcnt <> @numrows
	begin
	select @errmsg = 'Invalid JC Co# and Job combination '
	goto error
	end 
--validate EM Co# and Equipment
select @nullcnt = count(*) from inserted where Equipment is null
select @validcnt = count(*) from dbo.bEMEM e (nolock) join inserted i on i.EMCo = e.EMCo and i.Equipment = e.Equipment
if @validcnt + @nullcnt <> @numrows
	begin
	select @errmsg = 'Invalid EM Co# and Equipment combination '
	goto error
	end 
--validate CM Co# and CM Account
select @nullcnt = count(*) from inserted where CMAcct is null
select @validcnt = count(*) from dbo.bCMAC c (nolock) join inserted i on i.CMCo = c.CMCo and i.CMAcct = c.CMAcct
if @validcnt + @nullcnt <> @numrows
	begin
	select @errmsg = 'Invalid CM Co# and CM Account combination '
	goto error
	end 
   
---------------------------
-- VALIDATE MAIL COUNTRY --
---------------------------
select @validcnt = count(1)
from dbo.bHQCountry c (nolock) 
join inserted i on i.MailCountry = c.Country
select @nullcnt = count(1) from inserted where MailCountry is null
if @validcnt + @nullcnt <> @numrows
	begin
	select @errmsg = 'Invalid Mail Country'
	goto error
	end
-- validate MailCountry/State combinations
select @validcnt = count(1) -- Country/State combos are unique
from inserted i
join dbo.bHQCO c (nolock) on c.HQCo = i.INCo	-- join to get Default Country
join dbo.bHQST s (nolock) on isnull(i.MailCountry,c.DefaultCountry) = s.Country and i.MailState = s.State
select @nullcnt = count(1) from inserted where MailState is null
if @validcnt + @nullcnt <> @numrows
	begin
	select @errmsg = 'Invalid Mail Country and State combination'
	goto error
	end
---------------------------
-- VALIDATE SHIP COUNTRY --
---------------------------
select @validcnt = count(1)
from dbo.bHQCountry c (nolock) 
join inserted i on i.ShipCountry = c.Country
select @nullcnt = count(1) from inserted where ShipCountry is null
if @validcnt + @nullcnt <> @numrows
	begin
	select @errmsg = 'Invalid Ship Country'
	goto error
	end
-- validate ShipCountry/State combinations
select @validcnt = count(1) -- Country/State combos are unique
from inserted i
join dbo.bHQCO c (nolock) on c.HQCo = i.INCo	-- join to get Default Country
join dbo.bHQST s (nolock) on isnull(i.ShipCountry,c.DefaultCountry) = s.Country and i.ShipState = s.State
select @nullcnt = count(1) from inserted where ShipState is null
if @validcnt + @nullcnt <> @numrows
	begin
	select @errmsg = 'Invalid Ship Country and State combination'
	goto error
	end

-- HQ Auditing
INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
SELECT 'bINLM',' Location: ' + i.Loc, i.INCo, 'A', NULL, NULL, NULL, getdate(), SUSER_SNAME()
FROM inserted i
join bINCO c on c.INCo = i.INCo
where c.AuditLoc = 'Y'

--#30116 - initialize Data Security
declare @dfltsecgroup smallint
select @dfltsecgroup = DfltSecurityGroup
from dbo.DDDTSecurable (nolock) where Datatype = 'bLoc' and Secure = 'Y'
if @dfltsecgroup is not null
	begin
	insert dbo.vDDDS (Datatype, Qualifier, Instance, SecurityGroup)
	select 'bLoc', i.INCo, i.Loc, @dfltsecgroup
	from inserted i 
	where not exists(select 1 from dbo.vDDDS s (nolock) where s.Datatype = 'bLoc' and s.Qualifier = i.INCo 
						and s.Instance = i.Loc and s.SecurityGroup = @dfltsecgroup)
	end

return

error:
	select @errmsg = @errmsg + ' - cannot insert IN Locations.'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

 
CREATE trigger [dbo].[btINLMu] on [dbo].[bINLM] for UPDATE as
/*--------------------------------------------------------------
* Created : GR 5/31/00
* Modified:	GG 01/31/02 - #14177 - audit new columns CMCo and CMAcct
*			GG 02/14/05 - #19185 - audit new columns; CustMatlExpGLAcct, JobMatlExpGLAcct, InvMatlExpGLAcct
*			Dan So 03/17/2008 - #127082 - country and state validation
*			GG 06/16/08 - #128324 - fix Country/State validation
*			TRL 03/23/10 - #129350 - Added MSSurcharge GL Accnt Auditing
*
*  Update trigger for IN Locations
*
*--------------------------------------------------------------*/
   declare @numrows int, @errmsg varchar(255), @validcnt int, @validcnt2 int, @nullcnt int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   -- verify primary key not changed
   select @validcnt = count(*) from inserted i
   join deleted d on d.INCo = i.INCo and d.Loc=i.Loc
   if @validcnt <> @numrows
       begin
    	select @errmsg = 'Cannot change IN Company/Location '
    	goto error
    	end
   
---------------------------
-- VALIDATE MAIL COUNTRY --
---------------------------
if update(MailState) or update(MailCountry)
	begin
	select @validcnt = count(1) 
	from dbo.bHQCountry c with (nolock) 
	join inserted i on i.MailCountry = c.Country
	select @nullcnt = count(1) from inserted where MailCountry is null
	if @validcnt + @nullcnt <> @numrows
		begin
		select @errmsg = 'Invalid Mail Country'
		goto error
		end
	-- validate Mail Country/State combinations
	select @validcnt = count(1) -- Country/State combos are unique
	from inserted i
	join dbo.bHQCO c (nolock) on c.HQCo = i.INCo	-- join to get Default Country
	join dbo.bHQST s (nolock) on isnull(i.MailCountry,c.DefaultCountry) = s.Country and i.MailState = s.State
	select @nullcnt = count(1) from inserted where MailState is null
	if @validcnt + @nullcnt <> @numrows
		begin
		select @errmsg = 'Invalid Mail Country and State combination'
		goto error
		end
	end
---------------------------
-- VALIDATE SHIP COUNTRY --
---------------------------
if update(ShipState) or update(ShipCountry)
	begin
	select @validcnt = count(1) 
	from dbo.bHQCountry c with (nolock) 
	join inserted i on i.ShipCountry = c.Country
	select @nullcnt = count(1) from inserted where ShipCountry is null
	if @validcnt + @nullcnt <> @numrows
		begin
		select @errmsg = 'Invalid Ship Country'
		goto error
		end
	-- validate Ship Country/State combinations
	select @validcnt = count(1) -- Country/State combos are unique
	from inserted i
	join dbo.bHQCO c (nolock) on c.HQCo = i.INCo	-- join to get Default Country
	join dbo.bHQST s (nolock) on isnull(i.ShipCountry,c.DefaultCountry) = s.Country and i.ShipState = s.State
	select @nullcnt = count(1) from inserted where ShipState is null
	if @validcnt + @nullcnt <> @numrows
		begin
		select @errmsg = 'Invalid Ship Country and State combination'
		goto error
		end
	end


   -- HQ Auditing
  IF exists(select top 1 1 from inserted i 
       		join dbo.bINCO a (nolock) on i.INCo = a.INCo
       		where a.AuditLoc = 'Y')
   BEGIN
   	if update(Description)
   		begin
       	insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLM', ' Location: ' + i.Loc, i.INCo, 'C',
           	'Description', d.Description, i.Description, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.Description, '') <> isnull(i.Description, '') and a.AuditLoc = 'Y'
   		end
   	if update(Active)
   		begin
   		insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLM', ' Location: ' + i.Loc, i.INCo, 'C',
           	'Active', d.Active, i.Active, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where d.Active <> i.Active and a.AuditLoc = 'Y'
   		end
   	if update(MailAddress)
   		begin
       	insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLM', ' Location: ' + i.Loc, i.INCo, 'C',
           	'MailAddress', d.MailAddress, i.MailAddress, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.MailAddress, '') <> isnull(i.MailAddress, '') and a.AuditLoc = 'Y'
   		end
   	if update(MailCity)
   		begin
       	insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    		select 'bINLM', ' Location: ' + i.Loc, i.INCo, 'C',
           	'MailCity', d.MailCity, i.MailCity, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.MailCity, '') <> isnull(i.MailCity, '') and a.AuditLoc = 'Y'
   		end
   	if update(MailState)
   		begin
       	insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLM', ' Location: ' + i.Loc, i.INCo, 'C',
           	'MailState', d.MailState, i.MailState, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.MailState, '') <> isnull(i.MailState, '') and a.AuditLoc = 'Y'
   		end
   	if update(MailZip)
   		begin
       	insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLM', ' Location: ' + i.Loc, i.INCo, 'C',
           	'MailZip', d.MailZip, i.MailZip, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.MailZip,'') <> isnull(i.MailZip,'') and a.AuditLoc = 'Y'
   		end

	------------------
	-- MAIL COUNTRY --
	------------------
	IF UPDATE(MailCountry)
		BEGIN
			INSERT INTO dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
			     SELECT 'bINLM', ' Location: ' + i.Loc, i.INCo, 'C',
			            'MailCountry',  d.MailCountry, i.MailCountry, getdate(), SUSER_SNAME()
			       FROM Inserted i 
                   JOIN Deleted d ON d.INCo = i.INCo  
					AND d.Loc = i.Loc
			       JOIN bINCO a ON a.INCo = i.INCo
			      WHERE ISNULL(d.MailCountry,'') <> ISNULL(i.MailCountry,'')
					AND a.AuditLoc = 'Y'
		END

   	if update(MailAddress2)
   		begin
       	insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLM', ' Location: ' + i.Loc, i.INCo, 'C',
           	'MailAddress2', d.MailAddress2, i.MailAddress2, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.MailAddress2, '') <> isnull(i.MailAddress2, '') and a.AuditLoc = 'Y'
   		end
   	if update(ShipAddress)
   		begin
       	insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLM', ' Location: ' + i.Loc, i.INCo, 'C',
       		'ShipAddress', d.ShipAddress, i.ShipAddress, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.ShipAddress, '') <> isnull(i.ShipAddress, '') and a.AuditLoc = 'Y'
   		end
   	if update(ShipCity)
   		begin
       	insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLM', ' Location: ' + i.Loc, i.INCo, 'C',
       		'ShipCity', d.ShipCity, i.ShipCity, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.ShipCity, '') <> isnull(i.ShipCity, '') and a.AuditLoc = 'Y'
   		end
   	if update(ShipState)
   		begin
       	insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLM', ' Location: ' + i.Loc, i.INCo, 'C',
       		'ShipState', d.ShipState, i.ShipState, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.ShipState, '') <> isnull(i.ShipState, '') and a.AuditLoc = 'Y'
   		end
   	if update(ShipZip)
   		begin
       	insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLM', ' Location: ' + i.Loc, i.INCo, 'C',
       		'ShipZip', d.ShipZip, i.ShipZip, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.ShipZip, '') <> isnull(i.ShipZip, '') and a.AuditLoc = 'Y'
   		end

	------------------
	-- SHIP COUNTRY --
	------------------
   	IF UPDATE(ShipCountry)
   		BEGIN
       		INSERT INTO dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   			     SELECT 'bINLM', ' Location: ' + i.Loc, i.INCo, 'C',
       				    'ShipCountry', d.ShipCountry, i.ShipCountry, getdate(), SUSER_SNAME()
    			   FROM Inserted i
       		       JOIN Deleted d ON d.INCo = i.INCo 
					AND d.Loc = i.Loc
       			   JOIN dbo.bINCO a ON a.INCo = i.INCo
    			  WHERE ISNULL(d.ShipCountry, '') <> ISNULL(i.ShipCountry, '') 
				    AND a.AuditLoc = 'Y'
   		END

   	if update(ShipAddress2)
   		begin
       	insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLM', ' Location: ' + i.Loc, i.INCo, 'C',
       		'ShipAddress2', d.ShipAddress2, i.ShipAddress2, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.ShipAddress2, '') <> isnull(i.ShipAddress2, '') and a.AuditLoc = 'Y'
   		end
   	if update(LocGroup)
   		begin
       	insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLM', ' Location: ' + i.Loc, i.INCo, 'C',
           	'LocGroup', convert(varchar(5),d.LocGroup), convert(varchar(5),i.LocGroup), getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where d.LocGroup <> i.LocGroup and a.AuditLoc = 'Y'
   		end
   	if update(TaxGroup)
   		begin
       	insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLM', ' Location: ' + i.Loc, i.INCo, 'C',
           	'TaxGroup', convert(varchar(5),d.TaxGroup), convert(varchar(5),i.TaxGroup), getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.TaxGroup, 0) <> isnull(i.TaxGroup, 0) and a.AuditLoc = 'Y'
   		end
   	if update(TaxCode)
   		begin
       	insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLM', ' Location: ' + i.Loc, i.INCo, 'C',
           	'TaxCode', d.TaxCode, i.TaxCode, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.TaxCode, '') <> isnull(i.TaxCode, '') and a.AuditLoc = 'Y'
   		end
   	if update(HaulTaxOpt)
   		begin
       	insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLM', ' Location: ' + i.Loc, i.INCo, 'C',
           	'HaulTaxOpt', convert(varchar(5),d.HaulTaxOpt), convert(varchar(5),i.HaulTaxOpt), getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where d.HaulTaxOpt <> i.HaulTaxOpt and a.AuditLoc = 'Y'
   		end
   	if update(CostMethod)
   		begin
       	insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLM', ' Location: ' + i.Loc, i.INCo, 'C',
           	'CostMethod', convert(varchar(5),d.CostMethod), convert(varchar(5),i.CostMethod), getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.CostMethod, 0) <> isnull(i.CostMethod, 0) and a.AuditLoc = 'Y'
   		end
   	if update(JCCo)
   		begin
       	insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLM', ' Location: ' + i.Loc, i.INCo, 'C',
           	'JCCo', convert(varchar(5),d.JCCo), convert(varchar(5),i.JCCo), getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.JCCo, 0) <> isnull(i.JCCo, 0) and a.AuditLoc = 'Y'
   		end
   	if update(Job)
   		begin
       	insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLM', ' Location: ' + i.Loc, i.INCo, 'C',
           	'Job', d.Job, i.Job, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.Job, '') <> isnull(i.Job, '') and a.AuditLoc = 'Y'
   		end
   	if update(EMCo)
   		begin
       	insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLM', ' Location: ' + i.Loc, i.INCo, 'C',
           	'EMCo', convert(varchar(5),d.EMCo), convert(varchar(5),i.EMCo), getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.EMCo, 0) <> isnull(i.EMCo, 0) and a.AuditLoc = 'Y'
   		end
   	if update(Equipment)
   		begin
   	    insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLM', ' Location: ' + i.Loc, i.INCo, 'C',
           	'Equipment', d.Equipment, i.Equipment, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.Equipment, '') <> isnull(i.Equipment, '') and a.AuditLoc = 'Y'
   		end
   	if update(RecType)
   		begin
       	insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLM', ' Location: ' + i.Loc, i.INCo, 'C',
           	'RecType', convert(varchar(10),d.RecType), convert(varchar(10),i.RecType), getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.RecType, 0) <> isnull(i.RecType, 0) and a.AuditLoc = 'Y'
   		end
   	if update(PriceTemplate)
   		begin
       	insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLM', ' Location: ' + i.Loc, i.INCo, 'C',
           	'PriceTemplate', convert(varchar(10),d.PriceTemplate), convert(varchar(10),i.PriceTemplate), getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.PriceTemplate, 0) <> isnull(i.PriceTemplate, 0) and a.AuditLoc = 'Y'
   		end
   	if update(WghtOpt)
   		begin
       	insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLM', ' Location: ' + i.Loc, i.INCo, 'C',
           	'WghtOpt', convert(varchar(10),d.WghtOpt), convert(varchar(10),i.WghtOpt), getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc
       	join bINCO a on a.INCo = i.INCo
    		where d.WghtOpt <> i.WghtOpt and a.AuditLoc = 'Y'
   		end
   	if update(GLCo)
   		begin
   	    insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLM', ' Location: ' + i.Loc, i.INCo, 'C',
           	'GLCo', convert(varchar(5),d.GLCo), convert(varchar(5),i.GLCo), getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where d.GLCo <> i.GLCo and a.AuditLoc = 'Y'
   		end
   	if update(InvGLAcct)
   		begin
       	insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLM', ' Location: ' + i.Loc, i.INCo, 'C',
           	'InvGLAcct', d.InvGLAcct, i.InvGLAcct, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where d.InvGLAcct <> i.InvGLAcct and a.AuditLoc = 'Y'
   		end
   	if update(AdjGLAcct)
   		begin
       	insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLM', ' Location: ' + i.Loc, i.INCo, 'C',
           	'AdjGLAcct', d.AdjGLAcct, i.AdjGLAcct, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where d.AdjGLAcct <> i.AdjGLAcct and a.AuditLoc = 'Y'
   		end
   	if update(CostGLAcct)
   		begin
       	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLM', ' Location: ' + i.Loc, i.INCo, 'C',
           	'CostGLAcct', d.CostGLAcct, i.CostGLAcct, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where d.CostGLAcct <> i.CostGLAcct and a.AuditLoc = 'Y'
   		end
   	if update(CostVarGLAcct)
   		begin
       	insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLM', ' Location: ' + i.Loc, i.INCo, 'C',
           	'CostVarGLAcct', d.CostVarGLAcct, i.CostVarGLAcct, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.CostVarGLAcct, '') <> isnull(i.CostVarGLAcct, '') and a.AuditLoc = 'Y'
   		end
   	if update(MiscGLAcct)
   		begin
       	insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLM', ' Location: ' + i.Loc, i.INCo, 'C',
           	'MiscGLAcct', d.MiscGLAcct, i.MiscGLAcct, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.MiscGLAcct, '') <> isnull(i.MiscGLAcct, '') and a.AuditLoc = 'Y'
   		end
   	if update(TaxGLAcct)
   		begin
       	insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLM', ' Location: ' + i.Loc, i.INCo, 'C',
           	'TaxGLAcct', d.TaxGLAcct, i.TaxGLAcct, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.TaxGLAcct, '') <> isnull(i.TaxGLAcct, '') and a.AuditLoc = 'Y'
   		end
   	if update(CostProdGLAcct)
   		begin
   		insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLM', ' Location: ' + i.Loc, i.INCo, 'C',
           	'CostProdGLAcct', d.CostProdGLAcct, i.CostProdGLAcct, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.CostProdGLAcct, '') <> isnull(i.CostProdGLAcct, '') and a.AuditLoc = 'Y'
   		end
   	if update(ValProdGLAcct)
   		begin
       	insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLM', ' Location: ' + i.Loc, i.INCo, 'C',
           	'ValProdGLAcct', d.ValProdGLAcct, i.ValProdGLAcct, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.ValProdGLAcct, '') <> isnull(i.ValProdGLAcct, '') and a.AuditLoc = 'Y'
   		end
   	if update(ProdQtyGLAcct)
   		begin
       	insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLM', ' Location: ' + i.Loc, i.INCo, 'C',
           	'ProdQtyGLAcct', d.ProdQtyGLAcct, i.ProdQtyGLAcct, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.ProdQtyGLAcct, '') <> isnull(i.ProdQtyGLAcct, '') and a.AuditLoc = 'Y'
   		end
   	if update(CustSalesGLAcct)
   		begin
       	insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLM', ' Location: ' + i.Loc, i.INCo, 'C',
           	'CustSalesGLAcct', d.CustSalesGLAcct, i.CustSalesGLAcct, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.CustSalesGLAcct, '') <> isnull(i.CustSalesGLAcct, '') and a.AuditLoc = 'Y'
   		end
   	if update(JobSalesGLAcct)
   		begin
       	insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLM', ' Location: ' + i.Loc, i.INCo, 'C',
           	'JobSalesGLAcct', d.JobSalesGLAcct, i.JobSalesGLAcct, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.JobSalesGLAcct, '') <> isnull(i.JobSalesGLAcct, '') and a.AuditLoc = 'Y'
   		end
   	if update(InvSalesGLAcct)
   		begin
       	insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLM', ' Location: ' + i.Loc, i.INCo, 'C',
           	'InvSalesGLAcct', d.InvSalesGLAcct, i.InvSalesGLAcct, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc
       	join dbo.bINCO a on a.INCo = i.INCo
    		where isnull(d.InvSalesGLAcct, '') <> isnull(i.InvSalesGLAcct, '') and a.AuditLoc = 'Y'
   		end
   	if update(EquipSalesGLAcct)
   		begin
       	insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLM', ' Location: ' + i.Loc, i.INCo, 'C',
           	'EquipSalesGLAcct', d.EquipSalesGLAcct, i.EquipSalesGLAcct, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.EquipSalesGLAcct, '') <> isnull(i.EquipSalesGLAcct, '') and a.AuditLoc = 'Y'
   		end
   	if update(CustQtyGLAcct)
   		begin
       	insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLM', ' Location: ' + i.Loc, i.INCo, 'C',
           	'CustQtyGLAcct', d.CustQtyGLAcct, i.CustQtyGLAcct, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.CustQtyGLAcct, '') <> isnull(i.CustQtyGLAcct, '') and a.AuditLoc = 'Y'
   		end
   	if update(JobQtyGLAcct)
   		begin
       	insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLM', ' Location: ' + i.Loc, i.INCo, 'C',
           	'JobQtyGLAcct', d.JobQtyGLAcct, i.JobQtyGLAcct, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.JobQtyGLAcct, '') <> isnull(i.JobQtyGLAcct, '') and a.AuditLoc = 'Y'
   		end
   	if update(InvQtyGLAcct)
   		begin
       	insert into bHQMA select 'bINLM', ' Location: ' + i.Loc, i.INCo, 'C',
           	'InvQtyGLAcct', d.InvQtyGLAcct, i.InvQtyGLAcct, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.InvQtyGLAcct, '') <> isnull(i.InvQtyGLAcct, '') and a.AuditLoc = 'Y'
   		end
   	if update(CustHaulRevEquipGLAcct)
   		begin
       	insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLM', ' Location: ' + i.Loc, i.INCo, 'C',
           	'CustHaulRevEquipGLAcct', d.CustHaulRevEquipGLAcct, i.CustHaulRevEquipGLAcct, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.CustHaulRevEquipGLAcct, '') <> isnull(i.CustHaulRevEquipGLAcct, '') and a.AuditLoc = 'Y'
   		end
   	if update(JobHaulRevEquipGLAcct)
   		begin
       	insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLM', ' Location: ' + i.Loc, i.INCo, 'C',
           	'JobHaulRevEquipGLAcct', d.JobHaulRevEquipGLAcct, i.JobHaulRevEquipGLAcct, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.JobHaulRevEquipGLAcct, '') <> isnull(i.JobHaulRevEquipGLAcct, '') and a.AuditLoc = 'Y'
   		end
   	if update(InvHaulRevEquipGLAcct)
   		begin
       	insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLM', ' Location: ' + i.Loc, i.INCo, 'C',
           	'InvHaulRevEquipGLAcct', d.InvHaulRevEquipGLAcct, i.InvHaulRevEquipGLAcct, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc
       	join dbo.bINCO a on a.INCo = i.INCo
    		where isnull(d.InvHaulRevEquipGLAcct, '') <> isnull(i.InvHaulRevEquipGLAcct, '') and a.AuditLoc = 'Y'
   		end
   	if update(CustHaulRevOutGLAcct)
   		begin
       	insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLM', ' Location: ' + i.Loc, i.INCo, 'C',
           	'CustHaulRevOutGLAcct', d.CustHaulRevOutGLAcct, i.CustHaulRevOutGLAcct, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.CustHaulRevOutGLAcct, '') <> isnull(i.CustHaulRevOutGLAcct, '') and a.AuditLoc = 'Y'
   		end
   	if update(JobHaulRevOutGLAcct)
   		begin
        	insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLM', ' Location: ' + i.Loc, i.INCo, 'C',
           	'JobHaulRevOutGLAcct', d.JobHaulRevOutGLAcct, i.JobHaulRevOutGLAcct, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.JobHaulRevOutGLAcct, '') <> isnull(i.JobHaulRevOutGLAcct, '') and a.AuditLoc = 'Y'
   		end
   	if update(InvHaulRevOutGLAcct)
   		begin
        	insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLM', ' Location: ' + i.Loc, i.INCo, 'C',
           	'InvHaulRevOutGLAcct', d.InvHaulRevOutGLAcct, i.InvHaulRevOutGLAcct, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.InvHaulRevOutGLAcct, '') <> isnull(i.InvHaulRevOutGLAcct, '') and a.AuditLoc = 'Y'
   		end
   	if update(CustHaulExpEquipGLAcct)
   		begin
   		insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLM', ' Location: ' + i.Loc, i.INCo, 'C',
           	'CustHaulExpEquipGLAcct', d.CustHaulExpEquipGLAcct, i.CustHaulExpEquipGLAcct, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.CustHaulExpEquipGLAcct, '') <> isnull(i.CustHaulExpEquipGLAcct, '') and a.AuditLoc = 'Y'
   		end
   	if update(JobHaulExpEquipGLAcct)
   		begin
   		insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLM', ' Location: ' + i.Loc, i.INCo, 'C',
           	'JobHaulExpEquipGLAcct', d.JobHaulExpEquipGLAcct, i.JobHaulExpEquipGLAcct, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.JobHaulExpEquipGLAcct, '') <> isnull(i.JobHaulExpEquipGLAcct, '') and a.AuditLoc = 'Y'
   		end
   	if update(InvHaulExpEquipGLAcct)
   		begin
   		insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLM', ' Location: ' + i.Loc, i.INCo, 'C',
           	'InvHaulExpEquipGLAcct', d.InvHaulExpEquipGLAcct, i.InvHaulExpEquipGLAcct, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.InvHaulExpEquipGLAcct, '') <> isnull(i.InvHaulExpEquipGLAcct, '') and a.AuditLoc = 'Y'
   		end
   	if update(CustHaulExpOutGLAcct)
   		begin
   		insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLM', ' Location: ' + i.Loc, i.INCo, 'C',
           	'CustHaulExpOutGLAcct', d.CustHaulExpOutGLAcct, i.CustHaulExpOutGLAcct, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.CustHaulExpOutGLAcct, '') <> isnull(i.CustHaulExpOutGLAcct, '') and a.AuditLoc = 'Y'
   		end
   	if update(JobHaulExpOutGLAcct)
   		begin
       	insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLM', ' Location: ' + i.Loc, i.INCo, 'C',
           	'JobHaulExpOutGLAcct', d.JobHaulExpOutGLAcct, i.JobHaulExpOutGLAcct, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.JobHaulExpOutGLAcct, '') <> isnull(i.JobHaulExpOutGLAcct, '') and a.AuditLoc = 'Y'
   		end
   	if update(InvHaulExpOutGLAcct)
   		begin
   		insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLM', ' Location: ' + i.Loc, i.INCo, 'C',
           	'InvHaulExpOutGLAcct', d.InvHaulExpOutGLAcct, i.InvHaulExpOutGLAcct, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.InvHaulExpOutGLAcct, '') <> isnull(i.InvHaulExpOutGLAcct, '') and a.AuditLoc = 'Y'
   		end
   	if update(ARDiscountGLAcct)
   		begin
   		insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLM', ' Location: ' + i.Loc, i.INCo, 'C',
           	'ARDiscountGLAcct', d.ARDiscountGLAcct, i.ARDiscountGLAcct, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.ARDiscountGLAcct, '') <> isnull(i.ARDiscountGLAcct, '') and a.AuditLoc = 'Y'
   		end
   	if update(CMCo)
   		begin
   		insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLM', ' Location: ' + i.Loc, i.INCo, 'C',
           	'CMCo', convert(varchar(5),d.CMCo), convert(varchar(5),i.CMCo), getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.CMCo, 0) <> isnull(i.CMCo, 0) and a.AuditLoc = 'Y'
   		end
   	if update(CMAcct)
   		begin
       	insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLM', ' Location: ' + i.Loc, i.INCo, 'C',
           	'CMAcct', convert(varchar(6),d.CMAcct), convert(varchar(6),i.CMAcct), getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.CMAcct, 0) <> isnull(i.CMAcct, 0) and a.AuditLoc = 'Y'
   		end
   	if update(InvReviewer)
   		begin
       	insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLM', ' Location: ' + i.Loc, i.INCo, 'C',
           	'InvReviewer', d.InvReviewer, i.InvReviewer, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.InvReviewer, '') <> isnull(i.InvReviewer, '') and a.AuditLoc = 'Y'
   		end
   	if update(PurReviewer)
   		begin
       	insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLM', ' Location: ' + i.Loc, i.INCo, 'C',
           	'PurReviewer', d.PurReviewer, i.PurReviewer, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.PurReviewer, '') <> isnull(i.PurReviewer, '') and a.AuditLoc = 'Y'
   		end
   	if update(CustMatlExpGLAcct)
   		begin
   		insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLM', ' Location: ' + i.Loc, i.INCo, 'C',
           	'CustMatlExpGLAcct', d.CustMatlExpGLAcct, i.CustMatlExpGLAcct, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.CustMatlExpGLAcct, '') <> isnull(i.CustMatlExpGLAcct, '') and a.AuditLoc = 'Y'
   		end
   	if update(JobMatlExpGLAcct)
   		begin
   		insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLM', ' Location: ' + i.Loc, i.INCo, 'C',
           	'JobMatlExpGLAcct', d.JobMatlExpGLAcct, i.JobMatlExpGLAcct, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.JobMatlExpGLAcct, '') <> isnull(i.JobMatlExpGLAcct, '') and a.AuditLoc = 'Y'
   		end
   	if update(InvMatlExpGLAcct)
   		begin
   		insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLM', ' Location: ' + i.Loc, i.INCo, 'C',
           	'InvMatlExpGLAcct', d.InvMatlExpGLAcct, i.InvMatlExpGLAcct, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.InvMatlExpGLAcct, '') <> isnull(i.InvMatlExpGLAcct, '') and a.AuditLoc = 'Y'
   		end
   		
   /*START MS Surcharge Issue 129350*/
    if update(CustSurchargeRevEquipGLAcct)
   begin
   		insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLM', ' Location: ' + i.Loc, i.INCo, 'C',
           	'CustSurchargeRevEquipGLAcct', d.CustSurchargeRevEquipGLAcct, i.CustSurchargeRevEquipGLAcct, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.CustSurchargeRevEquipGLAcct, '') <> isnull(i.CustSurchargeRevEquipGLAcct, '') and a.AuditLoc = 'Y'
   	end
   		
   if update(JobSurchargeRevEquipGLAcct)
   begin
   		insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLM', ' Location: ' + i.Loc, i.INCo, 'C',
           	'JobSurchargeRevEquipGLAcct', d.JobSurchargeRevEquipGLAcct, i.JobSurchargeRevEquipGLAcct, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.JobSurchargeRevEquipGLAcct, '') <> isnull(i.JobSurchargeRevEquipGLAcct, '') and a.AuditLoc = 'Y'
   	end
   	
   if update(InvSurchargeRevEquipGLAcct)
   begin
   		insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLM', ' Location: ' + i.Loc, i.INCo, 'C',
           	'InvSurchargeRevEquipGLAcct', d.InvSurchargeRevEquipGLAcct, i.InvSurchargeRevEquipGLAcct, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.InvSurchargeRevEquipGLAcct, '') <> isnull(i.InvSurchargeRevEquipGLAcct, '') and a.AuditLoc = 'Y'
   	end
   	
   if update(CustSurchargeRevOutGLAcct)
   begin
   		insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLM', ' Location: ' + i.Loc, i.INCo, 'C',
           	'CustSurchargeRevOutGLAcct', d.CustSurchargeRevOutGLAcct, i.CustSurchargeRevOutGLAcct, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.CustSurchargeRevOutGLAcct, '') <> isnull(i.CustSurchargeRevOutGLAcct, '') and a.AuditLoc = 'Y'
   	end	
   		
   if update(JobSurchargeRevOutGLAcct)
   begin
   		insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLM', ' Location: ' + i.Loc, i.INCo, 'C',
           	'JobSurchargeRevOutGLAcct', d.JobSurchargeRevOutGLAcct, i.JobSurchargeRevOutGLAcct, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.JobSurchargeRevOutGLAcct, '') <> isnull(i.JobSurchargeRevOutGLAcct, '') and a.AuditLoc = 'Y'
   	end	
   	
   if update(InvSurchargeRevOutGLAcct)
   begin
   		insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLM', ' Location: ' + i.Loc, i.INCo, 'C',
           	'InvSurchargeRevOutGLAcct', d.InvSurchargeRevOutGLAcct, i.InvSurchargeRevOutGLAcct, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.InvSurchargeRevOutGLAcct, '') <> isnull(i.InvSurchargeRevOutGLAcct, '') and a.AuditLoc = 'Y'
   	end	
   
   if update(CustSurchargeExpOutGLAcct)
   begin
   		insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLM', ' Location: ' + i.Loc, i.INCo, 'C',
           	'CustSurchargeExpOutGLAcct', d.CustSurchargeExpOutGLAcct, i.CustSurchargeExpOutGLAcct, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.CustSurchargeExpOutGLAcct, '') <> isnull(i.CustSurchargeExpOutGLAcct, '') and a.AuditLoc = 'Y'
   	end	
   	
   if update(JobSurchargeExpOutGLAcct)
   begin
   		insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLM', ' Location: ' + i.Loc, i.INCo, 'C',
           	'JobSurchargeExpOutGLAcct', d.JobSurchargeExpOutGLAcct, i.JobSurchargeExpOutGLAcct, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.JobSurchargeExpOutGLAcct, '') <> isnull(i.JobSurchargeExpOutGLAcct, '') and a.AuditLoc = 'Y'
   	end	
   	
   if update(InvSurchargeExpOutGLAcct)
   begin
   		insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLM', ' Location: ' + i.Loc, i.INCo, 'C',
           	'InvSurchargeExpOutGLAcct', d.InvSurchargeExpOutGLAcct, i.InvSurchargeExpOutGLAcct, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.InvSurchargeExpOutGLAcct, '') <> isnull(i.InvSurchargeExpOutGLAcct, '') and a.AuditLoc = 'Y'
   	end
   /*End MS Surcharge Issue*/ 	
   
   /*End for HQ Autdit Begin*/
  END
   
   return
   
    error:
       select @errmsg = @errmsg + ' - cannot update IN Locations'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
  
 




GO
CREATE UNIQUE CLUSTERED INDEX [biINLM] ON [dbo].[bINLM] ([INCo], [Loc]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bINLM] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bINLM].[Active]'
GO
EXEC sp_bindrule N'[dbo].[brCMAcct]', N'[dbo].[bINLM].[CMAcct]'
GO
