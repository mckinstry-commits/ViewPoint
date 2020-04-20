SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMVGInitialize    Script Date:  ******/
CREATE  proc [dbo].[bspPMUIInitialize]
/*************************************
 * Created By:	GF 08/21/2007
 * Modified By:
 *
 *
 *
 *
 * called from PM Import Master form to initialize PMUI records 
 *
 * Pass:
 * @routine		PM Routine
 *
 * Success returns:
 *	0 
 *
 * Error returns:
 *	1 and error message
 **************************************/
(@routine varchar(10) = null,  @msg varchar(255) output)
as 
set nocount on

declare @rcode int

select @rcode = 0

---- for each standard import routine check to see if exists, if not add to PMUI
if not exists(select ImportRoutine from PMUI where ImportRoutine = 'Bid2Win')
	begin
	insert into PMUI (ImportRoutine, Description, FileType, Delimiter, OtherDelim, TextQualifier,
			ScheduleOfValues, StandardItemCode, RecordTypeCol, BegRecTypePos, EndRecTypePos, XMLRowTag)
	select 'Bid2Win', 'Bid2Win Estimating', 'D', '2', NULL, '"', 'N', 'Y', 1, NULL, NULL, NULL
	end

if not exists(select ImportRoutine from PMUI where ImportRoutine = 'Generic')
	begin
	insert into PMUI (ImportRoutine, Description, FileType, Delimiter, OtherDelim, TextQualifier,
			ScheduleOfValues, StandardItemCode, RecordTypeCol, BegRecTypePos, EndRecTypePos, XMLRowTag)
	select 'Generic', 'User Defined File Layout (i.e. spreadsheet)', 'D', '2', NULL, '"', 'N', 'Y', 1, NULL, NULL, NULL
	end

if not exists(select ImportRoutine from PMUI where ImportRoutine = 'HCSS')
	begin
	insert into PMUI (ImportRoutine, Description, FileType, Delimiter, OtherDelim, TextQualifier,
			ScheduleOfValues, StandardItemCode, RecordTypeCol, BegRecTypePos, EndRecTypePos, XMLRowTag)
	select 'HCSS', 'HCSS - old vision format (fixed width)', 'F', NULL, NULL, NULL, 'N', 'N', NULL, 1, 1, NULL
	end

if not exists(select ImportRoutine from PMUI where ImportRoutine = 'HCSSHeavy')
	begin
	insert into PMUI (ImportRoutine, Description, FileType, Delimiter, OtherDelim, TextQualifier,
			ScheduleOfValues, StandardItemCode, RecordTypeCol, BegRecTypePos, EndRecTypePos, XMLRowTag)
	select 'HCSSHeavy', 'HCSS Heavy Bid', 'D', '2', NULL, '"', 'N', 'Y', 1, NULL, NULL, NULL
	end

if not exists(select ImportRoutine from PMUI where ImportRoutine = 'HardDollar')
	begin
	insert into PMUI (ImportRoutine, Description, FileType, Delimiter, OtherDelim, TextQualifier,
			ScheduleOfValues, StandardItemCode, RecordTypeCol, BegRecTypePos, EndRecTypePos, XMLRowTag)
	select 'HardDollar', 'Hard Dollar Estimating', 'D', '2', NULL, '"', 'N', 'Y', 1, NULL, NULL, NULL
	end

if not exists(select ImportRoutine from PMUI where ImportRoutine = 'Timberline')
	begin
	insert into PMUI (ImportRoutine, Description, FileType, Delimiter, OtherDelim, TextQualifier,
			ScheduleOfValues, StandardItemCode, RecordTypeCol, BegRecTypePos, EndRecTypePos, XMLRowTag)
	select 'Timberline', 'Timberline Precision Estimating', 'D', '2', NULL, '"', 'N', 'Y', 1, NULL, NULL, NULL
	end






bspexit:
	if @rcode<>0 select @msg = isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMUIInitialize] TO [public]
GO
