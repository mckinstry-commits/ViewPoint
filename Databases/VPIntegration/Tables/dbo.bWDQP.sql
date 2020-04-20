CREATE TABLE [dbo].[bWDQP]
(
[QueryName] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[Param] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[Description] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   
   CREATE      trigger [dbo].[btWDQPd] on [dbo].[bWDQP] for delete as
   

/*--------------------------------------------------------------
   *
   *  Delete trigger for bWDQP - Notifier Jobs - 
   *                            delete trigger from jobs when deleted from Queries
   *  Created By:  TV 11/16/02
   *  Modified by: 
   *
   *--------------------------------------------------------------*/
   
   declare @numrows int, @errmsg varchar(255)--, @rcode int 
   
   
   
   set nocount on
   
   delete bWDJP from deleted d 
   where bWDJP.Param = d.Param and bWDJP.QueryName = d.QueryName
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		MV
-- Create date: 8/1/07
-- Description:	updates bWDJP when a param is added to bWDQP
-- =============================================
CREATE TRIGGER [dbo].[vtWDQPi] on [dbo].[bWDQP] for INSERT 
AS 
BEGIN
	SET NOCOUNT ON;

	declare @jobname varchar(150),@param varchar(50),@desc varchar(255),@queryname varchar(50)

    if exists(select top 1 1 from bWDJB j join inserted i on j.QueryName = i.QueryName)
	begin
		select @jobname = JobName from bWDJB j join inserted i on j.QueryName = i.QueryName
		select @queryname = QueryName, @param = Param, @desc = Description from inserted
		insert into bWDJP (JobName,Param,Description,QueryName) 
		values (@jobname,@param,@desc,@queryname)
	end

END

GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bWDQP] ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biWDQP] ON [dbo].[bWDQP] ([QueryName], [Param]) ON [PRIMARY]
GO
