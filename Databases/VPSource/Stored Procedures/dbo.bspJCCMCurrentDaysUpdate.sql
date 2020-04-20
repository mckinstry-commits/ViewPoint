SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/********************** SCRIPT CREATED 11/07/2003 *********************************/
CREATE    PROCEDURE [dbo].[bspJCCMCurrentDaysUpdate]
/************************************************************************
* Created By:	GF 11/07/2003
* Modified By: TV - 23061 added isnulls
*				GF 02/15/2012 TK-12673 #145530 check sum of change days before update, may exceed small integer maximum
*
*
* Purpose of Stored Procedure:
*
* Calculate JCCM.CurrentDays, called from update triggers (issue #22944).  
*
* Parameters:
*   @jcco
*   @contract
* 
* Return values:
*
*   returns 0 if successful
*   returns 1 and error msg if failed
*
*************************************************************************/
(@jcco bCompany = null, @contract bContract = null)
AS
SET NOCOUNT ON

declare @rcode int, @jcoi_changedays int, @pmoi_changedays INT,
		----TK-12673
		@JCCM_OriginalDays INT

SET @rcode = 0

if isnull(@jcco,'') = '' or isnull(@contract,'') = ''
goto bspexit

-- get JCOI.ChangeDays
select @jcoi_changedays = sum(ChangeDays)
from dbo.bJCOI where JCCo=@jcco and Contract=@contract and isnull(ChangeDays,0) <> 0
if @jcoi_changedays is null set @jcoi_changedays = 0

-- get PMOI.ChangeDays
select @pmoi_changedays = sum(a.ChangeDays)
from dbo.bPMOI a where a.PMCo=@jcco and a.Contract=@contract and isnull(a.ChangeDays,0) <> 0
and a.ACO is not null and a.ACOItem is not null
and not exists(select top 1 1 from bJCOI b where b.JCCo=a.PMCo and b.Contract=a.Contract
	and b.ACO=a.ACO and b.ACOItem=a.ACOItem)
if @pmoi_changedays is null set @pmoi_changedays = 0

----TK-12673
---- get original days from JCCM
SELECT @JCCM_OriginalDays = ISNULL(OriginalDays,0)
FROM dbo.bJCCM
WHERE JCCo = @jcco AND Contract = @contract
IF @@ROWCOUNT = 0 GOTO bspexit

---- check sum first and do not update if exceeds 32766
if ABS(@JCCM_OriginalDays + @jcoi_changedays + @pmoi_changedays) < 32767
	BEGIN
	UPDATE dbo.bJCCM SET CurrentDays = OriginalDays + ISNULL(@jcoi_changedays,0) + ISNULL(@pmoi_changedays,0)
	WHERE JCCo = @jcco AND Contract = @contract
	END



bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCCMCurrentDaysUpdate] TO [public]
GO
