CREATE TABLE [dbo].[vRPRMc]
(
[Mod] [char] (2) COLLATE Latin1_General_BIN NOT NULL,
[ReportID] [int] NOT NULL,
[MenuSeq] [smallint] NULL,
[Active] [dbo].[bYN] NOT NULL
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [viRPRMc] ON [dbo].[vRPRMc] ([Mod], [ReportID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO








CREATE    trigger [dbo].[vtRPRMci] on [dbo].[vRPRMc] for INSERT 
/*-----------------------------------------------------------------
 *	Created: GG 08/01/03
 *	Modified:
 *
 *	This trigger rejects insertion in vRPRMc (Custom Module Reports) if
 *	any of the following error conditions exist:
 *
 *		Invalid Module
 *		Invalid Report
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
join dbo.vDDMO m on m.Mod = i.Mod
if @validcnt <> @numrows
 	begin
 	select @errmsg = 'Invalid Module'
 	goto error
 	end
 
-- check Report
select @validcnt = count(*)
from inserted i
join dbo.RPRTShared r on r.ReportID = i.ReportID
if @validcnt <> @numrows
 	begin
 	select @errmsg = 'Invalid Report ID'
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
    select @errmsg = @errmsg + ' - cannot insert Module Report (vRPRMc)!'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
 
 










GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



/****** Object:  Trigger dbo.vtRPRMcu    Script Date: 8/28/99 9:38:16 AM ******/
CREATE      trigger [dbo].[vtRPRMcu] on [dbo].[vRPRMc] for UPDATE as
 

/* UPDATE trigger on vRPRMc
  *  Modified - DANF 12/03/2003 - 23061 Added isnull check, with (nolock) and dbo.
  *  Modified - TerryLis 06/13/2005, Changed for VP6
  */
   declare
 	@numrows int,
 	@nullcnt int,
 	@validcnt int,
 	@errno   int,
 	@errmsg  varchar(255)
  
 
   select @numrows = @@rowcount
   set nocount on
 
 select @validcnt=count(*) from dbo.vDDMO m with (nolock)
 	join inserted on m.Mod=inserted.Mod
 if @validcnt<>@numrows
 	begin
 	select @errmsg='Invalid Module'
 	goto error
 	end
 
 select @validcnt=count(*) from dbo.RPRTShared r with (nolock)
 	join inserted on r.ReportID=inserted.ReportID
 if @validcnt<>@numrows
 	begin
 	select @errmsg='Report ID not found in vRPRTc'
 	goto error
 	end
 return
 
 error:
 select @errmsg=isnull(@errmsg,'') + ' - cannot insert Module'
 RAISERROR(@errmsg, 11, -1);
 
 rollback transaction
 
 
 
 









GO

EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[vRPRMc].[Active]'
GO
