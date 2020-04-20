USE Viewpoint
GO

If EXISTS ( Select * From INFORMATION_SCHEMA.ROUTINES Where ROUTINE_NAME='mckfnPRMyTimesheetUnapprv' and ROUTINE_SCHEMA='dbo' and ROUTINE_TYPE='FUNCTION' )
Begin
	Print 'DROP FUNCTION dbo.mckfnPRMyTimesheetUnapprv'
	DROP FUNCTION dbo.mckfnPRMyTimesheetUnapprv
End
GO

Print 'CREATE FUNCTION dbo.mckfnPRMyTimesheetUnapprv'
GO


CREATE FUNCTION [dbo].[mckfnPRMyTimesheetUnapprv]
(
	 @PRCo bCompany = NULL
	,@PRGroup bGroup = NULL
	,@PREndDate bDate
	,@PaySeqIncl VARCHAR(8000) = NULL
	,@PaySeqExcl VARCHAR(8000) = NULL
)
RETURNS TABLE
AS
 /* 
	Purpose:	Gets PR MyTimesheet data for PR import process to batch Payroll Pay Sequence based on employees' location driven by Dept. 
				  NOTE: Each unique pay seq will be placed in individual batches
	Created:	6.6.18
	Author:		Leo Gurdian
	HISTORY:

	11.06.18 LG - simply to bring in ONLY Status = 1 (unapproved)
	10.23.18 LG - disallowed status =1 (unapproved/partial) to come in
	08.13.18 LG - added pay seq inlcude/exclude filter so Payroll can split up work
	07.12.18 LG - added Union columns to satisfy PR posting
	07.10.18 LG - include or not include already posted timesheets via @Posted flag
	07.08.18 LG - return fully approved timesheets only. leaves out partially approved timesheets. 
	06.26.18 LG - add approved / unapproved filter	
	06.06.18 LG - init

	INPUT:	@PaySeqIncl  - pay sequences that will be included 
			@PaySeqExcl  - pay sequences that will be exclude

	OUTPUT:	Unapproved timesheets (Status = 1) only

	DEPEND:	dbo.mfnSplitString and mvwPREHReports.udPaySequence

	REF:	 PRMyTimesheet.Status
			 1 - unapproved or partially approved
			 2 - approved
			 3 - error
			 4 - batched
*/
RETURN
(
Select * From
(
Select 
  PRCo
, PRGroup
, Employee
, EmployeeName
, PREndDate
		, CASE WHEN DayNum = 'DayOne' THEN 1
				 WHEN DayNum = 'DayTwo' THEN 2
				 WHEN DayNum = 'DayThree' THEN 3
				 WHEN DayNum = 'DayFour' THEN 4
				 WHEN DayNum = 'DayFive' THEN 5
				 WHEN DayNum = 'DaySix' THEN 6
				 WHEN DayNum = 'DaySeven' THEN 7
		  End As 'DayNum'
, Hours
, JCCo
, Job
, Phase
, PhaseGroup
, SMCo
, WorkOrder
, Scope
, PayType
, PaySeq = CASE WHEN PaySeq IS NULL THEN 1 ELSE PaySeq END 
, unpvt.Status
, Approved
, ApprovedBy 
, ApprovedOn 
, EarnCode
, Craft
, Class
, Shift
, SMCostType
, SMJCCostType
, Memo
, LineType
From
(
/* TEST 
declare @PRCo bCompany = NULL
declare @PRGroup bGroup = NULL
declare @PREndDate bDate = '05/13/2018 00:00:00'
*/
	Select
		CASE WHEN eh.PRCo is null Then 1 ELSE eh.PRCo END AS PRCo 
		, eh.PRGroup As PRGroup
		, t.EntryEmployee AS Employee
		, eh.FullName as 'EmployeeName'
		, t.StartDate + 6 As PREndDate
		, DayOne
		, DayTwo
		, DayThree
		, DayFour
		, DayFive
		, DaySix
		, DaySeven
		, ISNULL(t.JCCo, eh.JCCo) AS JCCo
		, CASE WHEN t.JCCo IS NULL THEN '' 
				 ELSE ISNULL(t.Job,'') END AS Job
		, ISNULL(t.Phase, '') AS Phase
		, PhaseGroup
		, SMCo
		, WorkOrder
		, Scope
		, PayType
		, eh.udPaySequence As PaySeq 
		, th.Status
		, Approved
		, REPLACE(ISNULL(t.ApprovedBy,''),'MCKINSTRY\','') AS ApprovedBy
		, ApprovedOn 
		, EarnCode
		, t.Craft
		, t.Class
		, Shift
		, SMCostType
		, SMJCCostType
		, Memo
		, LineType
	From PRMyTimesheetDetail t with(nolock)
			INNER JOIN PRMyTimesheet th with(nolock)
								ON t.PRCo = th.PRCo
							AND t.EntryEmployee = th.EntryEmployee
							AND t.StartDate = th.StartDate
							AND t.Sheet = th.Sheet
			INNER JOIN mvwPREHReports eh with(nolock)
							ON eh.Employee = t.Employee
							AND t.PRCo = eh.PRCo
	Where		 (t.PRCo		= @PRCo	   OR @PRCo IS NULL)
			AND (PRGroup		= @PRGroup OR @PRGroup IS NULL)
			AND (t.StartDate + 6)	= @PREndDate
			AND (th.Status = 1 ) -- unapproved 
			/* 11/07 LG disabled 'Include Batched Timesheets' checkbox in the UI so disabling OR below.. */
			--OR th.Status = Case When @Posted = 1 Then 4 ELSE 1 END) -- disallows or allows (4) posted timesheets to be picked up 
) p
UNPIVOT
	(Hours FOR DayNum IN
		( DayOne
		, DayTwo
		, DayThree
		, DayFour
		, DayFive
		, DaySix
		, DaySeven)
	) As unpvt
) a
	Where (PaySeq	  IN (SELECT Item As udPaySequence FROM dbo.mfnSplitString(@PaySeqIncl,',')) OR @PaySeqIncl IS NULL)
	  AND (PaySeq NOT IN (SELECT Item FROM mfnSplitString(@PaySeqExcl,',')) OR @PaySeqExcl IS NULL)
)

GO


Grant SELECT ON dbo.mckfnPRMyTimesheetUnapprv TO [MCKINSTRY\Viewpoint Users]

GO


/* TEST

Select * from mckfnPRMyTimesheetUnapprv(NULL, NULL, '10/07/2018', null, null)

*/
