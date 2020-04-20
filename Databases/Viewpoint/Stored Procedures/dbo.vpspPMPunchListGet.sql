SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[vpspPMPunchListGet]
/************************************************************
* CREATED:     2/22/06  CHS
* Modified:		12/4/06 chs
* MODIFIED:		6/7/07	CHS
*				GF 11/11/2011 TK-09953
*
*
* USAGE:
*   gets PM Punch List
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*    JCCo and Job 
*
************************************************************/
(@JCCo bCompany, @Job bJob, @KeyID BIGINT = Null)
AS
SET NOCOUNT ON;


SELECT 
	CAST(p.[KeyID] as BIGINT) as KeyID
	,p.PMCo
	,p.Project
	,p.PunchList
	,p.Description
	,p.Description as 'PunchListDescription'
	,p.PunchListDate
	----TK-09953
	,p.[PrintOption]
	,cc.[DisplayValue] as 'PrintOptionDescription'
		
	,p.Notes 
	,p.UniqueAttchID
	----case p.PrintOption
	----	when 'D' then 'Due Date' 
	----	when 'F' then 'Responsible Firm'
	----	when 'L' then 'Location'
	----	else '' 
	----	end as 'PrintOptionDescription'

FROM dbo.PMPU p with (nolock)
----TK-09953
LEFT JOIN dbo.DDCI cc WITH (NOLOCK) ON cc.ComboType = 'PMPunchPrintOption' AND p.PrintOption = cc.DatabaseValue

Where p.PMCo=@JCCo
	AND p.Project=@Job
	AND p.KeyID = IsNull(@KeyID, p.KeyID)



GO
GRANT EXECUTE ON  [dbo].[vpspPMPunchListGet] TO [VCSPortal]
GO
