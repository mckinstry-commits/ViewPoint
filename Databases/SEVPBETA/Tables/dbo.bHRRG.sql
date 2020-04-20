CREATE TABLE [dbo].[bHRRG]
(
[HRCo] [dbo].[bCompany] NOT NULL,
[RatingGroup] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
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



CREATE   trigger [dbo].[btHRRGd] on [dbo].[bHRRG] for DELETE as
    
     

/*--------------------------------------------------------------
*  Delete trigger for HRRG
*  Created By: mh 02/17/06
*  Modified By: 
*               
*               
*				
*--------------------------------------------------------------*/

	declare @numrows int, @errmsg varchar(255), @validcnt int, @validcnt2 int
    
   	select @numrows = @@rowcount
   	if @numrows = 0 return
   	set nocount on
    
   	/* Check bHRRI for detail */
   	if exists(select 1 from deleted d JOIN dbo.bHRRI h ON
    	d.HRCo = h.HRCo and d.RatingGroup = h.RatingGroup)
   	begin
       	select @errmsg = 'Entries exist in bHRRI.  Remove using HR Rating Group Codes.'
   		goto error
   	end
   
   	return
    
   	error:
   		select @errmsg = @errmsg + ' - cannot delete from HRRG'
   		RAISERROR(@errmsg, 11, -1);
   		rollback transaction
    
   
  
 






GO
CREATE UNIQUE CLUSTERED INDEX [biHRRG] ON [dbo].[bHRRG] ([HRCo], [RatingGroup]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bHRRG] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
