SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  PROC [dbo].[vspDDAllocations] 
/**********************************
*	Created by TV 10/20/05
*	Modified By: Dan So 03/19/09 - Issue: #132746 - Increased 'ColumnName' from 25 to 30 characters
*				 AMR - 6/27/11 - TK-06411, Fixing performance issue by using an inline table function.
*
*	Returns values for EM Allocations 
*	and JC allocations
*
*
************************************/
    (
      @form VARCHAR(25),
      @emem bYN = 'N'
    )
AS 
    SET nocount ON
 
    DECLARE @local_table TABLE ( ColumnName VARCHAR(30) ) 

    INSERT  INTO @local_table
            ( ColumnName
            )
/*SELECT 	
  	isnull(F.ColumnName,'')as 'ColumnName'
  	FROM DDDTShared D with (nolock) join DDFIShared F with (nolock)on D.Datatype = F.Datatype
   join  DDUI U with (nolock) on U.Form = F.Form and U.Seq = F.Seq where*/
            SELECT  ColumnName
				-- inline table function for perf
            FROM    dbo.vfDDFIShared(@form)
            WHERE   FieldType = 4
                  

    IF @form = 'EMEquipment'
        AND @emem = 'Y' 
        BEGIN
            INSERT  INTO @local_table
                    ( ColumnName )
            VALUES  ( 'EMEM.PurchasePrice' )
            INSERT  INTO @local_table
                    ( ColumnName )
            VALUES  ( 'EMEM.CurrentAppraisal' )
            INSERT  INTO @local_table
                    ( ColumnName )
            VALUES  ( 'EMEM.ReplCost' )
            INSERT  INTO @local_table
                    ( ColumnName )
            VALUES  ( 'EMEM.LeasePayment' )
        END 

    SELECT  ISNULL(ColumnName, '')
    FROM    @local_table

GO
GRANT EXECUTE ON  [dbo].[vspDDAllocations] TO [public]
GO
