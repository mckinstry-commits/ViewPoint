SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[bspVAWDNotifierInsertWDQF]  
   /*******************************************************************  
   * CREATED: JM 08/23/02  
   *   TV - 23061 added isnulls  
   *   MV - 5/7/07 #28321 use View instead of table    
   * LAST MODIFIED:   
   *    CC - 01/27/2008 - 129920 Update to not delete existing records  
   *    GC - 03/04/2010 - 137657 Re-sequence properly now that we are preserving existing records.
   *	CC - 05/14/2010 - 139446 Basically, undo of previous changes, pick up is key field from the existing records
   *							 purge the existing records, and re-insert from the temp table
   *    CC - 07/27/2010 - 140756 Added default to the @EmailFields table for IsKeyField
   * USAGE: Adds TableColumns and EMailFields to bWDQF for a   
   * specified QueryName and SelectStatement   
   *  
   * INPUT PARAMS:   
   * @queryname - Notifier QueryName  
   * @selectstatement - Triggering select statement  
   *  
   * OUTPUT PARAMS:  
   * @rcode - Return code; 0 = success and record added  
   *        1 = code failure  
   *        2 = smg not initialized  
   *  
   * @errmsg - Error message; temp copied if success, error message if failure  
   ********************************************************************/  
   (@queryname varchar(50) = null,   
   @selectclause varchar(6000) = null,  
   @errmsg varchar(255) output)  
     
   AS  
      
   SET NOCOUNT ON  
     
   /* declare locals */  
   DECLARE  
   @aspos    smallint  
      ,@charpos   smallint  
      ,@checkchar   char(1)  
      ,@endbracketpos  smallint  
      ,@endspacepos  smallint  
      ,@lowerselectclause varchar(6000)  
      ,@rcode    tinyint  
      ,@seq    smallint   
      ,@startbracketpos smallint  
      ,@tablecolumn  varchar(100)  
   ,@emailparam  varchar(55)  
     
   SELECT @rcode = 0  
     
   /* Verify required parameters passed */  
   IF @queryname IS NULL  
    BEGIN  
     SELECT @errmsg = 'Missing Query Name!', @rcode = 1  
     GOTO bspexit  
    END  
      
   IF @selectclause IS NULL  
   BEGIN  
     SELECT @errmsg = 'Missing Select Clause!', @rcode = 1  
     GOTO bspexit  
   END  
     
     
   /* set the select clause  to lower case so comparisons will always work properly */  
   SELECT @lowerselectclause = LOWER(@selectclause)  
     
     
   /* Set all position holders to zero */  
   SELECT @aspos = 0  
   , @charpos = 0  
   , @endspacepos = 0  
   , @startbracketpos = 0  
   , @endbracketpos = 0  
   , @seq = 0  
     
   DECLARE @EmailFields TABLE  
 (  
  QueryName  VARCHAR (50) NOT NULL,  
  Seq    smallint NOT NULL,  
  TableColumn  VARCHAR(100) NOT NULL,  
  EMailField  VARCHAR(100) NOT NULL,  
  IsKeyField  bYN NULL  
 )  
     
   /* Top of loop on EMailFields */  
   NextEMailField:  
     
   SELECT @seq = @seq + 1  
     
   /* Find the next occurance of ' as ' in the justified select clause, starting from the last occurance */  
   SELECT @aspos = CHARINDEX(' as ', @lowerselectclause, @aspos+1)  
     
   /* Skip the first ' as ' since it will be associated with the IDENTITY column definition */  
   SELECT @charpos = @aspos  
     
   /* Top of loop on characters within the EMailField */  
   NextChar:  
    /* Grab the next character in the EMailField */  
    SELECT @checkchar = SUBSTRING(@lowerselectclause,@charpos-1,1)  
      
  --If we've hit a space or a period, take the EMailField definition (do not include the alias)   
  IF @checkchar = ' ' OR @checkchar = '.'  
     BEGIN  
      SELECT @tablecolumn = SUBSTRING(@selectclause,@charpos,@aspos-@charpos)  
   GOTO GetEMailField  
     END  
      
    /* If we haven't defined an EMailField, set the character position to the next and keep going */  
    SELECT @charpos = @charpos - 1  
   GOTO NextChar  
     
   GetEMailField:  
    /* Define the next EMailField */  
  SELECT @startbracketpos = CHARINDEX('[', @selectclause, @endbracketpos)  
    
  IF @startbracketpos = 0 AND @endbracketpos <> 0  
   GOTO bspexit  
    
  SELECT @endbracketpos = CHARINDEX(']', @selectclause, @startbracketpos)  
    
    /* Exit if Select Statement does not have required brackets */  
  IF @startbracketpos = 0 OR @endbracketpos = 0  
     BEGIN   
      SELECT @errmsg = 'Select Clause does not contain required brackets around EMain Field names (eg ''[FieldName]'')!', @rcode = 1  
      GOTO bspexit  
     END  
      
    --The tablecolumn and the Emailparams should be the same - the '[]'   
    SELECT @emailparam = SUBSTRING(@selectclause, @startbracketpos, @endbracketpos - @startbracketpos + 1)  
    SELECT @tablecolumn = SUBSTRING(@selectclause, @startbracketpos + 1, @endbracketpos - @startbracketpos -1)  
      
    /* Insert the field into holding table */  
    INSERT @EmailFields (QueryName, Seq, TableColumn, EMailField, IsKeyField)   
    VALUES (@queryname, @seq, @tablecolumn, @emailparam, 'N');
    
    select * from @EmailFields
     
   GOTO NextEMailField  
       
   bspexit:      
     
 IF @rcode=1   
     SELECT @errmsg=@errmsg + CHAR(13) + CHAR(10) + '[bspVANotifierInsertWDQF]'  
 ELSE  
 BEGIN  
    
    /* Update our temp table with the existing records (those we hadn't changed)*/
	UPDATE tempFields
	SET IsKeyField = currentFields.IsKeyField
	FROM @EmailFields AS tempFields
	INNER JOIN WDQF AS currentFields ON tempFields.QueryName = currentFields.QueryName AND tempFields.EMailField = currentFields.EMailField AND tempFields.TableColumn = currentFields.TableColumn
	 
    /* Now delete out ALL query fields since we have them preserved in our temp table */
	DELETE WDQF  
    FROM WDQF   
    WHERE QueryName = @queryname  
        
    /* Insert our query fields (which have now been preserverd and resequence back into WDQF) */
    INSERT INTO WDQF (QueryName, Seq, TableColumn, EMailField, IsKeyField)  
    SELECT e.QueryName, Row_Number() OVER(ORDER BY (SELECT NULL)), e.TableColumn, e.EMailField, e.IsKeyField  
    FROM @EmailFields e       
    ORDER BY Row_Number() OVER(ORDER BY (SELECT NULL))
      
    RETURN @rcode  
 END 


GO
GRANT EXECUTE ON  [dbo].[bspVAWDNotifierInsertWDQF] TO [public]
GO
