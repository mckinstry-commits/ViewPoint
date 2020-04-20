SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspVACompanyCopyWizardEnableTriggers]  
  
/***********************************************************    
* CREATED: Narendra 29-11-2012  
*      
* Usage:    
* Used by Company copy wizard to enable the list of disabled triggers.  
*    
* Input params:    
* @tablesToCheck - comma delimited list of trigger names and table names separated by colon 
*				   e.g   btPMFMd:bPMFM,btAPCOi:bAPCO
* Output params: 
* @msg - error message.   
* RETURN VALUE    
*   0   success    
*   1   fail    
*****************************************************/    
(@tablesToCheck VARCHAR(MAX), @msg varchar(1000)=null output)  
AS  
BEGIN  
 SET NOCOUNT ON;  
 DECLARE @Trigger varchar(30), @Table varchar(30), @rcode int  
   
 DECLARE @tables TABLE  
 (  
  TriggerName VARCHAR(128) NULL,  
  TableName VARCHAR(128) NULL  
 );  
   
 SELECT @rcode = 0  
   
BEGIN TRY  
 INSERT INTO @tables(TriggerName,TableName)   
  SELECT TriggerNames,TableNames FROM dbo.vfTriggerDetailsTableFromArray(@tablesToCheck);  
END TRY    
BEGIN CATCH    
    SELECT  @msg = 'Err retrieving Trigger details from comma separated Table names. Err Msg: ' + ERROR_MESSAGE() ,@rcode = 1   
END CATCH  
   
-- open cursor on @table  
DECLARE vcTable CURSOR FOR  
SELECT TriggerName,TableName  
FROM @tables  
  
 /* open cursor */     
OPEN vcTable    
  
vcTable_loop:    
FETCH NEXT FROM vcTable INTO @Trigger,@Table  
IF @@FETCH_STATUS = -1 GOTO vcTable_end    
  
BEGIN TRY  
  EXEC('ALTER TABLE ' + @Table + ' ENABLE TRIGGER ' +@Trigger)  
END TRY    
BEGIN CATCH    
    SELECT  @msg = 'Err enabling trigger ' + @Trigger +  + ' on table ' + @Table + '. Err Msg: ' + ERROR_MESSAGE() ,@rcode = 1   
END CATCH  
   
 --get next column    
GOTO vcTable_loop     
   
vcTable_end:    
CLOSE vcTable    
DEALLOCATE vcTable    
  
END  
RETURN @rcode  
  
GO
GRANT EXECUTE ON  [dbo].[vspVACompanyCopyWizardEnableTriggers] TO [public]
GO
