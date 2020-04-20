SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*****************************************/
CREATE function [dbo].[vfRFIResponseNextSeq] 
	(@rfiid bigint = null)
returns bigint
as
begin

/***********************************************************
* CREATED BY:	GF 07/25/2009
* MODIFIED By:
*
*
*
* USAGE:
* This function is used as the default constraint for vPMRFIResponse
* and returns the next RFI Response Sequence for the parent RFI id.
*
*
* INPUT PARAMETERS
* @rfiid		PMRFI Key ID
*
*
* OUTPUT PARAMETERS
* next number
*
* RETURN VALUE
*   0         success
*   1         Failure or nothing to format
*****************************************************/

declare @next_seq bigint

set @next_seq = 0

if @rfiid is null goto bspexit

---- get next sequence number from vPMRFIResponse
select @next_seq = max(Seq) from dbo.PMRFIResponse with (nolock) where RFIID = @rfiid
if @@rowcount = 0 set @next_seq = 0
if isnull(@next_seq,0) = 0 set @next_seq = 1


bspexit:
	return(@next_seq)
	end

GO
GRANT EXECUTE ON  [dbo].[vfRFIResponseNextSeq] TO [public]
GO
