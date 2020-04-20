SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspPMProjectBudgetCopy]
/*******************************************************************************
 * Created By:	GF 06/11/2007 6.x
 * Modified By:	GP 7/28/2011 - TK-07143 changed bPO to varchar(30)
 *
 *
 * This SP will copy a source project budget to a destination project budget.
 *
 * It Returns either STDBTK_SUCCESS or STDBTK_ERROR and a msg in @msg
 *
 * Pass In
 * PMCo				PM Company
 * SrcProject		PM Source Project to copy from
 * SrcBudget		PM Source Project Budget to copy from
 * DestProject		PM Destination Project to copy into
 * DestBudget		PM Destination Project Budget to copy into, must be a new budget
 * DestBudgetDesc	PM Destination Project Budget Description
 *
 * RETURN PARAMS
 *   msg           Error Message, or Success message
 *
 * Returns
 *      STDBTK_ERROR on Error, STDBTK_SUCCESS if Successful
 *
 ********************************************************************************/
(@pmco bCompany, @srcproject bJob, @srcbudget varchar(10), @destproject bProject,
 @destbudget varchar(10), @destbudgetdesc bItemDesc = null, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @opencursor tinyint, @initcount int, @diff int,
  		@logtype tinyint, @seq smallint, @prco bCompany, @crew varchar(10),
		@vendorgroup bGroup, @firmnumber bFirm, @contactcode bEmployee, @equipment bEquip,
		@visitor varchar(60), @description varchar(8000), @arrivetime smalldatetime,
		@departtime smalldatetime, @catstatus char(1), @supervisor varchar(30),
		@foreman tinyint, @journeymen tinyint, @apprentices tinyint, @phasegroup bGroup,
  		@phase bPhase, @po varchar(30), @material varchar(30), @quantity int, @location bLoc,
  		@issue bIssue, @delticket varchar(10), @toseq smallint, @pmdldesc varchar(255),
		@pmdlweather varchar(60), @pmdlwind varchar(30), @pmdltemphi smallint, @pmdltemplow smallint,
  		@empYN bYN, @crewYN bYN, @subcYN bYN, @equipYN bYN, @activYN bYN, @convYN bYN, @delivYN bYN,
		@accYN bYN, @visYN bYN, @pmehud_flag bYN, @pmedud_flag bYN, @joins varchar(2000),
  		@where varchar(2000)


select @rcode = 0, @opencursor = 0, @pmehud_flag = 'N', @pmedud_flag = 'N'

---- verify source project/budget does not equal destination project/budget
if @srcproject=@destproject and @srcbudget=@destbudget
	begin
	select @msg = 'The source project and budget are the same as destination project and budget, cannot copy.', @rcode = 1
	goto bspexit
	end

---- verify destination project and budget does not exists
if exists(select PMCo from PMEH where PMCo=@pmco and Project=@destproject and BudgetNo=@destbudget)
	begin
	select @msg = 'Destination project and budget already exists, cannot copy to.', @rcode = 1
	goto bspexit
	end

---- verify source project exists
if not exists(select JCCo from JCJM where JCCo=@pmco and Job=@srcproject)
	begin
	select @msg = 'Invalid source project, cannot copy from.', @rcode = 1
	goto bspexit
	end

---- verify destination project exists
if not exists(select JCCo from JCJM where JCCo=@pmco and Job=@destproject)
	begin
	select @msg = 'Invalid destination project, cannot copy to.', @rcode = 1
	goto bspexit
	end

---- verify source project budget exists
if not exists(select PMCo from PMEH where PMCo=@pmco and Project=@srcproject and BudgetNo=@srcbudget)
	begin
	select @msg = 'Invalid source project budget, cannot copy from.', @rcode = 1
	goto bspexit
	end

-- -- -- set the user memo flags for the tables that have user memos
if exists(select name from syscolumns where name like 'ud%' and id = object_id('dbo.bPMEH'))
  	select @pmehud_flag = 'Y'
if exists(select name from syscolumns where name like 'ud%' and id = object_id('dbo.bPMED'))
  	select @pmedud_flag = 'Y'


BEGIN TRY

	begin

	begin transaction

	---- insert destination project budget into PMEH
	insert into PMEH (PMCo, Project, BudgetNo, Description, Notes)
	select @pmco, @destproject, @destbudget, @destbudgetdesc, d.Notes
	from PMEH d with (nolock) where d.PMCo=@pmco and d.Project=@srcproject and d.BudgetNo=@srcbudget

	---- copy user memos if any
	if @pmehud_flag = 'Y'
		begin
		---- build joins and where clause
		select @joins = ' from PMEH join PMEH z on z.PMCo = ' + convert(varchar(3),@pmco)
							+ ' and z.Project = ' + CHAR(39) + @destproject + CHAR(39)
							+ ' and z.BudgetNo = ' + CHAR(39) + @destbudget + CHAR(39)
		select @where = ' where PMEH.PMCo = ' + convert(varchar(3),@pmco)
						+ ' and PMEH.Project = ' + CHAR(39) + @srcproject + CHAR(39)
						+ ' and PMEH.BudgetNo = ' + CHAR(39) + @srcbudget + CHAR(39)
		---- execute user memo update
		exec @rcode = bspPMProjectCopyUserMemos 'PMEH', @joins, @where, @msg output
		end

		---- insert destination project budget cost (PMED)
		insert PMED(PMCo, Project, BudgetNo, Seq, CostLevel, GroupNo, Line, BudgetCode, Description, PhaseGroup, 
				Phase, CostType, Units, UM, HrsPerUnit, Hours, HourCost, UnitCost, Markup, Amount, Notes)
		select @pmco, @destproject, @destbudget, isnull(max(c.Seq),0) + ROW_NUMBER() OVER(ORDER BY c.PMCo ASC, c.Project ASC, c.BudgetNo ASC),
				h.CostLevel, h.GroupNo, h.Line, h.BudgetCode, h.Description, h.PhaseGroup,
				h.Phase, h.CostType, h.Units, h.UM, h.HrsPerUnit, h.Hours, h.HourCost, h.UnitCost, h.Markup,
				h.Amount, h.Notes
		from PMED h with (nolock)
		left join PMED c on c.PMCo=@pmco and c.Project=@destproject and c.BudgetNo=@destbudget
		where h.PMCo=@pmco and h.Project=@srcproject and h.BudgetNo=@srcbudget
		group by h.PMCo, h.Project, h.BudgetNo, c.PMCo, c.Project, c.BudgetNo, h.CostLevel, h.GroupNo, h.Line,
				 h.BudgetCode, h.Description, h.PhaseGroup, h.Phase, h.CostType, h.Units, h.UM, h.HrsPerUnit,
				 h.Hours, h.HourCost, h.UnitCost, h.Markup, h.Amount, h.Notes



	commit transaction

	select @msg = 'Project Budget has been successfully copied.'
	end

END TRY

BEGIN CATCH
	begin
	IF @@TRANCOUNT > 0
		begin
		rollback transaction
		end
	select @msg = 'Project Budget copied failed. ' + ERROR_MESSAGE()
	select @rcode = 1
	end
END CATCH



-- -- -- declare cursor for PMDD for from project, date, and daily log
-- -- -- only log types for employee, crew, subcontract, equipment, and activity are copied
----declare bcPMDD cursor LOCAL FAST_FORWARD
----for select LogType, Seq, PRCo, Crew, VendorGroup, FirmNumber, ContactCode, Equipment, 
----  	Visitor, Description, ArriveTime, DepartTime, CatStatus, Supervisor, Foreman, Journeymen, 
----  	Apprentices, PhaseGroup, Phase, PO, Material, Quantity, Location, Issue, DelTicket,
----	UM, EMCo
----from PMDD with (nolock) where PMCo=@pmco and Project=@project and LogDate=@fromdate
----and DailyLog=@fromlog and LogType < 5
----
------ -- -- open cursor
----open bcPMDD
----select @opencursor = 1
----
------ -- -- set some defaults
----select @initcount=0, @diff=DATEDIFF(day, @fromdate,@todate)
----
------ -- -- loop through PMDD
----process_loop:
----fetch next from bcPMDD into @logtype, @seq, @prco, @crew, @vendorgroup, @firmnumber, @contactcode, @equipment, 
----  	@visitor, @description, @arrivetime, @departtime, @catstatus, @supervisor, @foreman, @journeymen, 
----  	@apprentices, @phasegroup, @phase, @po, @material, @quantity, @location, @issue, @delticket, 
----	@um, @emco
----
----
----if (@@fetch_status <> 0) goto process_loop_end
----
------ -- -- only copy log entries flagged to copy
----if @copy_employee = 'N' and @logtype = 0 goto process_loop
----if @copy_crew = 'N' and @logtype = 1 goto process_loop
----if @copy_subcontract = 'N' and @logtype = 2 goto process_loop
----if @copy_equipment = 'N' and @logtype = 3 goto process_loop
----if @copy_activity = 'N' and @logtype = 4 goto process_loop
----
------ -- -- for each log type get next seq number
----select @toseq = 0
----
----begin transaction
----select @toseq = isNull(max(Seq),0) 
----from PMDD with (nolock) where PMCo=@pmco and Project=@project and LogDate=@todate and DailyLog=@tolog and LogType=@logtype
----
----select @toseq = @toseq + 1
----insert into PMDD(PMCo, Project, LogDate, DailyLog, LogType, Seq, PRCo, Crew, VendorGroup, FirmNumber,
----			ContactCode, Equipment, Visitor, Description, ArriveTime, DepartTime,
----			CatStatus, Supervisor, Foreman, Journeymen, Apprentices, PhaseGroup, Phase, PO, Material,
----			Quantity, Location, Issue, DelTicket, CreatedChangedBy, UM, EMCo)
----select @pmco, @project, @todate, @tolog, @logtype, @toseq, @prco, @crew, @vendorgroup, @firmnumber,
----			@contactcode, @equipment, @visitor, @description, DATEADD(day, @diff, @arrivetime), DATEADD(day, @diff, @departtime),
----			@catstatus, @supervisor, @foreman, @journeymen, @apprentices, @phasegroup, @phase, @po, @material,
----			@quantity, @location, @issue, @delticket, @createdchangedby, @um, @emco
----if @@rowcount <> 0 and @pmddud_flag = 'Y'
----  	begin
----  	-- build joins and where clause
----  	select @joins = ' from PMDD join PMDD z on z.PMCo = ' + convert(varchar(3),@pmco) + ' and z.Project = ' + CHAR(39) + @project + CHAR(39)
----  						+ ' and z.LogDate = ' + CHAR(39) + convert(varchar(11),@fromdate, 1) + CHAR(39)
----  						+ ' and z.DailyLog = ' + convert(varchar(6), @fromlog)
----  						+ ' and z.LogType = ' + convert(varchar(3), @logtype)
----  						+ ' and z.Seq = ' + convert(varchar(10), @seq)
----  	select @where = ' where PMDD.PMCo = ' + convert(varchar(3),@pmco) + ' and PMDD.Project = ' + CHAR(39) + @project + CHAR(39)
----  						+ ' and PMDD.LogDate = ' + CHAR(39) + convert(varchar(11),@todate, 1) + CHAR(39)
----  						+ ' and PMDD.DailyLog = ' + convert(varchar(6), @tolog)
----  						+ ' and PMDD.LogType = ' + convert(varchar(3), @logtype)
----  						+ ' and PMDD.Seq = ' + convert(varchar(10), @toseq)
----  	-- execute user memo update
----  	exec @rcode = dbo.bspPMProjectCopyUserMemos 'PMDD', @joins, @where, @msg output
----  	end




bspexit:
	select @msg = isnull(@msg,'')
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMProjectBudgetCopy] TO [public]
GO
