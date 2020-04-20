CREATE TABLE [dbo].[bEMEH]
(
[EMCo] [dbo].[bCompany] NOT NULL,
[OldEquipmentCode] [dbo].[bEquip] NOT NULL,
[NewEquipmentCode] [dbo].[bEquip] NOT NULL,
[VPUserName] [dbo].[bVPUserName] NOT NULL,
[ChangeStartDate] [dbo].[bDate] NULL,
[ChangeCompleteDate] [dbo].[bDate] NULL
) ON [PRIMARY]
ALTER TABLE [dbo].[bEMEH] ADD
CONSTRAINT [FK_bEMEH_bEMCO_EMCo] FOREIGN KEY ([EMCo]) REFERENCES [dbo].[bEMCO] ([EMCo])
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    trigger [dbo].[btEMEHd] on [dbo].[bEMEH] for DELETE as   
/*********************************************************************
*	CREATED BY: TRL 09/04/08 Issue 126196
*	MODIFIED By:
*			
*	This trigger rejects delete in bEMEH (EM Equipment Change Header) when the following conditions exist:
*
*	1. If the ChangeInProgress flag has not be set to No, EMEH rec can be deleted
*	2. Entry exists in bEMED - EM Equipment Change Detail
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

--Check bEMED,no change detail records should exist. 
if exists(select * from deleted d
	Inner Join bEMED e with(nolock) on e.EMCo = d.EMCo and e.VPUserName=d.VPUserName 
	and e.OldEquipmentCode=d.OldEquipmentCode and e.NewEquipmentCode=d.NewEquipmentCode) 
begin
   	select @errmsg = 'Records exist in EM Equipment Change Detail table (bEMED).'
   	goto error
end
   

   
return
   
error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot delete Equipment Change Header!'
	
	RAISERROR(@errmsg, 11, -1);
   
	rollback transaction
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE trigger [dbo].[btEMEHu] on [dbo].[bEMEH] for update as
/*--------------------------------------------------------------
 * Created:  TRL  09/02/08 Issue 126196
 * Modified:
 *			
 *  Update Trigger for EM Equipment Change Header
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
		select @errmsg = 'Primary key fields may not be changed'
        GoTo error
    End
End

return
           
     
error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot update EM Equipment Change Header!'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
     
     
     
     
     
    
    
    
    
    
    
    
   
   
   
   
   
   
   
   
  
 



GO
