SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[bsp_HQADRecover] as 
    /******************************************
    	Created:  RM 09/16/02
        Modified: RT 03/16/04, Issue #24070 Fix for new index cross references.
    
    	Recovers HQAD records that were saved during build process.
    ******************************************/
    
    declare @RecordID as int
    
    select @RecordID = max(RecID) from bHQAD
    
    update bHQADSave
    set @RecordID = @RecordID + 1, RecID = @RecordID
    
    insert bHQAD select * from bHQADSave s 
    where not exists(select * from bHQAD d where s.ColumnName=d.ColumnName and s.ParentColumn=d.ParentColumn)

GO
GRANT EXECUTE ON  [dbo].[bsp_HQADRecover] TO [public]
GO
