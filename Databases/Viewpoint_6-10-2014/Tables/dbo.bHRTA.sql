CREATE TABLE [dbo].[bHRTA]
(
[HRCo] [dbo].[bCompany] NOT NULL,
[HRRef] [dbo].[bHRRef] NOT NULL,
[DateOut] [dbo].[bDate] NOT NULL,
[Asset] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[DateIn] [dbo].[bDate] NULL,
[MemoOut] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[MemoIn] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   CREATE trigger [dbo].[btHRTAd] on [dbo].[bHRTA] for Delete
   as
   

/**************************************************************
   * Created: 06/17/04 mh
   * Last Modified:  MH 1/8/07.  6.x recode issue 28133.  When
   *				deleting a transaction, need to restore the previous
   *				Assigned value in HRCA.  This would be the person who
   *				last checked out the asset.
   *				mh 10/29/2008 - 127008
   *
   **************************************************************/
   declare @errmsg varchar(255), @numrows int, @hrco bCompany, @asset varchar(20), 
   @opencurs tinyint, @dateout bDate, @datein bDate, @rcode int
    
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
    
   	declare delCurs cursor local fast_forward for
   	select HRCo, Asset, DateOut, DateIn from deleted 
   	where HRCo is not null and HRRef is not null and DateOut is not null
   	and Asset is not null
   
   	open delCurs
   	select @opencurs = 1
   
   	fetch next from delCurs into @hrco, @asset, @dateout, @datein 
   
   	while @@fetch_status = 0
   	begin
   
   		if @datein is not null
   		begin
   			if exists(select 1 from dbo.bHRTA where HRCo = @hrco and Asset = @asset and
   			DateOut = (select min(DateOut) from dbo.HRTA with (nolock)
   			where HRCo = @hrco and Asset = @asset and DateOut > @dateout)) 	
   			begin
   				select @errmsg = 'Subsequent checkout records exit for this Asset.'
   				goto error
   			end
   		end 
   
   		--update dbo.bHRCA set Status = 0 where HRCo = @hrco and Asset = @asset

		update dbo.bHRCA set Status = 0, Assigned = (select HRTA.HRRef from bHRTA HRTA join deleted d on HRTA.HRCo = d.HRCo and 
		HRTA.Asset = d.Asset where HRTA.DateIn is not null and HRTA.DateOut = 
		(Select max(DateOut) FROM bHRTA HRTAMAX where 
		HRTA.HRCo = HRTAMAX.HRCo and HRTA.Asset = HRTAMAX.Asset and DateIn is not null))
		where HRCo = @hrco and Asset = @asset

   		fetch next from delCurs into @hrco, @asset, @dateout, @datein 
   
   	end
   
   
   	if @opencurs = 1
   	begin
   		close delCurs
   		deallocate delCurs
   	end
   
   Return
   
   error:
   
   	if @opencurs = 1
   	begin
   		close delCurs
   		deallocate delCurs
   	end
   
   select @errmsg = (@errmsg + ' - cannot delete HRTA! ')
   RAISERROR(@errmsg, 11, -1);
   rollback transaction
   
   
  
 




GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   
   CREATE    trigger [dbo].[btHRTAi] on [dbo].[bHRTA] for Insert as
   

/*-----------------------------------------------------------------
    *  Created by: mh 6/2/04
    * 	Modified by:
    */----------------------------------------------------------------
   
   declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   	declare @hrco bCompany, @asset varchar(20), @dateout bDate, @hrref bHRRef,
   	@opencurs tinyint
   
   	declare insert_Curs cursor local fast_forward for
   	select HRCo, Asset, HRRef, DateOut
   	from inserted

   	open insert_Curs
   
   	fetch next from insert_Curs into @hrco, @asset, @hrref, @dateout
   
   	select @opencurs = 1
   
   	while @@fetch_status = 0
   	begin

   		Update bHRCA set bHRCA.Assigned = i.HRRef, /*bHRCA.Status = 1*/ 
		bHRCA.Status = (case isnull(convert(varchar(11),DateIn),'Y') when 'Y' then 1 else 0 end)
   		from inserted i, bHRCA c
   		where i.HRCo = c.HRCo and i.Asset = c.Asset and 
   		i.HRCo = @hrco and i.HRRef = @hrref and i.DateOut = @dateout and i.Asset = @asset
   
   		fetch next from insert_Curs into @hrco, @asset, @hrref, @dateout
   
   	end
   
   	if @opencurs = 1
   	begin
   		close insert_Curs
   		deallocate insert_Curs
   		select @opencurs = 0
   	end
   
   	return
   
   error:
   
   	if @opencurs = 1
   	begin
   		close insert_Curs
   		deallocate insert_Curs
   		select @opencurs = 0
   	end
   
   	select @errmsg = @errmsg + ' - cannot update HRTA!'
   	RAISERROR(@errmsg, 11, -1);
   
   	rollback transaction
   
   
   
   
   
  
 




GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO










CREATE        trigger [dbo].[btHRTAu] on [dbo].[bHRTA] for Update as
   

/*-----------------------------------------------------------------
    *  Created: mh 6/3/04
    *  Modified:	mh 10/29/2008 - 127008 
    * 
    */----------------------------------------------------------------
   
   declare @errmsg varchar(255), @validcnt int, @numrows int
   SELECT @numrows = @@rowcount
   IF @numrows = 0 return
   SET nocount on
   
   	declare @hrco bCompany, @asset varchar(20), @dateout bDate, @datein bDate, @nextdateout bDate, 
   	@hrref bHRRef, @opencurs tinyint
   
   	declare update_Curs cursor local fast_forward for
   	select HRCo, Asset, DateOut, HRRef, DateIn from inserted where HRCo is not null and Asset is not null
   
   	open update_Curs
   
   	fetch next from update_Curs into @hrco, @asset, @dateout, @hrref, @datein
   
   	select @opencurs = 1
   
   	while @@fetch_status = 0
   	begin
   
   		if update(DateIn)
   		begin
   
   			select @nextdateout = min(DateOut) 
   			from dbo.bHRTA 
   			where HRCo = @hrco and Asset = @asset and DateOut > @dateout
   
   			if @datein is null and @nextdateout is not null
   			begin
   				select @errmsg = 'Subsequent Check Out records exist for this asset.  Cannot set DateIn to null. '
   				goto error
   			end

   			if @datein > @nextdateout
   			begin
   				select @errmsg = 'Subsequent Check Out records exist for this asset.  Cannot update DateIn. '
   				goto error
   			end

--Issue 120188 - if you enter a DateIn Status should be set to zero.  Was unconditionally setting 
--Status to 1.  mh 2/9/06
			if @datein is not null
				Update dbo.bHRCA set Status = 0 where HRCo = @hrco and Asset = @asset
			else
   				Update dbo.bHRCA set Status = 1 where HRCo = @hrco and Asset = @asset
			   
   		end
   
   		fetch next from update_Curs into @hrco, @asset, @dateout, @hrref, @datein
   
   	end
   
   	if @opencurs = 1
   	begin
   		close update_Curs
   		deallocate update_Curs
   		select @opencurs = 0
   	end
   
   return
   error:
   
   	if @opencurs = 1
   	begin
   		close update_Curs
   		deallocate update_Curs
   		select @opencurs = 0
   	end
   
       SELECT @errmsg = @errmsg +  ' - cannot update HR Company Asset Checkout!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
   
   
   
  
 





GO
CREATE UNIQUE CLUSTERED INDEX [biHRTA] ON [dbo].[bHRTA] ([HRCo], [HRRef], [DateOut], [Asset]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bHRTA] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
