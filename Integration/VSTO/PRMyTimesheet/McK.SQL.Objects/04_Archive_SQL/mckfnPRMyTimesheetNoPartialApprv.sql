USE Viewpoint
GO

If EXISTS ( Select * From INFORMATION_SCHEMA.ROUTINES Where ROUTINE_NAME='mckfnPRMyTimesheetNoPartialApprv' and ROUTINE_SCHEMA='dbo' and ROUTINE_TYPE='FUNCTION' )
Begin
	Print 'DROP FUNCTION dbo.mckfnPRMyTimesheetNoPartialApprv'
	DROP FUNCTION dbo.mckfnPRMyTimesheetNoPartialApprv
End
GO

Print 'CREATE FUNCTION dbo.mckfnPRMyTimesheetNoPartialApprv'
GO


CREATE FUNCTION [dbo].[mckfnPRMyTimesheetNoPartialApprv]
(
	 @PRCo bCompany = NULL
	,@PRGroup bGroup = NULL
	,@PREndDate bDate
	,@Approved BIT = NULL
	,@Posted BIT = NULL 
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

	10.23.18 LG - disallowed status =1 (unapproved/partial) to come in
	08.13.18 LG - added pay seq inlcude/exclude filter so Payroll can split up work
	07.12.18 LG - added Union columns to satisfy PR posting
	07.10.18 LG - include or not include already posted timesheets via @Posted flag
	07.08.18 LG - return fully approved timesheets only. leaves out partially approved timesheets. 
	06.26.18 LG - add approved / unapproved filter	
	06.06.18 LG - init


	INPUT:	@Approved = 1 approved
							 = 0 unapproved
							 = NULL approved + unapproved (default)

			@Posted	 = 1 allows already posted timesheets to be picked up, else ommit
							= 0 ommit 
							= NULL ommit (default)

			@PaySeqIncl  - pay sequences that will be included 
			@PaySeqExcl  - pay sequences that will be exclude

	OUTPUT:	Timesheets that are fully approved only.  No partially approved timesheets included. 

	DEPEND:	dbo.mckfnPRMyTimesheet

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
, EarnCode
, Craft
, Class
, Shift
, SMCostType
, SMJCCostType
, PaySeq = CASE WHEN PaySeq IS NULL THEN 1 ELSE PaySeq END 
, Memo
, LineType
From
(
/* TEST 
declare @PRCo bCompany = NULL
declare @PRGroup bGroup = NULL
declare @PREndDate bDate = '05/13/2018 00:00:00'
declare @Approved BIT = 1
declare @Posted BIT = 0
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
		, EarnCode
		, t.Craft
		, t.Class
		, Shift
		, SMCostType
		, SMJCCostType
		, eh.udPaySequence As PaySeq 
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
	Where		 (t.PRCo			= @PRCo OR @PRCo IS NULL)
			AND (PRGroup		= @PRGroup OR @PRGroup IS NULL)
			AND (t.StartDate + 6)	= @PREndDate
			AND (t.Approved = Case When @Approved = 1 Then 'Y' Else 'N' End OR @Approved IS NULL)
			AND (@Approved = 1 AND eh.Employee NOT IN (Select distinct Employee from dbo.mckfnPRMyTimesheet(@PRCo, @PRGroup, @PREndDate, 0)) OR @Approved = 0 OR @Approved IS NULL) -- unapproved 
			AND ((th.Status = Case When @Posted = 0 OR @Posted IS NULL Then 2 Else 4 End) OR (th.Status BETWEEN 2 AND 3))  -- disallows or allows posted timesheets to be picked up
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
	Where (PaySeq		IN (SELECT Item As udPaySequence FROM dbo.mfnSplitString(@PaySeqIncl,',')) OR @PaySeqIncl IS NULL)
	  AND (PaySeq NOT IN (SELECT Item FROM mfnSplitString(@PaySeqExcl,',')) OR @PaySeqExcl IS NULL)
)

GO


Grant SELECT ON dbo.mckfnPRMyTimesheetNoPartialApprv TO [MCKINSTRY\Viewpoint Users]

GO


/* TEST

Select * from mckfnPRMyTimesheetNoPartialApprv(null, null, '05/13/2018 00:00:00', 1, 0)

where Employee = '52931'

*/
