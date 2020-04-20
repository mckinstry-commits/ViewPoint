CREATE TABLE [dbo].[bHRER]
(
[HRCo] [dbo].[bCompany] NOT NULL,
[HRRef] [dbo].[bHRRef] NOT NULL,
[ReviewDate] [dbo].[bDate] NOT NULL,
[Reviewer] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[PositionCode] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[NextReviewDate] [dbo].[bDate] NULL,
[ReviewNotes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[HistSeq] [int] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   CREATE   trigger [dbo].[btHRERd] on [dbo].[bHRER] for Delete
   as
   

/**************************************************************
   *	Created: 04/03/00 ae
   * 	Last Modified: mh 10/11/02 Added Update to HREH
   *				mh 2/20/03 Issue 20486
   *				mh 3/16/04 Issue 23061
   *				mh 4/8/04 - Reviewdate truncated in keystring
   *				mh 10/29/2008 - 127008
   *
   **************************************************************/
   
   declare @errmsg varchar(255), @validcnt int, @validcnt2 int, @errno int, @numrows int, @nullcnt int, @rcode int
    
    
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   
   	/* Need to check HRRP and not allow delete if related records exist */
   
   	if exists(select 1 from dbo.bHRRP h with (nolock) join deleted d on h.HRCo = d.HRCo and h.HRRef = d.HRRef and
   	h.ReviewDate = d.ReviewDate)
   	begin
   		select @errmsg = 'Grid entries exist in HRRP.  Remove using HR Resource Review - Peformance Ratings Grid.'
   		goto error 
   	end
    
   	/* Audit inserts */
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
   	select 'bHRER', 'HRCo: ' + convert(char(3),isnull(d.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(d.HRRef,'')) +
   	' ReviewDate: ' + convert(varchar(11),isnull(d.ReviewDate,'')) + ' Reviewer: ' + convert(varchar(30),isnull(d.Reviewer,'')),
    d.HRCo, 'D', '', null, null, getdate(), SUSER_SNAME()
    from deleted d join dbo.bHRCO e with (nolock) on
   	d.HRCo = e.HRCo 
   	where e.AuditReviewYN = 'Y'
    
   	return
   
	error:
   
   	select @errmsg = (@errmsg + ' - cannot delete HRER! ')
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
    
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   CREATE        trigger [dbo].[btHRERi] on [dbo].[bHRER] for INSERT as
   	

/*-----------------------------------------------------------------
   	*   Created by: kb 2/5/99
   	*	Modified by: ae 03/31/00 added audits
   	*			mh 3/16/04 23061
   	*			mh 4/8/04.  Date being truncated
   	*			mh 7/13/04	25029
	*			mh 01/14/08 119853
	*			mh 10/29/2008 - 127008
   	*
   	*	This trigger rejects update in bHRER (Companies) if the
   	*	following error condition exists:
   	*
   	*		Invalid HQ Company number
   	*		Invalid HR Resource number
   	*
   	*
   	*	Adds HR Employment History Record if HRCO_ReviewHistYN = 'Y'
   	*/----------------------------------------------------------------
    
   	declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int, 
   	@hrco bCompany, @hrref bHRRef, @seq int, @revhistcode varchar(10), 
   	@revhistyn bYN, @reviewdate bDate, @opencurs tinyint
   	
   	select @numrows = @@rowcount
   	if @numrows = 0 return
   	set nocount on
    
    	/* check for key changes */
   	select @validcnt = count(*) from inserted i, bHQCO h where i.HRCo =h.HQCo
   
   	if @validcnt <> @numrows
   	begin
   		select @errmsg = 'Invalid HR Company'
   		goto error
   	end
    
   	select @validcnt = count(i.HRCo) from inserted i
   	join dbo.bHRRM h on i.HRCo = h.HRCo and i.HRRef = h.HRRef
     	
   	if @validcnt <> @numrows
 	begin
 		select @errmsg = 'Invalid Resource'
  		goto error
 	end
    
   	/* validate sex code*/
   	select @validcnt = count(i.HRCo) from inserted i where i.PositionCode is not null
    	if @validcnt > 0  	
   	begin
     	select @validcnt2 = count(i.HRCo) 
   		from inserted i join dbo.bHRPC h 
   		on i.HRCo = h.HRCo and h.PositionCode = i.PositionCode 
    		if @validcnt <> @validcnt2
	   	  	begin
     			select @errmsg = 'Invalid Position Code'
     			goto error
   		  	end
     end
    
   	/*insert HREH record if flag set in HRCO*/
   --25029
   	declare insert_curs cursor local fast_forward for
   
   	select HRCo, HRRef, ReviewDate from inserted 
   	where HRCo is not null and HRRef is not null
   
   	open insert_curs
   
   	select @opencurs = 1
   
   	fetch next from insert_curs into @hrco, @hrref, @reviewdate
   
   	while @@fetch_status = 0
   	begin
   
   		select @revhistyn = ReviewHistYN, @revhistcode = ReviewHistCode
   		from dbo.bHRCO with (nolock) where HRCo = @hrco
   
   		if @revhistyn = 'Y' and @revhistcode is not null
   		begin
   			select @seq = isnull(max(Seq),0)+1
   			from dbo.bHREH with (nolock) 
   			where HRCo = @hrco and HRRef = @hrref
   
   			insert dbo.bHREH (HRCo, HRRef, Seq, Code, DateChanged, Type)
   			values (@hrco, @hrref, @seq, @revhistcode, @reviewdate, 'H')
   
   	  		update dbo.bHRER 
   			set HistSeq = @seq 
   			where HRCo = @hrco and HRRef = @hrref and ReviewDate = @reviewdate
   		end
   
   		fetch next from insert_curs into @hrco, @hrref, @reviewdate
   	end
   
   	if @opencurs = 1
   	begin
   		close insert_curs
   		deallocate insert_curs
   		select @opencurs = 0
   	end
    
   	/* Audit inserts */

	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
   	select 'bHRER', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')) +
    ' ReviewDate: ' + convert(varchar(11),isnull(i.ReviewDate,'')) + ' Reviewer: ' + convert(varchar(30),isnull(i.Reviewer,'')),
    i.HRCo, 'A', '', null, null, getdate(), SUSER_SNAME()
    from inserted i join dbo.bHRCO e with (nolock) on e.HRCo = i.HRCo where e.AuditReviewYN = 'Y'
    
   	return
    
    error:
   
   	if @opencurs = 1
   	begin
   		close insert_curs
   		deallocate insert_curs
   	end
   
     	select @errmsg = @errmsg + ' - cannot insert HR Resource Review!'
     	RAISERROR(@errmsg, 11, -1);
    
     	rollback transaction
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   CREATE        trigger [dbo].[btHRERu] on [dbo].[bHRER] for UPDATE as
    	

		/*-----------------------------------------------------------------
    	*   	Created by: kb 2/5/99
    	* 		Modified by: mh 9/5/02 - added update to HREH
    	*					mh 2/20/03 Issue 20486
    	*					mh 3/16/04 23061
    	*					mh 4/8/04 Corrected truncated date.  Also fixed HQMA.TableName being used. 
    	*					Was using HREB instead of HRER
   		*					mh 4/29/2005 - 28581 - Change HRRef conversion from varchar(5) to varchar(6)
		*					mh 10/29/2008 - 127008
    	*
    	*	This trigger rejects update in bHRER (Companies) if the
    	*	following error condition exists:
    	*	
    	*/----------------------------------------------------------------
     
    	declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int
     
    	select @numrows = @@rowcount
    	if @numrows = 0 return
    	set nocount on
     
    	/* check for key changes */
    	if update(HRCo)
      	begin
    	  	select @validcnt = count(i.HRCo) from 
    		inserted i join deleted d on
    		i.HRCo = d.HRCo
    	
    	  	if @validcnt <> @numrows
    		begin
    	  		select @errmsg = 'Cannot change HR Company'
    	  		goto error
    		end
      	end
     
    	if update(HRRef)
      	begin
      		select @validcnt = count(i.HRCo) 
    		from inserted i join deleted d on
    	  	i.HRCo = d.HRCo and i.HRRef = d.HRRef
    
    	  	if @validcnt <> @numrows
      		begin
      			select @errmsg = 'Cannot change HR Resource'
      			goto error
      		end
      	end
     
    	if update(ReviewDate)
      	begin
    	  	select @validcnt = count(i.HRCo) 
    		from inserted i join deleted d on 
    		i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.ReviewDate = d.ReviewDate
    	  	if @validcnt <> @numrows
    		begin
    	  		select @errmsg = 'Cannot change ReviewDate'
    	  		goto error
    		end
      	end
     
    	select @validcnt = count(i.HRCo) from inserted i where i.PositionCode is not null
    	if @validcnt > 0
      	begin
      		select @validcnt2 = count(i.HRCo) 
    		from inserted i join dbo.bHRPC h on 
    		i.HRCo = h.HRCo and h.PositionCode = i.PositionCode
      		if @validcnt <> @validcnt2
      		begin
      			select @errmsg = 'Invalid Position Code'
    	  		goto error
      		end
      	end
    
    	/*Insert HQMA records*/

	if update(Reviewer)
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
    	select 'bHRER', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')) +
        ' ReviewDate: ' + convert(varchar(11),isnull(i.ReviewDate,'')) +  ' Reviewer: ' + convert(varchar(30),isnull(i.Reviewer,'')),
        i.HRCo, 'C','Reviewer',
        convert(varchar(30),d.Reviewer), Convert(varchar(30),i.Reviewer),
      	getdate(), SUSER_SNAME()
      	from inserted i join deleted d on 
    	i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.ReviewDate = d.ReviewDate 
    	join dbo.bHRCO e with (nolock) on 
    	i.HRCo = e.HRCo
    	where isnull(i.Reviewer,'') <> isnull(d.Reviewer,'') and e.AuditReviewYN  = 'Y'

	if update(PositionCode)
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
    	select 'bHRER', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')) +
        ' ReviewDate: ' + convert(varchar(11),isnull(i.ReviewDate,'')) +  ' Reviewer: ' + convert(varchar(30),isnull(i.Reviewer,'')),
        i.HRCo, 'C','PositionCode',
        convert(varchar(10),d.PositionCode), Convert(varchar(10),i.PositionCode),
      	getdate(), SUSER_SNAME()
      	from inserted i join deleted d on 
    	i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.ReviewDate = d.ReviewDate 
    	join dbo.bHRCO e with (nolock) on 
    	i.HRCo = e.HRCo
    	where isnull(i.PositionCode,'') <> isnull(d.PositionCode,'') and e.AuditReviewYN  = 'Y'

	if update(NextReviewDate)    
    	insert into dbo.bHQMA select 'bHRER', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')) +
        ' ReviewDate: ' + convert(varchar(11),isnull(i.ReviewDate,'')) +  ' Reviewer: ' + convert(varchar(30),isnull(i.Reviewer,'')),
        i.HRCo, 'C','NextReviewDate',
        convert(varchar(11),d.NextReviewDate), Convert(varchar(11),i.NextReviewDate),
      	getdate(), SUSER_SNAME()
      	from inserted i join deleted d on 
    	i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.ReviewDate = d.ReviewDate 
    	join dbo.bHRCO e with (nolock) on 
    	i.HRCo = e.HRCo
    	where isnull(i.NextReviewDate,'') <> isnull(d.NextReviewDate,'') and e.AuditReviewYN  = 'Y'
    
    	return
    
     
    error:
    
      	select @errmsg = @errmsg + ' - cannot update HR Resource Review!'
      	RAISERROR(@errmsg, 11, -1);
     
      	rollback transaction
    
    
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biHRER] ON [dbo].[bHRER] ([HRCo], [HRRef], [ReviewDate]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bHRER] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
