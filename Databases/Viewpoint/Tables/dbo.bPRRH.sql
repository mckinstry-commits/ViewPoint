CREATE TABLE [dbo].[bPRRH]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[Crew] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[PostDate] [dbo].[bDate] NOT NULL,
[SheetNum] [smallint] NOT NULL,
[PRGroup] [dbo].[bGroup] NULL,
[JCCo] [dbo].[bCompany] NOT NULL,
[Job] [dbo].[bJob] NOT NULL,
[Shift] [tinyint] NOT NULL,
[PhaseGroup] [dbo].[bGroup] NOT NULL,
[Phase1] [dbo].[bPhase] NULL,
[Phase1Units] [dbo].[bUnits] NULL,
[Phase1CostType] [dbo].[bJCCType] NULL,
[Phase2] [dbo].[bPhase] NULL,
[Phase2Units] [dbo].[bUnits] NULL,
[Phase2CostType] [dbo].[bJCCType] NULL,
[Phase3] [dbo].[bPhase] NULL,
[Phase3Units] [dbo].[bUnits] NULL,
[Phase3CostType] [dbo].[bJCCType] NULL,
[Phase4] [dbo].[bPhase] NULL,
[Phase4Units] [dbo].[bUnits] NULL,
[Phase4CostType] [dbo].[bJCCType] NULL,
[Phase5] [dbo].[bPhase] NULL,
[Phase5Units] [dbo].[bUnits] NULL,
[Phase5CostType] [dbo].[bJCCType] NULL,
[Phase6] [dbo].[bPhase] NULL,
[Phase6Units] [dbo].[bUnits] NULL,
[Phase6CostType] [dbo].[bJCCType] NULL,
[Phase7] [dbo].[bPhase] NULL,
[Phase7Units] [dbo].[bUnits] NULL,
[Phase7CostType] [dbo].[bJCCType] NULL,
[Phase8] [dbo].[bPhase] NULL,
[Phase8Units] [dbo].[bUnits] NULL,
[Phase8CostType] [dbo].[bJCCType] NULL,
[CreatedOn] [smalldatetime] NOT NULL,
[CreatedBy] [dbo].[bVPUserName] NOT NULL,
[ApprovedBy] [dbo].[bVPUserName] NULL,
[Status] [tinyint] NOT NULL,
[SendSeq] [int] NULL,
[PRBatchMth] [dbo].[bMonth] NULL,
[PRBatchId] [dbo].[bBatchID] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biPRRH] ON [dbo].[bPRRH] ([PRCo], [Crew], [PostDate], [SheetNum]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [biPRRHJob] ON [dbo].[bPRRH] ([JCCo], [Job], [PhaseGroup]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
   
	CREATE trigger [dbo].[btPRRHu] on [dbo].[bPRRH] for UPDATE as
   

	
	/*-----------------------------------------------------------------
    *  Created: mh 
    *  Modified: mh 6/27/08 - Added updates to PRRQ - Issue 128703 	
	*			 mh 02/25/08 - Issue 132185.  Only re-initialize/update related grids
    *						PRRE/PRRQ if the phase has actually changed.  
	*			mh 02/05/09 - Issue 132185.  Cannot solely rely on update function
	*				when determining if a Phase value has changed.  Need to look at both
	*				inserted and deleted value.
	*			mh 02/06/09 - Issue 131950.  Cannot make changes to a timesheet if Status > 0
    *
    *
    *
    */----------------------------------------------------------------

	declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int, @opencurs tinyint,
	@prco bCompany, @crew varchar(10), @postdate bDate, @sheetnum smallint, @craft bCraft, @class bClass, 
	@template smallint, @shift tinyint, @jcco bCompany, @job bJob, @jobcraft bCraft, @rcode tinyint

	select @numrows = @@rowcount
	
	if @numrows = 0 return

	set nocount on

	if update(ApprovedBy) or update([Status]) or update(SendSeq) or update(PRBatchMth) or update(PRBatchId) 
	begin
		return
	end

	/*Reject updates if Timesheet is locked, no need to check anything else if locked or
	status is greater then zero*/
	if exists(select 1 from inserted i join deleted d on i.PRCo = d.PRCo and i.Crew = d.Crew and
	i.PostDate = d.PostDate and i.SheetNum = d.SheetNum and i.Status = d.Status where i.Status > 0)
	begin
		select @errmsg = 'Timesheet has been locked and cannot be edited.'
		goto error
	end

	select @opencurs = 0
   
	/* check for key changes */
	if update(PRCo)
	begin
		select @validcnt = count(1) from deleted d
		join inserted i on d.PRCo = i.PRCo
		if @validcnt <> @numrows
		begin
			select @errmsg = 'Cannot change PR Company '
			goto error
		end
	end

	if update(Crew)
	begin
		select @validcnt = count(1) from deleted d
		join inserted i on d.PRCo = i.PRCo and d.Crew = i.Crew
		if @validcnt <> @numrows
		begin
			select @errmsg = 'Cannot change Crew '
			goto error
		end
	end

	if update(PostDate)
	begin
		select @validcnt = count(1) from deleted d
		join inserted i on d.PRCo = i.PRCo and d.Crew = i.Crew and d.PostDate = i.PostDate
		if @validcnt <> @numrows
		begin
			select @errmsg = 'Cannot change Timecard Date '
			goto error
		end
	end

	if update(SheetNum)
	begin
		select @validcnt = count(1) from deleted d
		join inserted i on d.PRCo = i.PRCo and d.Crew = i.Crew and d.PostDate = i.PostDate and d.SheetNum = i.SheetNum
		if @validcnt <> @numrows
		begin
			select @errmsg = 'Cannot change Sheet # '
			goto error
		end
	end
	
	if update(JCCo) or update(Job) or update(Shift)
	begin

		if (select count(1) from bPRRE p join inserted i on p.PRCo = i.PRCo and p.Crew = i.Crew and 
			p.PostDate = i.PostDate and i.SheetNum = p.SheetNum) > 0
		begin
			--We have Employees in PRRE.  Repull their rates

			declare cursPRRH cursor local fast_forward for
			select PRCo, Crew, PostDate, SheetNum, Shift, JCCo, Job from inserted

			open cursPRRH

			select @opencurs = 1

			fetch next from cursPRRH into @prco, @crew, @postdate, @sheetnum, @shift, @jcco, @job

			while @@fetch_status = 0
			begin

				--Need Template
				select @template=CraftTemplate from JCJM where JCCo = @jcco and Job = @job

				--reciprocal craft?
				exec @rcode = bspPRJobCraftDflt @prco, @craft, @template, @jobcraft output, @errmsg

				if @rcode = 0
				begin

					if @jobcraft is not null
						select @craft = @jobcraft
						--Not validating Class against craft here.  At this point Class is null.  The way bspPRTSRateDflt is being called
						--without an employee...that procedure will spin through all the employees in PRRE and get the thier class.  bspPRRateDefault
						--will be called from within bspPRTSRateDefault. Craft/Class validation will be done within bspPRRateDefault.
				end
				else --@rcode = 1
				begin
					goto error
				end

				--Passing in null for @employee parameter.  Proceedure will update all employees if @employee is null.
				--do not care about the outputs other then @errmsg
				exec @rcode = bspPRTSRateDflt @prco, @crew, @postdate, @sheetnum, null, @craft, @class, @template,
				@shift, null, null, null, @errmsg output

				if @rcode = 1
					goto error

				fetch next from cursPRRH into @prco, @crew, @postdate, @sheetnum, @shift, @jcco, @job

			end

		end

	end

		
	declare @iphase1 bPhase, @iphase2 bPhase, @iphase3 bPhase, @iphase4 bPhase, @iphase5 bPhase, 
	@iphase6 bPhase, @iphase7 bPhase, @iphase8 bPhase, @dphase1 bPhase, @dphase2 bPhase, @dphase3 bPhase, 
	@dphase4 bPhase, @dphase5 bPhase, @dphase6 bPhase, @dphase7 bPhase, @dphase8 bPhase  

	declare @whichphase varchar(7), @msg varchar(100), @openPRRHPhase tinyint

	--Recycled variables.  Initialize them to null
	select @prco = null, @crew = null, @postdate = null, @sheetnum = null, @jcco = null, @job = null

	declare cursPRRHPhase cursor local fast_forward for
	select i.PRCo, i.Crew, i.PostDate, i.SheetNum, i.Phase1, i.Phase2, i.Phase3, 
	i.Phase4, i.Phase5, i.Phase6, i.Phase7, i.Phase8, i.JCCo, i.Job, 
	d.Phase1, d.Phase2, d.Phase3, d.Phase4, d.Phase5, d.Phase6, d.Phase7, d.Phase8
	from inserted i 
	join deleted d on i.PRCo = d.PRCo and i.Crew = d.Crew and i.PostDate = d.PostDate and i.SheetNum = d.SheetNum

	open cursPRRHPhase
	select @openPRRHPhase = 1

	fetch next from cursPRRHPhase into @prco, @crew, @postdate, @sheetnum, @iphase1, @iphase2, @iphase3, @iphase4, @iphase5,
	@iphase6, @iphase7, @iphase8, @jcco, @job,
	@dphase1, @dphase2, @dphase3, @dphase4, @dphase5, @dphase6, @dphase7, @dphase8

	while @@fetch_status = 0
	begin

		if update(Phase1)
		begin
			if ((@iphase1 is not null) and (isnull(@iphase1,'') <> isnull(@dphase1,'')))
			begin
				exec vspPRTSEquipInitAddedPhase @prco, @crew, @postdate, @sheetnum, @jcco, @job, @iphase1, 'Phase1', @msg output
				exec vspPRTSEmpInitAddedPhase @prco, @crew, @postdate, @sheetnum, @jcco, @job, @iphase1, 'Phase1', @msg output
			end
			else
			begin
				if (@iphase1 is null)
				begin
					--Phase is been removed.  Clean up PRRQ
					update PRRQ set Phase1CType = null, Phase1Rev = null, Phase1Usage = null
					where PRCo = @prco and Crew = @crew and PostDate = @postdate and SheetNum = @sheetnum

					--Phase was removed.  Clean up PRRE
					update PRRE set Phase1RegHrs = null, Phase1OTHrs = null, Phase1DblHrs = null
					where PRCo = @prco and Crew = @crew and PostDate = @postdate and SheetNum = @sheetnum
				end
			end
		end

		if update(Phase2)
		begin
			if ((@iphase2 is not null) and (isnull(@iphase2,'') <> isnull(@dphase2,'')))
			begin
				exec vspPRTSEquipInitAddedPhase @prco, @crew, @postdate, @sheetnum, @jcco, @job, @iphase2, 'Phase2', @msg output
				exec vspPRTSEmpInitAddedPhase @prco, @crew, @postdate, @sheetnum, @jcco, @job, @iphase2, 'Phase2', @msg output
			end
			else
			begin
				if (@iphase2 is null)
				begin
					--Phase is been removed.  Clean up PRRQ
					update PRRQ set Phase2CType = null, Phase2Rev = null, Phase2Usage = null
					where PRCo = @prco and Crew = @crew and PostDate = @postdate and SheetNum = @sheetnum

					--Phase was removed.  Clean up PRRE
					update PRRE set Phase2RegHrs = null, Phase2OTHrs = null, Phase2DblHrs = null
					where PRCo = @prco and Crew = @crew and PostDate = @postdate and SheetNum = @sheetnum
				end
			end
		end
	
		if update(Phase3)
		begin
			if ((@iphase3 is not null) and (isnull(@iphase3,'') <> isnull(@dphase3,'')))
			begin
				exec @rcode = vspPRTSEquipInitAddedPhase @prco, @crew, @postdate, @sheetnum, @jcco, @job, @iphase3, 'Phase3', @msg output
				exec vspPRTSEmpInitAddedPhase @prco, @crew, @postdate, @sheetnum, @jcco, @job, @iphase3, 'Phase3', @msg output
			end
			else
			begin
				if (@iphase3 is null)
				begin
					--Phase is been removed.  Clean up PRRQ
					update PRRQ set Phase3CType = null, Phase3Rev = null, Phase3Usage = null
					where PRCo = @prco and Crew = @crew and PostDate = @postdate and SheetNum = @sheetnum

					--Phase was removed.  Clean up PRRE
					update PRRE set Phase3RegHrs = null, Phase3OTHrs = null, Phase3DblHrs = null
					where PRCo = @prco and Crew = @crew and PostDate = @postdate and SheetNum = @sheetnum
				end
			end
		end
	
		if update(Phase4)
		begin
			if ((@iphase4 is not null) and (isnull(@iphase4,'') <> isnull(@dphase4,'')))
			begin
				exec vspPRTSEquipInitAddedPhase @prco, @crew, @postdate, @sheetnum, @jcco, @job, @iphase4, 'Phase4', @msg output
				exec vspPRTSEmpInitAddedPhase @prco, @crew, @postdate, @sheetnum, @jcco, @job, @iphase4, 'Phase4', @msg output
			end
			else
			begin
				if (@iphase4 is null)
				begin
					--Phase is been removed.  Clean up PRRQ
					update PRRQ set Phase4CType = null, Phase4Rev = null, Phase4Usage = null
					where PRCo = @prco and Crew = @crew and PostDate = @postdate and SheetNum = @sheetnum

					--Phase was removed.  Clean up PRRE
					update PRRE set Phase4RegHrs = null, Phase4OTHrs = null, Phase4DblHrs = null
					where PRCo = @prco and Crew = @crew and PostDate = @postdate and SheetNum = @sheetnum
				end
			end
		end
	
		if update(Phase5)
		begin
			if ((@iphase5 is not null) and (isnull(@iphase5,'') <> isnull(@dphase5,'')))
			begin
				exec vspPRTSEquipInitAddedPhase @prco, @crew, @postdate, @sheetnum, @jcco, @job, @iphase5, 'Phase5', @msg output
				exec vspPRTSEmpInitAddedPhase @prco, @crew, @postdate, @sheetnum, @jcco, @job, @iphase5, 'Phase5', @msg output
			end
			else
			begin
				if (@iphase5 is null)
				begin
					--Phase is been removed.  Clean up PRRQ
					update PRRQ set Phase5CType = null, Phase5Rev = null, Phase5Usage = null
					where PRCo = @prco and Crew = @crew and PostDate = @postdate and SheetNum = @sheetnum

					--Phase was removed.  Clean up PRRE
					update PRRE set Phase5RegHrs = null, Phase5OTHrs = null, Phase5DblHrs = null
					where PRCo = @prco and Crew = @crew and PostDate = @postdate and SheetNum = @sheetnum
				end
			end
		end
	
		if update(Phase6)
		begin
			if ((@iphase6 is not null) and (isnull(@iphase6,'') <> isnull(@dphase6,'')))
			begin
				exec vspPRTSEquipInitAddedPhase @prco, @crew, @postdate, @sheetnum, @jcco, @job, @iphase6, 'Phase6', @msg output
				exec vspPRTSEmpInitAddedPhase @prco, @crew, @postdate, @sheetnum, @jcco, @job, @iphase6, 'Phase6', @msg output
			end
			else
			begin
				if (@iphase6 is null)
				begin
					--Phase is been removed.  Clean up PRRQ
					update PRRQ set Phase6CType = null, Phase6Rev = null, Phase6Usage = null
					where PRCo = @prco and Crew = @crew and PostDate = @postdate and SheetNum = @sheetnum

					--Phase was removed.  Clean up PRRE
					update PRRE set Phase6RegHrs = null, Phase6OTHrs = null, Phase6DblHrs = null
					where PRCo = @prco and Crew = @crew and PostDate = @postdate and SheetNum = @sheetnum
				end
			end
		end
	
		if update(Phase7)
		begin
			if ((@iphase7 is not null) and (isnull(@iphase7,'') <> isnull(@dphase7,'')))
			begin
				exec vspPRTSEquipInitAddedPhase @prco, @crew, @postdate, @sheetnum, @jcco, @job, @iphase7, 'Phase7', @msg output
				exec vspPRTSEmpInitAddedPhase @prco, @crew, @postdate, @sheetnum, @jcco, @job, @iphase7, 'Phase7', @msg output
			end
			else
			begin
				if (@iphase7 is null)
				begin
					--Phase is been removed.  Clean up PRRQ
					update PRRQ set Phase7CType = null, Phase7Rev = null, Phase7Usage = null
					where PRCo = @prco and Crew = @crew and PostDate = @postdate and SheetNum = @sheetnum

					--Phase was removed.  Clean up PRRE
					update PRRE set Phase7RegHrs = null, Phase7OTHrs = null, Phase7DblHrs = null
					where PRCo = @prco and Crew = @crew and PostDate = @postdate and SheetNum = @sheetnum
				end
			end
		end

		
		if update(Phase8)
		begin
			if ((@iphase8 is not null) and (isnull(@iphase8,'') <> isnull(@dphase8,'')))
			begin
				exec vspPRTSEquipInitAddedPhase @prco, @crew, @postdate, @sheetnum, @jcco, @job, @iphase8, 'Phase8', @msg output
				exec vspPRTSEmpInitAddedPhase @prco, @crew, @postdate, @sheetnum, @jcco, @job, @iphase8, 'Phase8', @msg output
			end
			else
			begin
				if (@iphase8 is null)
				begin
					--Phase is been removed.  Clean up PRRQ
					update PRRQ set Phase8CType = null, Phase8Rev = null, Phase8Usage = null
					where PRCo = @prco and Crew = @crew and PostDate = @postdate and SheetNum = @sheetnum

					--Phase was removed.  Clean up PRRE
					update PRRE set Phase8RegHrs = null, Phase8OTHrs = null, Phase8DblHrs = null
					where PRCo = @prco and Crew = @crew and PostDate = @postdate and SheetNum = @sheetnum
				end
			end
		end

		if (update(Phase1) or update(Phase2) or update(Phase3) or update(Phase4) or update(Phase5)
		or update(Phase6) or update(Phase7) or update(Phase8)) 
		begin

			update PRRE set TotalHrs = (isnull(Phase1RegHrs,0) + isnull(Phase1OTHrs,0) + isnull(Phase1DblHrs,0) + 
			isnull(Phase2RegHrs,0) + isnull(Phase2OTHrs,0) + isnull(Phase2DblHrs,0) + isnull(Phase3RegHrs,0) + 
			isnull(Phase3OTHrs,0) + isnull(Phase3DblHrs,0) + isnull(Phase4RegHrs,0) + isnull(Phase4OTHrs,0) + 
			isnull(Phase4DblHrs,0) + isnull(Phase5RegHrs,0) + isnull(Phase5OTHrs,0) + isnull(Phase5DblHrs,0) + 
			isnull(Phase6RegHrs,0) + isnull(Phase6OTHrs,0) + isnull(Phase6DblHrs,0) + isnull(Phase7RegHrs,0) + 
			isnull(Phase7OTHrs,0) + isnull(Phase7DblHrs,0) + isnull(Phase8RegHrs,0) + isnull(Phase8OTHrs,0) + 
			isnull(Phase8DblHrs,0))
			where PRCo = @prco and Crew = @crew and PostDate = @postdate and SheetNum = @sheetnum

			update PRRQ set TotalUsage = (isnull(Phase1Usage,0) + isnull(Phase2Usage,0) + isnull(Phase3Usage,0) + isnull(Phase4Usage,0) + isnull(Phase5Usage,0) + isnull(Phase6Usage,0) + isnull(Phase7Usage,0) + isnull(Phase8Usage,0))
			where PRCo = @prco and Crew = @crew and PostDate = @postdate and SheetNum = @sheetnum
			
		end

		fetch next from cursPRRHPhase into @prco, @crew, @postdate, @sheetnum, @iphase1, 
		@iphase2, @iphase3, @iphase4, @iphase5, @iphase6, @iphase7, @iphase8, @jcco, @job,
		@dphase1, @dphase2, @dphase3, @dphase4, @dphase5, @dphase6, @dphase7, @dphase8

	end

	if @opencurs = 1
	begin
		close cursPRRH
		deallocate cursPRRH
	end

	if @openPRRHPhase = 1
	begin
		close cursPRRHPhase
		deallocate cursPRRHPhase
	end


----Test Auditing Code.  We had a problem with Employee Hours getting dropped when the user 
--hit "Lock/Send".  We wanted to know if anything else was changing. Leaving this code commented 
--out in case it is needed again...like Audits are requested.  mh
--
--	if update(PRGroup)
--		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
--		select 'bPRRH', 'PRCo: ' + convert(char(3),isnull(i.PRCo,'')) + 
--		' Crew: ' + convert(varchar,isnull(i.Crew,'')) +
--		' PostDate: ' + convert(varchar,isnull(i.PostDate,'')) +  
--		' SheetNum: ' + convert(varchar,isnull(i.SheetNum,'')),
--		i.PRCo, 'C','PRGroup',
--		convert(varchar,d.PRGroup), Convert(varchar,i.PRGroup),
--		getdate(), SUSER_SNAME()
--		from inserted i join deleted d on 
--		i.PRCo = d.PRCo and i.Crew = d.Crew and i.PostDate = d.PostDate and 
--		i.SheetNum = d.SheetNum 
--		where isnull(i.PRGroup,0) <> isnull(d.PRGroup,0) 
--
--	if update(JCCo)
--		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
--		select 'bPRRH', 'PRCo: ' + convert(char(3),isnull(i.PRCo,'')) + 
--		' Crew: ' + convert(varchar,isnull(i.Crew,'')) +
--		' PostDate: ' + convert(varchar,isnull(i.PostDate,'')) +  
--		' SheetNum: ' + convert(varchar,isnull(i.SheetNum,'')),
--		i.PRCo, 'C','JCCo',
--		convert(varchar,d.JCCo), Convert(varchar,i.JCCo),
--		getdate(), SUSER_SNAME()
--		from inserted i join deleted d on 
--		i.PRCo = d.PRCo and i.Crew = d.Crew and i.PostDate = d.PostDate and 
--		i.SheetNum = d.SheetNum 
--		where isnull(i.JCCo,0) <> isnull(d.JCCo,0) 
--
--	if update(Job)
--		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
--		select 'bPRRH', 'PRCo: ' + convert(char(3),isnull(i.PRCo,'')) + 
--		' Crew: ' + convert(varchar,isnull(i.Crew,'')) +
--		' PostDate: ' + convert(varchar,isnull(i.PostDate,'')) +  
--		' SheetNum: ' + convert(varchar,isnull(i.SheetNum,'')),
--		i.PRCo, 'C','Job',
--		convert(varchar,d.Job), Convert(varchar,i.Job),
--		getdate(), SUSER_SNAME()
--		from inserted i join deleted d on 
--		i.PRCo = d.PRCo and i.Crew = d.Crew and i.PostDate = d.PostDate and 
--		i.SheetNum = d.SheetNum 
--		where isnull(i.Job,'') <> isnull(d.Job,'') 
--
--	if update(Shift)
--		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
--		select 'bPRRH', 'PRCo: ' + convert(char(3),isnull(i.PRCo,'')) + 
--		' Crew: ' + convert(varchar,isnull(i.Crew,'')) +
--		' PostDate: ' + convert(varchar,isnull(i.PostDate,'')) +  
--		' SheetNum: ' + convert(varchar,isnull(i.SheetNum,'')),
--		i.PRCo, 'C','Shift',
--		convert(varchar,d.Shift), Convert(varchar,i.Shift),
--		getdate(), SUSER_SNAME()
--		from inserted i join deleted d on 
--		i.PRCo = d.PRCo and i.Crew = d.Crew and i.PostDate = d.PostDate and 
--		i.SheetNum = d.SheetNum 
--		where isnull(i.Shift,0) <> isnull(d.Shift,0) 
--
--	if update(PhaseGroup)
--		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
--		select 'bPRRH', 'PRCo: ' + convert(char(3),isnull(i.PRCo,'')) + 
--		' Crew: ' + convert(varchar,isnull(i.Crew,'')) +
--		' PostDate: ' + convert(varchar,isnull(i.PostDate,'')) +  
--		' SheetNum: ' + convert(varchar,isnull(i.SheetNum,'')),
--		i.PRCo, 'C','PhaseGroup',
--		convert(varchar,d.PhaseGroup), Convert(varchar,i.PhaseGroup),
--		getdate(), SUSER_SNAME()
--		from inserted i join deleted d on 
--		i.PRCo = d.PRCo and i.Crew = d.Crew and i.PostDate = d.PostDate and 
--		i.SheetNum = d.SheetNum 
--		where isnull(i.PhaseGroup,0) <> isnull(d.PhaseGroup,0) 
--
--	if update(Phase1)
--		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
--		select 'bPRRH', 'PRCo: ' + convert(char(3),isnull(i.PRCo,'')) + 
--		' Crew: ' + convert(varchar,isnull(i.Crew,'')) +
--		' PostDate: ' + convert(varchar,isnull(i.PostDate,'')) +  
--		' SheetNum: ' + convert(varchar,isnull(i.SheetNum,'')),
--		i.PRCo, 'C','Phase1',
--		convert(varchar,d.Phase1), Convert(varchar,i.Phase1),
--		getdate(), SUSER_SNAME()
--		from inserted i join deleted d on 
--		i.PRCo = d.PRCo and i.Crew = d.Crew and i.PostDate = d.PostDate and 
--		i.SheetNum = d.SheetNum 
--		where isnull(i.Phase1,'') <> isnull(d.Phase1,'') 
--
--	if update(Phase1Units)
--		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
--		select 'bPRRH', 'PRCo: ' + convert(char(3),isnull(i.PRCo,'')) + 
--		' Crew: ' + convert(varchar,isnull(i.Crew,'')) +
--		' PostDate: ' + convert(varchar,isnull(i.PostDate,'')) +  
--		' SheetNum: ' + convert(varchar,isnull(i.SheetNum,'')),
--		i.PRCo, 'C','Phase1Units',
--		convert(varchar,d.Phase1Units), Convert(varchar,i.Phase1Units),
--		getdate(), SUSER_SNAME()
--		from inserted i join deleted d on 
--		i.PRCo = d.PRCo and i.Crew = d.Crew and i.PostDate = d.PostDate and 
--		i.SheetNum = d.SheetNum 
--		where isnull(i.Phase1Units,0) <> isnull(d.Phase1Units,0) 
--
--	if update(Phase1CostType)
--		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
--		select 'bPRRH', 'PRCo: ' + convert(char(3),isnull(i.PRCo,'')) + 
--		' Crew: ' + convert(varchar,isnull(i.Crew,'')) +
--		' PostDate: ' + convert(varchar,isnull(i.PostDate,'')) +  
--		' SheetNum: ' + convert(varchar,isnull(i.SheetNum,'')),
--		i.PRCo, 'C','Phase1CostType',
--		convert(varchar,d.Phase1CostType), Convert(varchar,i.Phase1CostType),
--		getdate(), SUSER_SNAME()
--		from inserted i join deleted d on 
--		i.PRCo = d.PRCo and i.Crew = d.Crew and i.PostDate = d.PostDate and 
--		i.SheetNum = d.SheetNum 
--		where isnull(i.Phase1CostType,0) <> isnull(d.Phase1CostType,0) 
--
--	if update(Phase2)
--		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
--		select 'bPRRH', 'PRCo: ' + convert(char(3),isnull(i.PRCo,'')) + 
--		' Crew: ' + convert(varchar,isnull(i.Crew,'')) +
--		' PostDate: ' + convert(varchar,isnull(i.PostDate,'')) +  
--		' SheetNum: ' + convert(varchar,isnull(i.SheetNum,'')),
--		i.PRCo, 'C','Phase2',
--		convert(varchar,d.Phase2), Convert(varchar,i.Phase2),
--		getdate(), SUSER_SNAME()
--		from inserted i join deleted d on 
--		i.PRCo = d.PRCo and i.Crew = d.Crew and i.PostDate = d.PostDate and 
--		i.SheetNum = d.SheetNum 
--		where isnull(i.Phase2,'') <> isnull(d.Phase2,'') 
--
--	if update(Phase2Units)
--		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
--		select 'bPRRH', 'PRCo: ' + convert(char(3),isnull(i.PRCo,'')) + 
--		' Crew: ' + convert(varchar,isnull(i.Crew,'')) +
--		' PostDate: ' + convert(varchar,isnull(i.PostDate,'')) +  
--		' SheetNum: ' + convert(varchar,isnull(i.SheetNum,'')),
--		i.PRCo, 'C','Phase2Units',
--		convert(varchar,d.Phase2Units), Convert(varchar,i.Phase2Units),
--		getdate(), SUSER_SNAME()
--		from inserted i join deleted d on 
--		i.PRCo = d.PRCo and i.Crew = d.Crew and i.PostDate = d.PostDate and 
--		i.SheetNum = d.SheetNum 
--		where isnull(i.Phase2Units,0) <> isnull(d.Phase2Units,0) 
--
--	if update(Phase2CostType)
--		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
--		select 'bPRRH', 'PRCo: ' + convert(char(3),isnull(i.PRCo,'')) + 
--		' Crew: ' + convert(varchar,isnull(i.Crew,'')) +
--		' PostDate: ' + convert(varchar,isnull(i.PostDate,'')) +  
--		' SheetNum: ' + convert(varchar,isnull(i.SheetNum,'')),
--		i.PRCo, 'C','Phase2CostType',
--		convert(varchar,d.Phase2CostType), Convert(varchar,i.Phase2CostType),
--		getdate(), SUSER_SNAME()
--		from inserted i join deleted d on 
--		i.PRCo = d.PRCo and i.Crew = d.Crew and i.PostDate = d.PostDate and 
--		i.SheetNum = d.SheetNum 
--		where isnull(i.Phase2CostType,0) <> isnull(d.Phase2CostType,0) 
--
--
--	if update(Phase3)
--		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
--		select 'bPRRH', 'PRCo: ' + convert(char(3),isnull(i.PRCo,'')) + 
--		' Crew: ' + convert(varchar,isnull(i.Crew,'')) +
--		' PostDate: ' + convert(varchar,isnull(i.PostDate,'')) +  
--		' SheetNum: ' + convert(varchar,isnull(i.SheetNum,'')),
--		i.PRCo, 'C','Phase3',
--		convert(varchar,d.Phase3), Convert(varchar,i.Phase3),
--		getdate(), SUSER_SNAME()
--		from inserted i join deleted d on 
--		i.PRCo = d.PRCo and i.Crew = d.Crew and i.PostDate = d.PostDate and 
--		i.SheetNum = d.SheetNum 
--		where isnull(i.Phase3,'') <> isnull(d.Phase3,'') 
--
--	if update(Phase3Units)
--		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
--		select 'bPRRH', 'PRCo: ' + convert(char(3),isnull(i.PRCo,'')) + 
--		' Crew: ' + convert(varchar,isnull(i.Crew,'')) +
--		' PostDate: ' + convert(varchar,isnull(i.PostDate,'')) +  
--		' SheetNum: ' + convert(varchar,isnull(i.SheetNum,'')),
--		i.PRCo, 'C','Phase3Units',
--		convert(varchar,d.Phase3Units), Convert(varchar,i.Phase3Units),
--		getdate(), SUSER_SNAME()
--		from inserted i join deleted d on 
--		i.PRCo = d.PRCo and i.Crew = d.Crew and i.PostDate = d.PostDate and 
--		i.SheetNum = d.SheetNum 
--		where isnull(i.Phase3Units,0) <> isnull(d.Phase3Units,0) 
--
--	if update(Phase3CostType)
--		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
--		select 'bPRRH', 'PRCo: ' + convert(char(3),isnull(i.PRCo,'')) + 
--		' Crew: ' + convert(varchar,isnull(i.Crew,'')) +
--		' PostDate: ' + convert(varchar,isnull(i.PostDate,'')) +  
--		' SheetNum: ' + convert(varchar,isnull(i.SheetNum,'')),
--		i.PRCo, 'C','Phase3CostType',
--		convert(varchar,d.Phase3CostType), Convert(varchar,i.Phase3CostType),
--		getdate(), SUSER_SNAME()
--		from inserted i join deleted d on 
--		i.PRCo = d.PRCo and i.Crew = d.Crew and i.PostDate = d.PostDate and 
--		i.SheetNum = d.SheetNum 
--		where isnull(i.Phase3CostType,0) <> isnull(d.Phase3CostType,0) 
--
--
--	if update(Phase4)
--		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
--		select 'bPRRH', 'PRCo: ' + convert(char(3),isnull(i.PRCo,'')) + 
--		' Crew: ' + convert(varchar,isnull(i.Crew,'')) +
--		' PostDate: ' + convert(varchar,isnull(i.PostDate,'')) +  
--		' SheetNum: ' + convert(varchar,isnull(i.SheetNum,'')),
--		i.PRCo, 'C','Phase4',
--		convert(varchar,d.Phase4), Convert(varchar,i.Phase4),
--		getdate(), SUSER_SNAME()
--		from inserted i join deleted d on 
--		i.PRCo = d.PRCo and i.Crew = d.Crew and i.PostDate = d.PostDate and 
--		i.SheetNum = d.SheetNum 
--		where isnull(i.Phase4,'') <> isnull(d.Phase4,'') 
--
--	if update(Phase4Units)
--		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
--		select 'bPRRH', 'PRCo: ' + convert(char(3),isnull(i.PRCo,'')) + 
--		' Crew: ' + convert(varchar,isnull(i.Crew,'')) +
--		' PostDate: ' + convert(varchar,isnull(i.PostDate,'')) +  
--		' SheetNum: ' + convert(varchar,isnull(i.SheetNum,'')),
--		i.PRCo, 'C','Phase4Units',
--		convert(varchar,d.Phase4Units), Convert(varchar,i.Phase4Units),
--		getdate(), SUSER_SNAME()
--		from inserted i join deleted d on 
--		i.PRCo = d.PRCo and i.Crew = d.Crew and i.PostDate = d.PostDate and 
--		i.SheetNum = d.SheetNum 
--		where isnull(i.Phase4Units,0) <> isnull(d.Phase4Units,0) 
--
--	if update(Phase4CostType)
--		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
--		select 'bPRRH', 'PRCo: ' + convert(char(3),isnull(i.PRCo,'')) + 
--		' Crew: ' + convert(varchar,isnull(i.Crew,'')) +
--		' PostDate: ' + convert(varchar,isnull(i.PostDate,'')) +  
--		' SheetNum: ' + convert(varchar,isnull(i.SheetNum,'')),
--		i.PRCo, 'C','Phase4CostType',
--		convert(varchar,d.Phase4CostType), Convert(varchar,i.Phase4CostType),
--		getdate(), SUSER_SNAME()
--		from inserted i join deleted d on 
--		i.PRCo = d.PRCo and i.Crew = d.Crew and i.PostDate = d.PostDate and 
--		i.SheetNum = d.SheetNum 
--		where isnull(i.Phase4CostType,0) <> isnull(d.Phase4CostType,0) 
--
--
--	if update(Phase5)
--		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
--		select 'bPRRH', 'PRCo: ' + convert(char(3),isnull(i.PRCo,'')) + 
--		' Crew: ' + convert(varchar,isnull(i.Crew,'')) +
--		' PostDate: ' + convert(varchar,isnull(i.PostDate,'')) +  
--		' SheetNum: ' + convert(varchar,isnull(i.SheetNum,'')),
--		i.PRCo, 'C','Phase5',
--		convert(varchar,d.Phase5), Convert(varchar,i.Phase5),
--		getdate(), SUSER_SNAME()
--		from inserted i join deleted d on 
--		i.PRCo = d.PRCo and i.Crew = d.Crew and i.PostDate = d.PostDate and 
--		i.SheetNum = d.SheetNum 
--		where isnull(i.Phase5,'') <> isnull(d.Phase5,'') 
--
--	if update(Phase5Units)
--		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
--		select 'bPRRH', 'PRCo: ' + convert(char(3),isnull(i.PRCo,'')) + 
--		' Crew: ' + convert(varchar,isnull(i.Crew,'')) +
--		' PostDate: ' + convert(varchar,isnull(i.PostDate,'')) +  
--		' SheetNum: ' + convert(varchar,isnull(i.SheetNum,'')),
--		i.PRCo, 'C','Phase5Units',
--		convert(varchar,d.Phase5Units), Convert(varchar,i.Phase5Units),
--		getdate(), SUSER_SNAME()
--		from inserted i join deleted d on 
--		i.PRCo = d.PRCo and i.Crew = d.Crew and i.PostDate = d.PostDate and 
--		i.SheetNum = d.SheetNum 
--		where isnull(i.Phase5Units,0) <> isnull(d.Phase5Units,0) 
--
--	if update(Phase5CostType)
--		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
--		select 'bPRRH', 'PRCo: ' + convert(char(3),isnull(i.PRCo,'')) + 
--		' Crew: ' + convert(varchar,isnull(i.Crew,'')) +
--		' PostDate: ' + convert(varchar,isnull(i.PostDate,'')) +  
--		' SheetNum: ' + convert(varchar,isnull(i.SheetNum,'')),
--		i.PRCo, 'C','Phase5CostType',
--		convert(varchar,d.Phase5CostType), Convert(varchar,i.Phase5CostType),
--		getdate(), SUSER_SNAME()
--		from inserted i join deleted d on 
--		i.PRCo = d.PRCo and i.Crew = d.Crew and i.PostDate = d.PostDate and 
--		i.SheetNum = d.SheetNum 
--		where isnull(i.Phase5CostType,0) <> isnull(d.Phase5CostType,0) 
--
--	if update(Phase6)
--		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
--		select 'bPRRH', 'PRCo: ' + convert(char(3),isnull(i.PRCo,'')) + 
--		' Crew: ' + convert(varchar,isnull(i.Crew,'')) +
--		' PostDate: ' + convert(varchar,isnull(i.PostDate,'')) +  
--		' SheetNum: ' + convert(varchar,isnull(i.SheetNum,'')),
--		i.PRCo, 'C','Phase6',
--		convert(varchar,d.Phase6), Convert(varchar,i.Phase6),
--		getdate(), SUSER_SNAME()
--		from inserted i join deleted d on 
--		i.PRCo = d.PRCo and i.Crew = d.Crew and i.PostDate = d.PostDate and 
--		i.SheetNum = d.SheetNum 
--		where isnull(i.Phase6,'') <> isnull(d.Phase6,'') 
--
--	if update(Phase6Units)
--		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
--		select 'bPRRH', 'PRCo: ' + convert(char(3),isnull(i.PRCo,'')) + 
--		' Crew: ' + convert(varchar,isnull(i.Crew,'')) +
--		' PostDate: ' + convert(varchar,isnull(i.PostDate,'')) +  
--		' SheetNum: ' + convert(varchar,isnull(i.SheetNum,'')),
--		i.PRCo, 'C','Phase6Units',
--		convert(varchar,d.Phase6Units), Convert(varchar,i.Phase6Units),
--		getdate(), SUSER_SNAME()
--		from inserted i join deleted d on 
--		i.PRCo = d.PRCo and i.Crew = d.Crew and i.PostDate = d.PostDate and 
--		i.SheetNum = d.SheetNum 
--		where isnull(i.Phase6Units,0) <> isnull(d.Phase6Units,0) 
--
--	if update(Phase6CostType)
--		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
--		select 'bPRRH', 'PRCo: ' + convert(char(3),isnull(i.PRCo,'')) + 
--		' Crew: ' + convert(varchar,isnull(i.Crew,'')) +
--		' PostDate: ' + convert(varchar,isnull(i.PostDate,'')) +  
--		' SheetNum: ' + convert(varchar,isnull(i.SheetNum,'')),
--		i.PRCo, 'C','Phase6CostType',
--		convert(varchar,d.Phase6CostType), Convert(varchar,i.Phase6CostType),
--		getdate(), SUSER_SNAME()
--		from inserted i join deleted d on 
--		i.PRCo = d.PRCo and i.Crew = d.Crew and i.PostDate = d.PostDate and 
--		i.SheetNum = d.SheetNum 
--		where isnull(i.Phase6CostType,0) <> isnull(d.Phase6CostType,0) 
--
--	if update(Phase7)
--		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
--		select 'bPRRH', 'PRCo: ' + convert(char(3),isnull(i.PRCo,'')) + 
--		' Crew: ' + convert(varchar,isnull(i.Crew,'')) +
--		' PostDate: ' + convert(varchar,isnull(i.PostDate,'')) +  
--		' SheetNum: ' + convert(varchar,isnull(i.SheetNum,'')),
--		i.PRCo, 'C','Phase7',
--		convert(varchar,d.Phase7), Convert(varchar,i.Phase7),
--		getdate(), SUSER_SNAME()
--		from inserted i join deleted d on 
--		i.PRCo = d.PRCo and i.Crew = d.Crew and i.PostDate = d.PostDate and 
--		i.SheetNum = d.SheetNum 
--		where isnull(i.Phase7,'') <> isnull(d.Phase7,'') 
--
--	if update(Phase7Units)
--		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
--		select 'bPRRH', 'PRCo: ' + convert(char(3),isnull(i.PRCo,'')) + 
--		' Crew: ' + convert(varchar,isnull(i.Crew,'')) +
--		' PostDate: ' + convert(varchar,isnull(i.PostDate,'')) +  
--		' SheetNum: ' + convert(varchar,isnull(i.SheetNum,'')),
--		i.PRCo, 'C','Phase7Units',
--		convert(varchar,d.Phase7Units), Convert(varchar,i.Phase7Units),
--		getdate(), SUSER_SNAME()
--		from inserted i join deleted d on 
--		i.PRCo = d.PRCo and i.Crew = d.Crew and i.PostDate = d.PostDate and 
--		i.SheetNum = d.SheetNum 
--		where isnull(i.Phase7Units,0) <> isnull(d.Phase7Units,0) 
--
--	if update(Phase7CostType)
--		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
--		select 'bPRRH', 'PRCo: ' + convert(char(3),isnull(i.PRCo,'')) + 
--		' Crew: ' + convert(varchar,isnull(i.Crew,'')) +
--		' PostDate: ' + convert(varchar,isnull(i.PostDate,'')) +  
--		' SheetNum: ' + convert(varchar,isnull(i.SheetNum,'')),
--		i.PRCo, 'C','Phase7CostType',
--		convert(varchar,d.Phase7CostType), Convert(varchar,i.Phase7CostType),
--		getdate(), SUSER_SNAME()
--		from inserted i join deleted d on 
--		i.PRCo = d.PRCo and i.Crew = d.Crew and i.PostDate = d.PostDate and 
--		i.SheetNum = d.SheetNum 
--		where isnull(i.Phase7CostType,0) <> isnull(d.Phase7CostType,0) 
--
--
--	if update(Phase8)
--		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
--		select 'bPRRH', 'PRCo: ' + convert(char(3),isnull(i.PRCo,'')) + 
--		' Crew: ' + convert(varchar(10),isnull(i.Crew,'')) +
--		' PostDate: ' + convert(varchar(11),isnull(i.PostDate,'')) +  
--		' SheetNum: ' + convert(varchar(5),isnull(i.SheetNum,'')),
--		i.PRCo, 'C','Phase8',
--		convert(varchar(20),d.Phase8), Convert(varchar(20),i.Phase8),
--		getdate(), SUSER_SNAME()
--		from inserted i join deleted d on 
--		i.PRCo = d.PRCo and i.Crew = d.Crew and i.PostDate = d.PostDate and 
--		i.SheetNum = d.SheetNum 
--		where isnull(i.Phase8,'') <> isnull(d.Phase8,'') 
--
--	if update(Phase8Units)
--		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
--		select 'bPRRH', 'PRCo: ' + convert(char(3),isnull(i.PRCo,'')) + 
--		' Crew: ' + convert(varchar,isnull(i.Crew,'')) +
--		' PostDate: ' + convert(varchar,isnull(i.PostDate,'')) +  
--		' SheetNum: ' + convert(varchar,isnull(i.SheetNum,'')),
--		i.PRCo, 'C','Phase8Units',
--		convert(varchar,d.Phase8Units), Convert(varchar,i.Phase8Units),
--		getdate(), SUSER_SNAME()
--		from inserted i join deleted d on 
--		i.PRCo = d.PRCo and i.Crew = d.Crew and i.PostDate = d.PostDate and 
--		i.SheetNum = d.SheetNum 
--		where isnull(i.Phase8Units,0) <> isnull(d.Phase8Units,0) 
--
--	if update(Phase8CostType)
--		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
--		select 'bPRRH', 'PRCo: ' + convert(char(3),isnull(i.PRCo,'')) + 
--		' Crew: ' + convert(varchar,isnull(i.Crew,'')) +
--		' PostDate: ' + convert(varchar,isnull(i.PostDate,'')) +  
--		' SheetNum: ' + convert(varchar,isnull(i.SheetNum,'')),
--		i.PRCo, 'C','Phase8CostType',
--		convert(varchar,d.Phase8CostType), Convert(varchar,i.Phase8CostType),
--		getdate(), SUSER_SNAME()
--		from inserted i join deleted d on 
--		i.PRCo = d.PRCo and i.Crew = d.Crew and i.PostDate = d.PostDate and 
--		i.SheetNum = d.SheetNum 
--		where isnull(i.Phase8CostType,0) <> isnull(d.Phase8CostType,0) 
--
--	if update(CreatedOn)
--		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
--		select 'bPRRH', 'PRCo: ' + convert(char(3),isnull(i.PRCo,'')) + 
--		' Crew: ' + convert(varchar,isnull(i.Crew,'')) +
--		' PostDate: ' + convert(varchar,isnull(i.PostDate,'')) +  
--		' SheetNum: ' + convert(varchar,isnull(i.SheetNum,'')),
--		i.PRCo, 'C','CreatedOn',
--		convert(varchar,d.CreatedOn), Convert(varchar,i.CreatedOn),
--		getdate(), SUSER_SNAME()
--		from inserted i join deleted d on 
--		i.PRCo = d.PRCo and i.Crew = d.Crew and i.PostDate = d.PostDate and 
--		i.SheetNum = d.SheetNum 
--		where isnull(i.CreatedOn,'') <> isnull(d.CreatedOn,'') 
--
--
--	if update(CreatedBy)
--		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
--		select 'bPRRH', 'PRCo: ' + convert(char(3),isnull(i.PRCo,'')) + 
--		' Crew: ' + convert(varchar,isnull(i.Crew,'')) +
--		' PostDate: ' + convert(varchar,isnull(i.PostDate,'')) +  
--		' SheetNum: ' + convert(varchar,isnull(i.SheetNum,'')),
--		i.PRCo, 'C','CreatedBy',
--		convert(varchar,d.CreatedOn), Convert(varchar,i.CreatedOn),
--		getdate(), SUSER_SNAME()
--		from inserted i join deleted d on 
--		i.PRCo = d.PRCo and i.Crew = d.Crew and i.PostDate = d.PostDate and 
--		i.SheetNum = d.SheetNum 
--		where isnull(i.CreatedBy,'') <> isnull(d.CreatedBy,'') 
--
--
--	if update([Status])
--		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
--		select 'bPRRH', 'PRCo: ' + convert(char(3),isnull(i.PRCo,'')) + 
--		' Crew: ' + convert(varchar,isnull(i.Crew,'')) +
--		' PostDate: ' + convert(varchar,isnull(i.PostDate,'')) +  
--		' SheetNum: ' + convert(varchar,isnull(i.SheetNum,'')),
--		i.PRCo, 'C','Status',
--		convert(varchar,d.CreatedOn), Convert(varchar,i.CreatedOn),
--		getdate(), SUSER_SNAME()
--		from inserted i join deleted d on 
--		i.PRCo = d.PRCo and i.Crew = d.Crew and i.PostDate = d.PostDate and 
--		i.SheetNum = d.SheetNum 
--		where isnull(i.[Status],'') <> isnull(d.[Status],'') 
--
--
--	if update(SendSeq)
--		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
--		select 'bPRRH', 'PRCo: ' + convert(char(3),isnull(i.PRCo,'')) + 
--		' Crew: ' + convert(varchar,isnull(i.Crew,'')) +
--		' PostDate: ' + convert(varchar,isnull(i.PostDate,'')) +  
--		' SheetNum: ' + convert(varchar,isnull(i.SheetNum,'')),
--		i.PRCo, 'C','SendSeq',
--		convert(varchar,d.CreatedOn), Convert(varchar,i.CreatedOn),
--		getdate(), SUSER_SNAME()
--		from inserted i join deleted d on 
--		i.PRCo = d.PRCo and i.Crew = d.Crew and i.PostDate = d.PostDate and 
--		i.SheetNum = d.SheetNum 
--		where isnull(i.SendSeq,0) <> isnull(d.SendSeq,0) 
--
--
--	if update(PRBatchMth)
--		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
--		select 'bPRRH', 'PRCo: ' + convert(char(3),isnull(i.PRCo,'')) + 
--		' Crew: ' + convert(varchar,isnull(i.Crew,'')) +
--		' PostDate: ' + convert(varchar,isnull(i.PostDate,'')) +  
--		' SheetNum: ' + convert(varchar,isnull(i.SheetNum,'')),
--		i.PRCo, 'C','PRBatchMth',
--		convert(varchar,d.CreatedOn), Convert(varchar,i.CreatedOn),
--		getdate(), SUSER_SNAME()
--		from inserted i join deleted d on 
--		i.PRCo = d.PRCo and i.Crew = d.Crew and i.PostDate = d.PostDate and 
--		i.SheetNum = d.SheetNum 
--		where isnull(i.PRBatchMth,'') <> isnull(d.PRBatchMth,'') 
--
--	if update(PRBatchId)
--		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
--		select 'bPRRH', 'PRCo: ' + convert(char(3),isnull(i.PRCo,'')) + 
--		' Crew: ' + convert(varchar,isnull(i.Crew,'')) +
--		' PostDate: ' + convert(varchar,isnull(i.PostDate,'')) +  
--		' SheetNum: ' + convert(varchar,isnull(i.SheetNum,'')),
--		i.PRCo, 'C','PRBatchId',
--		convert(varchar,d.CreatedOn), Convert(varchar,i.CreatedOn),
--		getdate(), SUSER_SNAME()
--		from inserted i join deleted d on 
--		i.PRCo = d.PRCo and i.Crew = d.Crew and i.PostDate = d.PostDate and 
--		i.SheetNum = d.SheetNum 
--		where isnull(i.PRBatchId,0) <> isnull(d.PRBatchId,0) 
--

--End Test Auditing Code

	return

error:
	
	if @opencurs = 1
	begin
		close cursPRRH
		deallocate cursPRRH
	end

	if @openPRRHPhase = 1
	begin
		close cursPRRHPhase
		deallocate cursPRRHPhase
	end

	select @errmsg = isnull(@errmsg,'') + ' - cannot update PR Crew Timesheet Employee Hours!'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction


GO
