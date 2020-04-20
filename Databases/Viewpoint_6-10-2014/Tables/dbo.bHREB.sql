CREATE TABLE [dbo].[bHREB]
(
[HRCo] [dbo].[bCompany] NOT NULL,
[HRRef] [dbo].[bHRRef] NOT NULL,
[BenefitCode] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[DependentSeq] [int] NOT NULL,
[EligDate] [dbo].[bDate] NULL,
[ReminderDate] [dbo].[bDate] NULL,
[ActiveYN] [dbo].[bYN] NULL,
[EffectDate] [dbo].[bDate] NULL,
[EndDate] [dbo].[bDate] NULL,
[ReinstateYN] [dbo].[bYN] NULL,
[ReinstateDate] [dbo].[bDate] NULL,
[SmokerYN] [dbo].[bYN] NULL,
[ID] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[EmployerCost] [dbo].[bDollar] NULL,
[HistSeq] [int] NULL,
[UpdatedYN] [dbo].[bYN] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[CafePlanYN] [dbo].[bYN] NULL,
[CafePlanAmt] [dbo].[bDollar] NULL,
[BatchId] [dbo].[bBatchID] NULL,
[InUseBatchId] [dbo].[bBatchID] NULL,
[InUseMth] [dbo].[bMonth] NULL,
[Ben1] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[Rel1] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[Ben2] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[Rel2] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE          trigger [dbo].[btHREBd] on [dbo].[bHREB] for Delete
   as
   
   	 

	/**************************************************************
   	* 	Created: 04/03/00 ae
   	* 	Last Modified: 	mh 10/21/02 - added update to HREH
    *					mh 3/14/04 - 23061 
	*					mh 12/1/01 - 26360
   	*					mh 7/20/06 - 120935 - Need to check HRBE and HRBL for related 
	*					records prior to delete from HREB
	*					mh 10/29/2008 - 127008
   	*
   	**************************************************************/
   
   	declare @errmsg varchar(255), @validcnt int, @validcnt2 int,@errno int, 
   	@numrows int, @nullcnt int, @rcode int, @hrco bCompany, @hrref bHRRef, 
   	@seq int, @benefithistcode varchar(10), @datechgd bDate, @opencurs tinyint, 
   	@benefitcode varchar(10), @dependentseq int, @benefithistyn bYN
   
   	select @numrows = @@rowcount
   	if @numrows = 0 return
   	set nocount on
   
	--Need to check for related records in HRBL and HRBE and reject deletion if they exist.
	if exists(select 1 from bHRBL l join deleted d on l.HRCo = d.HRCo and l.BenefitCode = d.BenefitCode and 
		l.HRRef = d.HRRef and l.DependentSeq = d.DependentSeq)
   		begin
   			select @errmsg = 'Related Deduction/Liability Code entries exist in HRBL'  
   			goto error
   		end
	
	if exists(select 1 from bHRBE e join deleted d on e.HRCo = d.HRCo and e.BenefitCode = d.BenefitCode and 
		e.HRRef = d.HRRef and e.DependentSeq = d.DependentSeq)
   		begin
   			select @errmsg = 'Related Earnings Code entries exist in HRBL'  
   			goto error
   		end

   	declare deleted_curs cursor local fast_forward for
   	select HRCo, HRRef, BenefitCode, DependentSeq 
   	from deleted where HRCo is not null and
   	HRRef is not null and BenefitCode is not null and DependentSeq is not null
   
   	open deleted_curs
   	select @opencurs = 1
   
   	fetch next from deleted_curs into @hrco, @hrref, @benefitcode, @dependentseq
   
   	
   	while @@fetch_status = 0
   	begin
   		select @benefithistcode = BenefitHistCode, @benefithistyn = BenefitHistYN
   		from dbo.bHRCO with (nolock) where HRCo = @hrco
   
   		if @benefithistyn = 'Y' and @benefithistcode is not null
   		begin
   			select @seq = isnull(max(Seq),0)+1, @datechgd = convert(varchar(11), getdate()) 
   			from dbo.bHREH with (nolock) 
   			where HRCo = @hrco and HRRef = @hrref
   
   			insert dbo.bHREH (HRCo, HRRef, Seq, Code, DateChanged, Type)
   			values (@hrco, @hrref, @seq, @benefithistcode, @datechgd, 'H')
   
   	  		update dbo.bHREB 
   			set HistSeq = @seq 
   			where HRCo = @hrco and HRRef = @hrref
     			and BenefitCode = @benefitcode and DependentSeq = @dependentseq
   
   		end
   		--26360 - moved the following statement outside the if statement to prevent infinite loop   mh 12/1/04
   		fetch next from deleted_curs into @hrco, @hrref, @benefitcode, @dependentseq
   
   	end
   
   	if @opencurs = 1
   	begin
   		close deleted_curs
   		deallocate deleted_curs
   		select @opencurs = 0
   	end
   
   	/* Audit inserts */
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
   	select 'bHREB', 'HRCo: ' + convert(char(3),isnull(d.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(d.HRRef,'')) +
    ' BenefitCode: ' + convert(varchar(10),isnull(d.BenefitCode,'')) + ' DependentSeq: ' + convert(varchar(6),isnull(d.DependentSeq,'')),
    d.HRCo, 'D', '', null, null, getdate(), SUSER_SNAME()
    from deleted d join dbo.bHRCO e with (nolock) on
   	d.HRCo = e.HRCo
   	where e.AuditBenefitsYN = 'Y'
   
    	Return
   error:
   
   	if @opencurs = 1
   	begin
   		close insert_curs
   		deallocate insert_curs
   	end
   
   select @errmsg = (@errmsg + ' - cannot delete HREB! ')
   RAISERROR(@errmsg, 11, -1);
   rollback transaction

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE          trigger [dbo].[btHREBi] on [dbo].[bHREB] for INSERT as
   
    


	/*-----------------------------------------------------------------
     *   	Created by: 	ae  3/31/00
     * 		Modified by:  	mh 3/16/04 23061
     *						mh 07/16/04 25029
	 *						mh 10/29/2008 - 127008
     *
     */----------------------------------------------------------------
   
   	declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int,
   	@opencurs tinyint, @benefitcode varchar(10), @dependentseq int, @benefithistyn bYN
   
   	select @numrows = @@rowcount
   	if @numrows = 0 return
   	set nocount on
   
   	declare @hrco bCompany, @hrref bHRRef, @benefithistcode varchar(10), @dependseq int,
   	@seq int, @datechgd bDate
   
   	/*insert HREH record if flag set in HRCO*/
   
   	declare insert_curs cursor local fast_forward for
   	select HRCo, HRRef, BenefitCode, DependentSeq from inserted where HRCo is not null and
   	HRRef is not null and BenefitCode is not null and DependentSeq is not null
   
   	open insert_curs
   	select @opencurs = 1
   
   	fetch next from insert_curs into @hrco, @hrref, @benefitcode, @dependentseq
   
   	while @@fetch_status = 0
   	begin
   		select @benefithistcode = BenefitHistCode, @benefithistyn = BenefitHistYN
   		from dbo.bHRCO with (nolock) where HRCo = @hrco
   	
   		if @benefithistyn = 'Y' and @benefithistcode is not null
   		begin
   			select @seq = isnull(max(Seq),0)+1, @datechgd = convert(varchar(11), getdate()) 
   			from dbo.bHREH with (nolock) 
   			where HRCo = @hrco and HRRef = @hrref
   
   			insert dbo.bHREH (HRCo, HRRef, Seq, Code, DateChanged, Type)
   			values (@hrco, @hrref, @seq, @benefithistcode, @datechgd, 'H')
   
   	  		update dbo.bHREB 
   			set HistSeq = @seq 
   			where HRCo = @hrco and HRRef = @hrref
     			and BenefitCode = @benefitcode and DependentSeq = @dependentseq
   		end
   	
   		fetch next from insert_curs into @hrco, @hrref, @benefitcode, @dependentseq
   	end
   
   	if @opencurs = 1
   	begin
   		close insert_curs
   		deallocate insert_curs
   		select @opencurs = 0
   	end
   
   	 /* Audit inserts */

	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)   
   	select 'bHREB', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')) +
    ' BenefitCode: ' + convert(varchar(10),isnull(i.BenefitCode,'')) + ' DependentSeq: ' + convert(varchar(6),isnull(i.DependentSeq,'')),
    i.HRCo, 'A', '', null, null, getdate(), SUSER_SNAME()
    from inserted i join dbo.bHRCO e with (nolock) on
   	e.HRCo = i.HRCo 
   	where e.AuditBenefitsYN = 'Y'
   
   	return
   
   error:
   
   	if @opencurs = 1
   	begin
   		close insert_curs
   		deallocate insert_curs
   	end
   
    	select @errmsg = @errmsg + ' - cannot insert into HREB!'
    	RAISERROR(@errmsg, 11, -1);
    	rollback transaction


GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE                      trigger [dbo].[btHREBu] on [dbo].[bHREB] for UPDATE as
    
    	


/*-----------------------------------------------------------------
*   	Created by: 	ae 5/29/99
* 		Modified by: 	SR 10/23/01 - Issue 15014 - added bHREB into selection of Update(EndDate), Update(EffectDate)
*						mh 3/16/04 23061
*						mh 07/16/04 25059, 25138
*						mh 12/7/04 26347
*						mh 4/29/2005 - 28581 - Change HRRef conversion from varchar(5) to varchar(6)
*						mh 02/21/2008 - 23347 - Remove references to UpdatePRYN
*						mh 10/29/2008 - 127008
*
*	This trigger updates HREB.UpdatedYN to N if EffectiveDate or
*	ExpirationDate changed
*
*/----------------------------------------------------------------
    
    	declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int,
    	@hrco bCompany, @hrref bHRRef, @seq int, @code varchar(10),
    	@benefithistcode varchar(10), @dependseq int, @datechgd bDate,
    	@opencurs tinyint, @benefitcode varchar(10), @dependentseq int, @benefithistyn bYN
    
    	select @numrows = @@rowcount
    	if @numrows = 0 return
    	set nocount on
    
    	/* check for key changes */
    	if update(EffectDate) or update(EndDate)
    	begin
    		Update dbo.bHREB Set UpdatedYN = 'N' 
    		from inserted i
    		join deleted d 
    		on i.HRCo = d.HRCo and i.HRRef = d.HRRef and 
    		i.BenefitCode = d.BenefitCode and i.DependentSeq = d.DependentSeq
    		join dbo.bHREB b with (nolock) 
    		on i.HRCo = b.HRCo and i.HRRef = b.HRRef and 
    		i.BenefitCode = b.BenefitCode and i.DependentSeq=b.DependentSeq
    		where isnull(i.EffectDate, '') <> isnull(d.EffectDate,'') or  isnull(i.EndDate, '') <> isnull(d.EndDate,'')
    	end
    
    /* Issue 26347 - The above update works when updating effective date.  The following update 
    fails...it updates all records...when changing end date.  They are both the same.  Combined
    both.  Added the where clause.*/
    /*	if update(EndDate)
    	begin
    		Update dbo.bHREB Set UpdatedYN = 'N'
    		from inserted i
    		join deleted d 
    		on i.HRCo = d.HRCo and i.HRRef = d.HRRef and 
    		i.BenefitCode = d.BenefitCode and i.DependentSeq = d.DependentSeq
    		join dbo.HREB b with (nolock) 
    		on i.HRCo = b.HRCo and i.HRRef = b.HRRef and 
    		i.BenefitCode = b.BenefitCode and i.DependentSeq = b.DependentSeq 
    	end
    */
    
    	/*insert HREH record if flag set in HRCO*/
    	if not update(UpdatedYN)
    	begin
    		if not update(HistSeq)
    		begin
    
    			declare insert_curs cursor local fast_forward for
    			select HRCo, HRRef, BenefitCode, DependentSeq 
    			from inserted where HRCo is not null and
    			HRRef is not null and BenefitCode is not null and DependentSeq is not null
    		
    			open insert_curs
    			select @opencurs = 1
    		
    			fetch next from insert_curs into @hrco, @hrref, @benefitcode, @dependentseq
    			
    			while @@fetch_status = 0
    			begin
    				select @benefithistcode = BenefitHistCode, @benefithistyn = BenefitHistYN
    				from dbo.bHRCO with (nolock) where HRCo = @hrco
    	
    				if @benefithistyn = 'Y' and @benefithistcode is not null
    				begin
    					select @seq = isnull(max(Seq),0)+1, @datechgd = convert(varchar(11), getdate()) 
    					from dbo.bHREH with (nolock) 
    					where HRCo = @hrco and HRRef = @hrref
    
    					insert dbo.bHREH (HRCo, HRRef, Seq, Code, DateChanged, Type)
    					values (@hrco, @hrref, @seq, @benefithistcode, @datechgd, 'H')
    
    			  		update dbo.bHREB 
    					set HistSeq = @seq 
    					where HRCo = @hrco and HRRef = @hrref
    		  			and BenefitCode = @benefitcode and DependentSeq = @dependentseq
    				end
    
    				fetch next from insert_curs into @hrco, @hrref, @benefitcode, @dependentseq
    			end
    		end
    	end
    
    	if @opencurs = 1
    	begin
    		close insert_curs
    		deallocate insert_curs
    		select @opencurs = 0
    	end
    
   	/*Insert HQMA record*/

	if update(EligDate)
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
		select 'bHREB', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')) +
		' BenefitCode: ' + convert(varchar(10),isnull(i.BenefitCode,'')) +  'DependentSeq: ' + convert(varchar(5),isnull(i.DependentSeq,'')),
		i.HRCo, 'C','EligDate',
		convert(varchar(20),d.EligDate), Convert(varchar(20),i.EligDate),
		getdate(), SUSER_SNAME()
		from inserted i join deleted d on 
		i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.BenefitCode = d.BenefitCode and 
		i.DependentSeq = d.DependentSeq
		join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
		where isnull(i.EligDate,'') <> isnull(d.EligDate,'') and e.AuditBenefitsYN = 'Y'

	if update(ReminderDate)	    
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
    	select 'bHREB', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')) +
        ' BenefitCode: ' + convert(varchar(10),isnull(i.BenefitCode,'')) +  'DependentSeq: ' + convert(varchar(5),isnull(i.DependentSeq,'')),
        i.HRCo, 'C','ReminderDate',
        convert(varchar(20),d.ReminderDate), Convert(varchar(20),i.ReminderDate),
    	getdate(), SUSER_SNAME()
    	from inserted i join deleted d on 
    	i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.BenefitCode = d.BenefitCode and 
    	i.DependentSeq = d.DependentSeq
    	join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
    	where isnull(i.ReminderDate,'') <> isnull(d.ReminderDate,'') and e.AuditBenefitsYN = 'Y'

	if update(ActiveYN)
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
    	select 'bHREB', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')) +
        ' BenefitCode: ' + convert(varchar(10),isnull(i.BenefitCode,'')) +  'DependentSeq: ' + convert(varchar(5),isnull(i.DependentSeq,'')),
        i.HRCo, 'C','ActiveYN',
        convert(varchar(1),d.ActiveYN), Convert(varchar(1),i.ActiveYN),
    	getdate(), SUSER_SNAME()
    	from inserted i join deleted d on 
    	i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.BenefitCode = d.BenefitCode and 
    	i.DependentSeq = d.DependentSeq
    	join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
    	where isnull(i.ActiveYN,'') <> isnull(d.ActiveYN,'') and e.AuditBenefitsYN = 'Y'

	if update(EffectDate)    
    	insert into bHQMA select 'bHREB', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')) +
        ' BenefitCode: ' + convert(varchar(10),isnull(i.BenefitCode,'')) +  'DependentSeq: ' + convert(varchar(5),isnull(i.DependentSeq,'')),
        i.HRCo, 'C','EffectDate',
        convert(varchar(20),d.EffectDate), Convert(varchar(20),i.EffectDate),
    	getdate(), SUSER_SNAME()
    	from inserted i join deleted d on 
    	i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.BenefitCode = d.BenefitCode and 
    	i.DependentSeq = d.DependentSeq
    	join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
    	where isnull(i.EffectDate,'') <> isnull(d.EffectDate,'') and e.AuditBenefitsYN = 'Y'

	if update(EndDate)    
    	insert into bHQMA select 'bHREB', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')) +
        ' BenefitCode: ' + convert(varchar(10),isnull(i.BenefitCode,'')) +  'DependentSeq: ' + convert(varchar(5),isnull(i.DependentSeq,'')),
        i.HRCo, 'C','EndDate',
        convert(varchar(20),d.EndDate), Convert(varchar(20),i.EndDate),
    	getdate(), SUSER_SNAME()
    	from inserted i join deleted d on 
    	i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.BenefitCode = d.BenefitCode and 
    	i.DependentSeq = d.DependentSeq
    	join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
    	where isnull(i.EndDate,'') <> isnull(d.EndDate,'') and e.AuditBenefitsYN = 'Y'

	if update(ReinstateYN)    
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
    	select 'bHREB', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')) +
        ' BenefitCode: ' + convert(varchar(10),isnull(i.BenefitCode,'')) +  'DependentSeq: ' + convert(varchar(5),isnull(i.DependentSeq,'')),
        i.HRCo, 'C','ReinstateYN',
        convert(varchar(1),d.ReinstateYN), Convert(varchar(1),i.ReinstateYN),
    	getdate(), SUSER_SNAME()
    	from inserted i join deleted d on 
    	i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.BenefitCode = d.BenefitCode and 
    	i.DependentSeq = d.DependentSeq
    	join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
    	where isnull(i.ReinstateYN,'') <> isnull(d.ReinstateYN,'') and e.AuditBenefitsYN = 'Y'
    
	if update(ReinstateDate)
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
    	select 'bHREB', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')) +
        ' BenefitCode: ' + convert(varchar(10),isnull(i.BenefitCode,'')) +  'DependentSeq: ' + convert(varchar(5),isnull(i.DependentSeq,'')),
        i.HRCo, 'C','ReinstateDate',
        convert(varchar(20),d.ReinstateDate), Convert(varchar(20),i.ReinstateDate),
    	getdate(), SUSER_SNAME()
    	from inserted i join deleted d on 
    	i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.BenefitCode = d.BenefitCode and 
    	i.DependentSeq = d.DependentSeq
    	join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
    	where isnull(i.ReinstateDate,'') <> isnull(d.ReinstateDate,'') and e.AuditBenefitsYN = 'Y'

	if update(SmokerYN)
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
    	select 'bHREB', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')) +
        ' BenefitCode: ' + convert(varchar(10),isnull(i.BenefitCode,'')) +  'DependentSeq: ' + convert(varchar(5),isnull(i.DependentSeq,'')),
        i.HRCo, 'C','SmokerYN',
        convert(varchar(1),d.SmokerYN), Convert(varchar(1),i.SmokerYN),
    	getdate(), SUSER_SNAME()
    	from inserted i join deleted d on 
    	i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.BenefitCode = d.BenefitCode and 
    	i.DependentSeq = d.DependentSeq
    	join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
    	where isnull(i.SmokerYN,'') <> isnull(d.SmokerYN,'') and e.AuditBenefitsYN = 'Y'

	if update(ID)
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
    	select 'bHREB', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')) +
        ' BenefitCode: ' + convert(varchar(10),isnull(i.BenefitCode,'')) +  'DependentSeq: ' + convert(varchar(5),isnull(i.DependentSeq,'')),
        i.HRCo, 'C','ID',
        convert(varchar(20),d.ID), Convert(varchar(20),i.ID),
    	getdate(), SUSER_SNAME()
    	from inserted i join deleted d on 
    	i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.BenefitCode = d.BenefitCode and 
    	i.DependentSeq = d.DependentSeq
    	join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
    	where isnull(i.ID,'') <> isnull(d.ID,'') and e.AuditBenefitsYN = 'Y'

	if update(EmployerCost)
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
    	select 'bHREB', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')) +
    	' BenefitCode: ' + convert(varchar(10),isnull(i.BenefitCode,'')) +  'DependentSeq: ' + convert(varchar(5),isnull(i.DependentSeq,'')),
        i.HRCo, 'C','EmployerCost',
        convert(varchar(12),d.EmployerCost), Convert(varchar(12),i.EmployerCost),
    	getdate(), SUSER_SNAME()
    	from inserted i join deleted d on 
    	i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.BenefitCode = d.BenefitCode and 
    	i.DependentSeq = d.DependentSeq
    	join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
    	where isnull(i.EmployerCost,0) <> isnull(d.EmployerCost,0) and e.AuditBenefitsYN = 'Y'
    
    /*
    	insert into bHQMA select 'bHREB', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')) +
        ' BenefitCode: ' + convert(varchar(10),isnull(i.BenefitCode,'')) +  'DependentSeq: ' + convert(varchar(5),isnull(i.DependentSeq,'')),
        i.HRCo, 'C','HistSeq',
        convert(varchar(6),d.HistSeq), Convert(varchar(6),i.HistSeq),
    	getdate(), SUSER_SNAME()
    	from inserted i join deleted d on 
    	i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.BenefitCode = d.BenefitCode and 
    	i.DependentSeq = d.DependentSeq
    	join dbo.HRCO e with (nolock) on i.HRCo = e.HRCo
    	where isnull(i.HistSeq,0) <> isnull(d.HistSeq,0) and e.AuditBenefitsYN = 'Y'
    */

/*	Issue 23347
    	insert into bHQMA select 'bHREB', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')) +
        ' BenefitCode: ' + convert(varchar(10),isnull(i.BenefitCode,'')) +  'DependentSeq: ' + convert(varchar(5),isnull(i.DependentSeq,'')),
        i.HRCo, 'C','UpdatePRYN',
        convert(varchar(1),d.UpdatePRYN), Convert(varchar(1),i.UpdatePRYN),
    	getdate(), SUSER_SNAME()
    	from inserted i join deleted d on 
    	i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.BenefitCode = d.BenefitCode and 
    	i.DependentSeq = d.DependentSeq
    	join dbo.HRCO e with (nolock) on i.HRCo = e.HRCo
    	where isnull(i.UpdatePRYN,'') <> isnull(d.UpdatePRYN,'') and e.AuditBenefitsYN = 'Y'
*/    
	if update(CafePlanYN)
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
		select 'bHREB', 'HRCo: ' + convert(char(3),
		i.HRCo) + ' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')) +
		' BenefitCode: ' + convert(varchar(10),isnull(i.BenefitCode,'')) +  'DependentSeq: ' + convert(varchar(5),isnull(i.DependentSeq,'')),
		i.HRCo, 'C','CafePlanYN',
		convert(varchar(1),d.CafePlanYN), Convert(varchar(1),i.CafePlanYN),
		getdate(), SUSER_SNAME()
		from inserted i join deleted d on 
		i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.BenefitCode = d.BenefitCode and 
		i.DependentSeq = d.DependentSeq
		join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
		where isnull(i.CafePlanYN,'') <> isnull(d.CafePlanYN,'') and e.AuditBenefitsYN = 'Y'

	if update(CafePlanAmt) 
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)   
    	select 'bHREB', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')) +
        ' BenefitCode: ' + convert(varchar(10),isnull(i.BenefitCode,'')) +  'DependentSeq: ' + convert(varchar(5),isnull(i.DependentSeq,'')),
        i.HRCo, 'C','CafePlanAmt',
        convert(varchar(12),d.CafePlanAmt), Convert(varchar(12),i.CafePlanAmt),
    	getdate(), SUSER_SNAME()
    	from inserted i join deleted d on 
    	i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.BenefitCode = d.BenefitCode and 
    	i.DependentSeq = d.DependentSeq
    	join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
    	where isnull(i.CafePlanAmt,0) <> isnull(d.CafePlanAmt,0) and e.AuditBenefitsYN = 'Y'

	if update(Ben1)
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
    	select 'bHREB', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')) +
        ' BenefitCode: ' + convert(varchar(10),isnull(i.BenefitCode,'')) +  'DependentSeq: ' + convert(varchar(5),isnull(i.DependentSeq,'')),
        i.HRCo, 'C','Ben1',
        convert(varchar(30),d.Ben1), Convert(varchar(30),i.Ben1),
    	getdate(), SUSER_SNAME()
    	from inserted i join deleted d on 
    	i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.BenefitCode = d.BenefitCode and 
    	i.DependentSeq = d.DependentSeq
    	join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
    	where isnull(i.Ben1,'') <> isnull(d.Ben1,'') and e.AuditBenefitsYN = 'Y'

	if update(Rel1)
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
        select 'bHREB', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')) +
        ' BenefitCode: ' + convert(varchar(10),isnull(i.BenefitCode,'')) +  'DependentSeq: ' + convert(varchar(5),isnull(i.DependentSeq,'')),
        i.HRCo, 'C','Rel1',
        convert(varchar(30),d.Rel1), Convert(varchar(30),i.Rel1),
    	getdate(), SUSER_SNAME()
    	from inserted i join deleted d on 
    	i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.BenefitCode = d.BenefitCode and 
    	i.DependentSeq = d.DependentSeq
    	join dbo.HRCO e with (nolock) on i.HRCo = e.HRCo
    	where isnull(i.Rel1,'') <> isnull(d.Rel1,'') and e.AuditBenefitsYN = 'Y'

	if update(Ben2)    
    	insert into bHQMA select 'bHREB', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')) +
        ' BenefitCode: ' + convert(varchar(10),isnull(i.BenefitCode,'')) +  'DependentSeq: ' + convert(varchar(5),isnull(i.DependentSeq,'')),
        i.HRCo, 'C','Ben2',
        convert(varchar(30),d.Ben2), Convert(varchar(30),i.Ben2),
    	getdate(), SUSER_SNAME()
    	from inserted i join deleted d on 
    	i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.BenefitCode = d.BenefitCode and 
    	i.DependentSeq = d.DependentSeq
    	join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
    	where isnull(i.Ben2,'') <> isnull(d.Ben2,'') and e.AuditBenefitsYN = 'Y'

	if update(Rel2)
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
    	select 'bHREB', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')) +
        ' BenefitCode: ' + convert(varchar(10),isnull(i.BenefitCode,'')) +  'DependentSeq: ' + convert(varchar(5),isnull(i.DependentSeq,'')),
        i.HRCo, 'C','Rel2',
        convert(varchar(30),d.Rel2), Convert(varchar(30),i.Rel2),
    	getdate(), SUSER_SNAME()
    	from inserted i join deleted d on 
    	i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.BenefitCode = d.BenefitCode and 
    	i.DependentSeq = d.DependentSeq
    	join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
    	where isnull(i.Rel2,'') <> isnull(d.Rel2,'') and e.AuditBenefitsYN = 'Y'
    
    	return
    
    error:
    
    	if @opencurs = 1
    	begin
    		close insert_curs
    		deallocate insert_curs
    	end
    
    	select @errmsg = @errmsg + ' - could not update HR Resource Benefit Code!'
    	RAISERROR(@errmsg, 11, -1);
    
    	rollback transaction


GO
ALTER TABLE [dbo].[bHREB] WITH NOCHECK ADD CONSTRAINT [CK_bHREB_ActiveYN] CHECK (([ActiveYN]='Y' OR [ActiveYN]='N' OR [ActiveYN] IS NULL))
GO
ALTER TABLE [dbo].[bHREB] WITH NOCHECK ADD CONSTRAINT [CK_bHREB_CafePlanYN] CHECK (([CafePlanYN]='Y' OR [CafePlanYN]='N' OR [CafePlanYN] IS NULL))
GO
ALTER TABLE [dbo].[bHREB] WITH NOCHECK ADD CONSTRAINT [CK_bHREB_ReinstateYN] CHECK (([ReinstateYN]='Y' OR [ReinstateYN]='N' OR [ReinstateYN] IS NULL))
GO
ALTER TABLE [dbo].[bHREB] WITH NOCHECK ADD CONSTRAINT [CK_bHREB_SmokerYN] CHECK (([SmokerYN]='Y' OR [SmokerYN]='N' OR [SmokerYN] IS NULL))
GO
ALTER TABLE [dbo].[bHREB] WITH NOCHECK ADD CONSTRAINT [CK_bHREB_UpdatedYN] CHECK (([UpdatedYN]='Y' OR [UpdatedYN]='N' OR [UpdatedYN] IS NULL))
GO
CREATE UNIQUE CLUSTERED INDEX [biHREB] ON [dbo].[bHREB] ([HRCo], [HRRef], [BenefitCode], [DependentSeq]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bHREB] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
