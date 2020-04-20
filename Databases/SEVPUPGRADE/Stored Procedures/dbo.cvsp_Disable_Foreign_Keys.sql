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
	Title:	VCS Disable Foreign Keys
	Created: 2011	
	Created by:	VCS Technical Services
	Revisions:	1. 
				2. 

	Notes: 

**/

CREATE PROCEDURE [dbo].[cvsp_Disable_Foreign_Keys] 
AS

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'TblFKs'))
EXEC cvsp_Enable_Foreign_Keys;

declare @SQLStr varchar(MAX)
declare @FKName sysname, @FKTabName sysname
DECLARE @tblFKsD Table (TabName sysname, FKName sysname)--DisableTable 


create table TblFKs (TabName sysname, FKName sysname);


--Insert list of Foreign key constraints that are enabled 
--to be used to Disable then Enable the ForeignKeys
INSERT INTO TblFKs (TabName, FKName) 
      SELECT OBJECT_NAME(fk.parent_object_id), fk.name 
      FROM sys.foreign_keys AS fk
      WHERE fk.is_disabled = 0;

--Insert list into temp table
INSERT INTO @tblFKsD (TabName, FKName) 
      SELECT TabName, FKName
      FROM TblFKs AS fk;
    
--Disable the Foreign Keys in Preparation for delete.
WHILE EXISTS (SELECT 1 FROM  @tblFKsD)
      BEGIN
            SELECT TOP 1 @FKName = FKName, @FKTabName = TabName
                  FROM @tblFKsD AS tfk
            -- create string to disable the constraint
            SET @SQLStr = 'ALTER TABLE ' + @FKTabName + ' NOCHECK CONSTRAINT ' + @FKName
            EXEC (@SQLStr)
            
            DELETE @tblFKsD WHERE FKName = @FKName AND TabName = @FKTabName
          
      END;
      
GO
