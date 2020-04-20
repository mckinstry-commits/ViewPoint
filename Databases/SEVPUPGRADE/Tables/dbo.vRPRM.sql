CREATE TABLE [dbo].[vRPRM]
(
[Mod] [char] (2) COLLATE Latin1_General_BIN NOT NULL,
[ReportID] [int] NOT NULL,
[MenuSeq] [smallint] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE TRIGGER [dbo].[vtRPRMd] ON [dbo].[vRPRM] FOR delete
/************************************
* Created: ??
* Modified: GG 08/26/08 - removed restrictions, changed auditing from bHQMA to vDDDA
*
* Delete trigger on vRPRM (Report Module assignments)
* Adds audit entry
*
************************************/
as
 
declare @errmsg varchar(255)
  
if @@rowcount = 0 return
set nocount on
 
-- DD Audit 
insert dbo.vDDDA (TableName, Action, KeyString, FieldName,
	OldValue, NewValue, RevDate, UserName, HostName)
select 'vRPRM', 'D', 'ReportID: ' + convert(varchar,ReportID) + ' Module : ' + Mod, null,
	null, null, getdate(), SUSER_SNAME(), host_name()
from deleted

return
 
error:
    select @errmsg = isnull(@errmsg,'') + ' - cannot delete Module from RPRM'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
 
 
 
 
 
 









GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE   trigger [dbo].[vtRPRMi] on [dbo].[vRPRM] for INSERT 
/*-----------------------------------------------------------------
 *	Created: GG 08/01/03
 *	Modified:
 *
 *	This trigger rejects insertion in vRPRM (Module Reports) if
 *	any of the following error conditions exist:
 *
 *		Invalid Module
 *		Invalid Report
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
 
-- check Reports
select @validcnt = count(*)
from inserted i
join dbo.vRPRT r on r.ReportID = i.ReportID
if @validcnt <> @numrows
 	begin
 	select @errmsg = 'Invalid Report'
 	goto error
 	end

return
 
error:
    select @errmsg = @errmsg + ' - cannot insert Module Report!'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
 
 







GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/****** Object:  Trigger dbo.vtRPRMu    Script Date: 8/28/99 9:38:16 AM ******/
CREATE     trigger [dbo].[vtRPRMu] on [dbo].[vRPRM] for UPDATE as
 

/* UPDATE trigger on vRPRM
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
 
 select @validcnt=count(*) from dbo.vRPRT r with (nolock)
 	join inserted on r.ReportID=inserted.ReportID
 if @validcnt<>@numrows
 	begin
 	select @errmsg='Report ID not found in vRPRT'
 	goto error
 	end
 return
 
 error:
 select @errmsg=isnull(@errmsg,'') + ' - cannot insert Module'
 RAISERROR(@errmsg, 11, -1);
 
 rollback transaction
 
 
 
 







GO
CREATE UNIQUE CLUSTERED INDEX [viRPRM] ON [dbo].[vRPRM] ([Mod], [ReportID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
