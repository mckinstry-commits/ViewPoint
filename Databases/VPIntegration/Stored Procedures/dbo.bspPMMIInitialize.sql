SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMMIInitialize    Script Date: 8/28/99 9:35:15 AM ******/
   CREATE  proc [dbo].[bspPMMIInitialize]
   /*************************************
   * Created By:	CJW 4/8/98
   * Modified By:	kb 11/18/98
   *				GF 11/04/2004 - issue #25825 changed item from tinyint to integer
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
    @copyfinstatus bYN, @copydetfinstatus bYN, @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int, @vendorgroup bGroup
   
   set @rcode = 0
   
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
   -- -- -- if we are copying the items but have not set the beginning or ending item 
   -- -- -- set it to set the beginitem and enditem equal to null so that
   if @copyitems = 'Y'
   	begin
   	select @beginitem = isnull(@beginitem,0)
   	select @enditem = isnull(@enditem,99999)
   	end
   	
   select @vendorgroup=h.VendorGroup from bHQCO h with (nolock) join bPMCO p with (nolock) on h.HQCo=p.APCo where p.PMCo=@pmco
   
   -- -- -- begin transaction
   if exists(select 1 from bPMMM with (nolock) where PMCo = @pmco and Project = @project and 
   	MeetingType = @meetingtype and MeetingDate = @meetingdate and MinutesType = @minutestype)
   	begin
   	if @copyitems = 'N' and @copyattendees = 'N'
   		begin
   		select @msg = 'Meeting already exists.', @rcode = 1
   		goto bspexit
   		end
   	if @copyitems = 'Y' 
   		begin
   		insert PMMI (PMCo, Project, MeetingType, Meeting, MinutesType, Item, 
   			OriginalItem, Minutes, VendorGroup, InitFirm, Initiator, ResponsibleFirm, 
   			ResponsiblePerson, InitDate, DueDate, FinDate, Status, Issue)
   		select @pmco, @project, @meetingtype, @destmeeting, 
   			@destminutestype, Item, OriginalItem, Minutes, VendorGroup, InitFirm, 
   			Initiator, ResponsibleFirm, ResponsiblePerson, InitDate, DueDate, FinDate, 
   			PMMI.Status, Issue 
   			from PMMI with (nolock) 
   			left join PMSC with (nolock) on PMSC.Status = PMMI.Status  
   			where PMCo = @pmco and Project = @project and MeetingType = @meetingtype 
   			and Meeting = @meeting and MinutesType = @minutestype and 
   			(@copyfinstatus = 'Y' or (PMSC.CodeType <>'F' and @copyfinstatus = 'N'))
   			and Item>=isnull(@beginitem,Item) and Item<=isnull(@enditem,Item)
   		end
   	if @copyattendees = 'Y' 
   		begin
   		insert PMMD (PMCo, Project, MeetingType, Meeting, MinutesType,
   			VendorGroup, FirmNumber, ContactCode, PresentYN)
   		select @pmco, @project, @meetingtype, @destmeeting, 
   			@destminutestype, VendorGroup, FirmNumber, ContactCode, PresentYN
   			from PMMD with (nolock) where PMCo = @pmco and Project = @project 
   			and MeetingType = @meetingtype and Meeting = @meeting and 
   			MinutesType = @minutestype
   		end
   	end
   else
   	begin
   	insert PMMM(PMCo, Project, MeetingType, MeetingDate, Meeting, MinutesType, MeetingTime, 
   		Location, Subject, VendorGroup, FirmNumber, Preparer, NextDate, NextTime, 
   		NextLocation)
   	select @pmco, @project, @meetingtype, @meetingdate, @destmeeting, @destminutestype, 
   		MeetingTime, Location, Subject, VendorGroup, FirmNumber, Preparer, NextDate, 
   		NextTime, NextLocation 
   		from PMMM with (nolock) where PMCo = @pmco and Project = @project
   		and MeetingType = @meetingtype and Meeting = @meeting and 
   		MinutesType = @minutestype
   	if @copyitems='Y'
   		begin
   		insert PMMI (PMCo, Project, MeetingType, Meeting, MinutesType, Item, 
   			OriginalItem, Minutes, VendorGroup, InitFirm, Initiator, ResponsibleFirm, 
   			ResponsiblePerson, InitDate, DueDate, FinDate, Status, Issue)
   		select @pmco, @project, @meetingtype, @destmeeting, 
   			@destminutestype, Item, OriginalItem, Minutes, VendorGroup, InitFirm, 
   			Initiator, ResponsibleFirm, ResponsiblePerson, InitDate, DueDate, FinDate, 
   			PMSC.Status, Issue 
   			from PMMI with (nolock) 
   			left join PMSC with (nolock) on PMSC.Status = PMMI.Status  
   			where PMCo = @pmco and Project = @project and MeetingType = @meetingtype 
   			and Meeting = @meeting and MinutesType = @minutestype and 
   			(@copyfinstatus = 'Y' or (PMSC.CodeType <>'F' and @copyfinstatus = 'N'))
   			and Item>=isnull(@beginitem,Item) and Item<=isnull(@enditem,Item)
   		end
   	if @copyattendees = 'Y' 
   		begin
   		insert PMMD (PMCo, Project, MeetingType, Meeting, MinutesType,
   			VendorGroup, FirmNumber, ContactCode, PresentYN)
   		select @pmco, @project, @meetingtype, @destmeeting, 
   			@destminutestype, VendorGroup, FirmNumber, ContactCode, PresentYN
   			from PMMD with (nolock) where PMCo = @pmco and Project = @project 
   			and MeetingType = @meetingtype and Meeting = @meeting and 
   			MinutesType = @minutestype
   		end
   	end
   
   
   
   	
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMMIInitialize] TO [public]
GO
