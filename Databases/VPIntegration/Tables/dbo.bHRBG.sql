CREATE TABLE [dbo].[bHRBG]
(
[HRCo] [dbo].[bCompany] NOT NULL,
[BenefitGroup] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Description] [dbo].[bDesc] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE  trigger [dbo].[btHRBGd] on [dbo].[bHRBG] for DELETE as
    
     

/*--------------------------------------------------------------
*  Delete trigger for HRBG
*  Created By: mh 03/17/06
*  Modified By: 
*               
*               
*				
*--------------------------------------------------------------*/

	declare @numrows int, @errmsg varchar(255), @validcnt int, @validcnt2 int
    
   	select @numrows = @@rowcount
   	if @numrows = 0 return
   	set nocount on
    
   	/* Check bHRGI for detail */
   	if exists(select 1 from deleted d JOIN dbo.bHRGI h ON
    	d.HRCo = h.HRCo and d.BenefitGroup = h.BenefitGroup)
   	begin
       	select @errmsg = 'Entries exist in bHRGI.  Remove using HR Benefit Group.'
   		goto error
   	end
   
   	return
    
   	error:
   		select @errmsg = @errmsg + ' - cannot delete from HRBG'
   		RAISERROR(@errmsg, 11, -1);
   		rollback transaction
    
    




GO
CREATE UNIQUE CLUSTERED INDEX [biHRBG] ON [dbo].[bHRBG] ([HRCo], [BenefitGroup]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bHRBG] ([KeyID]) ON [PRIMARY]
GO
