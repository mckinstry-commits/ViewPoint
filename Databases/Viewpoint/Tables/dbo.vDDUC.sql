CREATE TABLE [dbo].[vDDUC]
(
[VPUserName] [dbo].[bVPUserName] NOT NULL,
[Company] [dbo].[bCompany] NOT NULL,
[ColorSchemeID] [int] NULL,
[SmartCursorColor] [int] NULL,
[ReqFieldColor] [int] NULL,
[AccentColor1] [int] NULL,
[AccentColor2] [int] NULL,
[UseColorGrad] [dbo].[bYN] NULL,
[FormColor1] [int] NULL,
[FormColor2] [int] NULL,
[GradDirection] [tinyint] NULL,
[LabelBackgroundColor] [int] NULL,
[LabelTextColor] [int] NULL,
[LabelBorderStyle] [int] NULL
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [viDDUC] ON [dbo].[vDDUC] ([VPUserName], [Company]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





create  trigger [dbo].[vtDDUCi] on [dbo].[vDDUC] for INSERT 
/*-----------------------------------------------------------------
 * Created: GG 4/3/06
 * Modified:
 *
 *	This trigger rejects insertion in vDDUC (User Company Preferences) if
 *	any of the following error conditions exist:
 *
 *	Invalid User
 *
 * 	Audits insert in bHQMA
 *
 */----------------------------------------------------------------
as


declare @errmsg varchar(255), @numrows int, @validcnt int

select @numrows = @@rowcount
if @numrows = 0 return 
 
set nocount on
 
-- validate user
select @validcnt = count(*)
from dbo.vDDUP u (nolock)
join inserted i on u.VPUserName = i.VPUserName
if @validcnt <> @numrows
	begin
 	select @errmsg = 'Invalid User, not setup in DD User Profile'
 	goto error
 	end
 
-- add HQMA audit
insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'vDDUC', 'Name: ' + VPUserName, Company, 'A', null, null, null, getdate(), SUSER_SNAME()
from inserted

return
 
error:
	select @errmsg = @errmsg + ' - cannot insert User Company Preferences!'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction








GO

EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[vDDUC].[UseColorGrad]'
GO
