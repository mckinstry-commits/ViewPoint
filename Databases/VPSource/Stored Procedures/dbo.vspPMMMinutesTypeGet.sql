SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMMMinutesTypeGet    Script Date: 06/21/2005 ******/
CREATE  proc [dbo].[vspPMMMinutesTypeGet]
/*************************************
 * Created By:	GF 02/14/2007
 * Modified by: GF 09/03/2010 - issue #141031 change to use date only function
 *
 *
 * called from PMMeeting Minutes form to return agenda values (MinutesType=0) if any.
 * Will be used as defaults form meeting (MinutesType=1) when minutes type is meeting.
 * Also looks for a previous meeting and return next date, time, and location for new
 * meeting.
 *
 * Pass:
 * PMCo			PM Company
 * Project		PM Project
 * MeetingType	PM Meeting Type
 * Meeting		PM Meeting
 * MinutesType	PM Meeting Minutes Type
 *
 * Returns:
 * meetngdate	PM agenda meeting date
 * meetingtime	PM agenda meeting time
 * location		PM agenda location
 * subject		PM agenda subject
 * firm			PM agenda our firm
 * preparer		PM agenda preparer
 * nextdate		PM agenda next date
 * nexttime		PM agenda next time
 * nextlocation	PM agenda next location
 * prevdate		PM Previous meeting next date
 * prevtime		PM Previous meeting next time
 * prevloc		PM Previous meeting next location
 * agenda_exists	YN flag 'Y' - agenda exists
 *
 * Success returns:
 *	0 and Minutes type Description
 *
 * Error returns:
 * 
 *	1 and error message
 **************************************/
(@pmco bCompany, @project bJob, @meetingtype bDocType, @meeting int, @minutestype tinyint,
 @meetingdate bDate = null output, @meetingtime smalldatetime = null output, @location bDesc = null output,
 @subject bItemDesc = null output, @firm bVendor = null output, @preparer bEmployee = null output,
 @nextdate bDate = null output, @nexttime smalldatetime = null output, @nextlocation bDesc = null output,
 @prevdate bDate = null output, @prevtime smalldatetime = null output, @prevlocation bDesc = null output,
 @agenda_exists bYN output, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @currdate bDate, @autogenmtgno varchar(1)

select @rcode = 0, @msg = '', @agenda_exists = 'N'

----#141031
set @currdate = dbo.vfDateOnly()

---- get meeting generate option from JCJM
select @autogenmtgno=AutoGenMTGNo
from JCJM with (nolock) where JCCo=@pmco and Job=@project
if @@rowcount = 0 select @autogenmtgno='T'

-- -- -- set minutes agenda description
select @msg = case when @minutestype = 0 then 'Agenda' when @minutestype = 1 then 'Meeting' else 'Invalid' end

-- -- -- get PMMM data for agenda (MinutesType=0)
select @meetingdate=MeetingDate, @meetingtime=MeetingTime, @location=Location,
		@subject=Subject, @firm=FirmNumber, @preparer=Preparer, @nextdate=NextDate,
		@nexttime=NextTime, @nextlocation=NextLocation
from PMMM with (nolock) where PMCo=@pmco and Project=@project and MeetingType=@meetingtype
and Meeting=@meeting and MinutesType=0
if @@rowcount = 1 select @agenda_exists = 'Y'


---- when the meeting is greater than 1, then look for a previous meeting info
---- where the date is less than or equal to system date and meeting < this meeting
---- also use the job master option for how meeting are generated when looking for previous
if @meeting > 1
	begin
	if @autogenmtgno = 'P'
		begin
		select @prevdate=max(NextDate), @prevtime=max(NextTime), @prevlocation=max(NextLocation)
		from PMMM with (nolock) 
		where PMCo=@pmco and Project=@project and Meeting<@meeting and MeetingDate<=@currdate
		end
	else
		begin
		select @prevdate=max(NextDate), @prevtime=max(NextTime), @prevlocation=max(NextLocation)
		from PMMM with (nolock) where PMCo=@pmco and Project=@project and MeetingType=@meetingtype
		and MinutesType=@minutestype and Meeting<@meeting and MeetingDate<=@currdate
		end
	end





bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMMMinutesTypeGet] TO [public]
GO
