CREATE TABLE [dbo].[bAPHD]
(
[APCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[APTrans] [dbo].[bTrans] NOT NULL,
[APLine] [smallint] NOT NULL,
[APSeq] [tinyint] NOT NULL,
[HoldCode] [dbo].[bHoldCode] NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btAPHDd    Script Date: 8/28/99 9:36:54 AM ******/
   CREATE trigger [dbo].[btAPHDd] on [dbo].[bAPHD] for DELETE as
   

/*-----------------------------------------------------------------
    *	Created : 7/11/97 EN
    *	Modified: 1/7/99 EN
    *				GG 12/11/01 - #15573 - cleanup, remove psuedo cursor
    *				GF 08/12/2003 - issue #22112 - performance
	*				MV 11/17/09 - #133119 - audit hold code release
    *
    *	Delete trigger for AP Transaction Hold Detail
    *	Resets transaction detail status if all hold detail is removed
    */----------------------------------------------------------------
   
   declare @errmsg varchar(255), @numrows int, @validcnt int,  @key varchar(30), @co bCompany
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   -- reset transaction detail status to 'open' if all hold detail has been removed
   update bAPTD set Status = 1	
   from bAPTD t with (nolock) 
   join deleted d on d.APCo=t.APCo and d.Mth=t.Mth and d.APTrans=t.APTrans and d.APLine=t.APLine and d.APSeq=t.APSeq
   where t.Status = 2 
   and (select count(*) from bAPHD h with (nolock) where h.APCo = t.APCo and h.Mth =  t.Mth
   		and h.APTrans = t.APTrans and h.APLine = t.APLine and h.APSeq = t.APSeq) = 0


	/* Audit delete */
	INSERT INTO bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
           SELECT 'bAPHD', 'Mth: ' + isnull(convert(char(8), d.Mth,1),'') 
		+ ' Trans: ' + isnull(convert(varchar(4), d.APTrans),'') + ' Line: ' + isnull(convert(varchar(2),d.APLine),'') 
		+ ' Seq: ' + isnull(convert(varchar(1), d.APSeq),'') + ' HoldCode: ' +  isnull(d.HoldCode,''),
   		d.APCo, 'D',NULL, NULL, NULL, getdate(), SUSER_SNAME() 
		FROM deleted d
   		JOIN bAPCO c ON d.APCo = c.APCo
		JOIN bAPTD t ON d.APCo = t.APCo and d.Mth=t.Mth and d.APTrans=t.APTrans and d.APLine=t.APLine and d.APSeq=t.APSeq
		where c.AuditTransHoldCodeYN = 'Y' and t.AuditYN = 'Y'

   return
   
   
   
   error:
   	select @errmsg = @errmsg + ' - Cannot delete AP transaction hold detail!'
   	RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger btAPHDi    Script Date: 8/28/99 9:36:54 AM ******/
   CREATE trigger [dbo].[btAPHDi] on [dbo].[bAPHD] for INSERT as
   

/*-----------------------------------------------------------------
    * Created By:	EN 7/11/97
    * Modified By: KB 12/8/98
    *				GG 12/11/01 - #15573 - cleanup, removed psuedo cursor
    *				MV 06/11/02 - #14160 update status to 2 in bAPTD if it's not already 2
    *				GF 08/12/2003 - issue #22112 - performance
	*				MV 08/24/06 - #121887 check for trans in clear batch
    *	
    *
    *	This trigger rejects insertion in bAPHD (Trans Hold Detail)
    *	if any of the following error conditions exist:
    *
    *		Invalid Hold Code
    *		Invalid AP Trans, Line, and Seq
    *		Invalid Transaction Detail Status - cannot be paid or cleared
    *
    *	Put transaction detail on hold - changes APTD.Status to '2'
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @validcnt int, @KeySeq tinyint,
   		@KeyCo bCompany, @KeyMth bMonth, @KeyTrans bTrans, @KeyLine smallint
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   -- validate Hold Code
   select @validcnt = count(*) from bHQHC v with (nolock) join inserted i on i.HoldCode = v.HoldCode
   if @validcnt <> @numrows
     	begin
     	select @errmsg = 'Hold Code not setup in HQ'
     	goto error
     	end
   
   -- validate Transaction Detail - must exist
   select @validcnt = count(*) from bAPTD v with (nolock)
   join inserted i on i.APCo = v.APCo and i.Mth = v.Mth and i.APTrans = v.APTrans
     	and i.APLine = v.APLine and i.APSeq = v.APSeq
   if @validcnt <> @numrows
     	begin
     	select @errmsg = 'Invalid Transaction Line and Seq#'
     	goto error
     	end
   
   -- check that Transaction Detail is not paid or cleared
   select @validcnt = count(*) from inserted i
   join bAPTD v with (nolock) on i.APCo = v.APCo and i.Mth = v.Mth and i.APTrans = v.APTrans
     	and i.APLine = v.APLine and i.APSeq = v.APSeq
   where v.Status in (3,4)
   if @validcnt <> 0
     	begin
     	select @errmsg = 'Transaction detail has been paid or cleared'
     	goto error
     	end

	-- check that transaction detail is not in a clear batch
	select @validcnt = count(*) from inserted i 
	join bAPCT c with(nolock) on i.APCo = c.Co and i.Mth=c.ExpMth and i.APTrans=c.APTrans
	if @validcnt <> 0
		begin
		select @errmsg = 'Transaction has hold detail.'
     	goto error
		end
   
   -- put Transaction detail on Hold
   update bAPTD
   set Status = 2
   from inserted i join bAPTD d on i.APCo = d.APCo and i.Mth = d.Mth and i.APTrans = d.APTrans
   and i.APLine = d.APLine and i.APSeq = d.APSeq and d.Status <> 2	--#14160

	   
   return
   
   
   
   error:
     	select @errmsg = @errmsg + ' - cannot insert AP transaction Hold Detail!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
  
 




GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btAPHDu    Script Date: 8/28/99 9:36:54 AM ******/
   CREATE  trigger [dbo].[btAPHDu] on [dbo].[bAPHD] for UPDATE as
   

/*-----------------------------------------------------------------
    *	Created : 8/26/98 EN
    *	Modified : 8/26/98 EN
    *			10/17/02 MV - 18878 quoted identifier cleanup.
    *			
    *
    *	This trigger rejects update in bAPHD (Transaction Hold Detail)
    *	if any of the following error conditions exist:
    *
    *		Cannot change APCo
    *		Cannot change Mth
    *		Cannot change APTrans
    *		Cannot change APLine
    *		Cannot change APSeq
    *		Cannot change HoldCode
    *
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @validcnt int
   
   select @numrows = @@rowcount
   if @numrows = 0 return 
   
   set nocount on
   
   /* verify primary key not changed */
   select @validcnt = count(*) from deleted d, inserted i
   	where d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
   	and d.APLine = i.APLine and d.APSeq = i.APSeq and d.HoldCode = i.HoldCode
   if @numrows <> @validcnt
   	begin
   	select @errmsg = 'Cannot change Primary Key'
   	goto error
   	end
   	
   		
   return
   
   
   error:
   	select @errmsg = @errmsg + ' - cannot update Transaction Hold Detail!'
       	RAISERROR(@errmsg, 11, -1);
       	rollback transaction
   
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biAPHD] ON [dbo].[bAPHD] ([APCo], [Mth], [APTrans], [APLine], [APSeq], [HoldCode]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
