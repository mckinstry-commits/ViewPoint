SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/**
=========================================================================
Copyright © 2011 Viewpoint Construction Software (VCS) 
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:	VCS Enable Foreign Keys
	Created: 2011	
	Created by:	VCS Technical Services
	Revisions:	1. 
				2. 

	Notes: 

**/

CREATE PROCEDURE [dbo].[cvsp_Enable_Foreign_Keys] 
AS

declare @SQLStr varchar(MAX)
declare @FKName sysname, @FKTabName sysname
DECLARE @tblFKsE Table (TabName sysname, FKName sysname)--EnableTable 

--Insert list into temp table
INSERT INTO @tblFKsE (TabName, FKName) 
      SELECT TabName, FKName
      FROM TblFKs AS fk;
    
--Disable the Foreign Keys in Preparation for delete.
WHILE EXISTS (SELECT 1 FROM  @tblFKsE)
      BEGIN
            SELECT TOP 1 @FKName = FKName, @FKTabName = TabName
                  FROM @tblFKsE AS tfk
            -- create string to enable or disable the constraint
            SET @SQLStr = 'ALTER TABLE ' + @FKTabName + ' CHECK CONSTRAINT ' + @FKName
            EXEC (@SQLStr)
            DELETE @tblFKsE WHERE FKName = @FKName AND TabName = @FKTabName
      END    ;             

Drop table TblFKs;
GO
