CREATE TABLE [dbo].[vRPTY]
(
[ReportType] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Description] [varchar] (30) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE trigger [dbo].[vtRPTYd] on [dbo].[vRPTY] for DELETE as
/*-------------------------------------------------------------- 
 * Created:  GG 10/24/06
 * Modified:
 *  
 * Prevents deletion of standard Report Types if they are referenced by any report
 * 
 *--------------------------------------------------------------*/
declare @numrows int, @errmsg varchar(255) 

select @numrows = @@rowcount 
if @numrows = 0 return
set nocount on 
 
-- check for use on existing reports
if exists(select top 1 1 from deleted d 
    join dbo.RPRTShared o with (nolock) ON d.ReportType = o.ReportType)
    begin
    select @errmsg = 'Report Type is in use on existing reports'
    goto error
    end

return
 
error:
    select @errmsg = isnull(@errmsg,'') + ' - cannot delete Report Type.'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
 
 
 







GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE  trigger [dbo].[vtRPTYu] on [dbo].[vRPTY] for UPDATE as
/**********************************************
 * Created: TL 6/13/05
 * Modified: GG 10/25/06
 *
 * Prevents update of primary key (Report Type)
 *
 *******************************************/

declare @numrows int, @errmsg  varchar(255)
 
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
     select @errmsg = isnull(@errmsg,'') + ' - cannot update Report Type.'
     RAISERROR(@errmsg, 11, -1);
     rollback transaction

GO
CREATE UNIQUE CLUSTERED INDEX [viRPTY] ON [dbo].[vRPTY] ([ReportType]) ON [PRIMARY]
GO
