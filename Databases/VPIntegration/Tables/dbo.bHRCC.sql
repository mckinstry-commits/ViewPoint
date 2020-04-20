CREATE TABLE [dbo].[bHRCC]
(
[HRCo] [dbo].[bCompany] NOT NULL,
[ClaimContact] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Name] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[Address] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[City] [dbo].[bDesc] NULL,
[State] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[Zip] [dbo].[bZip] NULL,
[Phone] [dbo].[bPhone] NULL,
[Fax] [dbo].[bPhone] NULL,
[Email] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[Web_Address] [varchar] (30) COLLATE Latin1_General_BIN NULL,
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
-- =============================================
-- Author:		MarkH
-- Create date: 4/1/2008
-- Description:	Prevent deletion of Contacts that are in use 
--				in bHRAI and bHRAC
-- =============================================
CREATE TRIGGER [dbo].[btHRCCd] ON  [dbo].[bHRCC] for delete
AS 
BEGIN

declare @validcnt int, @validcnt2 int, @nullcnt int, @errmsg varchar(100), @numrows integer

	select @numrows = @@rowcount
	if @numrows = 0 return

	SET NOCOUNT ON;

	/* check HRAI */
	if exists(select 1 from dbo.bHRAI h with (nolock)
		join deleted d on h.HRCo = d.HRCo and h.AttendingPhysician = d.ClaimContact)
	begin
		select @errmsg = 'Contact assigned as an Attending Physician in HR Accident Detail.'
		goto error
	end
	
	if exists(select 1 from dbo.bHRAC h with (nolock)
		join deleted d on h.HRCo = d.HRCo and h.ClaimContact = d.ClaimContact)
	begin
		select @errmsg = 'Contact assigned as a Claim Contact in HR Accident Contacts.'
		goto error
	end


return

error:

	select @errmsg = @errmsg + ' - cannot update HR Claims Contact!'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction

END

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[btHRCCi] ON  [dbo].[bHRCC] for insert
-- =============================================
-- Created: ??
-- Modified: GG 06/16/08 - #128324 - fix Country/State validation
--
-- 
-- =============================================

AS 

declare @validcnt int, @validcnt2 int, @nullcnt int, @errmsg varchar(100), @numrows integer

select @numrows = @@rowcount
if @numrows = 0 return

SET NOCOUNT on

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
-- validate Country/State combinations
select @validcnt = count(1) -- Country/State combos are unique
from inserted i
join dbo.bHQCO c (nolock) on c.HQCo = i.HRCo	-- join to get Default Country
join dbo.bHQST s (nolock) on isnull(i.Country,c.DefaultCountry) = s.Country and i.State = s.State
select @nullcnt = count(1) from inserted where State is null
if @validcnt + @nullcnt <> @numrows
	begin
	select @errmsg = 'Invalid Country and State combination'
	goto error
	end
	
return

error:
	select @errmsg = @errmsg + ' - cannot insert HR Claims Contact!'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[btHRCCu] ON  [dbo].[bHRCC] for update
-- =============================================
-- Created:	??	
-- Modified: GG 06/16/08 - #128324 - fix Country/State validation
-- 
-- 
-- =============================================
AS 

declare @validcnt int, @validcnt2 int, @nullcnt int, @errmsg varchar(100), @numrows integer

select @numrows = @@rowcount
if @numrows = 0 return
SET NOCOUNT on

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
	join dbo.bHQCO c (nolock) on c.HQCo = i.HRCo	-- join to get Default Country
	join dbo.bHQST s (nolock) on isnull(i.Country,c.DefaultCountry) = s.Country and i.State = s.State
	select @nullcnt = count(1) from inserted where [State] is null
	if @validcnt + @nullcnt <> @numrows
		begin
		select @errmsg = 'Invalid Country and State combination'
		goto error
		end
	end

return

error:
	select @errmsg = @errmsg + ' - cannot update HR Claims Contact!'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction

GO
CREATE UNIQUE CLUSTERED INDEX [biHRCC] ON [dbo].[bHRCC] ([HRCo], [ClaimContact]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bHRCC] ([KeyID]) ON [PRIMARY]
GO
