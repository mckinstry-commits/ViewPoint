SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspPREmplValforPRSeqCntrl]
/************************************************************************
* CREATED: mh 7/25/07    
* MODIFIED:  mh 7/16/07 125062    
*
* Purpose of Stored Procedure
*
*    Validate PR Employee and Group and check for unposted timecards
*    
*           
* Notes about Stored Procedure
* 
*
* returns 0 if successfull 
* returns 1 and error msg if failed
*
*************************************************************************/

        (@prco bCompany, @prgroup bGroup, @empl varchar(15), @activeopt varchar(1),
	@prenddate bDate, @payseq tinyint, @emplout bEmployee=null output, @sortname bSortName output, 
	@lastname varchar(30) output, @firstname varchar(30) output, @paymethod char(1) output, 
	@timecards smallint output, @msg varchar(60) output)

as
set nocount on

    declare @rcode int

    select @rcode = 0

	exec @rcode = bspPREmplGroupVal @prco, @prgroup, @empl, @activeopt, @emplout output, 
	@sortname output, @lastname output, @firstname output, @paymethod output, 
	@msg output

--	select @timecards = Count(*) 
--	from PRTB b 
--	join HQBC h on b.Co = h.Co and b.Mth = h.Mth and b.BatchId = h.BatchId 
--	join PRPC p on p.PRCo = h.Co and p.PRGroup = h.PRGroup and p.PREndDate = h.PREndDate 
--	where p.PRCo = @prco and p.PRGroup = @prgroup and p.PREndDate = @prenddate and b.Employee = @emplout
--	and b.PaySeq = @payseq

	select @timecards = count(1) from PRTH where PRCo = @prco and PRGroup = @prgroup and 
	Employee = @empl and PREndDate = @prenddate and PaySeq = @payseq

vspexit:

    return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPREmplValforPRSeqCntrl] TO [public]
GO
