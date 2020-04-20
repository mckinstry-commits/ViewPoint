CREATE TABLE [dbo].[bPRCM]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[Craft] [dbo].[bCraft] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[Address] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[City] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[State] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[Zip] [dbo].[bZip] NULL,
[EffectiveDate] [dbo].[bDate] NOT NULL,
[ReportType] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[VendorGroup] [dbo].[bGroup] NULL,
[Vendor] [dbo].[bVendor] NULL,
[OTSched] [tinyint] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[TradeSeq] [tinyint] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[HolidayOT] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRCM_HolidayOT] DEFAULT ('N'),
[MaxRegHrsPerWeek] [dbo].[bHrs] NULL,
[Country] [char] (2) COLLATE Latin1_General_BIN NULL,
[PensionNumber] [varchar] (7) COLLATE Latin1_General_BIN NULL,
[SuperWeeklyMin] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bPRCM_SuperWeeklyMin] DEFAULT ((0))
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btPRCMd    Script Date: 8/28/99 9:38:10 AM ******/
   CREATE   trigger [dbo].[btPRCMd] on [dbo].[bPRCM] for DELETE as
   

/*-----------------------------------------------------------------
    *  Created: EN 3/30/00
    *  Modified: BC 1/16/01 - Issue # 11945 - Added check for (bPRCC),
    *			(bPRCD), (bPRCE), (bPRCF), (bPRCP), (bPRCT), (bPREH), (bPRTC),
    *			(bPRTD), (bPRTE), (bPRTF), (bPRTI), (bPRTP), (bPRTR)
    *
    *	        EN 6/7/00 - delete corresponding entries from bPRCI, bPRCS and bPRCB
    *          EN 1/2/01 - warn rather than deleting corresponding entries from bPRCI, bPRCS, bPRCB
    *          GG 3/21/01 - removed checks on tables requiring valid Class (will be checked in btPRCCd)
    *                      - added checks for bPRCA and bPRAE
    *          MV 4/26/01 - added check for bPRCH
    *			EN 01/28/03 - issue 23061  added isnull check, with (nolock), and dbo
    *
    *  Delete trigger on PR Craft Master checks that Craft is no longer in use.
    *
    * Inserts HQ Master Audit entry.
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @prco bCompany, @craft bCraft
   select @numrows = @@rowcount
   set nocount on
   if @numrows = 0 return
   
    -- check for Craft Items
    if exists(select * from dbo.bPRCI w with (nolock) join deleted d on w.PRCo = d.PRCo and w.Craft = d.Craft)
    	begin
   	select @errmsg = 'Craft Add-ons, Deductions, and/or Liabilities exist'
   	goto error
   	end
    -- check for Capped Sequences
    if exists(select * from dbo.bPRCS w with (nolock) join deleted d on w.PRCo = d.PRCo and w.Craft = d.Craft)
    	begin
   	select @errmsg = 'Capped Earnings and/or Liabilities exist'
   	goto error
   	end
    -- check for Capped Basis
    if exists(select * from dbo.bPRCB w with (nolock) join deleted d on w.PRCo = d.PRCo and w.Craft = d.Craft)
    	begin
   	select @errmsg = 'Capped Basis entries exist'
   	goto error
   	end
   -- check for Craft Class
    if exists(select * from dbo.bPRCC w with (nolock) join deleted d on w.PRCo = d.PRCo and w.Craft = d.Craft)
    	begin
   	select @errmsg = 'Classes exist'
   	goto error
   	end
    -- check for Craft Template
    if exists(select * from dbo.bPRCT w with (nolock)join deleted d on w.PRCo = d.PRCo and w.Craft = d.Craft)
    	begin
   	select @errmsg = 'Craft Templates exist'
   	goto error
   	end
    -- check for Craft Accums
    if exists(select * from dbo.bPRCA w with (nolock) join deleted d on w.PRCo = d.PRCo and w.Craft = d.Craft)
    	begin
   	select @errmsg = 'Craft report accumulations exist'
   	goto error
   	end
    -- check for Employee Header
    if exists(select * from dbo.bPREH w with (nolock) join deleted d on w.PRCo = d.PRCo and w.Craft = d.Craft)
    	begin
   	select @errmsg = 'Craft assigned in Employee Header'
   	goto error
   	end
    -- check for Auto Earnings
    if exists(select * from dbo.bPRAE w with (nolock) join deleted d on w.PRCo = d.PRCo and w.Craft = d.Craft)
    	begin
   	select @errmsg = 'Craft assigned in Employee Auto Earnings'
   	goto error
   	end
    -- check for Craft Holidays
    if exists(select * from dbo.bPRCH h with (nolock) join deleted d on h.PRCo = d.PRCo and h.Craft = d.Craft)
    	begin
   	select @errmsg = 'Craft assigned in Craft Holidays'
   	goto error
   	end
   /* Audit Craft deletions */
   insert into dbo.bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bPRCM', 'Craft: ' + d.Craft, d.PRCo, 'D', null, null, null, getdate(), SUSER_SNAME()
   	from deleted d join dbo.PRCO p on d.PRCo = p.PRCo where p.AuditCraftClass = 'Y'
   
   return
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot delete PR Craft Master!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 

CREATE trigger [dbo].[btPRCMi] on [dbo].[bPRCM] for INSERT as
/*-----------------------------------------------------------------
* Created: EN 3/30/00
* Modified:	EN 10/9/02 - issue 18877 change double quotes to single
*			EN 01/28/03 - issue 23061  added isnull check, with (nolock), and dbo
*			EN 3/18/08 - #127081  modified HQST validation to include country
*			GG 06/16/08 - #128324 - fix Country/State validation
*
*	This trigger rejects insertion in bPRCM (PR Craft Master) if the
*	following error condition exists:
*
*	Adds HQ Master Audit entry.
*/----------------------------------------------------------------
declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int, @nullcnt int
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
   
--validate Country
select @validcnt = count(1)
from dbo.bHQCountry c (nolock) 
join inserted i on i.Country = c.Country
select @nullcnt = count(1) from inserted where Country is null
if @validcnt + @nullcnt <> @numrows
	begin
	select @errmsg = 'Invalid Country'
	goto error
	end
-- validate Country/State combinations
select @validcnt = count(1) -- Country/State combos are unique
from inserted i
join dbo.bHQCO c (nolock) on c.HQCo = i.PRCo	-- join to get Default Country
join dbo.bHQST s (nolock) on isnull(i.Country,c.DefaultCountry) = s.Country and i.State = s.State
select @nullcnt = count(1) from inserted where State is null
if @validcnt + @nullcnt <> @numrows
	begin
	select @errmsg = 'Invalid Country and State combination'
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
   
   /*validate vendor */
   select @validcnt = count(*) from inserted i where i.Vendor is not null
   select @validcnt2 = count(*) from dbo.bAPVM r with (nolock)
           JOIN inserted i on i.VendorGroup=r.VendorGroup and i.Vendor=r.Vendor where i.Vendor is not null
   if @validcnt<>@validcnt2
    	begin
    	select @errmsg = 'Invalid Vendor '
    	goto error
    	end
   
   /* validate Overtime Schedule */
   select @validcnt = count(*) from inserted i where i.OTSched is not null
   select @validcnt2 = count(*) from dbo.bPROT c with (nolock) join inserted i on c.PRCo = i.PRCo and c.OTSched = i.OTSched
   	where i.OTSched is not null
   if @validcnt <> @validcnt2
   	begin
   	select @errmsg = 'Invalid OT Schedule'
   	goto error
   	end
   
   /* add HQ Master Audit entry */
   Insert into dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bPRCM', 'Craft: ' + i.Craft, i.PRCo, 'A', null, null, null, getdate(), SUSER_SNAME()
       from inserted i join dbo.PRCO p on i.PRCo = p.PRCo where p.AuditCraftClass = 'Y'
   
   
   return
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot insert PR Craft Master!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
CREATE trigger [dbo].[btPRCMu] on [dbo].[bPRCM] for UPDATE as
/*-----------------------------------------------------------------
* Created: EN 3/30/00
* Modified: EN 10/09/00 - Checking for key changes incorrectly
*			EN 01/28/03 - issue 23061  added isnull check, with (nolock), and dbo
*			EN 9/25/07 issue 119734  added HQMA audit for new columns HolidayOT and MaxRegHrsPerWeek
*			mh 10/01/07 Issue 125084 - Corrected Audit entry for EffectiveDate.  Was pulling in Description.
*			EN 3/7/08 #127081  added HQMA audit for new Country column
*			EN 3/18/08 #127081  modified HQST validation to include country
*			GG 06/16/08 - #128324 - fix Country/State validation
*
* Validates and inserts HQ Master Audit entry.
*
*		Cannot change primary key - PR Company
*/----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int, @nullcnt int
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   /* check for key changes */
   if update(PRCo)
       begin
       select @validcnt = count(*) from deleted d join inserted i on d.PRCo = i.PRCo
       if @validcnt <> @numrows
         	begin
         	select @errmsg = 'Cannot change PR Company '
         	goto error
         	end
       end
   if update(Craft)
       begin
       select @validcnt = count(*) from deleted d join inserted i on d.PRCo = i.PRCo and d.Craft = i.Craft
       if @validcnt <> @numrows
        	begin
       	select @errmsg = 'Cannot change Craft '
       	goto error
       	end
       end
-- validate County/State
if update([State]) or update(Country)
	begin
	select @validcnt = count(1) 
	from dbo.bHQCountry c with (nolock) 
	join inserted i on i.Country = c.Country
	select @nullcnt = count(1) from inserted where Country is null
	if @validcnt + @nullcnt <> @numrows
		begin
		select @errmsg = 'Invalid Country'
		goto error
		end
	-- validate Country/State combinations
	select @validcnt = count(1) -- Country/State combos are unique
	from inserted i
	join dbo.bHQCO c (nolock) on c.HQCo = i.PRCo	-- join to get Default Country
	join dbo.bHQST s (nolock) on isnull(i.Country,c.DefaultCountry) = s.Country and i.State = s.State
	select @nullcnt = count(1) from inserted where [State] is null
	if @validcnt + @nullcnt <> @numrows
		begin
		select @errmsg = 'Invalid Country and State combination'
		goto error
		end
	end
   
   
   /* validate Vendor Group */
   if update(VendorGroup)
       begin
       select @validcnt = count(*) from inserted i where i.VendorGroup is not null
       select @validcnt2 = count(*) from dbo.bHQGP c with (nolock) join inserted i on c.Grp = i.VendorGroup where i.VendorGroup is not null
       if @validcnt <> @validcnt2
       	begin
       	select @errmsg = 'Invalid Vendor Group '
       	goto error
       	end
       end
   
   /*validate vendor */
   if update(Vendor)
       begin
       select @validcnt = count(*) from inserted i where i.Vendor is not null
       select @validcnt2 = count(*) from dbo.bAPVM r with (nolock)
               JOIN inserted i on i.VendorGroup=r.VendorGroup and i.Vendor=r.Vendor where i.Vendor is not null
       if @validcnt<>@validcnt2
        	begin
        	select @errmsg = 'Invalid Vendor '
        	goto error
        	end
       end
   
   /* validate Overtime Schedule */
   if update(OTSched)
       begin
       select @validcnt = count(*) from inserted i where i.OTSched is not null
   	select @validcnt2 = count(*) from dbo.bPROT c with (nolock) join inserted i on c.PRCo = i.PRCo and c.OTSched = i.OTSched
   		where i.OTSched is not null
   	if @validcnt <> @validcnt2
   		begin
   		select @errmsg = 'Invalid OT Schedule'
   		goto error
   		end
       end
   
   /* Insert records into HQMA for changes made to audited fields */
   if exists(select * from inserted i join dbo.PRCO a with (nolock) on i.PRCo = a.PRCo and a.AuditCraftClass = 'Y')
       begin
       insert into dbo.bHQMA select 'bPRCM',
      	    'Craft: ' + i.Craft,
           i.PRCo, 'C', 'Description', d.Description, i.Description, getdate(), SUSER_SNAME()
          	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.Craft = d.Craft
           join dbo.PRCO p on i.PRCo = p.PRCo
           where isnull(i.Description,'') <> isnull(d.Description,'') and p.AuditCraftClass = 'Y'
       insert into dbo.bHQMA select 'bPRCM',
       	'Craft: ' + i.Craft,
       	i.PRCo, 'C', 'Address', d.Address, i.Address,
       	getdate(), SUSER_SNAME()	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.Craft = d.Craft
           join dbo.PRCO p on i.PRCo = p.PRCo
           where isnull(i.Address,'') <> isnull(d.Address,'') and p.AuditCraftClass = 'Y'
       insert into dbo.bHQMA select 'bPRCM',
       	'Craft: ' + i.Craft,
       	i.PRCo, 'C', 'City', d.City, i.City,
       	getdate(), SUSER_SNAME()	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.Craft = d.Craft
           join dbo.PRCO p on i.PRCo = p.PRCo
           where isnull(i.City,'') <> isnull(d.City,'') and p.AuditCraftClass = 'Y'
       insert into dbo.bHQMA select 'bPRCM',
       	'Craft: ' + i.Craft,
       	i.PRCo, 'C', 'State', d.State, i.State,
       	getdate(), SUSER_SNAME()	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.Craft = d.Craft
           join dbo.PRCO p on i.PRCo = p.PRCo
           where isnull(i.State,'') <> isnull(d.State,'') and p.AuditCraftClass = 'Y'
       insert into dbo.bHQMA select 'bPRCM',
       	'Craft: ' + i.Craft,
       	i.PRCo, 'C', 'Zip', d.Zip, i.Zip,
       	getdate(), SUSER_SNAME()	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.Craft = d.Craft
           join dbo.PRCO p on i.PRCo = p.PRCo
           where isnull(i.Zip,'') <> isnull(d.Zip,'') and p.AuditCraftClass = 'Y'
       insert into dbo.bHQMA select 'bPRCM',
       	'Craft: ' + i.Craft,
       	i.PRCo, 'C', 'Country', d.Country, i.Country,
       	getdate(), SUSER_SNAME()	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.Craft = d.Craft
           join dbo.PRCO p on i.PRCo = p.PRCo
           where isnull(i.Country,'') <> isnull(d.Country,'') and p.AuditCraftClass = 'Y'
       insert into dbo.bHQMA select 'bPRCM',
       	'Craft: ' + i.Craft,
       	i.PRCo, 'C', 'Effective Date', convert(varchar(11),d.EffectiveDate), convert(varchar(11),i.EffectiveDate),
       	getdate(), SUSER_SNAME()	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.Craft = d.Craft
           join dbo.PRCO p on i.PRCo = p.PRCo
           where isnull(i.EffectiveDate,0) <> isnull(d.EffectiveDate,0) and p.AuditCraftClass = 'Y'
       insert into dbo.bHQMA select 'bPRCM',
       	'Craft: ' + i.Craft,
       	i.PRCo, 'C', 'Report Type', d.ReportType, i.ReportType,
       	getdate(), SUSER_SNAME()	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.Craft = d.Craft
           join dbo.PRCO p on i.PRCo = p.PRCo
           where isnull(i.ReportType,'') <> isnull(d.ReportType,'') and p.AuditCraftClass = 'Y'
       insert into dbo.bHQMA select 'bPRCM',
       	'Craft: ' + i.Craft,
       	i.PRCo, 'C', 'Vendor Group', convert(varchar(6),d.VendorGroup), convert(varchar(6),i.VendorGroup),
       	getdate(), SUSER_SNAME()	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.Craft = d.Craft
           join dbo.PRCO p on i.PRCo = p.PRCo
           where isnull(i.VendorGroup,0) <> isnull(d.VendorGroup,0) and p.AuditCraftClass = 'Y'
       insert into dbo.bHQMA select 'bPRCM',
       	'Craft: ' + i.Craft,
       	i.PRCo, 'C', 'Vendor', convert(varchar(6),d.Vendor), convert(varchar(6),i.Vendor),
       	getdate(), SUSER_SNAME()	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.Craft = d.Craft
           join dbo.PRCO p on i.PRCo = p.PRCo
           where isnull(i.Vendor,0) <> isnull(d.Vendor,0) and p.AuditCraftClass = 'Y'
       insert into dbo.bHQMA select 'bPRCM',
       	'Craft: ' + i.Craft,
       	i.PRCo, 'C', 'OT Schedule', convert(varchar(3),d.OTSched), convert(varchar(3),i.OTSched),
       	getdate(), SUSER_SNAME()	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.Craft = d.Craft
           join dbo.PRCO p on i.PRCo = p.PRCo
           where isnull(i.OTSched,0) <> isnull(d.OTSched,0) and p.AuditCraftClass = 'Y'
   	   insert into dbo.bHQMA select 'bPRCM',
		'Craft: ' + i.Craft,
   		i.PRCo, 'C', 'Holiday OT', d.HolidayOT, i.HolidayOT, 
		getdate(), SUSER_SNAME()   	from inserted i
   		   join deleted d on i.PRCo = d.PRCo and i.Craft = d.Craft
           join dbo.PRCO p on i.PRCo = p.PRCo
       	   where d.HolidayOT <> i.HolidayOT and p.AuditCraftClass = 'Y'
       insert into dbo.bHQMA select 'bPRCM',
       	'Craft: ' + i.Craft,
       	i.PRCo, 'C', 'Max Hrs Per Week', convert(varchar,d.MaxRegHrsPerWeek), convert(varchar,i.MaxRegHrsPerWeek),
       	getdate(), SUSER_SNAME()	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.Craft = d.Craft
           join dbo.PRCO p on i.PRCo = p.PRCo
           where isnull(i.MaxRegHrsPerWeek,0) <> isnull(d.MaxRegHrsPerWeek,0) and p.AuditCraftClass = 'Y'

       insert into dbo.bHQMA select 'bPRCM',
       	'Craft: ' + i.Craft,
       	i.PRCo, 'C', 'Superannuation Weekly Minimum', convert(varchar,d.SuperWeeklyMin), convert(varchar,i.SuperWeeklyMin),
       	getdate(), SUSER_SNAME()	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.Craft = d.Craft
           join dbo.PRCO p on i.PRCo = p.PRCo
           where isnull(i.SuperWeeklyMin,0) <> isnull(d.SuperWeeklyMin,0) and p.AuditCraftClass = 'Y'
      end
   
   
   return
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot update PR Craft Master!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
  
 




GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPRCM] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPRCM] ON [dbo].[bPRCM] ([PRCo], [Craft]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
