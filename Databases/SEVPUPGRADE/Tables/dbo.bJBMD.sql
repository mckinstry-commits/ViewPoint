CREATE TABLE [dbo].[bJBMD]
(
[JBCo] [dbo].[bCompany] NOT NULL,
[BillMonth] [dbo].[bMonth] NOT NULL,
[BillNumber] [int] NOT NULL,
[CustGroup] [dbo].[bGroup] NOT NULL,
[MiscDistCode] [char] (10) COLLATE Latin1_General_BIN NOT NULL,
[DistDate] [dbo].[bDate] NULL,
[Description] [dbo].[bDesc] NULL,
[Amt] [dbo].[bDollar] NOT NULL,
[Purge] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJBMD_Purge] DEFAULT ('N'),
[AuditYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJBMD_AuditYN] DEFAULT ('Y'),
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE  TRIGGER [dbo].[btJBMDd] ON [dbo].[bJBMD]
   FOR DELETE AS
   

/**************************************************************
   *	This trigger updates JBIN interface flag if anything changes
   * in JBMD and the bill had been previously interfaced.
   *
   *  Created by: kb 2/23/00
   *  Modified by : bc 09/19/00 - added @@rowcount check
   *  		bc 01/04/01 - removed the 'left' out of the JBIN join statement
   *            		because it was updating ALL bills with InvStatus = 'I' to 'C'
   *    	kb 2/19/2 - issue #16147
   *		TJL 11/06/02 - Issue #18740, No need to update JBIN when bill is purged
   *
   **************************************************************/
   declare @errmsg varchar(255)
   
   /* When a JBIN record is being purged or deleted, it will return nothing from the
      statement below.  Therefore the UPDATE will be skipped. */
   if exists(select 1 
   		  from bJBIN n
   		  join deleted d on	d.JBCo = n.JBCo and d.BillMonth = n.BillMonth and d.BillNumber = n.BillNumber)
   	begin
   	update bJBIN  
   	set AuditYN = 'N', InvStatus = case InvStatus when 'I' then 'C' else InvStatus end
   	from bJBIN a 
   	join deleted d on d.JBCo = a.JBCo and d.BillMonth = a.BillMonth and d.BillNumber = a.BillNumber
   
   	if @@rowcount = 0
   		begin
   		select @errmsg = 'Error updating Bill Header '
   		goto error
   		end
   
   	update bJBIN  set
   	AuditYN = 'Y'
   	from bJBIN a 
   	join deleted d on d.JBCo = a.JBCo and d.BillMonth = a.BillMonth and d.BillNumber = a.BillNumber
   	end
   
   return
   
   error:
   select @errmsg = @errmsg + ' - cannot delete JB Miscellaneous Distribution!'
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE TRIGGER [dbo].[btJBMDi] ON [dbo].[bJBMD]
         FOR INSERT AS
    

/**************************************************************
       *	This trigger updates JBIN interface flag if anything changes
       * in JBMD and the bill had been previously interfaced.
       *
       *  Created by: kb 2/23/00
       *  Modified by :  bc 09/19/00 - added @@rowcount check
       *                 bc 01/04/01 - removed the 'left' from the join statement
     *                 kb 2/19/2 - issue #16147
       *
       **************************************************************/
      declare @errmsg varchar(255)
   
       update bJBIN set
       AuditYN = 'N', InvStatus = case InvStatus when 'I' then 'C' else InvStatus end
       from bJBIN a join inserted i on i.JBCo = a.JBCo and
       i.BillMonth = a.BillMonth and i.BillNumber = a.BillNumber
   
       if @@rowcount = 0
         begin
         select @errmsg = 'Error updating Bill Header '
         goto error
         end
   
       update bJBIN set
       AuditYN = 'Y', InvStatus = case InvStatus when 'I' then 'C' else InvStatus end
       from bJBIN a join inserted i on i.JBCo = a.JBCo and
       i.BillMonth = a.BillMonth and i.BillNumber = a.BillNumber
   
    return
   
      error:
      select @errmsg = @errmsg + ' - cannot insert JB Miscellaneous Distribution!'
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE TRIGGER [dbo].[btJBMDu]
   ON [dbo].[bJBMD]
   FOR UPDATE AS
   

/**************************************************************
   *	This trigger updates JBIN interface flag if anything changes
   * in JBMD and the bill had been previously interfaced.
   *
   *  Created by: kb 2/23/00
   *  Modified by :  bc 09/19/00 - added @@rowcount after update attempt
   *  		bc 01/04/01 - removed the 'left' from the join statement
   *    	kb 2/19/2 - issue #16147
   *		TJL 11/06/02 - Issue #18740, Exit if (Purge) Column is updated
   *
   **************************************************************/
      declare @errmsg varchar(255)
   
   If Update(Purge)
   	begin
   	return
   	end
   
       update bJBIN set
       AuditYN = 'N', InvStatus = case InvStatus when 'I' then 'C' else InvStatus end
       from bJBIN a join inserted i on i.JBCo = a.JBCo and
       i.BillMonth = a.BillMonth and i.BillNumber = a.BillNumber
       if @@rowcount = 0
         begin
         select @errmsg = 'Error updating Bill Header '
         goto error
         end
   
       update bJBIN set
       AuditYN = 'Y'
       from bJBIN a join inserted i on i.JBCo = a.JBCo and
       i.BillMonth = a.BillMonth and i.BillNumber = a.BillNumber
       return
   
      error:
      select @errmsg = @errmsg + ' - cannot update JB Miscellaneous Distribution!'
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biJBMD] ON [dbo].[bJBMD] ([JBCo], [BillMonth], [BillNumber], [CustGroup], [MiscDistCode]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bJBMD] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bJBMD].[Purge]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bJBMD].[AuditYN]'
GO
