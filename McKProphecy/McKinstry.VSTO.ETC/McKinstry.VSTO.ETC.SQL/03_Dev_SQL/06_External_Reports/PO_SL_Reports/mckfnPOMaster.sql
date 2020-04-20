use Viewpoint
go

if exists ( select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mckfnPOMaster' and ROUTINE_SCHEMA='dbo' and ROUTINE_TYPE='FUNCTION' )
begin
	print 'DROP FUNCTION dbo.mckfnPOMaster'
	DROP FUNCTION dbo.mckfnPOMaster
end
go

print 'CREATE FUNCTION dbo.mckfnPOMaster'
go

CREATE FUNCTION [dbo].[mckfnPOMaster]
(
	@Job		bJob 
)
-- ========================================================================
-- Object Name: dbo.mckfnPOMaster
-- Author:		Ziebell, Jonathan
-- Create date: 03/22/2017
-- Description: 
-- Update Hist: USER--------DATE-------DESC-----------
--				J.Ziebell	03/22/2017 Initial Build
--				J.Ziebell	05/24/2017 Update for Missing SMWorkOrders
--				J.Ziebell	05/31/2017 New update Round
--				J.Ziebell   06/08/2017 Add Work Orders
-- ========================================================================

RETURNS @retTable TABLE
(
	[PO Req #] [varchar](30) NOT NULL,
	[McK PO] [varchar](30) NULL,
	[Description] [dbo].[bItemDesc] NULL,
	[Item Count] [smallint] NULL,
	[Vendor] [dbo].[bVendor] NOT NULL,
	[Vendor Name] [varchar](60) NULL,
	[PO Status] [varchar](13) NULL,
	[PO Amount] [dbo].[bDollar] NOT NULL,
	[Invoiced] [dbo].[bDollar] NOT NULL,
	[Paid] [dbo].[bDollar] NOT NULL,
	[Current Due] [dbo].[bDollar] NOT NULL,
	[Remaining Committed] [dbo].[bDollar] NULL,
	[Overspend] [dbo].[bDollar] NULL,
	[Phase Code] [dbo].[bPhase] NULL,
	[Phase Code Description] [dbo].[bItemDesc] NULL,
	[Cost Type] [varchar](1) NULL,
	[WO #] [int] NULL,
	[Work Order Description] [varchar](255) NULL,
	[Ordered By] [int] NULL,
	[Ordered By Name] [varchar](62) NULL,
	[Order Date] [dbo].[bDate] NULL
	)

BEGIN
	INSERT @retTable
           ([PO Req #] 
           ,[McK PO]
		   ,[Description]
		   ,[Item Count]
           ,[Vendor]
           ,[Vendor Name]
		   ,[PO Status]
		   ,[PO Amount]
		   ,[Invoiced] 
		   ,[Paid]
		   ,[Current Due] 
		   ,[Remaining Committed]
		   ,[Overspend]
		   ,[Phase Code]
		   ,[Phase Code Description]
		   ,[Cost Type]
		   ,[WO #] 
		   ,[Work Order Description]
           ,[Ordered By]
           ,[Ordered By Name]
           ,[Order Date]
		   )
	SELECT POF.PO
	,	POF.McKPO
	,	POF.POItemDesc
	,   POF.ItemCount
	,	POF.Vendor
	,	POF.VendorName
	,	POF.POStatus
	,	POF.CurCost
	,	POF.InvCost
	,	POF.APPaidAmt
	,	POF.CurrentDue
	,	POF.RemainCommit
	,   POF.Overspend
	,	POF.Phase
	,	POF.PhaseDesc
	,   CT.Abbreviation
	,	POF.SMWorkOrder
	,	POF.SMWODescritpion 
	,	POF.udOrderedBy
	,	POF.OrderedByName
	,	POF.OrderDate
	FROM dbo.mckvwPOJobFlat POF
		INNER JOIN	JCCT CT 
			ON POF.PhaseGroup = CT.PhaseGroup
			AND POF.CostType = CT.CostType 
		WHERE POF.Job = @Job

RETURN

END

GO

Grant select on dbo.mckfnPOMaster  to [MCKINSTRY\Viewpoint Users]







