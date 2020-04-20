SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMMeetingMinutesCopy    Script Date: 8/28/99 9:35:15 AM ******/
CREATE   proc [dbo].[bspPMMeetingMinutesCopy]
/*************************************
 * CREATED BY:	kb 11/18/98
 * MODIFIED By: kb 12/15/98
 *              mh 03/21/2000 - Issue 6466, Items being copied need to be renumbered starting at 1 at the target.  Also
 *								  renumbering Item Detail lines at the target too.    
 *				GF 04/25/2002 - Fix for meeting minute attendees, now has seq number.
 *				GF 11/13/2002 - Issue #19310 - when coping attendees, 'Present' flag should be unchecked.
 *				GF 03/12/2003 issue #20670 - copy meeting minutes user memos PMMM, PMMI, PMML, and PMMD
 *				GF 05/12/2004 - issue #24580 - changed to use tables instead of views. Internal SQL error when job security on.
 *				GF 10/18/2007 - issue #125880 - need to copy PMML.Notes
 *				GF 03/24/2009 - issue #132867 ansi null problem with case statement.
				AR 11/29/10 - #142278 - removing old style joins replace with ANSI correct form

 *
 *	
 *
 * Pass:
 *   PMCO          PM Company 
 *   Project       Project 
 *	Meeting	
 *	MeetingType
 *	MinuteType
 *	Date
 *
 * Returns:
 *      MSG if Error
 * Success returns:
 *	0 on Success, 1 on ERROR
 *
 * Error returns:
 *	1 and error message
**************************************/
(@pmco bCompany, @project bJob, @meetingtype varchar(10), @meetingdate bDate,
 @meeting int, @minutestype tinyint, @destmeeting int, @destminutestype tinyint, 
 @copyattendees bYN, @copyitems bYN, @beginitem int, @enditem int, 
 @copyfinstatus bYN, @copydetfinstatus bYN, @destmeetingdate bDate, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @count int, @vendorgroup bGroup,  @currentitem tinyint, @itemseq int,
  		@seq tinyint, @firstseq bTrans, @prevmeeting tinyint, @originalitem varchar(10),
  		@srcPMCo bCompany, @srcProject bJob, @srcMeetingType varchar(10), @srcMeeting int, 
      	@srcMinuteType tinyint, @srcOrigItem varchar(10), @srcMinutes varchar(8000), @srcVendorGroup bGroup,
      	@srcInitFirm bFirm, @srcInit int, @srcResponsFirm bVendor, @srcRespPers int, @srcInitDate bDate,
      	@srcDueDate bDate, @srcFinDate bDate, @srcStatus bStatus, @srcIssue bIssue, @trgItem int, 
  		@srcDesc varchar(255), @trgItemLine int, @srcItem int, @openpmmicursor tinyint, @openpmmlcursor tinyint,
  		@pmmmud_flag bYN, @pmmiud_flag bYN, @pmmlud_flag bYN, @pmmdud_flag bYN, @joins varchar(2000),
  		@where varchar(2000), @insert varchar(2000), @sql varchar(4000), @select varchar(2000),
  		@srcitemline tinyint, @srcpmmi_description bItemDesc, @pmmlnotes varchar(max)
  
  select @rcode = 0, @openpmmicursor = 0, @openpmmlcursor = 0, @pmmmud_flag = 'N', @pmmiud_flag = 'N',
  	   @pmmlud_flag = 'N', @pmmdud_flag = 'N'
  
  if @pmco is null 
  	begin
  	select @msg = 'Missing PM Company!', @rcode = 1
  	goto bspexit
  	end
  if @project is null 
  	begin
  	select @msg = 'Missing Project!', @rcode = 1
  	goto bspexit
  	end
  if @meetingdate is null 
  	begin
  	select @msg = 'Missing Meeting Date!', @rcode = 1
  	goto bspexit
  	end
  if @meeting is null
  	begin
  	select @msg = 'Missing Meeting!', @rcode = 1
  	goto bspexit
  	end
  	
  if @copyitems = 'N' select @beginitem = null, @enditem = null
  
  -- if we are copying the items but have not set the beginning item set it to zero to get the first one
  -- if the ending item is not set then set it to the last number for the range
  if @copyitems = 'Y'
  	begin
  	select @beginitem = isnull(@beginitem,0)
  	select @enditem = isnull(@enditem,999999)
  	end
  	
  -- get the vendorgroup for this pm company
  select @vendorgroup=h.VendorGroup from bHQCO h with (nolock) join bPMCO p with (nolock) on h.HQCo=p.APCo where p.PMCo=@pmco
  
  -- set the user memo flags for the tables that have user memos
  if exists(select name from syscolumns where name like 'ud%' and id = object_id('dbo.bPMMM'))
  	select @pmmmud_flag = 'Y'
  if exists(select name from syscolumns where name like 'ud%' and id = object_id('dbo.bPMMI'))
  	select @pmmiud_flag = 'Y'
  if exists(select name from syscolumns where name like 'ud%' and id = object_id('dbo.bPMML'))
  	select @pmmlud_flag = 'Y'
  if exists(select name from syscolumns where name like 'ud%' and id = object_id('dbo.bPMMD'))
  	select @pmmdud_flag = 'Y'
  
  
  -- skip inserting of the meeting if it already exists but you can still copy the items/detail/attendees
  if exists(select 1 from bPMMM with (nolock) where PMCo = @pmco and Project = @project and MeetingType = @meetingtype
  				and Meeting=@destmeeting and MinutesType = @destminutestype)
  	begin
  	-- if the meeting exists and we aren't copying items or attendees then really there is nothing to 
  	-- be done, probably useful to let the user know this
  	if @copyitems = 'N' and @copyattendees = 'N'
  		begin
  		select @msg = 'Meeting already exists.', @rcode = 1
  		goto bspexit
  		end
  
  	if @copyitems = 'Y'
  		begin
  		if exists(select 1 from bPMMI with (nolock) where PMCo = @pmco and Project = @project and 
  		  	MeetingType = @meetingtype and Meeting = @destmeeting and MinutesType = @destminutestype
  		  	and Item >= @beginitem and Item <= @enditem)
  			begin
  			select @msg = 'Items to be copied already exist for this meeting.', @rcode = 1
  			goto bspexit
  			end
  
  	--issue 6466...part 1...need to rework how insert is done.  In destination meeting, items need to be 
  	--renumbered starting at 1.  Since btPMMIu will not allow a change to item renumber must be
  	--done prior to insert.  Using a cursor to do a line by line insert into PMMI.
      declare curMeetingMinutesCopy cursor LOCAL FAST_FORWARD for
      select @pmco, @project, @meetingtype, @destmeeting, @destminutestype, Item,  
			case when OriginalItem is null then convert(varchar(6),Meeting) + '.' + convert(varchar(3),Item) else OriginalItem end,
  			 Minutes, VendorGroup, InitFirm, Initiator, ResponsibleFirm, ResponsiblePerson, 
  			InitDate, DueDate, FinDate, bPMMI.Status, Issue, bPMMI.Description
  	from bPMMI with (nolock) left join bPMSC with (nolock) on bPMSC.Status = bPMMI.Status  
      where PMCo = @pmco and Project = @project and MeetingType = @meetingtype 
  	and Meeting = @meeting and MinutesType = @minutestype and 
  	(@copyfinstatus = 'Y' or bPMMI.Status is null or (bPMSC.CodeType <> 'F' and @copyfinstatus = 'N'))
  	and Item>=@beginitem and Item<=@enditem
  
      Open curMeetingMinutesCopy
  	set @openpmmicursor = 1
  
      fetch next from curMeetingMinutesCopy into 
  		@srcPMCo, @srcProject, @srcMeetingType, @srcMeeting, @srcMinuteType, @srcItem, @srcOrigItem, 
          @srcMinutes, @srcVendorGroup, @srcInitFirm, @srcInit, @srcResponsFirm, @srcRespPers, @srcInitDate,
          @srcDueDate, @srcFinDate, @srcStatus, @srcIssue, @srcpmmi_description
  
      select @trgItem = 1
  
      while @@fetch_status = 0
      	begin
          insert bPMMI (PMCo, Project, MeetingType, Meeting, MinutesType, Item, 
          		OriginalItem, Minutes, VendorGroup, InitFirm, Initiator, ResponsibleFirm, 
              	ResponsiblePerson, InitDate, DueDate, FinDate, Status, Issue, Description)    
  		values (@srcPMCo, @srcProject, @srcMeetingType, @srcMeeting, @srcMinuteType, @trgItem, 
                @srcOrigItem, @srcMinutes, @srcVendorGroup, @srcInitFirm, @srcInit, @srcResponsFirm, 
                @srcRespPers, @srcInitDate, @srcDueDate, @srcFinDate, @srcStatus, @srcIssue,
				@srcpmmi_description)
  		if @@error <> 0
  			begin
              select @msg = 'Error occurred while inserting items.  Terminating copy.', @rcode = 1
              goto bspexit
              end
  
  		-- now do user memos if needed
  		if @pmmiud_flag = 'Y'
  			begin
  			-- build joins and where clause
  			select @joins = ' from PMMI join PMMI z on z.PMCo = ' + convert(varchar(3),@pmco) 
  					+ ' and z.Project = ' + CHAR(39) + @project + CHAR(39) 
  					+ ' and z.MeetingType = ' + CHAR(39) + @meetingtype + CHAR(39)
  					+ ' and z.Meeting = ' + convert(varchar(10), @meeting)
  					+ ' and z.MinutesType = ' + convert(varchar(3), @minutestype)
  					+ ' and z.Item = ' + convert(varchar(3), @srcItem)
  			select @where = ' where PMMI.PMCo = ' + convert(varchar(3),@pmco) 
  					+ ' and PMMI.Project = ' + CHAR(39) + @project + CHAR(39)
  					+ ' and PMMI.MeetingType = ' + CHAR(39) + @meetingtype + CHAR(39)
  					+ ' and PMMI.Meeting = ' + convert(varchar(10), @destmeeting)
  					+ ' and PMMI.MinutesType = ' + convert(varchar(3), @destminutestype)
  					+ ' and PMMI.Item = ' + convert(varchar(3), @trgItem)
  
  			-- execute user memo update
  			exec @rcode = dbo.bspPMProjectCopyUserMemos 'PMMI', @joins, @where, @msg output
  			end
  
  		---- check for Item detail....if so need to copy that over.
		select @count = (select count(PMCo) from bPMML with (nolock) 
		where PMCo = @pmco and Project = @project and MeetingType = @meetingtype and Item = @srcItem)
  		if @count > 0
  			begin
			declare curMeetingDetailCopy cursor LOCAL FAST_FORWARD for
  			select @pmco, @project, @meetingtype, @destmeeting, @destminutestype, Item, ItemLine, bPMML.Description, 
  					VendorGroup, ResponsibleFirm, ResponsiblePerson, InitDate, DueDate, FinDate, bPMML.Status, bPMML.Notes
			from bPMML with (nolock) left join bPMSC with (nolock) on bPMSC.Status = bPMML.Status  
  			where PMCo = @pmco and Project = @project and MeetingType = @meetingtype 
  		    and Meeting = @meeting and MinutesType = @minutestype and (@copyfinstatus = 'Y'
  			or bPMML.Status is null or (bPMSC.CodeType <>'F' and @copyfinstatus = 'N')) and Item = @srcItem
  
			Open curMeetingDetailCopy
  			set @openpmmlcursor = 1
  
			fetch next from curMeetingDetailCopy into
				@srcPMCo, @srcProject, @srcMeetingType, @srcMeeting, @srcMinuteType, @srcItem, @srcitemline,
				@srcDesc, @srcVendorGroup, @srcResponsFirm, @srcRespPers, @srcInitDate, @srcDueDate,
				@srcFinDate, @srcStatus, @pmmlnotes
  
  			select @trgItemLine = 1
  
  			while @@fetch_status = 0
              	begin
  		        insert bPMML (PMCo, Project, MeetingType, Meeting, MinutesType, Item, 
                         ItemLine, Description, VendorGroup, ResponsibleFirm, ResponsiblePerson, 
                         InitDate, DueDate, FinDate, Status, Notes)
                  values (@srcPMCo, @srcProject, @srcMeetingType, @srcMeeting, @srcMinuteType, 
                          @trgItem, @trgItemLine, @srcDesc, @srcVendorGroup, @srcResponsFirm, @srcRespPers, 
                          @srcInitDate, @srcDueDate, @srcFinDate, @srcStatus, @pmmlnotes)
  				if @@error <> 0
                  	begin
                      select @msg = 'Error during Meeting Item copy.  Terminating copy.', @rcode = 1
                      goto bspexit
                      end
  
  				-- now do user memos if needed
  				if @pmmlud_flag = 'Y'
  					begin
  					-- build joins and where clause
  					select @joins = ' from PMML join PMML z on z.PMCo = ' + convert(varchar(3),@pmco) 
  							+ ' and z.Project = ' + CHAR(39) + @project + CHAR(39) 
  							+ ' and z.MeetingType = ' + CHAR(39) + @meetingtype + CHAR(39)
  							+ ' and z.Meeting = ' + convert(varchar(10), @meeting)
  							+ ' and z.MinutesType = ' + convert(varchar(3), @minutestype)
  							+ ' and z.Item = ' + convert(varchar(3), @srcItem)
  							+ ' and z.ItemLine = ' + convert(varchar(3), @srcitemline)
  					select @where = ' where PMML.PMCo = ' + convert(varchar(3),@pmco) 
  							+ ' and PMML.Project = ' + CHAR(39) + @project + CHAR(39)
  							+ ' and PMML.MeetingType = ' + CHAR(39) + @meetingtype + CHAR(39)
  							+ ' and PMML.Meeting = ' + convert(varchar(10), @destmeeting)
  							+ ' and PMML.MinutesType = ' + convert(varchar(3), @destminutestype)
  							+ ' and PMML.Item = ' + convert(varchar(3), @trgItem)
  							+ ' and PMML.ItemLine = ' + convert(varchar(3), @trgItemLine)
  					-- execute user memo update
  					exec @rcode = dbo.bspPMProjectCopyUserMemos 'PMML', @joins, @where, @msg output
  					end
  
  				fetch next from curMeetingDetailCopy into
                    	@srcPMCo, @srcProject, @srcMeetingType, @srcMeeting, @srcMinuteType, @srcItem,
						@srcitemline, @srcDesc, @srcVendorGroup, @srcResponsFirm, @srcRespPers, @srcInitDate,
						@srcDueDate, @srcFinDate, @srcStatus, @pmmlnotes
  				select @trgItemLine = @trgItemLine + 1
				end
  
  			close curMeetingDetailCopy
			deallocate curMeetingDetailCopy
  			set @openpmmlcursor = 0
			set @trgItemLine = 1
  
  		--end insert item detail
          end
  
  		--end detail insert          
          fetch next from curMeetingMinutesCopy into 
                @srcPMCo, @srcProject, @srcMeetingType, @srcMeeting, @srcMinuteType, @srcItem, @srcOrigItem, 
                @srcMinutes, @srcVendorGroup, @srcInitFirm, @srcInit, @srcResponsFirm, @srcRespPers, @srcInitDate,
                @srcDueDate, @srcFinDate, @srcStatus, @srcIssue, @srcpmmi_description
  
  		select @trgItem = @trgItem + 1
  		end
  
  
          close curMeetingMinutesCopy
          deallocate curMeetingMinutesCopy
  		set @openpmmicursor = 0
  	end
  
  
  	if @copyattendees = 'Y' 
  		begin
  		if @pmmdud_flag = 'N'
  			begin
  			--#142278
			 IF EXISTS ( SELECT 1
						 FROM   dbo.bPMMD x 
								JOIN dbo.bPMMD z ON x.PMCo = z.PMCo
													AND x.Project = z.Project
													AND x.MeetingType = z.MeetingType
													AND x.Meeting = z.Meeting
													AND x.MinutesType = z.MinutesType
													AND x.VendorGroup = z.VendorGroup
													AND x.FirmNumber = z.FirmNumber
													AND x.ContactCode = z.ContactCode
						 WHERE  x.PMCo = @pmco
								AND x.Project = @project
								AND x.MeetingType = @meetingtype
								AND x.Meeting = @destmeeting
								AND x.MinutesType = @destminutestype ) 
				BEGIN
					INSERT  bPMMD
							( PMCo,
							  Project,
							  MeetingType,
							  Meeting,
							  MinutesType,
							  Seq,
							  VendorGroup,
							  FirmNumber,
							  ContactCode,
							  PresentYN
							)
							SELECT  @pmco,
									@project,
									@meetingtype,
									@destmeeting,
									@destminutestype,
									ISNULL(MAX(Seq), 0) + 1,
									VendorGroup,
									FirmNumber,
									ContactCode,
									'N'
							FROM    bPMMD WITH ( NOLOCK )
							WHERE   PMCo = @pmco
									AND Project = @project
									AND MeetingType = @meetingtype
									AND Meeting = @meeting
									AND MinutesType = @minutestype
							GROUP BY VendorGroup,
									FirmNumber,
									ContactCode,
									PresentYN
				END
  			end
  		else
  			begin
  			-- insert meeting mintue attendees with user memos
  			select @insert = null, @select = null
  			exec @rcode = dbo.bspPMProjectCopyUDBuild 'PMMD', 'b', @insert output, @select output, @msg output
  
  			-- create insert statement
  			select @sql = 'insert into PMMD (PMCo, Project, MeetingType, Meeting, MinutesType, Seq, VendorGroup, FirmNumber, ContactCode, PresentYN'
  			-- add on PMMD user memos
  			select @sql = @sql + @insert
  
  			-- add on select statement
  			select @sql = @sql + ') select ' + convert(varchar(3),@pmco) + ', ' + CHAR(39) + @project + CHAR(39) + ', '
  					+ CHAR(39) + @meetingtype + CHAR(39) + ', ' + convert(varchar(10), @destmeeting) + ', '
  					+ convert(varchar(3), @destminutestype) + ', ' + 'isnull(max(b.Seq),0) + 1' + ', '
  					+ 'b.VendorGroup, b.FirmNumber, b.ContactCode, ' + CHAR(39) + 'N' + CHAR(39)
  			-- add on PMMD user memos
  			select @sql = @sql + @select
  
  			-- add on PMDD where clause
  			select @sql = @sql + ' from PMMD where b.PMCo = ' + convert(varchar(3),@pmco) 
  					   + ' and b.Project = ' + CHAR(39) + @project + CHAR(39)
  					   + ' and b.MeetingType = ' + CHAR(39) + @meetingtype + CHAR(39)
  					   + ' and b.Meeting = ' + convert(varchar(10), @meeting)
  					   + ' and b.MinutesType = ' + convert(varchar(3), @minutestype)
  					   + ' Group By b.VendorGroup, b.FirmNumber, b.ContactCode, b.PresentYN' + @select
  
  			-- execute query statement
  			exec (@sql)
  			end
  		end
  	end
  else
  	begin
  	insert bPMMM(PMCo, Project, MeetingType, MeetingDate, Meeting, MinutesType, MeetingTime, 
  		Location, Subject, VendorGroup, FirmNumber, Preparer, NextDate, NextTime, NextLocation, Notes)
  	select @pmco, @project, @meetingtype,
		case when @destmeetingdate is null then @meetingdate else @destmeetingdate end,
		@destmeeting, @destminutestype, 
  		MeetingTime, Location, Subject, VendorGroup, FirmNumber, Preparer, NextDate, 
  		NextTime, NextLocation, Notes from bPMMM where PMCo = @pmco and Project = @project
  		and MeetingType = @meetingtype and Meeting = @meeting and MinutesType = @minutestype
  	if @@rowcount <> 0 and @pmmmud_flag = 'Y'
  		begin
  		-- build joins and where clause
  		select @joins = ' from PMMM join PMMM z on z.PMCo = ' + convert(varchar(3),@pmco) 
  						+ ' and z.Project = ' + CHAR(39) + @project + CHAR(39) 
  						+ ' and z.MeetingType = ' + CHAR(39) + @meetingtype + CHAR(39)
  						+ ' and z.Meeting = ' + convert(varchar(10), @meeting)
  						+ ' and z.MinutesType = ' + convert(varchar(3), @minutestype)
  		select @where = ' where PMMM.PMCo = ' + convert(varchar(3),@pmco) 
  						+ ' and PMMM.Project = ' + CHAR(39) + @project + CHAR(39)
  						+ ' and PMMM.MeetingType = ' + CHAR(39) + @meetingtype + CHAR(39)
  						+ ' and PMMM.Meeting = ' + convert(varchar(10), @destmeeting)
  						+ ' and PMMM.MinutesType = ' + convert(varchar(3), @destminutestype)
  		-- execute user memo update
  		exec @rcode = dbo.bspPMProjectCopyUserMemos 'PMMM', @joins, @where, @msg output
  		end
  
  	if @copyitems='Y'
  		begin
          declare curMeetingMinutesCopy cursor LOCAL FAST_FORWARD for
          select @pmco, @project, @meetingtype, @destmeeting, @destminutestype, Item,  
				case when OriginalItem is null then convert(varchar(6),Meeting) + '.' + convert(varchar(3),Item) else OriginalItem end,
				Minutes, VendorGroup, InitFirm, Initiator, ResponsibleFirm, ResponsiblePerson, 
  			    InitDate, DueDate, FinDate, bPMMI.Status, Issue, bPMMI.Description
  		from bPMMI with (nolock) left join bPMSC with (nolock) on bPMSC.Status = bPMMI.Status  
          where PMCo = @pmco and Project = @project and MeetingType = @meetingtype 
  		and Meeting = @meeting and MinutesType = @minutestype and 
  		(@copyfinstatus = 'Y' or bPMMI.Status is null or (bPMSC.CodeType <> 'F'
  		and @copyfinstatus = 'N'))and Item>=@beginitem and Item<=@enditem
  
          Open curMeetingMinutesCopy
  		set @openpmmicursor = 1
  
          fetch next from curMeetingMinutesCopy into 
  			@srcPMCo, @srcProject, @srcMeetingType, @srcMeeting, @srcMinuteType, @srcItem, @srcOrigItem, 
              @srcMinutes, @srcVendorGroup, @srcInitFirm, @srcInit, @srcResponsFirm, @srcRespPers, @srcInitDate,
              @srcDueDate, @srcFinDate, @srcStatus, @srcIssue, @srcpmmi_description
  
  		select @trgItem = 1
  
  		while @@fetch_status = 0
  			begin
              insert bPMMI (PMCo, Project, MeetingType, Meeting, MinutesType, Item, 
                   OriginalItem, Minutes, VendorGroup, InitFirm, Initiator, ResponsibleFirm, 
                   ResponsiblePerson, InitDate, DueDate, FinDate, Status, Issue, Description)    
  			values (@srcPMCo, @srcProject, @srcMeetingType, @srcMeeting, @srcMinuteType, @trgItem, 
                    @srcOrigItem, @srcMinutes, @srcVendorGroup, @srcInitFirm, @srcInit, @srcResponsFirm, 
                    @srcRespPers, @srcInitDate, @srcDueDate, @srcFinDate, @srcStatus, @srcIssue,
					@srcpmmi_description)
  			if @@error <> 0
              	begin
                  select @msg = 'Error occurred while inserting items.  Terminating copy.', @rcode = 1
                  goto bspexit
                  end
  			-- now do user memos if needed
  			if @pmmiud_flag = 'Y'
  				begin
  				-- build joins and where clause
  				select @joins = ' from PMMI join PMMI z on z.PMCo = ' + convert(varchar(3),@pmco) 
  						+ ' and z.Project = ' + CHAR(39) + @project + CHAR(39) 
  						+ ' and z.MeetingType = ' + CHAR(39) + @meetingtype + CHAR(39)
  						+ ' and z.Meeting = ' + convert(varchar(10), @meeting)
  						+ ' and z.MinutesType = ' + convert(varchar(3), @minutestype)
  						+ ' and z.Item = ' + convert(varchar(3), @srcItem)
  				select @where = ' where PMMI.PMCo = ' + convert(varchar(3),@pmco) 
  						+ ' and PMMI.Project = ' + CHAR(39) + @project + CHAR(39)
  						+ ' and PMMI.MeetingType = ' + CHAR(39) + @meetingtype + CHAR(39)
  						+ ' and PMMI.Meeting = ' + convert(varchar(10), @destmeeting)
  						+ ' and PMMI.MinutesType = ' + convert(varchar(3), @destminutestype)
  						+ ' and PMMI.Item = ' + convert(varchar(3), @trgItem)
  				-- execute user memo update
  				exec @rcode = dbo.bspPMProjectCopyUserMemos 'PMMI', @joins, @where, @msg output
  				end
  
  			---- check for Item detail....if so need to copy that over.
			select @count = (select count(PMCo) from bPMML with (nolock) 
			where PMCo=@pmco and Project=@project and MeetingType=@meetingtype and Item=@srcItem)
  			if @count > 0
  				begin
				declare curMeetingDetailCopy cursor LOCAL FAST_FORWARD for
  				select @pmco, @project, @meetingtype, @destmeeting, @destminutestype, Item, ItemLine, bPMML.Description,
  						VendorGroup, ResponsibleFirm, ResponsiblePerson, InitDate, DueDate, FinDate, bPMML.Status, bPMML.Notes
				from bPMML with (nolock) left join bPMSC with (nolock) on bPMSC.Status = bPMML.Status  
				where PMCo = @pmco and Project = @project and MeetingType = @meetingtype 
  		        and Meeting = @meeting and MinutesType = @minutestype
  		        and (@copyfinstatus = 'Y' or bPMML.Status is null or (bPMSC.CodeType <> 'F' and @copyfinstatus = 'N')) and Item = @srcItem
  
  				Open curMeetingDetailCopy
  				set @openpmmlcursor = 1
  
				fetch next from curMeetingDetailCopy into
					@srcPMCo, @srcProject, @srcMeetingType, @srcMeeting, @srcMinuteType, @srcItem, @srcitemline,
					@srcDesc, @srcVendorGroup, @srcResponsFirm, @srcRespPers, @srcInitDate, @srcDueDate,
					@srcFinDate, @srcStatus, @pmmlnotes
  
                  set @trgItemLine = 1
  
                  while @@fetch_status = 0
                  	begin
  		            insert bPMML (PMCo, Project, MeetingType, Meeting, MinutesType, Item, ItemLine, Description,
  							VendorGroup, ResponsibleFirm, ResponsiblePerson, InitDate, DueDate, FinDate, Status, Notes)
					values (@srcPMCo, @srcProject, @srcMeetingType, @srcMeeting, @srcMinuteType, @trgItem, @trgItemLine,
							@srcDesc, @srcVendorGroup, @srcResponsFirm, @srcRespPers, @srcInitDate, @srcDueDate,
							@srcFinDate, @srcStatus, @pmmlnotes)
                      if @@error <> 0
                      	begin
                          select @msg = 'Error during Meeting Item copy.  Terminating copy.', @rcode = 1
                          goto bspexit
                          end
  
  				-- now do user memos if needed
  				if @pmmlud_flag = 'Y'
  					begin
  					-- build joins and where clause
  					select @joins = ' from PMML join PMML z on z.PMCo = ' + convert(varchar(3),@pmco) 
  							+ ' and z.Project = ' + CHAR(39) + @project + CHAR(39) 
  							+ ' and z.MeetingType = ' + CHAR(39) + @meetingtype + CHAR(39)
  							+ ' and z.Meeting = ' + convert(varchar(10), @meeting)
  							+ ' and z.MinutesType = ' + convert(varchar(3), @minutestype)
  							+ ' and z.Item = ' + convert(varchar(3), @srcItem)
  							+ ' and z.ItemLine = ' + convert(varchar(3), @srcitemline)
  					select @where = ' where PMML.PMCo = ' + convert(varchar(3),@pmco) 
  							+ ' and PMML.Project = ' + CHAR(39) + @project + CHAR(39)
  							+ ' and PMML.MeetingType = ' + CHAR(39) + @meetingtype + CHAR(39)
  							+ ' and PMML.Meeting = ' + convert(varchar(10), @destmeeting)
  							+ ' and PMML.MinutesType = ' + convert(varchar(3), @destminutestype)
  							+ ' and PMML.Item = ' + convert(varchar(3), @trgItem)
  							+ ' and PMML.ItemLine = ' + convert(varchar(3), @trgItemLine)
  					-- execute user memo update
  					exec @rcode = dbo.bspPMProjectCopyUserMemos 'PMML', @joins, @where, @msg output
  					end
  
  
					fetch next from curMeetingDetailCopy into
						@srcPMCo, @srcProject, @srcMeetingType, @srcMeeting, @srcMinuteType, @srcItem,
						@srcitemline, @srcDesc, @srcVendorGroup, @srcResponsFirm, @srcRespPers, @srcInitDate,
						@srcDueDate, @srcFinDate, @srcStatus, @pmmlnotes
                      select @trgItemLine = @trgItemLine + 1
                      end
  
				close curMeetingDetailCopy
				deallocate curMeetingDetailCopy
				set @openpmmlcursor = 0
				set @trgItemLine = 1
  
  				---- end insert item detail
				end
  
  			--end detail insert          
              fetch next from curMeetingMinutesCopy into 
              	@srcPMCo, @srcProject, @srcMeetingType, @srcMeeting, @srcMinuteType, @srcItem, @srcOrigItem, 
                  @srcMinutes, @srcVendorGroup, @srcInitFirm, @srcInit, @srcResponsFirm, @srcRespPers, @srcInitDate,
                  @srcDueDate, @srcFinDate, @srcStatus, @srcIssue, @srcpmmi_description
  
              select @trgItem = @trgItem + 1
              end
  
  		close curMeetingMinutesCopy
          deallocate curMeetingMinutesCopy
  		set @openpmmicursor = 0
  		end
  --	end
  
  	-- copy attendees if required
  	if @copyattendees = 'Y'
  		begin
  		if @pmmdud_flag = 'N'
  			begin
  			if exists(select 1 from bPMMD with (nolock) where PMCo=@pmco and Project=@project and MeetingType=@meetingtype
  							and Meeting = @meeting and MinutesType = @minutestype)
  			  	begin
  				insert bPMMD (PMCo, Project, MeetingType, Meeting, MinutesType, Seq,
  						VendorGroup, FirmNumber, ContactCode, PresentYN)
  				select @pmco, @project, @meetingtype, @destmeeting, @destminutestype, isnull(max(Seq),0)+1,
  						VendorGroup, FirmNumber, ContactCode, 'N'
  				from bPMMD with (nolock) where PMCo = @pmco and Project = @project and MeetingType = @meetingtype
  				and Meeting = @meeting and MinutesType = @minutestype
  				Group by VendorGroup,FirmNumber,ContactCode,PresentYN
  				end
  			end
  		else
  			begin
  			-- insert meeting mintue attendees with user memos
  			select @insert = null, @select = null
  			exec @rcode = dbo.bspPMProjectCopyUDBuild 'PMMD', 'b', @insert output, @select output, @msg output
  
  			-- create insert statement
  			select @sql = 'insert into PMMD (PMCo, Project, MeetingType, Meeting, MinutesType, Seq, VendorGroup, FirmNumber, ContactCode, PresentYN'
  			-- add on PMMD user memos
  			select @sql = @sql + @insert
  
  			-- add on select statement
  			select @sql = @sql + ') select ' + convert(varchar(3),@pmco) + ', ' + CHAR(39) + @project + CHAR(39) + ', '
  					+ CHAR(39) + @meetingtype + CHAR(39) + ', ' + convert(varchar(10), @destmeeting) + ', '
  					+ convert(varchar(3), @destminutestype) + ', ' + 'isnull(max(b.Seq),0) + 1' + ', '
  					+ 'b.VendorGroup, b.FirmNumber, b.ContactCode, ' + CHAR(39) + 'N' + CHAR(39)
  			-- add on PMMD user memos
  			select @sql = @sql + @select
  
  			-- add on PMDD where clause
  			select @sql = @sql + ' from PMMD b where b.PMCo = ' + convert(varchar(3),@pmco) 
  					   + ' and b.Project = ' + CHAR(39) + @project + CHAR(39)
  					   + ' and b.MeetingType = ' + CHAR(39) + @meetingtype + CHAR(39)
  					   + ' and b.Meeting = ' + convert(varchar(10), @meeting)
  					   + ' and b.MinutesType = ' + convert(varchar(3), @minutestype)
  					   + ' Group By b.VendorGroup, b.FirmNumber, b.ContactCode, b.PresentYN' + @select
  
  			-- execute query statement
  			exec (@sql)
  			end
  		end
  	end


bspexit:
  	if @openpmmicursor = 1
  		begin
  		close curMeetingMinutesCopy
  		deallocate curMeetingMinutesCopy
  		set @openpmmicursor = 0
  		end
  
  	if @openpmmlcursor = 1
  		begin
  		close curMeetingDetailCopy
  		deallocate curMeetingDetailCopy
  		set @openpmmlcursor = 0
  		end
  
  	return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspPMMeetingMinutesCopy] TO [public]
GO
