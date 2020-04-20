CREATE TABLE [dbo].[bJBJE]
(
[JBCo] [dbo].[bCompany] NOT NULL,
[BillMonth] [dbo].[bMonth] NOT NULL,
[BillNumber] [int] NOT NULL,
[JCMonth] [dbo].[bMonth] NOT NULL,
[JCTrans] [dbo].[bTrans] NOT NULL,
[ErrorDesc] [varchar] (100) COLLATE Latin1_General_BIN NULL,
[Purge] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJBJE_Purge] DEFAULT ('N'),
[AuditYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJBJE_AuditYN] DEFAULT ('Y')
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE TRIGGER [dbo].[btJBJEd] ON [dbo].[bJBJE]
   FOR DELETE AS
   

/**************************************************************
   *  Created by: kb 5/15/00
   *  Modified by:  TJL 11/06/02 - Issue #18740, exit on Bill Purge
   *		TJL 01/15/03 - Issue #19923, Update bJCCD.BillStatus when errors deleted
   *		TJL 03/11/03 - Issue #20329, Using UndefinedAsBilledYN flag when updating Bill Status
   *
   *  This trigger rejects insert of bJBJE
   *  if the following error condition exists:
   *	none
   *
   *
   **************************************************************/
   declare @errmsg varchar(255), @validcnt int, @errno int, @numrows int, @nullcnt int
   	
   select @numrows = @@rowcount
   
   if @numrows = 0 return
   set nocount on
   
   /* Reset JBBillStatus in bJCCD only if deleting the Bill from JBTMBillEdit form.
      (We want to be able to repull this transaction).  DO NOT reset during a purge. 
   		Purge:	d.Purge = 'Y' and d.AuditYN = 'N'
   		Delete:	d.Purge = 'Y' and d.AuditYN = 'Y'	
      Also, reset should not occur if this error (and bill) being deleted does NOT correspond to 
      the BillMonth and BillNumber for the transaction.  (Meaning that the transaction was later
      billed successfully on another bill)*/
   update bJCCD 
   set JBBillStatus = null, JBBillNumber = null, JBBillMonth = null 
   from deleted d  
   join bJCCD j on j.JCCo = d.JBCo and j.Mth = d.JCMonth and j.CostTrans = d.JCTrans
   	and j.JBBillMonth = d.BillMonth and j.JBBillNumber = d.BillNumber
   where d.Purge = 'Y' and d.AuditYN = 'Y'	
   
   return
   
   error:
   select @errmsg = @errmsg + ' - cannot insert JBJE!'
   
   RAISERROR(@errmsg, 11, -1);
   rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE TRIGGER [dbo].[btJBJEi] ON [dbo].[bJBJE]
   FOR INSERT AS
   

/**************************************************************
   *	This trigger rejects insert of bJBJE
   *	 if the following error condition exists:
   *		none
   *
   *  Created by: kb 5/15/00
   *  Modified by:  TJL 02/11/03 - Issue 20329, Use bJBCO rather than JBCO in select
   **************************************************************/
   declare @errmsg varchar(255), @validcnt int, @errno int, @numrows int, @nullcnt int,
   
   @co bCompany, @mth bMonth, @billnum int, @line int, @seq int, @jccdtrans bTrans,
   	@billstatus tinyint, @billmth bMonth
   select @numrows = @@rowcount
   
   if @numrows = 0 return
   set nocount on
   
   select @co = min(JBCo) from inserted i
   while @co is not null
   	begin
   	/* If a transaction fails to fit within a template sequence, for any number of
   	   reasons, we only flag the transaction as billed (so it's not picked up on
   	   another bill IF the JBCO.UndefinedAsBilledYN = 'Y' */
       if exists(select 1 from bJBCO where JBCo = @co and UndefinedAsBilledYN = 'Y')
           begin
           select @mth = min(JCMonth) 
   		from inserted i 
   		where JBCo = @co
           while @mth is not null
               begin
               select @jccdtrans = min(JCTrans) 
   			from inserted i 
   			where JBCo = @co and JCMonth = @mth
               while @jccdtrans is not null
                   begin
                   /* select @billmth = BillMonth, @billnum = BillNumber
                 	from bJBIJ 
   				where JBCo = @co and JCMonth = @mth and JCTrans = @jccdtrans
   
                  	update JCCD 
   				set JBBillStatus = 2, JBBillNumber = @billnum, JBBillMonth = @billmth 
   				from bJBIJ j 
   				join bJCCD d on d.JCCo = j.JBCo and d.Mth = j.JCMonth and d.CostTrans = j.JCTrans 
   				where JBCo = @co and JCMonth = @mth and JCTrans = @jccdtrans */
   
                   select @billmth = BillMonth, @billnum = BillNumber 
   				from inserted 
   				where JBCo = @co and JCMonth = @mth and JCTrans = @jccdtrans
   
                	update bJCCD 
   				set JBBillStatus = 2, JBBillNumber = @billnum, JBBillMonth = @billmth 
   				from inserted i  
   				join bJCCD d on d.JCCo = i.JBCo and d.Mth = i.JCMonth and d.CostTrans = i.JCTrans 
   				where JBCo = @co and JCMonth = @mth and JCTrans = @jccdtrans
   
                   select @jccdtrans = min(JCTrans) 
   				from inserted i 
   				where JBCo = @co and JCMonth = @mth and JCTrans > @jccdtrans
                   end
               select @mth = min(JCMonth) 
   			from inserted i 
   			where JBCo = @co and JCMonth > @mth
               end
      		end
   	select @co = min(JBCo) 
   	from inserted i 
   	where JBCo > @co
   	end
   
   return
   
   error:
   select @errmsg = @errmsg + ' - cannot insert JBJE!'
   
   RAISERROR(@errmsg, 11, -1);
   rollback transaction
   
   
  
 



GO
ALTER TABLE [dbo].[bJBJE] WITH NOCHECK ADD CONSTRAINT [CK_bJBJE_AuditYN] CHECK (([AuditYN]='Y' OR [AuditYN]='N'))
GO
ALTER TABLE [dbo].[bJBJE] WITH NOCHECK ADD CONSTRAINT [CK_bJBJE_Purge] CHECK (([Purge]='Y' OR [Purge]='N'))
GO
CREATE UNIQUE CLUSTERED INDEX [biJBJE] ON [dbo].[bJBJE] ([JBCo], [BillMonth], [BillNumber], [JCMonth], [JCTrans]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
