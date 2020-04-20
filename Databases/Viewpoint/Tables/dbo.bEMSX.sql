CREATE TABLE [dbo].[bEMSX]
(
[ShopGroup] [int] NOT NULL,
[Shop] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[Description] [dbo].[bDesc] NULL,
[Address] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[Address2] [dbo].[bDesc] NULL,
[City] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[State] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[Zip] [dbo].[bZip] NULL,
[Fax] [dbo].[bPhone] NULL,
[Phone] [dbo].[bPhone] NULL,
[ShopManager] [dbo].[bDesc] NULL,
[InvLoc] [dbo].[bLoc] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[INCo] [dbo].[bCompany] NULL,
[LastWorkOrder] [dbo].[bWO] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[Country] [char] (2) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biEMSX] ON [dbo].[bEMSX] ([ShopGroup], [Shop]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bEMSX] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btEMSXd    Script Date: 8/28/99 9:37:21 AM ******/
   CREATE  trigger [dbo].[btEMSXd] on [dbo].[bEMSX] for DELETE as
   

declare @errmsg varchar(255), @validcnt int
   /*-----------------------------------------------------------------
    *	CREATED BY:	 JM 5/19/99
    *	MODIFIED By: GF 04/04/2003 - issue #20915 Added ShopGroup to where clause for checks
    *				 TV 02/11/04 - 23061 added isnulls
    *	This trigger rejects delete in bEMSX (EM Cost Types) if  the following error condition exists:
    *
    *		Entry exists in EMEM for ShopGroup, Shop
    *		Entry exists in EMWH for ShopGroup, Shop
    *
    */----------------------------------------------------------------
   
   if @@rowcount = 0 return
   set nocount on
   
   -- Check EMEM
   if exists(select * from deleted d, bEMEM e where d.ShopGroup=e.ShopGroup and d.Shop=e.Shop)
   	begin
   	select @errmsg = 'Entries exist in bEMEM for this Shop'
   	goto error
   	end
   
   -- Check EMWO
   if exists(select * from deleted d, bEMWH e where d.ShopGroup=e.ShopGroup and d.Shop=e.Shop)
   	begin
   	select @errmsg = 'Entries exist in bEMWH for this Shop'
   	goto error
   	end
   
   
   /*To update the EMWOShop Table*/
   /*
   if exists (select Shop from EMWOShop where Shop = (select Shop from deleted))
   	begin
   	delete  Shop from EMWOShop
   	where Shop = (select Shop from deleted)
   	end
   */
   
   return
   
   
   
   error:
       select @errmsg = isnull(@errmsg,'') + ' - cannot delete EM Shop!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
CREATE trigger [dbo].[btEMSXi] on [dbo].[bEMSX] for INSERT as
/*-----------------------------------------------------------------
* CREATED: JM 5/19/99
* MODIFIED: TV 02/11/04 - 23061 added isnulls
*			Dan So 03/14/08 - 127082 - @state bStatem TO @state varchar(4)
*			Dan So 03/19/2008 - #127082 - country validation
*			GG 06/03/08 - #128324 - fix Country/State validation
*			GG 10/08/08 - #130130 - fix State validation
*			GP 11/11/08 - 131024, fix trigger validation for INCo & InvLoc.
*
*	This trigger rejects insertion in bEMSX (EM Shops) if the following error condition exists:
*
*		Invalid State vs bHQST
*		Invalid INVLoc vs bINLM by INCo
*		Invalid INCo vs bINCO
*
*/----------------------------------------------------------------
   
declare @numrows int, @validcnt int, @nullcnt int, @errmsg varchar(255)

select @numrows = @@rowcount
if @numrows = 0 return

set nocount on
   
/* Validate ShopGroup */
select @validcnt = count(*) from dbo.bHQGP h (nolock)
join inserted i on h.Grp = i.ShopGroup
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid Shop Group'
	goto error
   	end

/* Validate Country */
select @validcnt = count(1) 
from dbo.bHQCountry c with (nolock) 
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

/* Validate INCo. */
select @validcnt = count(*) from dbo.bINCO x (nolock)
join inserted i on x.INCo = i.INCo
select @nullcnt = count(*) from inserted where INCo is null
if @validcnt + @nullcnt <> @numrows
	begin
	select @errmsg = 'Invalid IN Company'
	goto error
	end

/* Validate InvLoc. */
select @validcnt = count(*) from dbo.bINLM x (nolock)
join inserted i on x.INCo = i.INCo and x.Loc = i.InvLoc
select @nullcnt = count(*) from inserted
where InvLoc is null
if @validcnt + @nullcnt <> @numrows
	begin
	select @errmsg = 'Invalid IN Co# and Location'
	goto error
	end

   
   /*Update EMWOShop Table with new Shops*/
   /*
   if not exists (select * from EMWOShop where Shop = (select Shop from inserted))
   	begin
   	update EMWOShop
   	set Shop = (select Shop from inserted),
   	Description = (select Description from inserted)
   	end
   	*/
return
   
error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot insert EM Shop!'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE trigger [dbo].[btEMSXu] on [dbo].[bEMSX] for UPDATE as
/*-----------------------------------------------------------------
* CREATED: JM 5/19/99
* MODIFIED: JM 2-12-02 Corrected reference to EMSX to include ShopGroup in key.
*			TV 02/11/04 - 23061 added isnulls
*			Dan So 03/14/08 - 127082 - @state bStatem TO @state varchar(4)
*			Dan So 03/19/2008 - #127082 - country validation
*			GG 06/03/08 - #128324 - fix Country/State validation
*			GG 10/08/08 - #130130 - fix State validation
*			GP 11/11/08 - 131024, fix trigger validation for INCo & InvLoc.
*
*	This trigger rejects update in bEMSX (EM Shops) if  the following error condition exists:
*
*		Change in key field (Shop)
*		Invalid State vs bHQST
*		Invalid INVLoc vs bINLM by INCo
*		Invalid INCo vs bINCO
*
*/----------------------------------------------------------------
   
declare @errmsg varchar(255), @numrows int, @validcnt int, @nullcnt int

select @numrows = @@rowcount
if @numrows = 0 return

set nocount on
   
/* Check for changes to key fields. */
if update(ShopGroup)
	begin
	select @errmsg = 'Cannot change ShopGroup'
	goto error
	end
if update(Shop)
	begin
	select @errmsg = 'Cannot change Shop'
	goto error
	end
--validate Country	
if update(Country)
	begin
	-- validate Country
	select @validcnt = count(1) from dbo.bHQCountry c (nolock) 
	join inserted i on i.Country = c.Country
	select @nullcnt = count(1) from inserted where Country is null
	if @validcnt + @nullcnt <> @numrows
		begin
		select @errmsg = 'Invalid Country'
		goto error
		end
	end
--validate State
if update(State)
	begin
	-- validate State - all State values must exist in bHQST
	if exists(select top 1 1 from inserted i where [State] not in(select [State] from dbo.bHQST))
		begin
		select @errmsg = 'Invalid State'
		goto error
		end
	end
-- validate Country/State combo
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
	
/* Validate INCo. */
if update(INCo)
   	begin
	select @validcnt = count(*) from dbo.bINCO x (nolock)
	join inserted i on x.INCo = i.INCo
	select @nullcnt = count(*) from inserted where INCo is null
   	if @validcnt + @nullcnt <> @numrows
   		begin
   		select @errmsg = 'Invalid IN Company'
   		goto error
   		end
	end
/* Validate InvLoc. */
if update(InvLoc)
	begin
	select @validcnt = count(*) from dbo.bINLM x (nolock)
	join inserted i on x.INCo = i.INCo and x.Loc = i.InvLoc
	select @nullcnt = count(*) from inserted where InvLoc is null
   	if @validcnt + @nullcnt <> @numrows
   		begin
   		select @errmsg = 'Invalid IN Company and Location'
   		goto error
		end
   	end
   
return
   
error:
       select @errmsg = isnull(@errmsg,'') + ' - cannot update EM Shop!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
   
  
 



GO
