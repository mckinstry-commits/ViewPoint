CREATE TABLE [dbo].[vDDBICompanies]
(
[Co] [dbo].[bCompany] NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE trigger [dbo].[vtvDDBICompaniesi] on [dbo].[vDDBICompanies] for INSERT as
/*-----------------------------------------------------------------
*  Created: DH 1/30/09
*  Modified:
*
*  Validates that company exists in HQ Company.
*
*/----------------------------------------------------------------
declare @errmsg varchar(255), @numrows int, @validcnt int
   
select @numrows = @@rowcount
if @numrows = 0 return
   
set nocount on
   
/* validate Company # in HQ */
select @validcnt = count(*) from inserted i
join dbo.bHQCO h (nolock) on h.HQCo = i.Co
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid Company'
	goto error
	end

return
   
error:
   	select @errmsg = @errmsg + ' - cannot insert Company!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
GO
ALTER TABLE [dbo].[vDDBICompanies] ADD CONSTRAINT [PK_vDDBICompanies] PRIMARY KEY CLUSTERED  ([Co]) ON [PRIMARY]
GO
