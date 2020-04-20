SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMDDGetNextLogSeq    Script Date: 08/23/2005 ******/
CREATE  proc [dbo].[vspPMDDGetNextLogSeq]
/*************************************
 * Created By:	GF 08/23/2005
 * Modified By:
 *
 *
 * USAGE:
 * Called from PM Daily Log related grid tabs to get the next sequential number
 * for the log type. The log types are as follows:
 * 0 - Employee, 1 - Crew, 2 - Subcontract, 3 - Equipment, 4 - Activity,
 * 5 - Conversation, 6 - Delivery, 7 - Accident, 8 - Visitor
 *
 *
 * INPUT PARAMETERS
 * @pmco			PM Company
 * @project			PM Project
 * @dailylog		PM Daily Log
 * @logdate			PM Daily log Date
 * @logtype			PM Daily Log Type
 *
 * Success returns:
 *	0 and Next PMDD sequence for log type
 *
 * Error returns:
 *	1 and error message
 **************************************/
(@pmco bCompany = null, @project bJob = null, @dailylog smallint = null,
 @logdate bDate = null, @logtype tinyint = 0, @seq smallint = 0 output,
 @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0

-- -- -- get next sequence number for PMDD.LogType
select @seq = max(Seq) + 1
from PMDD where PMCo=@pmco and Project=@project and LogDate=@logdate
and DailyLog=@dailylog and LogType=@logtype
if isnull(@seq,0) = 0 select @seq = 1






bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMDDGetNextLogSeq] TO [public]
GO
