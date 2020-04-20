SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/**************************************************
* Create Date:	12/01/2009
* Created By:	Jonathan Paullin 
* Modified By:	AMR - Issue TK-07089 , Fixing performance issue by using an inline table function.	
*		     
* Description: This procedure will return a list of all the scheduled changes that are past
*				due and need to be processed.
*
* Inputs: @errorMessage
*
* Outputs: @errorMessage -- which is never set - cool
*
*************************************************/

CREATE PROCEDURE [dbo].[vspVAGetScheduledChanges]
    (
      @errorMessage VARCHAR(512) OUTPUT
    )
AS 
    BEGIN	
        SET NOCOUNT ON ;   

        DECLARE @returnCode INT
        SELECT  @returnCode = 0
				
        SELECT  d.ViewName AS ViewName,
                d.ColumnName AS ColumnName,
                v.KeyIDToUpdate AS KeyIDToUpdate,
                v.NewValue AS NewValue,
                v.KeyID AS ScheduledChangeKeyID
        FROM    dbo.VAScheduledChanges v
        -- use inline table function for performance issues
                CROSS APPLY (SELECT ViewName,ColumnName,Seq FROM dbo.vfDDFIShared(v.FormName)) d 
		WHERE   v.UpdateStatus = 'Pending'
                AND v.EffectiveOn <= GETDATE()
                AND v.FieldSequence = d.Seq
		
        RETURN @returnCode
	
    END

GO
GRANT EXECUTE ON  [dbo].[vspVAGetScheduledChanges] TO [public]
GO
