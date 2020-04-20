CREATE TABLE [dbo].[bHRRE]
(
[State] [varchar] (4) COLLATE Latin1_General_BIN NOT NULL,
[LicCodeType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[LicCode] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[LicDesc] [varchar] (250) COLLATE Latin1_General_BIN NULL,
[Country] [char] (2) COLLATE Latin1_General_BIN NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[UniqueAttchID] [uniqueidentifier] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   CREATE trigger [dbo].[btHRREd] on [dbo].[bHRRE] for DELETE as
    
     

/*--------------------------------------------------------------
      *  Delete trigger for HRRE
      *  Created By: mh 5/20/05
      *  Modified By: 
      *               
      *               
      *				
      *--------------------------------------------------------------*/
   	declare @numrows int, @errmsg varchar(255), @validcnt int, @validcnt2 int
    
   	select @numrows = @@rowcount
   	if @numrows = 0 return
   	set nocount on
    
   	/* Check bHRDL for detail */
   	if exists(select 1 from deleted d JOIN dbo.bHRDL h ON
               d.State = h.State  and d.LicCodeType = h.LicCodeType and d.LicCode = h.LicCode)
   	begin
       	select @errmsg = 'Entries exist in bHRDL.  Remove using Resource Master.'
   		goto error
   	end
   
   	return
    
   	error:
   		select @errmsg = @errmsg + ' - cannot delete from HRRE'
   		RAISERROR(@errmsg, 11, -1);
   		rollback transaction
    
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   CREATE trigger [dbo].[btHRREi] on [dbo].[bHRRE] for INSERT as
   	

/**************************************************************
   	*   Created by: mh 08/16/2004
   	*	Modified by: 
   	*
   	*
   	*	This trigger rejects insert into bHRRE (License Restriction/Endorsement) if the
   	*	following error condition exists:
   	*
   	*		LicCodeType not in:
   	*			C - Certificate
   	*			E - Endorsement
   	*			R - Restriction
   	*
   	***************************************************************/
    
   	declare @errmsg varchar(255), @numrows int 
   
   	select @numrows = @@rowcount
   	if @numrows = 0 return
   	set nocount on
   
   	if exists(select 1 from inserted where LicCodeType not in ('C', 'R', 'E'))
   	begin
   		select @errmsg = 'Not a valid License Code Type.  Must be ''C'', ''R'', or ''E''.'
   		goto error
   	end
   
    
   	return
    
   error:
     	select @errmsg = @errmsg + ' - cannot insert HR Restriction Endorsement!'
     	RAISERROR(@errmsg, 11, -1);
    
     	rollback transaction
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   CREATE trigger [dbo].[btHRREu] on [dbo].[bHRRE] for UPDATE as
   
   	

/**************************************************************
   	*   Created by: mh 08/16/2004
   	*	Modified by: 
   	*
   	*
   	*	This trigger rejects update to bHRRE (License Restriction/Endorsement) if the
   	*	following error condition exists:
   	*
   	*		LicCodeType not in:
   	*			C - Certificate
   	*			E - Endorsement
   	*			R - Restriction
   	*
   	***************************************************************/
   	declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int,
   	@hrco bCompany, @hrref bHRRef, @seq int, @code varchar(10), @rewardseq int
   
   	select @numrows = @@rowcount
   	if @numrows = 0 return
   	set nocount on
   
   	/* check for key changes */
   	if update(State)
   	begin
   		select @validcnt = count(i.State) from inserted i join deleted d on
   		i.State = d.State
   		if @validcnt <> @numrows
   		begin
   			select @errmsg = 'Cannot change License State.'
   			goto error
   		end
   	end
   
   	if update(LicCodeType)
   	begin
   		select @validcnt = count(i.LicCodeType) from inserted i join deleted d on
   		i.LicCodeType = d.LicCodeType and i.State = d.State
   		if @validcnt <> @numrows
   		begin
   			select @errmsg = 'Cannot change License Code Type'
   			goto error
   		end
   	end
   
   	if update(LicCode)
   	begin
   		select @validcnt = count(i.LicCode) from inserted i join deleted d on
   		i.State = d.State and i.LicCodeType = d.LicCodeType and i.LicCode = d.LicCode
   		if @validcnt <> @numrows
   		begin
   			select @errmsg = 'Cannot change License Code'
   			goto error
   		end
   	end
   
   
   return
   
    error:
    	select @errmsg = @errmsg + ' - cannot update HR Restriction Endorsement!'
    	RAISERROR(@errmsg, 11, -1);
   
    	rollback transaction
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biHRRE] ON [dbo].[bHRRE] ([Country], [State], [LicCodeType], [LicCode]) ON [PRIMARY]
GO
