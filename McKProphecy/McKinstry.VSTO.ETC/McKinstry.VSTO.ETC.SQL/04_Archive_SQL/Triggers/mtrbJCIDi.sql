USE [Viewpoint]
GO
/****** Object:  Trigger [dbo].[btJCIDi]    Script Date: 5/9/2016 9:08:35 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/****** Object:  Trigger dbo.btJCIDi    Script Date: 8/28/99 9:37:44 AM ******/
CREATE TRIGGER [dbo].[mtrbJCIDi] ON [dbo].[bJCID] FOR INSERT AS
-- ========================================================================
-- Changes to INSERT TRIGGER on bJCID for project Prophecy
-- Author:		Ziebell, Jonathan
-- Create date: 05/05/2016
-- Description:	When Batch completed that inserts a JC RevProj Row, delete any previous detail project rows from budJCIPD and
--              Populate budJCIPD with values from budJCIRD (if available) 
-- Update Hist: USER--------DATE-------DESC-----------
-- ========================================================================

DECLARE @numrows2 int

SELECT @numrows2 = @@rowcount
if @numrows2 = 0 return
SET nocount on

BEGIN

--DELETE FROM budJCIPD
--Check for existing Revenue Project Detail Rows for the current Month, If old rows for current month found, Delete them. 
DELETE FROM budJCIPD 
WHERE EXISTS (SELECT 1 FROM inserted ins 
				WHERE ins.JCCo = budJCIPD.Co 
				AND ins.Contract = budJCIPD.Contract 
				AND ins.Item = budJCIPD.Item 
				AND ins.Mth = budJCIPD.Mth) 

--INSERT INTO budJCIPD
-- Check for Revenue Project Details Rows, If rows on budJCIRD rows are found, insert them into budJCIPD
				SET IDENTITY_INSERT budJCIPD ON
INSERT INTO budJCIPD ( Co, Contract, FromDate, Item, Mth, ProjDollars, ProjUnits, ToDate, UniqueAttchID, KeyID)
			SELECT	s.Co
				,	s.Contract
				,	s.FromDate
				,	s.Item
				,	s.Mth
				,	s.ProjDollars
				,	s.ProjUnits
				,   s.ToDate
				,	s.UniqueAttchID
				,	s.KeyID
			FROM budJCIRD s
				INNER JOIN INSERTED i
					ON s.Co = i.JCCo 
					AND s.BatchId = i.BatchId 
					AND s.Contract = i.Contract 
					AND s.Item = i.Item
					AND s.Mth = i.Mth 
			WHERE i.JCTransType = 'RP'
				AND i.TransSource = 'JC RevProj'
			SET IDENTITY_INSERT budJCIPD OFF

END

RETURN
   