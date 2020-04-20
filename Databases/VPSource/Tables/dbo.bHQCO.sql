CREATE TABLE [dbo].[bHQCO]
(
[HQCo] [dbo].[bCompany] NOT NULL,
[Name] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[Address] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[City] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[State] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[Zip] [dbo].[bZip] NULL,
[Address2] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[FedTaxId] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[Phone] [dbo].[bPhone] NULL,
[Fax] [dbo].[bPhone] NULL,
[VendorGroup] [dbo].[bGroup] NULL,
[MatlGroup] [dbo].[bGroup] NULL,
[PhaseGroup] [dbo].[bGroup] NULL,
[CustGroup] [dbo].[bGroup] NULL,
[TaxGroup] [dbo].[bGroup] NULL,
[EMGroup] [dbo].[bGroup] NULL,
[Vendor] [dbo].[bVendor] NULL,
[Customer] [dbo].[bCustomer] NULL,
[AuditCoParams] [dbo].[bYN] NOT NULL,
[AuditTax] [dbo].[bYN] NOT NULL,
[AuditMatl] [dbo].[bYN] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[ShopGroup] [dbo].[bGroup] NULL,
[STEmpId] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[MenuImage] [varchar] (256) COLLATE Latin1_General_BIN NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[Country] [char] (2) COLLATE Latin1_General_BIN NULL,
[DefaultCountry] [char] (2) COLLATE Latin1_General_BIN NOT NULL,
[ReportDateFormat] [tinyint] NOT NULL CONSTRAINT [DF_bHQCO_ReportDateFormat] DEFAULT ((1)),
[ContactGroup] [dbo].[bGroup] NULL,
[AuditContact] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bHQCO_AuditContact] DEFAULT ('N'),
[DFId] [int] NULL,
[CurrencyID] [int] NULL,
[MaskId] [int] NULL,
[udTESTCo] [dbo].[bYN] NULL CONSTRAINT [DF__bHQCO__udTESTCo__DEFAULT] DEFAULT ('N')
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
ALTER TABLE [dbo].[bHQCO] ADD
CONSTRAINT [CK_bHQCO_AuditCoParams] CHECK (([AuditCoParams]='Y' OR [AuditCoParams]='N'))
ALTER TABLE [dbo].[bHQCO] ADD
CONSTRAINT [CK_bHQCO_AuditMatl] CHECK (([AuditMatl]='Y' OR [AuditMatl]='N'))
ALTER TABLE [dbo].[bHQCO] ADD
CONSTRAINT [CK_bHQCO_AuditTax] CHECK (([AuditTax]='Y' OR [AuditTax]='N'))
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
CREATE trigger [dbo].[btHQCOd] on [dbo].[bHQCO] for DELETE as
/*----------------------------------------------------------
* Created: ??
* Modified: DANF 08/30/05 - Issue 29679 Check for Auditing entries before deleting company.
*			GF 10/22/2007 - issue #125889 changed HQMA check for entries other than bHQCO.
*			DH 1/30/2009 - Issue #132041 added check for vDDBICompanies
*
*
*
*	This trigger rejects delete in bHQCO (HQ Companies) if a
*	dependent record is found in:
*		GLCO
*		CMCO
*		HQBC
*		JCCO
*		Form or Report Security
*
*/---------------------------------------------------------
declare @errmsg varchar(255), @numrows int

select @numrows = @@rowcount
set nocount on
if @numrows = 0 return

/* check GLCO.GLCo */
if exists(select top 1 1 from dbo.bGLCO s (nolock) join deleted d on s.GLCo = d.HQCo)
	begin
	select @errmsg = 'GL Companies exist'
	goto error
	end
/* check CMCO.CMCo */
if exists(select top 1 1 from dbo.bCMCO s (nolock) join deleted d on s.CMCo = d.HQCo)
	begin
	select @errmsg = 'CM Companies exist'
	goto error
	end
/* check HQBC.Co */
if exists(select top 1 1 from dbo.bHQBC s (nolock) join deleted d on s.Co = d.HQCo)
	begin
	select @errmsg = 'HQ Batch Control entries exist'
	goto error
	end
/* check JCCO.JCCo */
if exists(select top 1 1 from dbo.bJCCO s (nolock) join deleted d on s.JCCo = d.HQCo)
	begin
	select @errmsg = 'Job Cost Companies exist'
	goto error
	end
/* check DDFS  */
if exists(select top 1 1 from dbo.vDDFS s (nolock) join deleted d on s.Co = d.HQCo)
begin
select @errmsg = 'Form Security exists'
goto error
end
/* check RPRS  */
if exists(select top 1 1 from dbo.vRPRS s (nolock) join deleted d on s.Co = d.HQCo)
	begin
	select @errmsg = 'Report Security exists'
	goto error
	end
/* check vDDBICompanies (accessible via VA Business Intelligence Mgmt form */
if exists(select top 1 1 from dbo.vDDBICompanies s (nolock) join deleted d on s.Co = d.HQCo)
	begin
	select @errmsg = 'BI Companies exist'
	goto error
	end

---- check HQMA
if exists(select top 1 1 from dbo.bHQMA s (nolock) join deleted d on s.Co = d.HQCo and s.TableName <> 'bHQCO')
	begin
	select @errmsg ='Auditing Entries exist. Run the Master Audit Purge before deleting HQ Company.'
	goto error
	end


---- Audit HQ Company deletions
insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bHQCO', 'HQ Co#: ' + convert(varchar(3),HQCo), HQCo, 'D', null, null, null, getdate(), SUSER_SNAME()
from deleted



return

error:
	select @errmsg = @errmsg + ' - cannot delete HQ Company!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
  
 



GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE trigger [dbo].[btHQCOi] on [dbo].[bHQCO] for INSERT as
/*-----------------------------------------------------------------
* Created: ??
* Modified: GG 04/20/07 - #30116 - data security review
*			TRL 02/13/08 #21452 
*			GG 06/06/08 - #128324 - add State/Country validation 
*			GG 10/08/08 - #130130 - fix State validation
*
*	This trigger rejects insertion in bHQCO (HQ Companies) if the
*	following error condition exists:
*
*	Invalid State
*	Invalid Country or State/Country combination
*	Invalid DefaultCountry
*
*	Adds HQ Master Audit entry.
*/----------------------------------------------------------------
declare @errmsg varchar(255), @numrows int, @validcnt int, @nullcnt int

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

---- GIL F. 03/05/2008 temp rem out unit Terry L reviews
------#21452: Update HQCR Attach Batch Reports to HQBC by Mod
----begin
----	Insert into HQCR(HQCo,Mod,AttachBatchReportsYN)
----	select i.HQCo, d.Mod,'N' from inserted i
----	Cross Join DDMO d
----	Left Join HQCR r on r.HQCo=i.HQCo and r.Mod=d.Mod
----	where r.HQCo = i.HQCo and IsNull(d.Active,'N')='Y' and r.Mod is Null
----	and d.Mod not in ('DD','DM','HQ','IM','UD','VA','VC','VP','WF')
----End

-- validate Country 
select @validcnt = count(1) 
from dbo.bHQCountry c (nolock) 
join inserted i on i.Country = c.Country
select @nullcnt = count(1) from inserted where Country is null
if @validcnt + @nullcnt <> @numrows
	begin
	select @errmsg = 'Invalid Country'
	goto error
	end
-- validate State - all State values must exist in bHQST
if exists(select top 1 1 from inserted i where [State] not in(select [State] from dbo.bHQST))
	begin
	select @errmsg = 'Invalid State'
	goto error
	end
-- validate Country/State combinations
select @validcnt = count(1) -- Country/State combos are unique
from dbo.bHQST (nolock) s
join inserted i on i.Country = s.Country and i.State = s.State
select @nullcnt = count(1) from inserted where Country is null or State is null
if @validcnt + @nullcnt <> @numrows
	begin
	select @errmsg = 'Invalid Country and State combination'
	goto error
	end
-- validate Default Country
select @validcnt = count(1)
from inserted i
join dbo.bHQCountry c (nolock) on c.Country = i.DefaultCountry
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid Default Country'
	goto error
	end

/* add HQ Master Audit entry */
insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bHQCO', 'HQ Co#: ' + convert(char(3), HQCo), HQCo, 'A', null, null, null, getdate(), SUSER_SNAME()
from inserted

   
--#30116 - initialize Data Security
declare @dfltsecgroup int
select @dfltsecgroup = DfltSecurityGroup
from dbo.DDDTShared (nolock) where Datatype = 'bHQCo' and Secure = 'Y'
if @dfltsecgroup is not null
	begin
	insert dbo.vDDDS (Datatype, Qualifier, Instance, SecurityGroup)
	select 'bHQCo', i.HQCo, i.HQCo, @dfltsecgroup
	from inserted i 
	where not exists(select 1 from dbo.vDDDS s (nolock) where s.Datatype = 'bHQCo' and s.Qualifier = i.HQCo 
						and s.Instance = convert(char(30),i.HQCo) and s.SecurityGroup = @dfltsecgroup)
	end 

return

error:
	select @errmsg = @errmsg + ' - cannot insert HQ Company!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
  
 



GO
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
   
CREATE  trigger [dbo].[btHQCOu] on [dbo].[bHQCO] for UPDATE as
/*-----------------------------------------------------------------
* Created: ??
* Modified: DANF 01/11/2000
*			JM 7/30/02 - Added rejection of update to ShopGroup when that ShopGroup
*				exists in EMEM, EMSX, or EMWH.
*			RM 11/27/02 - Took out check for shop group in EMSX, Issue#19442
*			GG 03/22/05 - #26993 - cleanup
*			GG 06/06/08 - #128324 - add State/Country validation 
*			GG 10/08/08 - #130130 - fix State validation
*
*		
*	This trigger rejects update in bHQCO (HQ Companies) if the
*	following error condition exists:
*
*		Cannot change HQ Company
*
*	Adds records to HQ Master Audit.
*/----------------------------------------------------------------
declare @errmsg varchar(255), @numrows int, @validcnt int, @nullcnt int,
		@hqco bCompany, @name varchar(60), @oldname varchar(60)

select @numrows = @@rowcount
if @numrows = 0 return

set nocount on
   
   /* reject primary index changes */
   select @validcnt = count(*) from deleted d, inserted i
   	where d.HQCo = i.HQCo
   if @numrows <> @validcnt
   	begin
   	select @errmsg = 'Cannot change HQ Company #'
   	goto error
   	end
   
   -- restrict Group changes
   if update(CustGroup)
   	begin
       if exists(select top 1 1 from dbo.bARTH a (nolock) 
   				join deleted d on a.CustGroup = d.CustGroup and a.ARCo = d.HQCo)
         	begin
   	   	select @errmsg = 'Cannot change Customer Group, AR Transactions exist for old group'
   	   	goto error
         	end
   	end
   if update(VendorGroup)
   	begin
       if exists(select top 1 1 from dbo.bAPTH a (nolock)
   				join deleted d on a.VendorGroup = d.VendorGroup and a.APCo = d.HQCo) or
   		exists(select top 1 1 from dbo.bPMPF p (nolock)
   				join deleted d on p.VendorGroup = d.VendorGroup and p.PMCo = d.HQCo)
   		begin
   	   	select @errmsg = 'Cannot change Vendor Group, AP Invoices or PM Firms exist for old group'
   	   	goto error
         	end
   	end
   if update(MatlGroup)
   	begin
       if exists(select top 1 1 from dbo.bAPTL a (nolock)
   				join deleted d on a.MatlGroup = d.MatlGroup and a.APCo = d.HQCo) or
   		exists(select top 1 1 from dbo.bARTL a (nolock)
   				join deleted d on a.MatlGroup = d.MatlGroup and a.ARCo = d.HQCo)
   		begin
   	   	select @errmsg = 'Cannot change Material Group, AP Invoice Lines or AR Transaction Lines exist for old group'
   	   	goto error
         	end
   	end
   if update(TaxGroup)
   	begin
       if exists(select top 1 1 from dbo.bAPTL a (nolock)
   				join deleted d on a.TaxGroup = d.TaxGroup and a.APCo = d.HQCo) or
   		exists(select top 1 1 from dbo.bARTL a (nolock)
   				join deleted d on a.TaxGroup = d.TaxGroup and a.ARCo = d.HQCo)
   		begin
   	   	select @errmsg = 'Cannot change Tax Group, AP Invoice Lines or AR Transaction Lines exist for old group'
   	   	goto error
         	end
   	end
   if update(PhaseGroup)
   	begin
       if exists(select top 1 1 from dbo.bJCJP j (nolock)
   				join deleted d on j.PhaseGroup = d.PhaseGroup and j.JCCo = d.HQCo)
   		begin
   	   	select @errmsg = 'Cannot change Phase Group because Job Phase detail exists for old group'
   	   	goto error
         	end
   	end
   if update(EMGroup)
   	begin
       if exists(select top 1 1 from dbo.bEMCD e (nolock)
   				join deleted d on e.EMGroup = d.EMGroup and e.EMCo = d.HQCo) or
   		exists(select top 1 1 from dbo.bEMRD e (nolock)
   				join deleted d on e.EMGroup = d.EMGroup and e.EMCo = d.HQCo) or
           exists(select top 1 1 from dbo.bEMEM e (nolock)
   				join deleted d on e.EMGroup = d.EMGroup and e.EMCo = d.HQCo)
         	begin
   	  	select @errmsg = 'Cannot change EM Group, EM Costs, Revenue, or Equipment exist for old group'
   	   	goto error
         	end
   	end
   if update(ShopGroup)
   	begin
        --Following line Removed per issue#19442
   	 --If exists(select * from EMSX join deleted d on EMSX.ShopGroup = d.ShopGroup)or
        if exists(select top 1 1 from dbo.bEMWH e (nolock)
   				join deleted d on e.ShopGroup = d.ShopGroup and e.EMCo = d.HQCo) or
           exists(select top 1 1 from dbo.bEMEM e (nolock)
   				join deleted d on e.ShopGroup = d.ShopGroup and e.EMCo = d.HQCo)
         	begin
   	   	select @errmsg = 'Cannot change Shop Group,  EM Work Orders or Equipment exist for old group'
   	   	goto error
         	end
   	end
   if update(AuditCoParams)
   	begin
   	if exists(select top 1 1 from inserted where isnull(AuditCoParams,'') <> 'Y')
   		begin
   		select @errmsg = 'Audit Company parameters must be ''Y'''
   		goto error
   		end
   	end
   	
if update(Country)
	begin
	-- validate Country 
	select @validcnt = count(1) 
	from dbo.bHQCountry c (nolock) 
	join inserted i on i.Country=c.Country
	select @nullcnt = count(1) from inserted where Country is null
		if @validcnt + @nullcnt <> @numrows
		begin
		select @errmsg = 'Invalid Country'
		goto error
		end
	end
if update(State)
	begin
	-- validate State - all State values must exist in bHQST
	if exists(select top 1 1 from inserted i where [State] not in(select [State] from dbo.bHQST))
		begin
		select @errmsg = 'Invalid State'
		goto error
		end
	end
if update(Country) or update([State])
	begin
	-- validate Country/State combinations
	select @validcnt = count(1) -- Country/State combos are unique
	from dbo.bHQST (nolock) s
	join inserted i on i.Country = s.Country and i.State = s.State
	select @nullcnt = count(1) from inserted where Country is null or [State] is null
	if @validcnt + @nullcnt <> @numrows
		begin
		select @errmsg = 'Invalid Country and State combination'
		goto error
		end
	end
if update (DefaultCountry)
	begin
	select @validcnt = count(1)
	from inserted i
	join dbo.bHQCountry c (nolock) on c.Country = i.DefaultCountry
	if @validcnt <> @numrows
		begin
		select @errmsg = 'Invalid Default Country'
		goto error
		end
	end




/* always update HQ Master Audit */
if update(Name)
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bHQCO', 'HQ Co#: ' + convert(char(3),i.HQCo), i.HQCo, 'C',
   		'Name', d.Name, i.Name, getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on i.HQCo = d.HQCo
   	where isnull(i.Name,'') <> isnull(d.Name,'')
if update(Address)
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bHQCO', 'HQ Co#: ' + convert(char(3),i.HQCo), i.HQCo, 'C',
   		'Address', d.Address, i.Address, getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on i.HQCo = d.HQCo
   	where isnull(i.Address,'') <> isnull(d.Address,'')
if update(City)
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bHQCO', 'HQ Co#: ' + convert(char(3),i.HQCo), i.HQCo, 'C',
   		'City', d.City, i.City, getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on i.HQCo = d.HQCo
   	where isnull(i.City,'') <> isnull(d.City,'')
 if update(State)
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bHQCO', 'HQ Co#: ' + convert(char(3),i.HQCo), i.HQCo, 'C',
   		'State', d.State, i.State, getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on i.HQCo = d.HQCo
   	where isnull(i.State,'') <> isnull(d.State,'')
if update(Zip)
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bHQCO', 'HQ Co#: ' + convert(char(3),i.HQCo), i.HQCo, 'C',
   		'Zip Code', d.Zip, i.Zip, getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on i.HQCo = d.HQCo
   	where isnull(i.Zip,'') <> isnull(d.Zip,'')
if update(Address2)
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bHQCO', 'HQ Co#: ' + convert(char(3),i.HQCo), i.HQCo, 'C',
   		'Address', d.Address2, i.Address2, getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on i.HQCo = d.HQCo
   	where isnull(i.Address2,'') <> isnull(d.Address2,'')
if update(FedTaxId)
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bHQCO', 'HQ Co#: ' + convert(char(3),i.HQCo), i.HQCo, 'C',
   	'FedTaxId', d.FedTaxId, i.FedTaxId, getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on i.HQCo = d.HQCo
   	where isnull(i.FedTaxId,'') <> isnull(d.FedTaxId,'')
if update(Phone)
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bHQCO', 'HQ Co#: ' + convert(char(3),i.HQCo), i.HQCo, 'C',
   		'Phone', d.Phone, i.Phone, getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on i.HQCo = d.HQCo
   	where isnull(i.Phone,'') <> isnull(d.Phone,'')
if update(Fax)
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bHQCO', 'HQ Co#: ' + convert(char(3),i.HQCo), i.HQCo, 'C',
   		'Fax', d.Fax, i.Fax, getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on i.HQCo = d.HQCo
   	where isnull(i.Fax,'') <> isnull(d.Fax,'')
if update(VendorGroup)
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bHQCO', 'HQ Co#: ' + convert(char(3),i.HQCo), i.HQCo, 'C',
   		'VendorGroup', convert(char(3),d.VendorGroup), convert(char(3),i.VendorGroup), getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on i.HQCo = d.HQCo
   	where isnull(i.VendorGroup,'') <> isnull(d.VendorGroup,'')
if update(MatlGroup)
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bHQCO', 'HQ Co#: ' + convert(char(3),i.HQCo), i.HQCo, 'C',
   		'MatlGroup', convert(char(3),d.MatlGroup), convert(char(3),i.MatlGroup), getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on i.HQCo = d.HQCo
   	where isnull(i.MatlGroup,'') <> isnull(d.MatlGroup,'')
if update(PhaseGroup)
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bHQCO', 'HQ Co#: ' + convert(char(3),i.HQCo), i.HQCo, 'C',
   		'PhaseGroup', convert(char(3),d.PhaseGroup), convert(char(3),i.PhaseGroup), getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on i.HQCo = d.HQCo
   	where isnull(i.PhaseGroup,'') <> isnull(d.PhaseGroup,'')
if update(CustGroup)
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bHQCO', 'HQ Co#: ' + convert(char(3),i.HQCo), i.HQCo, 'C',
   		'CustGroup', convert(char(3),d.CustGroup), convert(char(3),i.CustGroup), getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on i.HQCo = d.HQCo
   	where isnull(i.CustGroup,'') <> isnull(d.CustGroup,'')
if update(TaxGroup)
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bHQCO', 'HQ Co#: ' + convert(char(3),i.HQCo), i.HQCo, 'C',
   		'TaxGroup', convert(char(3),d.TaxGroup), convert(char(3),i.TaxGroup), getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on i.HQCo = d.HQCo
   	where isnull(i.TaxGroup,'') <> isnull(d.TaxGroup,'')
if update(EMGroup)
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bHQCO', 'HQ Co#: ' + convert(char(3),i.HQCo), i.HQCo, 'C',
   		'EMGroup', convert(char(3),d.EMGroup), convert(char(3),i.EMGroup), getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on i.HQCo = d.HQCo
   	where isnull(i.EMGroup,'') <> isnull(d.EMGroup,'')
if update(Vendor)
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bHQCO', 'HQ Co#: ' + convert(char(3),i.HQCo), i.HQCo, 'C',
   		'Vendor', convert(varchar(10),d.Vendor), convert(varchar(10),i.Vendor), getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on i.HQCo = d.HQCo
   	where isnull(i.Vendor,'') <> isnull(d.Vendor,'')
if update(Customer)
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bHQCO', 'HQ Co#: ' + convert(char(3),i.HQCo), i.HQCo, 'C',
   		'Customer', convert(varchar(10),d.Customer), convert(varchar(10),i.Customer), getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on i.HQCo = d.HQCo
   	where isnull(i.Customer,'') <> isnull(d.Customer,'')
if update(AuditTax)
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bHQCO', 'HQ Co#: ' + convert(char(3),i.HQCo), i.HQCo, 'C',
   		'AuditTax', d.AuditTax, i.AuditTax, getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on i.HQCo = d.HQCo
   	where isnull(i.AuditTax,'') <> isnull(d.AuditTax,'')
if update(AuditMatl)
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bHQCO', 'HQ Co#: ' + convert(char(3),i.HQCo), i.HQCo, 'C',
   		'AuditMatl', d.AuditMatl, i.AuditMatl, getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on i.HQCo = d.HQCo
   	where isnull(i.AuditMatl,'') <> isnull(d.AuditMatl,'')
if update(ShopGroup)
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bHQCO', 'HQ Co#: ' + convert(char(3),i.HQCo), i.HQCo, 'C',
   		'ShopGroup', d.ShopGroup, i.ShopGroup, getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on i.HQCo = d.HQCo
   	where isnull(i.ShopGroup,'') <> isnull(d.ShopGroup,'')
if update(STEmpId)
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bHQCO', 'HQ Co#: ' + convert(char(3),i.HQCo), i.HQCo, 'C',
   		'STEmpId', d.STEmpId, i.STEmpId, getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on i.HQCo = d.HQCo
   	where isnull(i.STEmpId,'') <> isnull(d.STEmpId,'')
if update(MenuImage)
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bHQCO', 'HQ Co#: ' + convert(char(3),i.HQCo), i.HQCo, 'C',
   		'MenuImage', d.MenuImage, i.MenuImage, getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on i.HQCo = d.HQCo
   	where isnull(i.MenuImage,'') <> isnull(d.MenuImage,'')
if update(Country)
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bHQCO', 'HQ Co#: ' + convert(char(3),i.HQCo), i.HQCo, 'C',
   		'Country', d.Country, i.Country, getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on i.HQCo = d.HQCo
   	where isnull(i.Country,'') <> isnull(d.Country,'')
if update(DefaultCountry)
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bHQCO', 'HQ Co#: ' + convert(char(3),i.HQCo), i.HQCo, 'C',
   		'DefaultCountry', d.DefaultCountry, i.DefaultCountry, getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on i.HQCo = d.HQCo
   	where i.DefaultCountry <> d.DefaultCountry


   return
   
   error:
   	select @errmsg = @errmsg + ' - cannot update HQ Company!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
  
 



GO
ALTER TABLE [dbo].[bHQCO] ADD CONSTRAINT [IX_bHQCO_HQCo_PhaseGroup] UNIQUE NONCLUSTERED  ([PhaseGroup], [HQCo]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biHQCO] ON [dbo].[bHQCO] ([HQCo]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bHQCO] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bHQCO] WITH NOCHECK ADD CONSTRAINT [FK_bHQCO_vCurrency_CurrencyID] FOREIGN KEY ([CurrencyID]) REFERENCES [dbo].[vCurrency] ([CurrencyID])
GO
ALTER TABLE [dbo].[bHQCO] WITH NOCHECK ADD CONSTRAINT [FK_bHQCO_vDateFormat_DFId] FOREIGN KEY ([DFId]) REFERENCES [dbo].[vDateFormat] ([DFId])
GO
ALTER TABLE [dbo].[bHQCO] WITH NOCHECK ADD CONSTRAINT [FK_bHQCO_vNumericMaskDetails_MaskId] FOREIGN KEY ([MaskId]) REFERENCES [dbo].[vNumericMaskDetails] ([MaskId])
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHQCO].[AuditCoParams]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHQCO].[AuditTax]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHQCO].[AuditMatl]'
GO
