SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMDailyLogCopy    Script Date: 8/28/99 9:35:10 AM ******/
CREATE procedure [dbo].[bspPMDailyLogCopy]
 /*******************************************************************************
  * This SP will copy daily logs from one log to another.  Pass in the Date and log
  * you want to pass from and the date and log you want to pass through along with
  * an options variable that holds which logs you want to copy.
  * The Options variable is a string of log types seperated by commas i.e. (1, 2,)
  * Created By: 
  * Modified By:	MH 01/4/00 to allow description to be copied over.
  *				MH 06/1/00 copying over Print Setup info.
  *				MH 11/8/00 change how dail log is copied. Destination no longer has to be set up first by user.
  *				GF 02/1/01 tolog and fromlog are smallints in PMDD and PMDL.
  *							changed @tolog and @fromlog from tinyints to smallints
  *				GF 03/12/03 issue #20670 - copy daily log user memos PMDL and PMDD
  *				GF 07/02/03 issue #21545 - added notes to copy for PMDL
  *				GF 02/03/04 issue #23670 - PMDD.Description was only 255 characters. Needs to be 8000 characters.
  *				GF 02/07/2005 - issue #22095 - allow daily log copy on all Job Status
  *				GF 10/20/2005 - issue #30126 - added PMDD.UM, PMDD.EMCo to copy. Was missing.
  *				GF 10/30/2008 - issue #130136 description changed from varchar(8000) to varchar(max)
  *				TRL  07/27/2011  TK-07143  Expand bPO parameters/varialbles to varchar(30)
  *
  *
  *
  * Both the from and to logs need to exits
  *
  * It Returns either STDBTK_SUCCESS or STDBTK_ERROR and a msg in @msg
  *
  * Pass In
  *   Connection    Connection to do query on
  *   PMCo          PM Company to initialize in
  *   Project       Project to initialize Submittals for
  *   FromDate      the date of the log you want to copy from
  *   FromLog       the log # from that date to copy from
  *   ToDate        the date of the log to copy to
  *   ToLog         The log number of the date to copy to
  *   Options       Options of what logs to copy (string of log types seperated by ,'s
  *
  * RETURN PARAMS
  *   msg           Error Message, or Success message
  *
  * Returns
  *      STDBTK_ERROR on Error, STDBTK_SUCCESS if Successful
  *
  ********************************************************************************/
  (@pmco bCompany, @project bJob, @fromdate bDate, @fromlog smallint, @todate bDate,
   @tolog smallint, @options varchar(15), @msg varchar(255) output)
  as
  set nocount on
  
declare @rcode int, @jobstatus tinyint, @opencursor tinyint, @initcount int, @diff int,
		@logtype tinyint, @seq smallint, @prco bCompany, @crew varchar(10),
		@vendorgroup bGroup, @firmnumber bFirm, @contactcode bEmployee, @equipment bEquip,
		@visitor varchar(60), @description varchar(max), @arrivetime smalldatetime,
		@departtime smalldatetime, @catstatus char(1), @supervisor varchar(30),
		@foreman tinyint, @journeymen tinyint, @apprentices tinyint, @phasegroup bGroup,
		@phase bPhase, @po varchar(30), @material varchar(30), @quantity int, @location bLoc,
		@issue bIssue, @delticket varchar(10), @toseq smallint, @pmdldesc varchar(255),
		@pmdlweather varchar(60), @pmdlwind varchar(30), @pmdltemphi smallint, @pmdltemplow smallint,
		@empYN bYN, @crewYN bYN, @subcYN bYN, @equipYN bYN, @activYN bYN, @convYN bYN, @delivYN bYN,
		@accYN bYN, @visYN bYN, @pmddud_flag bYN, @pmdlud_flag bYN, @joins varchar(2000),
		@where varchar(2000), @matlgroup bGroup, @um bUM, @emco bCompany
  
  select @rcode = 1, @opencursor = 0, @msg='Error in copy!', @pmddud_flag = 'N', @pmdlud_flag = 'N'
  
  -- make sure project is setup and correct status
  select @jobstatus=JobStatus from bJCJM with (nolock) where JCCo=@pmco and Job=@project
  if @@rowcount = 0
  	begin
      select @msg='Project ' + isnull(@project,'') + ' not setup, cannot copy!',@rcode=1
      goto bspexit
  	end
  
  -- make sure from log is setup
  if not exists(select top 1 1 from bPMDL with (nolock) where PMCo=@pmco and Project=@project and LogDate=@fromdate and DailyLog=@fromlog)
  	begin
      select @msg='Log ' + convert(varchar(15),@fromdate) + ':' + convert(varchar(5), @fromlog) + ' not setup, nothing to copy from!',@rcode=1
      goto bspexit
  	end
  
  
  -- make sure not copying from the same log
  if @fromdate=@todate and @fromlog=@tolog
  	begin
      select @msg='The from and to log are the same, you cannot copy a log onto itself.', @rcode=1
      goto bspexit
  	end
  
  -- set the user memo flags for the tables that have user memos
  if exists(select name from syscolumns where name like 'ud%' and id = object_id('dbo.bPMDL'))
  	select @pmdlud_flag = 'Y'
  if exists(select name from syscolumns where name like 'ud%' and id = object_id('dbo.bPMDD'))
  	select @pmddud_flag = 'Y'
  
  
  --Issue 9572, set up destination log
  if not exists(select TOP 1 1 from PMDL with (nolock) where PMCo=@pmco and Project=@project and LogDate=@todate and DailyLog=@tolog)
  	begin
  	insert into PMDL (PMCo, Project, LogDate, DailyLog, Description, Weather, Wind, TempHigh, TempLow,
  			EmployeeYN, CrewYN, SubcontractYN, EquipmentYN, ActivityYN, ConversationsYN, DeliveriesYN,
          	AccidentsYN, VisitorsYN, Notes)  
  	select @pmco, @project, @todate, @tolog, d.Description, d.Weather, d.Wind, d.TempHigh, d.TempLow,
  		   d.EmployeeYN, d.CrewYN, d.SubcontractYN, d.EquipmentYN, d.ActivityYN, d.ConversationsYN, d.DeliveriesYN,
  		   d.AccidentsYN, d.VisitorsYN, d.Notes 
  	from PMDL d with (nolock) where d.PMCo=@pmco and d.Project=@project and d.LogDate=@fromdate and d.DailyLog=@fromlog
  	if @@rowcount <> 0 and @pmdlud_flag = 'Y'
  		begin
  		-- build joins and where clause
  		select @joins = ' from PMDL join PMDL z on z.PMCo = ' + convert(varchar(3),@pmco) + ' and z.Project = ' 
  						+ CHAR(39) + @project + CHAR(39) + ' and z.LogDate = ' + CHAR(39) + convert(varchar(11),@fromdate, 1) + CHAR(39)
  						+ ' and z.DailyLog = ' + convert(varchar(6), @fromlog)
  		select @where = ' where PMDL.PMCo = ' + convert(varchar(3),@pmco) + ' and PMDL.Project = ' 
  						+ CHAR(39) + @project + CHAR(39) + ' and PMDL.LogDate = ' + CHAR(39) + convert(varchar(11),@todate, 1) + CHAR(39)
  						+ ' and PMDL.DailyLog = ' + convert(varchar(6), @tolog)
  		-- execute user memo update
  		exec @rcode = bspPMProjectCopyUserMemos 'PMDL', @joins, @where, @msg output
  		end
      end
  
  
---- declare cursor for all phases in phase range matching Document type
---- include Seq in select list to make sure we get one for each Phase in PMPS
declare bcPMDD cursor LOCAL FAST_FORWARD
	for select LogType, Seq, PRCo, Crew, VendorGroup, FirmNumber, ContactCode, Equipment, 
			Visitor, Description, ArriveTime, DepartTime, CatStatus, Supervisor, Foreman, Journeymen, 
			Apprentices, PhaseGroup, Phase, PO, Material, Quantity, Location, Issue, DelTicket,
			MatlGroup, UM, EMCo
from bPMDD with (nolock) where PMCo=@pmco and Project=@project and LogDate=@fromdate
and DailyLog=@fromlog and charindex(convert(char(1),LogType)+',',@options) > 0

-- open cursor
open bcPMDD
select @opencursor = 1

-- set some defaults
select @initcount=0, @diff=DATEDIFF(day, @fromdate,@todate)

-- loop through daily log detail
process_loop:
fetch next from bcPMDD into @logtype, @seq, @prco, @crew, @vendorgroup, @firmnumber, @contactcode, @equipment, 
		@visitor, @description, @arrivetime, @departtime, @catstatus, @supervisor, @foreman, @journeymen, 
		@apprentices, @phasegroup, @phase, @po, @material, @quantity, @location, @issue, @delticket,
		@matlgroup, @um, @emco

if (@@fetch_status <> 0) goto process_loop_end
  
  -- for each log type get next seq number
  select @toseq = 0
  begin transaction
  
  select @toseq = isNull(max(Seq),0) 
  from bPMDD with (nolock) where PMCo=@pmco and Project=@project and LogDate=@todate and DailyLog=@tolog and LogType=@logtype
  
  select @toseq = @toseq + 1
  insert into bPMDD(PMCo, Project, LogDate, DailyLog, LogType, Seq, PRCo, Crew,
  		VendorGroup, FirmNumber, ContactCode, Equipment, Visitor, Description, ArriveTime,
  		DepartTime, CatStatus, Supervisor, Foreman, Journeymen, Apprentices, PhaseGroup,
  		Phase, PO, Material, Quantity, Location, Issue, DelTicket, MatlGroup, UM, EMCo)
  select  @pmco, @project, @todate, @tolog, @logtype, @toseq, @prco, @crew, @vendorgroup,
          @firmnumber, @contactcode, @equipment, @visitor, @description, DATEADD(day, @diff, @arrivetime),
          DATEADD(day, @diff, @departtime), @catstatus, @supervisor, @foreman, @journeymen, @apprentices, @phasegroup,
          @phase, @po, @material, @quantity, @location, @issue, @delticket, @matlgroup, @um, @emco
  if @@rowcount <> 0 and @pmddud_flag = 'Y'
  	begin
  	-- build joins and where clause
  	select @joins = ' from PMDD join PMDD z on z.PMCo = ' + convert(varchar(3),@pmco) + ' and z.Project = ' + CHAR(39) + @project + CHAR(39)
  						+ ' and z.LogDate = ' + CHAR(39) + convert(varchar(11),@fromdate, 1) + CHAR(39)
  						+ ' and z.DailyLog = ' + convert(varchar(6), @fromlog)
  						+ ' and z.LogType = ' + convert(varchar(3), @logtype)
  						+ ' and z.Seq = ' + convert(varchar(10), @seq)
  	select @where = ' where PMDD.PMCo = ' + convert(varchar(3),@pmco) + ' and PMDD.Project = ' + CHAR(39) + @project + CHAR(39)
  						+ ' and PMDD.LogDate = ' + CHAR(39) + convert(varchar(11),@todate, 1) + CHAR(39)
  						+ ' and PMDD.DailyLog = ' + convert(varchar(6), @tolog)
  						+ ' and PMDD.LogType = ' + convert(varchar(3), @logtype)
  						+ ' and PMDD.Seq = ' + convert(varchar(10), @toseq)
  	-- execute user memo update
  	exec @rcode = dbo.bspPMProjectCopyUserMemos 'PMDD', @joins, @where, @msg output
  	end
  
  -- we add the number of days between the 2 logs so that dates stay in line
  commit transaction
  
  select @initcount=@initcount + 1
  goto process_loop
  
  process_loop_end:
  select @msg = convert(varchar(5),@initcount) + ' log entries copied.', @rcode = 0
  
  
  
  bspexit:
  	if @opencursor = 1
  		begin
          close bcPMDD
          deallocate bcPMDD
  		select @opencursor = 0
  		end
  		
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMDailyLogCopy] TO [public]
GO
