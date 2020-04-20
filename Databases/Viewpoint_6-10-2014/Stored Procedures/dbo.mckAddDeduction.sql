SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Mahendar B
-- Create date: 4/1/2014
-- Description:	Add new deductions from Union Class Excel.
-- =============================================
CREATE PROCEDURE [dbo].[mckAddDeduction]
@PRCo as tinyint
,@Craft as bCraft 
,@Class as bClass 
,@DLCode as bEDLCode
,@Factor as bRate
,@OldRate AS bUnitCost 
,@NewRate as bUnitCost

AS
BEGIN


INSERT INTO [Viewpoint].[dbo].[PRCD]
           ([PRCo]
           ,[Craft]
           ,[Class]
           ,[DLCode]
           ,[Factor]
           ,[OldRate]
           ,[NewRate])

     VALUES
           (@PRCo
           ,@Craft
           ,@Class
           ,@DLCode
           ,@Factor
           ,@OldRate
           ,@NewRate)
END

GO
