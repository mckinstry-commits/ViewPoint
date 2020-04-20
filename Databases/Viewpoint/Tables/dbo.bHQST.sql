CREATE TABLE [dbo].[bHQST]
(
[State] [varchar] (4) COLLATE Latin1_General_BIN NOT NULL,
[Name] [dbo].[bDesc] NULL,
[W2Name] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[Country] [char] (2) COLLATE Latin1_General_BIN NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biHQST] ON [dbo].[bHQST] ([Country], [State]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bHQST] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
  
CREATE trigger [dbo].[btHQSTd] on [dbo].[bHQST] for DELETE as
/*----------------------------------------------------------
* Created: ??
* Modified: GG 06/03/08 - #128324 - fix for Country/State validation
*			GF 03/13/2009 - issue #129409 price escalation
*
*
*	This trigger rejects delete in bHQST (HQ States) if a 
*	dependent record is found in:
*
*		HQCO - Company
*		HQRS - Reciprocal States (Job State or Resident State)
*
*/---------------------------------------------------------
declare @errmsg varchar(255), @numrows int

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on
   
-- check for Country/State use in any HQ Company
if exists(select top 1 1 from dbo.bHQCO c (nolock)
			join deleted d on d.State = c.State
			where d.Country = c.Country or d.Country = c.DefaultCountry)
	begin
	select @errmsg = 'Country and State combination assigned in HQ Company'
	goto error
	end
   
/* check HQRS.JobState */
if exists(select top 1 1 from dbo.bHQRS r (nolock)
			join deleted d on r.JobState = d.State)
	begin
	-- make sure at least one HQ State entry exists for the Job State
	if not exists(select top 1 1 from dbo.bHQST s (nolock)
					join dbo.bHQRS r on r.JobState = s.State)
		begin
		select @errmsg = 'Reciprocal Job State entries exist for this State'
		goto error
		end
	end
/* check HQRS.ResidentState */
if exists(select top 1 1 from dbo.bHQRS r (nolock)
			join deleted d on r.ResidentState = d.State)
	begin
	-- make sure at least one HQ State entry exists for the Resident State
	if not exists(select top 1 1 from dbo.bHQST s (nolock)
					join dbo.bHQRS r on r.ResidentState = s.State)
		begin
		select @errmsg = 'Reciprocal Resident State entries exist for this State'
		goto error
		end
	end

---- check HQPO.Country and HQPO.State #129409
if exists(select top 1 1 from dbo.bHQPO p with (nolock)	join deleted d on p.State = d.State)
	begin
	---- make sure at least one HQ State entry exists for the Price Index State
	if not exists(select top 1 1 from dbo.bHQST s with (nolock) join dbo.bHQPO p on p.State = s.State)
		begin
		select @errmsg = 'Price Index entries exist for this state'
		goto error
		end
	end
   
   
return
   
error:
	select @errmsg = @errmsg + ' - cannot delete HQ State!'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction

   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
CREATE trigger [dbo].[btHQSTi] on [dbo].[bHQST] for INSERT as
/*-----------------------------------------------------------------
*  Created GG 06/06/08  - #128324 - created to add Country validation
*  Modified: 
*
*	This trigger rejects insertion in bHQST (States)
*	if any of the following error conditions exist:
*
*		Invalid Country
*
*/----------------------------------------------------------------
declare @numrows int, @validcnt int, @errmsg varchar(255)

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

-- validate Country
select @validcnt = count(1)
from dbo.bHQCountry c (nolock)
join inserted i on i.Country = c.Country
if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid Country'
   	goto error
   	end
  
return

error:
   	select @errmsg = @errmsg + ' - cannot insert HQ State code!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 

CREATE trigger [dbo].[btHQSTu] on [dbo].[bHQST] for UPDATE as
/*-----------------------------------------------------------------
* Created: ??
* Modified: GG 06/06/08 - #128234 - add Country to key check
*
*	This trigger rejects update in bHQST (HQ States) if the 
*	following error condition exists:
*
*		Cannot change HQ Country or State
*
*/----------------------------------------------------------------
declare @errmsg varchar(255), @numrows int, @validcount int   

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on
   
/* reject key changes */
if update(Country) or update([State])
	begin
	select @errmsg = 'Cannot change Country or State'
	goto error
	end

return

error:
	select @errmsg = @errmsg + ' - cannot update HQ State!'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction

   
   
  
 



GO
