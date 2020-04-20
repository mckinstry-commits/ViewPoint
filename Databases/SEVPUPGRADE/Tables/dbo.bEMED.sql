CREATE TABLE [dbo].[bEMED]
(
[EMCo] [dbo].[bCompany] NOT NULL,
[OldEquipmentCode] [dbo].[bEquip] NOT NULL,
[NewEquipmentCode] [dbo].[bEquip] NOT NULL,
[VPUserName] [dbo].[bVPUserName] NOT NULL,
[VPMod] [varchar] (2) COLLATE Latin1_General_BIN NOT NULL,
[VPTableName] [dbo].[bDesc] NOT NULL,
[VPColumnName] [varchar] (60) COLLATE Latin1_General_BIN NOT NULL,
[VPColType] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[VPEMCo] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[RecordsChanged] [numeric] (18, 0) NULL,
[ChangeStatus] [varchar] (256) COLLATE Latin1_General_BIN NULL,
[RecordCount] [numeric] (18, 0) NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    trigger [dbo].[btEMEDd] on [dbo].[bEMED] for DELETE as   
/*********************************************************************
*	CREATED BY: TRL 09/04/08 Issue 126196
*	MODIFIED By:
*			
*	This trigger rejects delete in bEMED (EM Equipment Change Detail) when the following conditions exist:
*
*	1. If the EMEM ChangeInProgress flag has not be set to No, EMED rec can be deleted
*
********************************************************************/
declare @errmsg varchar(255), @validcnt int 

if @@rowcount = 0 return

set nocount on

--Check bEMEM
if exists(select * from deleted d
	Inner Join bEMEM e with(nolock)on e.EMCo=d.EMCo and e.Equipment = d.NewEquipmentCode and e.LastUsedEquipmentCode=d.OldEquipmentCode
	Where IsNull(ChangeInProgress,'N') = 'Y') 
begin
   	select @errmsg = 'The EM Equipment Change In Progress flag is still set is still Yes '
   	goto error
end   
  
return
   
error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot delete Equipment!'
	
	RAISERROR(@errmsg, 11, -1);
   
	rollback transaction
   
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE trigger [dbo].[btEMEDu] on [dbo].[bEMED] for update as
/*--------------------------------------------------------------
 * Created:  TRL  09/02/08 Issue 126196
 * Modified:
 *			
 *  Update Trigger for EM Equipment Change Detail
 *
 *--------------------------------------------------------------*/
declare @numrows int, @errmsg varchar(255), @validcnt int
     
 select @numrows = @@rowcount

 if @numrows = 0 return

 set nocount on

if update(EMCo) or Update(OldEquipmentCode) or Update(NewEquipmentCode)or Update(VPUserName)
begin
	select @validcnt = count(*) from inserted i 
	Inner JOIN deleted d ON d.EMCo = i.EMCo and d.OldEquipmentCode=i.OldEquipmentCode 
	and d.NewEquipmentCode=i.NewEquipmentCode and d.VPUserName=i.VPUserName 
    if @validcnt <> @numrows
    begin
		select @errmsg = 'Primary key fields may not be changed!'
        GoTo error
    End
End

return
           
     
error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot update EM Equipment Change Detail!'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
     
     
GO
