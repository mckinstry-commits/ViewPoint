CREATE TABLE [dbo].[bPMPD]
(
[PMCo] [dbo].[bCompany] NULL,
[Project] [dbo].[bJob] NOT NULL,
[PunchList] [dbo].[bDocument] NOT NULL,
[Item] [smallint] NOT NULL,
[ItemLine] [tinyint] NOT NULL,
[Description] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Location] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[VendorGroup] [dbo].[bGroup] NULL,
[ResponsibleFirm] [dbo].[bFirm] NULL,
[DueDate] [dbo].[bDate] NULL,
[FinDate] [dbo].[bDate] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
ALTER TABLE [dbo].[bPMPD] ADD
CONSTRAINT [FK_bPMPD_bJCJM] FOREIGN KEY ([PMCo], [Project]) REFERENCES [dbo].[bJCJM] ([JCCo], [Job])
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
   
   /****** Object:  Trigger dbo.btPMPDu    Script Date: 8/28/99 9:23:11 AM ******/
    
    CREATE  trigger [dbo].[btPMPDu] on [dbo].[bPMPD] for UPDATE as
     

    /*--------------------------------------------------------------
     *
     *  Update trigger for PMPD
     *  Created By: LM
     *  Date:       1/9/98
     *  Modified By:  bc 11/19/98
     *					JayR 03/23/2012 - TK-00000 Change to use FKs for validation, removed unused variables
     *
     *--------------------------------------------------------------*/
     if @@rowcount = 0 return
     set nocount on
   
   -- check for changes to PMCo
    if update(PMCo)
       begin
       RAISERROR('Cannot change PM Company - cannot update PMPD', 11, -1)
       ROLLBACK TRANSACTION
       RETURN 
       end
   
   -- check for changes to Project
    if update(Project)
       begin
       RAISERROR('Cannot change Project - cannot update PMPD', 11, -1)
       ROLLBACK TRANSACTION
       RETURN 
       end
   
   -- check for changes to PunchList
    if update(PunchList)
       begin
       RAISERROR('Cannot change PunchList - cannot update PMPD', 11, -1)
       ROLLBACK TRANSACTION
       RETURN 
       end
   
   -- check for changes to Item
    if update(Item)
       begin
       RAISERROR('Cannot change Item - cannot update PMPD', 11, -1)
       ROLLBACK TRANSACTION
       RETURN 
	END
		
   -- check for changes to ItemLine
    if update(ItemLine)
       begin
       RAISERROR('Cannot change ItemLine - cannot update PMPD', 11, -1)
       ROLLBACK TRANSACTION
       RETURN 
       end
   
   
   RETURN 
   
   
   
  
 



GO
ALTER TABLE [dbo].[bPMPD] WITH NOCHECK ADD CONSTRAINT [CK_bPMPD_ResponsibleFirm] CHECK (([ResponsibleFirm] IS NULL OR [VendorGroup] IS NOT NULL))
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPMPD] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPMPD] ON [dbo].[bPMPD] ([PMCo], [Project], [PunchList], [Item], [ItemLine]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO

ALTER TABLE [dbo].[bPMPD] WITH NOCHECK ADD CONSTRAINT [FK_bPMPD_bPMPL] FOREIGN KEY ([PMCo], [Project], [Location]) REFERENCES [dbo].[bPMPL] ([PMCo], [Project], [Location])
GO
ALTER TABLE [dbo].[bPMPD] WITH NOCHECK ADD CONSTRAINT [FK_bPMPD_bPMPU] FOREIGN KEY ([PMCo], [Project], [PunchList]) REFERENCES [dbo].[bPMPU] ([PMCo], [Project], [PunchList])
GO
ALTER TABLE [dbo].[bPMPD] WITH NOCHECK ADD CONSTRAINT [FK_bPMPD_bPMPI] FOREIGN KEY ([PMCo], [Project], [PunchList], [Item]) REFERENCES [dbo].[bPMPI] ([PMCo], [Project], [PunchList], [Item])
GO
ALTER TABLE [dbo].[bPMPD] WITH NOCHECK ADD CONSTRAINT [FK_bPMPD_bPMFM] FOREIGN KEY ([VendorGroup], [ResponsibleFirm]) REFERENCES [dbo].[bPMFM] ([VendorGroup], [FirmNumber])
GO
