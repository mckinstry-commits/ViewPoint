USE [Viewpoint]
GO

/****** Object:  StoredProcedure [dbo].[mckSMCostTypeUpdateCo]    Script Date: 1/8/2015 9:18:19 AM ******/
DROP PROCEDURE [dbo].[mckspSMCostTypeUpdateCo]
GO

/****** Object:  StoredProcedure [dbo].[mckSMCostTypeUpdateCo]    Script Date: 1/8/2015 9:18:19 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





CREATE PROCEDURE [dbo].[mckspSMCostTypeUpdateCo](
  	@Company	bCompany = null
)
AS
/******************************************************************************************
*                                                                        *
*                                                                                         *
* Purpose: Used for SM Work Orders to assigning to correct GL account								  *
*		It is scheduled to run daily for a seacific company                                                                                        *
*                                                                                         *
* Date			By			Comment                                                           *
* ==========	========	===================================================               *
* 12/15/20114   Arun Thomas        To be used for SMCostType update                                                                              *
*                                                                                         *
*******************************************************************************************/
BEGIN
 --BEGIN TRANSACTION ;
	--GO
	--DECLARE @Company bCompany;
	DECLARE SMCostTypeUpdateCo_Cursor CURSOR
       STATIC
       FOR

	SELECT  distinct a.WorkOrder, a.SMCo
			FROM SMWorkOrder a ,
				 SMWorkCompleted  b,
                 vSMWorkCompletedDetail c
       
			WHERE 1 = 1
			and a.WorkOrder = b.WorkOrder
			and c.WorkOrder = a.WorkOrder
			and exists ( SELECT 1 FROM  SMWorkOrderScope d
            WHERE c.Scope = b.Scope
                     and  d.Description is not null
					 and d.Description = 'Subcontract')
					 and b.SMCostType is null
					 and a.Job is null
                     and b.Type = '5'
					 and b.PO is not null
					-- and a.WorkOrder = '9019755'
					 and a.SMCo = @Company
       DECLARE @SMCo bCompany;
	   DECLARE @SMWorkOrder int;

       BEGIN
              OPEN SMCostTypeUpdateCo_Cursor;
              FETCH NEXT FROM SMCostTypeUpdateCo_Cursor into  @SMWorkOrder,@SMCo;
              WHILE @@FETCH_STATUS = 0
              BEGIN
              
             UPDATE vSMWorkCompletedDetail 
		     SET SMCostType = '3'
		     WHERE WorkOrder = @SMWorkOrder
		     and SMCostType is null
			 and SMCo = @SMCo
		
                           
              
                 FETCH NEXT FROM SMCostTypeUpdateCo_Cursor into  @SMWorkOrder,@SMCo;
              END
       
              CLOSE SMCostTypeUpdateCo_Cursor;
              DEALLOCATE SMCostTypeUpdateCo_Cursor;
        END

      --  GO
  --COMMIT TRANSACTION ;
   --     GO

END




GO


