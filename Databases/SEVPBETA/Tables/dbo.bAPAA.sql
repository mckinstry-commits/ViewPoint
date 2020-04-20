CREATE TABLE [dbo].[bAPAA]
(
[VendorGroup] [dbo].[bGroup] NOT NULL,
[Vendor] [dbo].[bVendor] NOT NULL,
[AddressSeq] [tinyint] NOT NULL,
[Type] [tinyint] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[Address] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[City] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[State] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[Zip] [dbo].[bZip] NULL,
[Address2] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[Country] [char] (2) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE    trigger [dbo].[btAPAAd] on [dbo].[bAPAA] for DELETE as
   

/*-----------------------------------------------------------------
    * Created: MV 11/06/02
    * Modified: 
    *
    *	This trigger restricts deletion of any APAA records if
    *	AddressSeq exists in APTH, APUI, APRH, or POHD.
    *
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   if exists(select * from bAPTH a, deleted d where a.VendorGroup=d.VendorGroup and a.Vendor=d.Vendor
   		and a.AddressSeq=d.AddressSeq)
   	begin
   	select @errmsg='AP Transaction(s) exist'
   	goto error
   	end
   if exists(select * from bAPUI a, deleted d where a.VendorGroup=d.VendorGroup and a.Vendor=d.Vendor
   		and a.AddressSeq=d.AddressSeq)
   	begin
   	select @errmsg='AP Unapproved Invoice(s) exist'
   	goto error
   	end
   
   if exists(select * from bAPRH a, deleted d where a.VendorGroup=d.VendorGroup and a.Vendor=d.Vendor
   		and a.AddressSeq=d.AddressSeq)
   	begin
   	select @errmsg='AP Recurring Invoice(s) exist'
   	goto error
   	end
   /*if exists(select * from bPOHD a, deleted d where a.VendorGroup=d.VendorGroup and a.Vendor=d.Vendor
   		and (a.PayAddressSeq=d.AddressSeq or a.POAddressSeq=d.AddressSeq))
   	begin
   	select @errmsg='Purchase Order(s) exist'
   	goto error
   	end*/
   
   
   return
   error:
   	select @errmsg = @errmsg + ' - cannot delete AP Additonal Address!'
       	RAISERROR(@errmsg, 11, -1);
       	rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
   
CREATE trigger [dbo].[btAPAAi] on [dbo].[bAPAA] for INSERT as
/*-----------------------------------------------------------------
* Created: MV 11/04/02
* Modified: MV 03/11/08 - #127347 Validate State/Country
*			GG 06/06/08 - #128324 - fix Country/State validation 
*			GG 10/08/08 - #130130 - fix State validation
*
* Validates AP Vendor and VendorGroup.
*/----------------------------------------------------------------
   
declare @errmsg varchar(255), @validcnt int, @numrows int, @nullcnt int

SELECT @numrows = @@rowcount
IF @numrows = 0 return

SET nocount on

/* validate Vendor  */
SELECT @validcnt = count(*)
FROM dbo.bAPVM v (nolock)
Join inserted i on v.VendorGroup=i.VendorGroup and v.Vendor=i.Vendor
IF @validcnt <> @numrows
	BEGIN
	SELECT @errmsg = 'Invalid Vendor'
	GOTO error
	end
   	
/* Validate Country */
select @validcnt = count(1) 
from dbo.bHQCountry c (nolock) 
join inserted i on i.Country=c.Country
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

return

error:
	SELECT @errmsg = @errmsg +  ' - cannot insert AP Additional Address!'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE  trigger [dbo].[btAPAAu] on [dbo].[bAPAA] for UPDATE as
/*-----------------------------------------------------------------
* Created: MV 11/04/02
* Modified: MV 03/11/08 issue #127347 International addresses
*			GG 06/06/08 - #128324 - fix Country/State validation 
*			GG 10/08/08 - #130130 - fix State validation
*
* Validates Vendor and VendorGroup.
* Cannot change primary key - VendorGroup,Vendor, AddressSeq
*/----------------------------------------------------------------


	declare @errmsg varchar(255), @numrows int, @validcnt int, @nullcnt int,
		@validcnt2 int
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on

   /* check for key changes */
   select @validcnt = count(*) from deleted d
       join inserted i on d.VendorGroup=i.VendorGroup and d.Vendor=i.Vendor
   		and d.AddressSeq=i.AddressSeq
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Cannot change Vendor or Sequence'
   	goto error
   	end
   
   /* validate Vendor  */
   SELECT @validcnt = count(*) FROM bAPVM a
      JOIN inserted i ON a.VendorGroup = i.VendorGroup and a.Vendor = i.Vendor
   IF @validcnt <> @numrows
      BEGIN
      SELECT @errmsg = 'Invalid Vendor'
      GOTO error
      END
   
if update(Country)
	begin
	/* Validate Country */
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
if update(Country) or update(State)
	begin
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
	end

return

error:
   	select @errmsg = @errmsg + ' - cannot update AP Additional Address!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
  
 



GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bAPAA] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biAPAA] ON [dbo].[bAPAA] ([VendorGroup], [Vendor], [AddressSeq]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
