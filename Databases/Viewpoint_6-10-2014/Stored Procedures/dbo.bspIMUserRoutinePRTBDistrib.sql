SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   proc [dbo].[bspIMUserRoutinePRTBDistrib]
/***********************************************************
 * CREATED BY: Shayona Roberts & Eric Anderson
 *
 *
 * Usage:
 *	Will look at all salary employees (PREH.SalaryAmt<>0) and total the hours for every timecard in the import id
 *  For that employee to come up with an hourly rate that will be applied to each timecard. Then takes the hours * Rate to come up with amount
 *
 * Input params:
 *  @Company		Current Company
 *	@ImportId	   	Import Identifier
 *	@ImportTemplate	Import ImportTemplate
 *  @Form  			Imporrt Form
 *
 * Output params:
 *	@msg		error message
 *
 * Return code:
 *	0 = success, 1 = failure
 ************************************************************/

 (@Company bCompany, @ImportId varchar(20), @ImportTemplate varchar(20), @Form varchar(20), @msg varchar(120) output)

as

set nocount on

declare @rcode int, @desc varchar(120), @Recseq int, @Employee bEmployee, @TotalHours bHrs, @Rate bUnitCost,
@Salary bDollar, @timecardhrs bHrs, @amt bDollar



select @rcode=0

/* check required input params */

if @ImportId is null
  begin
  select @desc = 'Missing ImportId.', @rcode = 1
  goto bspexit
  end
if @ImportTemplate is null
  begin
  select @desc = 'Missing ImportTemplate.', @rcode = 1
  goto bspexit
  end

if @Form is null
  begin
  select @desc = 'Missing Form.', @rcode = 1
  goto bspexit
 end


 declare WorkEditCursor cursor for
 select distinct(UploadVal)
     from IMWE with (nolock) join PREH e on IMWE.UploadVal=Employee    
     where IMWE.ImportId = @ImportId and IMWE.ImportTemplate = @ImportTemplate and IMWE.Form = @Form
     and IMWE.Identifier=25 and e.PRCo=@Company and isnull(e.SalaryAmt,0)<>0

open WorkEditCursor
-- set open cursor flag

fetch next from WorkEditCursor into @Employee


-- while cursor is not empty
while @@fetch_status = 0
begin

select @TotalHours=sum(convert(float,a.UploadVal)) 
from IMWE a join IMWE b on a.ImportId=b.ImportId and a.ImportTemplate=b.ImportTemplate and a.Form=b.Form
and a.RecordSeq=b.RecordSeq
where a.ImportId = @ImportId and a.ImportTemplate = @ImportTemplate and a.Form = @Form
and a.Identifier=195 and b.Identifier=25 and b.UploadVal=@Employee


select @Salary=SalaryAmt from bPREH where PRCo=@Company and Employee=@Employee

if @TotalHours<>0
select @Rate=@Salary/@TotalHours
else
select @Rate=0

	declare EmployeeCursor cursor for
	select RecordSeq from bIMWE where ImportId = @ImportId and ImportTemplate = @ImportTemplate and Form = @Form
		and Identifier=25 and UploadVal=@Employee

	Open EmployeeCursor

	fetch next from EmployeeCursor into @Recseq
	while @@fetch_status = 0
	begin

	select @timecardhrs=UploadVal from IMWE 
	where ImportId = @ImportId and ImportTemplate = @ImportTemplate and Form = @Form
		and Identifier=195 and RecordSeq=@Recseq

	select @amt=@Rate * @timecardhrs

	Update IMWE Set UploadVal=@Rate
	where ImportId = @ImportId and ImportTemplate = @ImportTemplate and Form = @Form
		and Identifier=200 and RecordSeq=@Recseq

	Update IMWE Set UploadVal=@amt
	where ImportId = @ImportId and ImportTemplate = @ImportTemplate and Form = @Form
		and Identifier=205 and RecordSeq=@Recseq

	fetch next from EmployeeCursor into @Recseq
	end

close EmployeeCursor
deallocate EmployeeCursor


        fetch next from WorkEditCursor into @Employee

end




close WorkEditCursor
deallocate WorkEditCursor




bspexit:
    select @msg = isnull(@desc,'User Routine') + char(13) + char(13) + '[IMUserRoutineForPRTBDistrib]'

    return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspIMUserRoutinePRTBDistrib] TO [public]
GO
