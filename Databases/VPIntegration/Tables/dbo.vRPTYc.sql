CREATE TABLE [dbo].[vRPTYc]
(
[ReportType] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Description] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[Active] [dbo].[bYN] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE    trigger [dbo].[vtRPTYcd] on [dbo].[vRPTYc] for DELETE as
/*-------------------------------------------------------------- 
 * Created: GG 10/24/06
 * Modified:
 *
 * Prevents deletion of custom Report Types if they are reference by any
 * report and has no corresponding standard entry in vRPTY.
 *
 *--------------------------------------------------------------*/ 
 declare @numrows int, @errmsg varchar(255)

 select @numrows = @@rowcount 
 if @numrows = 0 return
 set nocount on 
 
 -- check if OK to remove custom Report Type entries 
 if exists(select top 1 1 from deleted d join RPRTShared t (nolock) ON d.ReportType = t.ReportType)
	and not exists(select top 1 1 from deleted d join vRPTY t (nolock) on d.ReportType = t.ReportType)
    begin
    select @errmsg = 'Report Type in use and has no standard entry '
    goto error
    end
 
 return
 
 error:
    select @errmsg = isnull(@errmsg,'') + ' - cannot delete custom Report Type.'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
 
 
 








GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE trigger [dbo].[vtRPTYcu] on [dbo].[vRPTYc] for UPDATE as
/*************************************************
 * Created: GG 10/24/06
 * Modified:
 *
 * Prevents update of primary key (Report Type) in
 * custom Report Type table (vRPTYc).
 *
 *************************************************/
 
declare  @numrows int, @errmsg varchar(255)
 
select @numrows = @@rowcount
if @numrows = 0 return
set nocount on
 
if update(ReportType)
	begin
	select @errmsg = 'You are not allowed to change Report Type '
	goto error
	end

return

error:
     select @errmsg = isnull(@errmsg,'') + ' - cannot update custom Report Type.'
     RAISERROR(@errmsg, 11, -1);
     rollback transaction

 
 
 
 






GO
CREATE UNIQUE CLUSTERED INDEX [viRPTYc] ON [dbo].[vRPTYc] ([ReportType]) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[vRPTYc].[Active]'
GO
