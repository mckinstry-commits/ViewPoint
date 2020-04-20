CREATE TABLE [dbo].[bHRDP]
(
[HRCo] [dbo].[bCompany] NOT NULL,
[HRRef] [dbo].[bHRRef] NOT NULL,
[Seq] [smallint] NOT NULL,
[Name] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[Relationship] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[BirthDate] [dbo].[bDate] NULL,
[SSN] [char] (11) COLLATE Latin1_General_BIN NULL,
[Sex] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[HistSeq] [int] NULL,
[Address] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[City] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[State] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[Zip] [dbo].[bZip] NULL,
[Phone] [dbo].[bPhone] NULL,
[WorkPhone] [dbo].[bPhone] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[Country] [char] (2) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biHRDP] ON [dbo].[bHRDP] ([HRCo], [HRRef], [Seq]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bHRDP] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Trigger dbo.btHRDPd    Script Date: 2/20/2003 10:08:53 AM ******/
   
   CREATE  trigger [dbo].[btHRDPd] on [dbo].[bHRDP] for DELETE as
   

/*-----------------------------------------------------------------
    *  Created by: MH 10/10/02
    * 	Modified by: mh 2/20/03 Issue 20486
    *
    *	Purpose:  Update HREH on a delete.
    *	
    */----------------------------------------------------------------
    
   declare @errmsg varchar(255), @numrows int, @validcnt int
   declare @hrco bCompany, @hrref bEmployee, @seq int, @code varchar(10), @hrdpseq smallint 
   
   --mh 2/20/03 Issue 20486
    /*insert HREH record if flag set in HRCO*/
   /* 
    	select @hrco = min(d.HRCo), @code = h.DependHistCode from deleted d, HRCO h
    	where d.HRCo = h.HRCo and h.DependHistYN = 'Y' group by h.DependHistCode
    	
    	while @hrco is not null
    	begin
    		select @hrref = min(HRRef) from deleted where HRCo = @hrco
    
    		while @hrref is not null
    		begin
    			select @hrdpseq = min(Seq) from deleted where HRCo = @hrco and HRRef = @hrref
    			while @hrdpseq is not null
    			begin
    				select @seq = isnull(max(Seq),0)+1 from bHREH where HRCo = @hrco and
    					HRRef = @hrref
    
    				insert bHREH (HRCo, HRRef, Seq, Code, DateChanged)
    				values (@hrco, @hrref, @seq, @code, getdate())
   
    				select @hrdpseq = min(Seq) from deleted where HRCo = @hrco and HRRef = @hrref
    					and Seq > @hrdpseq
    				if @@rowcount = 0 select @hrdpseq = null
    			end
    
    			select @hrref = min(HRRef) from deleted where HRCo = @hrco and HRRef > @hrref
    			if @@rowcount = 0 select @hrref = null
    		end
    	
    		select @hrco = min(d.HRCo), @code = h.DependHistCode from deleted d, HRCO h
    			where d.HRCo = h.HRCo and h.DependHistYN = 'Y' and d.HRCo > @hrco group by h.DependHistCode
    
    		if @@rowcount = 0 select @hrco = null
    	end
   */
    
   return
    
   error:
   	select @errmsg = @errmsg + '.' 	RAISERROR(@errmsg, 11, -1);
    	rollback transaction

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  trigger [dbo].[btHRDPi] on [dbo].[bHRDP] for INSERT as
   

/*-----------------------------------------------------------------
* Created: kb 1/19/99
* Modified:  mh 07/16/04 25029
*
*	This trigger rejects update in bHRDP (Companies) if the
*	following error condition exists:
*
*		Invalid HQ Company number
*		Invalid HR Resource number
*		Sex <> 'M' and <> 'F'
*
*	Adds HR Employment History Record if HRCO_DependHistYN = 'Y'
*/----------------------------------------------------------------
   
declare @errmsg varchar(255), @numrows int, @validcnt int, @datechgd bDate,
   	@hrco bCompany, @hrref bHRRef, @seq int, @code varchar(10), @hrdpseq smallint,
   	@histseq int, @dependhistcode varchar(10), @dependhistyn bYN, @opencurs tinyint
   
select @numrows = @@rowcount
if @numrows = 0 return
set nocount on
   
-- validate HR Company
select @validcnt = count(1)
from inserted i 
join dbo.bHQCO h (nolock) on i.HRCo = h.HQCo
if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid HR Company'
   	goto error
   	end
-- validate HR Resource
select @validcnt = count(i.HRCo) 
from inserted i
join dbo.bHRRM h (nolock) on i.HRCo = h.HRCo and i.HRRef = h.HRRef
if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid Resource'
   	goto error
   	end
-- validate Sex
if exists(select (1) from inserted i where i.Sex <> 'M' and i.Sex <> 'F')
   	begin
   	select @errmsg = 'Sex must be (M) or (F)'
   	goto error
   	end
   
/*insert HREH record if flag set in HRCO*/
declare insert_curs cursor local fast_forward for
select HRCo, HRRef, Seq
from inserted
   
open insert_curs
select @opencurs = 1

fetch next from insert_curs into @hrco, @hrref, @seq
while @@fetch_status = 0
   	begin
   	select @dependhistcode = DependHistCode, @dependhistyn = DependHistYN
   	from dbo.HRCO with (nolock) where HRCo = @hrco
   
   	if @dependhistyn = 'Y' and @dependhistcode is not null
   		begin
   		select @histseq = isnull(max(Seq),0)+1, @datechgd = convert(varchar(11), getdate()) 
   		from dbo.bHREH with (nolock) 
   		where HRCo = @hrco and HRRef = @hrref
   
   		insert dbo.bHREH (HRCo, HRRef, Seq, Code, DateChanged, Type)
   		values (@hrco, @hrref, @histseq, @dependhistcode, @datechgd, 'H')
   
   	  	update dbo.bHRDP 
   		set HistSeq = @histseq 
   		where HRCo = @hrco and HRRef = @hrref and Seq = @seq
   		end
   
   		fetch next from insert_curs into @hrco, @hrref, @seq	
   	end
   
if @opencurs = 1
   	begin
   	close insert_curs
   	deallocate insert_curs
   	select @opencurs = 0
   	end
   
return
   
error:
   	if @opencurs = 1
   		begin
   		close insert_curs
   		deallocate insert_curs
   		end
   
   	select @errmsg = @errmsg + ' - cannot insert HR Resource Dependent!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE trigger [dbo].[btHRDPu] on [dbo].[bHRDP] for UPDATE as
/*-----------------------------------------------------------------
 * Created: kb 1/19/99
 * Modified: mh 2/20/03 Issue 20486
 *			mh 1/14/08 issue 119853
 *
 *	This trigger rejects update in bHRDP (Companies) if the
 *	following error condition exists:
 *
 *		Invalid HQ Company number
 *		Invalid HR Resource number
 *		Sex <> 'M' and <> 'F'
 *
 *	Adds HR Employment History Record if HRCO_DependHistYN = 'Y'
 */----------------------------------------------------------------

declare @errmsg varchar(255), @numrows int, @validcnt int
   
    declare @hrco bCompany, @hrref bEmployee, @seq int, @code varchar(10), @hrdpseq smallint,
	@birthdate bDate, @opencurs tinyint, @histseq int, @dependhistyn bYN, @dependhistcode varchar(10)
   
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
   
    /* check for key changes */
    if update (HRCo)
    	begin
    	select @validcnt = count(*) from deleted d, inserted i
    		where d.HRCo = i.HRCo
    	if @validcnt <> @numrows
    		begin
    		select @errmsg = 'Cannot change HR Company'
    		goto error
    		end
    	end
   
    if update (HRRef)
    	begin
    	select @validcnt = count(*) from deleted d, inserted i
    		where d.HRCo = i.HRCo and d.HRRef = i.HRRef
    	if @validcnt <> @numrows
    		begin
    		select @errmsg = 'Cannot change Resource'
    		goto error
    		end
    	end
   
    if update (Seq)
    	begin
    	select @validcnt = count(*) from deleted d, inserted i
    		where d.HRCo = i.HRCo and d.HRRef = i.HRRef and d.Seq = i.Seq
    	if @validcnt <> @numrows
    		begin
    		select @errmsg = 'Cannot change Seq'
    		goto error
    		end
    	end
   
    /* validate sex code*/
    select @validcnt = count(*) from inserted i where i.Sex <> 'M' and i.Sex <> 'F'
    if @validcnt > 0
   
    	begin
    	select @errmsg = 'Sex must be (M) or (F)'
    	goto error
    	end
   
   --mh 2/20/03 Issue 20486
   /*insert HREH record if flag set in HRCO*/
   /*
   	select @hrco = min(i.HRCo), @code = h.DependHistCode from inserted i, HRCO h
   	where i.HRCo = h.HRCo and h.DependHistYN = 'Y' group by h.DependHistCode
   	
   	while @hrco is not null
   	begin
   		select @hrref = min(HRRef) from inserted where HRCo = @hrco
   
   		while @hrref is not null
   		begin
   			select @hrdpseq = min(Seq) from inserted where HRCo = @hrco and HRRef = @hrref
   			while @hrdpseq is not null
   			begin
   				select @seq = isnull(max(Seq),0)+1 from bHREH where HRCo = @hrco and
   					HRRef = @hrref
   
   				insert bHREH (HRCo, HRRef, Seq, Code, DateChanged)
   				values (@hrco, @hrref, @seq, @code, getdate())
   
   				update bHRDP set HistSeq = @seq from bHRDP where HRCo = @hrco and HRRef = @hrref
   					and Seq = @hrdpseq
   
   				select @hrdpseq = min(Seq) from inserted where HRCo = @hrco and HRRef = @hrref
   					and Seq > @hrdpseq
   				if @@rowcount = 0 select @hrdpseq = null
   			end
   
   			select @hrref = min(HRRef) from inserted where HRCo = @hrco and HRRef > @hrref
   			if @@rowcount = 0 select @hrref = null
   		end
   	
   		select @hrco = min(i.HRCo), @code = h.DependHistCode from inserted i, HRCO h
   			where i.HRCo = h.HRCo and h.DependHistYN = 'Y' and i.HRCo > @hrco group by h.DependHistCode
   
   		if @@rowcount = 0 select @hrco = null
   	end
   */

		--Issue 119853
		if update(BirthDate)
		begin
			declare update_curs cursor local fast_forward for
				select HRCo, HRRef, Seq, isnull(BirthDate, convert(varchar(11), getdate())), HistSeq from inserted

			open update_curs
	
			fetch next from update_curs into @hrco, @hrref, @seq, @birthdate, @histseq

			select @opencurs = 1
			
			while @@fetch_status = 0
			begin

				if @histseq is not null	--assume no history records were ever created.
				begin
					select @dependhistyn = DependHistYN, @dependhistcode = DependHistCode
					from bHRCO where HRCo = @hrco

					if @dependhistyn = 'Y' and @dependhistcode is not null and @birthdate is not null
					begin
						if not exists(select 1 from bHREH where HRCo = @hrco and HRRef = @hrref and Seq = @histseq)
						begin
							goto inserthreh
						end
						else
						begin
							update bHREH set DateChanged = @birthdate 
							where HRCo = @hrco and HRRef = @hrref and Seq = @histseq
							goto endloop
						end
					end
				end
				else
				begin	--insert
					goto inserthreh
				end

				inserthreh:

					select @histseq = isnull(max(Seq),0)+1 
   					from dbo.bHREH with (nolock) 
   					where HRCo = @hrco and HRRef = @hrref
   
   					insert dbo.bHREH (HRCo, HRRef, Seq, Code, DateChanged, Type)
   					values (@hrco, @hrref, @histseq, @dependhistcode, @birthdate, 'H')
   
   	  				update dbo.bHRET 
   					set HistSeq = @histseq 
   					where HRCo = @hrco and HRRef = @hrref
     				and Seq = @seq

					goto endloop

				endloop:

				fetch next from update_curs into @hrco, @hrref, @seq, @birthdate, @histseq

			end

			if @opencurs = 1 
			begin
				close update_curs
				deallocate update_curs
			end
		end
     

		--end 199853
   
   
   
    return
   
    error:
    	select @errmsg = @errmsg + ' - cannot update HR Resource Dependent!'
   
    	RAISERROR(@errmsg, 11, -1);
    	rollback transaction

GO
