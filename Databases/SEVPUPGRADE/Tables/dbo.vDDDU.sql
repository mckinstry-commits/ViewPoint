CREATE TABLE [dbo].[vDDDU]
(
[Datatype] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[Qualifier] [tinyint] NOT NULL,
[Instance] [char] (30) COLLATE Latin1_General_BIN NOT NULL,
[VPUserName] [dbo].[bVPUserName] NOT NULL,
[Employee] [dbo].[bEmployee] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE trigger [dbo].[vtDDDUi] on [dbo].[vDDDU] for INSERT
/*****************************
* Created: DANF 02/05/2008
* Modified: 
*
* Insert trigger on vDDDU
*
*
* Updates Employee for Datatype equal to bEmployee
*
*************************************/

as

declare @errmsg varchar(255), @numrows int, @validcnt int
  
select @numrows = @@rowcount
if @numrows = 0 return

set nocount on

-- Update the Employee column if it is an Employee Data Type.
	update vDDDU 
	set Employee = i.Instance 
	from vDDDU u
	join inserted i on u.Datatype=i.Datatype and u.Qualifier=i.Qualifier and u.Instance= i.Instance and u.VPUserName=i.VPUserName
	where i.Datatype = 'bEmployee' and isnumeric(i.Instance) = 1


  	 	 	 
return

error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot insert DDDU!'
  	RAISERROR(@errmsg, 11, -1);
  	rollback transaction
  
   
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE trigger [dbo].[vtDDDUu] on [dbo].[vDDDU] for Update
/*****************************
* Created: DANF 02/05/2008
* Modified: 
*
* Update trigger on vDDDU
*
*
* Updates Employee for Datatype equal to bEmployee
*
*************************************/

as

declare @errmsg varchar(255), @numrows int, @validcnt int
  
select @numrows = @@rowcount
if @numrows = 0 return

set nocount on

-- Update the Employee column if it is an Employee Data Type.
	update vDDDU 
	set Employee = i.Instance 
	from vDDDU u
	join inserted i on u.Datatype=i.Datatype and u.Qualifier=i.Qualifier and u.Instance= i.Instance and u.VPUserName=i.VPUserName
	where i.Datatype = 'bEmployee' and isnumeric(i.Instance) = 1

  	 	 	 
return

error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot update DDDU!'
  	RAISERROR(@errmsg, 11, -1);
  	rollback transaction
  
   
GO
CREATE UNIQUE CLUSTERED INDEX [viDDDU] ON [dbo].[vDDDU] ([Datatype], [Qualifier], [Instance], [VPUserName]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [viDDDUEmployee] ON [dbo].[vDDDU] ([Employee]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [viDDDUInstance] ON [dbo].[vDDDU] ([Instance]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [viDDDUUser] ON [dbo].[vDDDU] ([VPUserName]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
