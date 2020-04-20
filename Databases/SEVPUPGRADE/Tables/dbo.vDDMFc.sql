CREATE TABLE [dbo].[vDDMFc]
(
[Mod] [char] (2) COLLATE Latin1_General_BIN NOT NULL,
[Form] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[Active] [dbo].[bYN] NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE trigger [dbo].[vtDDMFci] on [dbo].[vDDMFc] for INSERT 
/*-----------------------------------------------------------------
 *	Created: GG 08/01/03
 *	Modified:
 *
 *	This trigger rejects insertion in vDDMFc (Custom Module Forms) if
 *	any of the following error conditions exist:
 *
 *		Invalid Module
 *		Invalid Form
 *		Invalid Active flag
 *
 */----------------------------------------------------------------

as
 


declare @errmsg varchar(255), @numrows int, @validcnt int

select @numrows = @@rowcount
if @numrows = 0 return

set nocount on
 
-- check Modules
select @validcnt = count(*)
from inserted i
join vDDMO m on m.Mod = i.Mod
if @validcnt <> @numrows
 	begin
 	select @errmsg = 'Invalid Module'
 	goto error
 	end
 
-- check Forms
select @validcnt = count(*)
from inserted i
join DDFHShared f on f.Form = i.Form
if @validcnt <> @numrows
 	begin
 	select @errmsg = 'Invalid Form'
 	goto error
 	end

-- check Active flag
if exists(select top 1 1 from inserted where Active not in ('Y','N'))
	begin
	select @errmsg = 'Invalid Active flag, must be ''Y'' or ''N'''
	goto error
	end

return
 
error:
    select @errmsg = @errmsg + ' - cannot insert Module Form (vDDMFc)!'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
 
 





GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE  trigger [dbo].[vtDDMFcu] on [dbo].[vDDMFc] for UPDATE 
/*-----------------------------------------------------------------
 * 	Created: GG 08/01/03
 *	Modified:
 *
 *	This trigger rejects update in vDDMF (Custom Module Forms) if the
 *	following error condition exists:
 *
 *		Cannot change Module or Form
 *		Invalid Active flag
 *
 */----------------------------------------------------------------
as


declare @errmsg varchar(255), @numrows int, @validcnt int
 	 
select @numrows = @@rowcount
if @numrows = 0 return

set nocount on
 
/* check for key change */
select @validcnt = count(*) from inserted i
	join deleted d on i.Mod = d.Mod and i.Form = d.Form 
if @validcnt <> @numrows
 	begin
 	select @errmsg = 'Cannot change Module or Form'
 	goto error
 	end
 
-- check Active flag
if exists(select top 1 1 from inserted where Active not in ('Y','N'))
	begin
	select @errmsg = 'Invalid Active flag, must be ''Y'' or ''N'''
	goto error
	end

return
 
error:
    select @errmsg = @errmsg + ' - cannot update Module Forms (vDDMFc)!'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
 







GO
CREATE UNIQUE CLUSTERED INDEX [viDDMFc] ON [dbo].[vDDMFc] ([Mod], [Form]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[vDDMFc].[Active]'
GO
