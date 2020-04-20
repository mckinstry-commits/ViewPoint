SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspIMVPDefaultsSMWOScopeTask]

   /***********************************************************
    * CREATED BY:   Jim Emery  11/08/2012  TK-18467
    *
    * Usage:  SMWorkOrderScopeTask Import
    *	Used BY Imports to create values for needed or missing
    *      data based upon Viewpoint default rules.
    *
    * Input params:
    *	@ImportId	 Import Identifier
    *	@ImportTemplate	 Import Template
    *
    * Output params:
    *	@msg		error message
    *
    * RETURN code:
    *	0 = success, 1 = failure
    ************************************************************/
    (
     @Company bCompany
    ,@ImportId VARCHAR(20)
    ,@ImportTemplate VARCHAR(20)
    ,@Form VARCHAR(20)
    ,@rectype VARCHAR(30)
    ,@msg VARCHAR(120) OUTPUT
    )
AS 
    SET NOCOUNT ON;
   
    DECLARE @rcode INT;
    DECLARE @desc VARCHAR(120);
    DECLARE @status INT;
    DECLARE @defaultvalue VARCHAR(30);
   
    IF @ImportId IS NULL 
        BEGIN
            SELECT  @desc = 'Missing ImportId.'
                   ,@rcode = 1;
            GOTO vspexit;
        END;
    IF @ImportTemplate IS NULL 
        BEGIN
            SELECT  @desc = 'Missing ImportTemplate.'
                   ,@rcode = 1;
            GOTO vspexit;
        END;
    IF @Form IS NULL 
        BEGIN
            SELECT  @desc = 'Missing Form.'
                   ,@rcode = 1;
            GOTO vspexit;
        END;

 
/* Working Variables */
    DECLARE @Description VARCHAR(max); 
    DECLARE @Name VARCHAR(60);
    DECLARE @SMCo bCompany;
    DECLARE @SMStandardTask VARCHAR(15);
    DECLARE @Scope INT;
    DECLARE @ServiceItem VARCHAR(20);
    DECLARE @Task INT;
    DECLARE @WorkOrder INT;
    DECLARE @stdtaskname VARCHAR(60);
    DECLARE @stdtaskdescription VARCHAR(60);
    DECLARE @MaxTask INT;
    DECLARE @MaxIMTask INT;  

/* Cursor variables */
    DECLARE @Recseq INT; 
    DECLARE @Tablename VARCHAR(20);
    DECLARE @Column VARCHAR(30);
    DECLARE @Uploadval VARCHAR(60);
    DECLARE @Ident INT;
    DECLARE @valuelist VARCHAR(255);
    DECLARE @complete INT;
    DECLARE @counter INT;
    DECLARE @oldrecseq INT;
    DECLARE @currrecseq INT;
  
 
--Identifiers
    DECLARE @DescriptionID INT;
    DECLARE @NameID INT;
    DECLARE @SMCoID INT;
    DECLARE @SMStandardTaskID INT;
    DECLARE @ScopeID INT;
    DECLARE @ServiceItemID INT;
    DECLARE @TaskID INT;
    DECLARE @WorkOrderID INT;

 
/* Empty flags */ 
    DECLARE @IsEmptyDescription bYN;
    DECLARE @IsEmptyName bYN;
    DECLARE @IsEmptySMCo bYN;
    DECLARE @IsEmptySMStandardTask bYN;
    DECLARE @IsEmptyScope bYN;
    DECLARE @IsEmptyServiceItem bYN;
    DECLARE @IsEmptyTask bYN;
    DECLARE @IsEmptyWorkOrder bYN;

 
/* Overwrite flags */ 
    DECLARE @OverwriteDescription bYN;
    DECLARE @OverwriteName bYN;
    DECLARE @OverwriteSMCo bYN;
    DECLARE @OverwriteSMStandardTask bYN;
    DECLARE @OverwriteScope bYN;
    DECLARE @OverwriteServiceItem bYN;
    DECLARE @OverwriteTask bYN;
    DECLARE @OverwriteWorkOrder bYN;

;
/* Set Overwrite flags */ 
    SELECT  @OverwriteDescription = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form,'Description', @rectype);
    SELECT  @OverwriteName = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form,  'Name', @rectype);
    SELECT  @OverwriteSMCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'SMCo', @rectype);
    SELECT  @OverwriteSMStandardTask = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'SMStandardTask', @rectype);
    SELECT  @OverwriteScope = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Scope', @rectype);
    SELECT  @OverwriteServiceItem = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'ServiceItem', @rectype);
    SELECT  @OverwriteTask = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Task', @rectype);
    SELECT  @OverwriteWorkOrder = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'WorkOrder', @rectype);
 
--YN
    DECLARE @ynDescription bYN;
    DECLARE @ynName bYN;
    DECLARE @ynSMCo bYN;
    DECLARE @ynSMStandardTask bYN;
    DECLARE @ynScope bYN;
    DECLARE @ynServiceItem bYN;
    DECLARE @ynTask bYN;
    DECLARE @ynWorkOrder bYN;

    SELECT  @ynDescription = 'N';
    SELECT  @ynName = 'N';
    SELECT  @ynSMCo = 'N';
    SELECT  @ynSMStandardTask = 'N';
    SELECT  @ynScope = 'N';
    SELECT  @ynServiceItem = 'N';
    SELECT  @ynTask = 'N';
    SELECT  @ynWorkOrder = 'N';

;
 
/***** GET COLUMN IDENTIFIERS -  YN field: 
  Y means ONLY when [Use Viewpoint Default] IS set.
  N means RETURN Identifier regardless of [Use Viewpoint Default] IS set 
*******/ 
    SELECT  @DescriptionID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form,'Description', @rectype, 'N');
    SELECT  @NameID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Name', @rectype, 'N');
    SELECT  @SMCoID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'SMCo', @rectype, 'N');
    SELECT  @SMStandardTaskID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'SMStandardTask', @rectype, 'N');
    SELECT  @ScopeID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Scope', @rectype, 'N');
    SELECT  @ServiceItemID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'ServiceItem', @rectype,'N');
    SELECT  @TaskID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Task', @rectype, 'N');
    SELECT  @WorkOrderID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'WorkOrder', @rectype, 'N');
	
	IF @DescriptionID=0
		select @DescriptionID=Identifier FROM DDUD WHERE DDUD.Form=@Form AND dbo.DDUD.ColumnName = 'Description'
		
/* Columns that can be updated to ALL imported records as a set.
   The value IS NOT unique to the individual imported record. */
 

-- SMCo overwrite
    IF @SMCoID IS NOT NULL
        AND ( ISNULL(@OverwriteSMCo, 'Y') = 'Y' ) 
        BEGIN
	--Use Viewpoint Default = Y AND Overwrite Import Value = Y  
	--(Set ALL import records to this Company)
            UPDATE  IMWE
            SET     IMWE.UploadVal = @Company
            WHERE   IMWE.ImportTemplate = @ImportTemplate
                    AND IMWE.ImportId = @ImportId
                    AND IMWE.Identifier = @SMCoID
                    AND IMWE.RecordType = @rectype;
        END;

-- SMCo is null or not numeric
    IF @SMCoID IS NOT NULL
        AND ( ISNULL(@OverwriteSMCo, 'Y') = 'N' ) 
        BEGIN
	--[Use Viewpoint Default] = Y AND [Overwrite Import Value] = N  
	--(Set to this Company only IF no import value exists)
            UPDATE  IMWE
            SET     IMWE.UploadVal = @Company
            WHERE   IMWE.ImportTemplate = @ImportTemplate
                    AND IMWE.ImportId = @ImportId
                    AND IMWE.Identifier = @SMCoID
                    AND IMWE.RecordType = @rectype
                    AND (IMWE.UploadVal IS NULL OR ISNUMERIC(IMWE.UploadVal)=0);
        END;

/********* Begin default process. *******
 Multiple cursor records make up a single Import record determined BY a change in the RecSeq value.
 New RecSeq signals the beginning of the NEXT Import record. 
*/
           
    DECLARE WorkEditCursor CURSOR LOCAL FAST_FORWARD
    FOR
        SELECT  IMWE.RecordSeq
               ,IMWE.Identifier
               ,DDUD.TableName
               ,DDUD.ColumnName
               ,IMWE.UploadVal
        FROM    IMWE WITH ( NOLOCK )
        INNER JOIN DDUD WITH ( NOLOCK )
                ON IMWE.Identifier = DDUD.Identifier
                   AND DDUD.Form = IMWE.Form
        WHERE   IMWE.ImportId = @ImportId
                AND IMWE.ImportTemplate = @ImportTemplate
                AND IMWE.Form = @Form
                AND IMWE.RecordType = @rectype
        ORDER BY IMWE.RecordSeq
               ,IMWE.Identifier;
    
    OPEN WorkEditCursor;

    FETCH NEXT FROM WorkEditCursor INTO @Recseq, @Ident, @Tablename, @Column,
        @Uploadval;
   
    SELECT  @currrecseq = @Recseq
           ,@complete = 0
           ,@counter = 1;

-- WHILE cursor IS not empty
    WHILE @complete = 0 
        BEGIN

            IF @@fetch_status <> 0 
                SELECT  @Recseq = -1;

            IF @Recseq = @currrecseq	--Moves on to defaulting process when the first record of a DIFFERENT import RecordSeq IS detected
                BEGIN;
		/***** GET UPLOADED VALUES FOR THIS IMPORT RECORD ********/
		/* For each imported record:  (Each imported record has multiple records
		   in the IMWE table representing columns of the import record)
	       Cursor will cycle through each column of an imported record 
		   AND set the imported value INTO a variable that could be used 
		   during the defaulting process later IF desired.  
		   
		   The imported value here IS only needed IF the value will be 
		   used to help determine another default value in some way. */

					SELECT @Description=null
					IF @Column='SMCo' AND ISNUMERIC(@Uploadval)=1 SELECT @SMCo=CONVERT(tinyint, @Uploadval);
					IF @Column='WorkOrder' AND ISNUMERIC(@Uploadval)=1 SELECT @WorkOrder=CONVERT(int, @Uploadval);
					IF @Column='Scope' AND ISNUMERIC(@Uploadval)=1 SELECT @Scope=CONVERT(int, @Uploadval);		   
                    IF @Column = 'Description'  SELECT  @Description = @Uploadval;
                    IF @Column = 'Name' SELECT  @Name = @Uploadval;
                    IF @Column = 'SMStandardTask' SELECT  @SMStandardTask = @Uploadval;
                    IF @Column = 'ServiceItem' SELECT  @ServiceItem = @Uploadval;
                    IF @Column = 'Task' AND ISNUMERIC(@Uploadval)=1 SELECT @Task=CONVERT(int, @Uploadval);	
                    
                    IF @Column = 'Description' 
                        SET @IsEmptyDescription = CASE WHEN @Uploadval IS NULL THEN 'Y' ELSE 'N' END;
                    IF @Column = 'Name' 
                        SET @IsEmptyName = CASE WHEN @Uploadval IS NULL THEN 'Y' ELSE 'N' END;
                    IF @Column = 'SMCo' 
                        SET @IsEmptySMCo = CASE WHEN @Uploadval IS NULL THEN 'Y' ELSE 'N' END;
                    IF @Column = 'SMStandardTask' 
                        SET @IsEmptySMStandardTask = CASE WHEN @Uploadval IS NULL THEN 'Y' ELSE 'N' END;
                    IF @Column = 'Scope' 
                        SET @IsEmptyScope = CASE WHEN @Uploadval IS NULL THEN 'Y' ELSE 'N' END;
                    IF @Column = 'ServiceItem' 
                        SET @IsEmptyServiceItem = CASE WHEN @Uploadval IS NULL THEN 'Y' ELSE 'N' END;
                    IF @Column = 'Task' 
                        SET @IsEmptyTask = CASE WHEN @Uploadval IS NULL THEN 'Y' ELSE 'N' END;
                    IF @Column = 'WorkOrder' 
                        SET @IsEmptyWorkOrder = CASE WHEN @Uploadval IS NULL THEN 'Y' ELSE 'N' END;
                        
                    IF @@fetch_status <> 0 
                        SELECT  @complete = 1;	--set only after ALL records in IMWE have been processed

                    SELECT  @oldrecseq = @Recseq;

                    FETCH NEXT FROM WorkEditCursor 
			INTO @Recseq, @Ident, @Tablename, @Column, @Uploadval;
                END;
            ELSE 
                BEGIN
		/* A DIFFERENT import RecordSeq has been detected.  
		   Before moving on, set the default values for our previous Import Record. */
 
/********* SET DEFAULT VALUES ************************/
		/* At this moment, all columns of a single imported record have been
		   processed above.  The defaults for this single imported record 
		   will be set below before the cursor moves on to the columns of the NEXT
		   imported record.  */

/********** Validate SMCo  ******* Required ******/  
		IF @SMCoID<>0
				BEGIN;
					SELECT @msg=NULL
					IF @SMCo IS NULL AND @IsEmptySMCo='Y' 
						SELECT @msg='** Invalid SMCo must be provided'	
					ELSE IF @SMCo IS NULL AND @IsEmptySMCo='N' 
						SELECT @msg='** Invalid SMCo is empty or not numeric'		
					ELSE IF NOT EXISTS (SELECT  vSMCO.SMCo  
										FROM    dbo.vSMCO WITH ( NOLOCK )
										WHERE   dbo.vSMCO.SMCo = @SMCo)
						SELECT @msg= '** SMCo not in SM Company Parameters';
					IF @msg IS NOT NULL
					UPDATE IMWE
						SET IMWE.UploadVal = @msg
						WHERE IMWE.ImportTemplate=@ImportTemplate 
							AND IMWE.ImportId=@ImportId 
							AND IMWE.RecordSeq=@currrecseq
							AND IMWE.RecordType = @rectype
							AND IMWE.Identifier = @SMCoID;
            END;		   

/**********Validate WorkOrder  ******* Required ******/ 
					IF @WorkOrderID<>0 
						BEGIN;
							SELECT @msg=NULL
							IF @WorkOrder IS NULL AND @IsEmptyWorkOrder='Y' 
								SELECT @msg='** Invalid WorkOrder must be provided'	
							ELSE IF @WorkOrder IS NULL AND @IsEmptyWorkOrder='N' 
								SELECT @msg='** Invalid WorkOrder is empty or not numeric'		
							ELSE IF NOT EXISTS (SELECT  vSMWorkOrder.WorkOrder
												FROM    dbo.vSMWorkOrder WITH ( NOLOCK )
												WHERE   vSMWorkOrder.SMCo = @SMCo
														AND vSMWorkOrder.WorkOrder = @WorkOrder)
								SELECT @msg= '** Invalid Work Order';

							IF @msg IS NOT NULL
								UPDATE IMWE
									SET IMWE.UploadVal = @msg
									WHERE IMWE.ImportTemplate = @ImportTemplate 
										AND IMWE.ImportId = @ImportId 
										AND IMWE.RecordSeq = @currrecseq
										AND IMWE.RecordType = @rectype
										AND IMWE.Identifier = @WorkOrderID;
						END; 
						
/**********Validate Scope  ******* Required ******/ 
					IF @ScopeID<>0 
						BEGIN;
							SELECT @msg=NULL
							IF @Scope IS NULL AND @IsEmptyScope='Y' 
								SELECT @msg='** Invalid Scope must be provided'	
							ELSE IF @Scope IS NULL AND @IsEmptyScope='N' 
								SELECT @msg='** Invalid Scope is empty or not numeric'		
							ELSE IF NOT EXISTS (SELECT  vSMWorkOrderScope.Scope
												FROM    dbo.vSMWorkOrderScope WITH ( NOLOCK )
												WHERE   vSMWorkOrderScope.SMCo = @SMCo
														AND vSMWorkOrderScope.Scope = @Scope
														AND vSMWorkOrderScope.WorkOrder = @WorkOrder)
								SELECT @msg= '** Scope not on Work order'

							IF @msg IS NOT NULL
								UPDATE IMWE
									SET IMWE.UploadVal = @msg
									WHERE IMWE.ImportTemplate = @ImportTemplate 
										AND IMWE.ImportId = @ImportId 
										AND IMWE.RecordSeq = @currrecseq
										AND IMWE.RecordType = @rectype
										AND IMWE.Identifier = @ScopeID;
						END; 


/**********Task  ******* Required ******/ -- delete Testmsg  select * from Testmsg
                    IF @TaskID <> 0 AND ( ISNULL(@OverwriteTask, 'Y') = 'N' AND ISNULL(@IsEmptyTask, 'Y') = 'N' AND @Task IS null)  
                        BEGIN
                            UPDATE  IMWE
                            SET     IMWE.UploadVal = '** Invalid - Task must be numeric'
                            WHERE   IMWE.ImportTemplate = @ImportTemplate
                                    AND IMWE.ImportId = @ImportId
                                    AND IMWE.RecordSeq = @currrecseq
                                    AND IMWE.Identifier = @TaskID
                                    AND IMWE.RecordType = @rectype;
                        END;
                        
                    IF @TaskID <> 0 AND ( ISNULL(@OverwriteTask, 'Y') = 'Y' OR ISNULL(@IsEmptyTask, 'Y') = 'Y' ) 
                        BEGIN
					-- get the maximum task and add 1
                            SELECT  @MaxTask = 0
                                   ,@MaxIMTask = 0;
					
                            SELECT  @MaxTask = MAX(Task) + 1
                            FROM    dbo.vSMWorkOrderScopeTask WITH ( NOLOCK )
                            WHERE   SMCo = @SMCo
                                    AND WorkOrder = @WorkOrder
                                    AND Scope = @Scope;
					
                            IF ISNULL(@MaxTask, 0) = 0 
                                SELECT  @MaxTask = 1;
					-- get the maximum task from inside the imports
                            SELECT  @MaxIMTask = MAX(CONVERT(INT,UploadVal)) + 1
                            FROM    dbo.IMWE
                            JOIN ( SELECT    RecordSeq
                                      FROM      IMWE  -- get the max Scope for a work order
                                      WHERE     IMWE.ImportTemplate = @ImportTemplate
                                                AND dbo.IMWE.ImportId = @ImportId
                                                AND dbo.IMWE.Identifier = @SMCoID
                                                AND dbo.IMWE.RecordType = @rectype
                                                AND dbo.IMWE.UploadVal = @SMCo
                                    ) AS CO
                                    ON CO.RecordSeq = dbo.IMWE.RecordSeq
                            JOIN    ( SELECT    RecordSeq
                                      FROM      IMWE  -- get the max Scope for a work order
                                      WHERE     IMWE.ImportTemplate = @ImportTemplate
                                                AND dbo.IMWE.ImportId = @ImportId
                                                AND dbo.IMWE.Identifier = @WorkOrderID
                                                AND dbo.IMWE.RecordType = @rectype
                                                AND dbo.IMWE.UploadVal = @WorkOrder
                                    ) AS WO
                                    ON WO.RecordSeq = dbo.IMWE.RecordSeq 
                                       AND WO.RecordSeq = CO.RecordSeq 
                                    
                            JOIN ( SELECT    RecordSeq
                                      FROM      IMWE  -- get the max Scope for a work order
                                      WHERE     IMWE.ImportTemplate = @ImportTemplate
                                                AND dbo.IMWE.ImportId = @ImportId
                                                AND dbo.IMWE.Identifier = @ScopeID
                                                AND dbo.IMWE.RecordType = @rectype
                                                AND dbo.IMWE.UploadVal = @Scope
                                    ) AS SC
                                    ON SC.RecordSeq = dbo.IMWE.RecordSeq 
										AND SC.RecordSeq = CO.RecordSeq
										AND SC.RecordSeq = WO.RecordSeq 
                            WHERE   dbo.IMWE.ImportTemplate = @ImportTemplate
                                    AND dbo.IMWE.ImportId = @ImportId
                                    AND dbo.IMWE.Identifier = @TaskID
                                    AND dbo.IMWE.RecordType = @rectype
                                    AND dbo.IMWE.UploadVal IS NOT null
									AND ISNUMERIC(dbo.IMWE.UploadVal)=1;
									
                            IF ISNULL(@MaxIMTask, 0) = 0 
                                SELECT  @MaxIMTask = 1;
                                
                            SELECT  @msg = CASE WHEN @MaxTask >= @MaxIMTask
                                                 THEN @MaxTask
                                                 ELSE @MaxIMTask
                                            END;
                                            
                            UPDATE  IMWE
                            SET     IMWE.UploadVal = @msg
                            WHERE   IMWE.ImportTemplate = @ImportTemplate
                                    AND IMWE.ImportId = @ImportId
                                    AND IMWE.RecordSeq = @currrecseq
                                    AND IMWE.Identifier = @TaskID
                                    AND IMWE.RecordType = @rectype;
                        END;

/********** Validate SMStandardTask  *** varchar **********/  
                    SELECT  @stdtaskname = NULL
                           ,@stdtaskdescription = NULL -- reset values
					IF @SMStandardTaskID <> 0 AND @IsEmptySMStandardTask='N'  
					BEGIN;
						SELECT  @msg=null
						SELECT  @stdtaskname = vSMStandardTask.Name
							   ,@stdtaskdescription = LEFT(vSMStandardTask.Description ,60)
						FROM    dbo.vSMStandardTask WITH ( NOLOCK )
						WHERE   vSMStandardTask.SMCo = @SMCo
								AND @SMStandardTask = vSMStandardTask.SMStandardTask;
						IF @@rowcount = 0 
							SELECT @msg='** Invalid SM Standard Task',@stdtaskname = NULL, @stdtaskdescription=null;
;
						IF @msg IS NOT NULL
							BEGIN;
								UPDATE  IMWE
								SET     IMWE.UploadVal = @msg
								WHERE   IMWE.ImportTemplate = @ImportTemplate
										AND IMWE.ImportId = @ImportId
										AND IMWE.RecordSeq = @currrecseq
										AND IMWE.Identifier = @SMStandardTaskID
										AND IMWE.RecordType = @rectype;
							END;
                     END;

/**********Name  ******* Required ******/  
                    IF @NameID <> 0
                        AND ( ISNULL(@OverwriteName, 'Y') = 'Y'
                              OR ISNULL(@IsEmptyName, 'Y') = 'Y' ) 
                        BEGIN
                            SELECT  @Name = @stdtaskname 
                            UPDATE  IMWE
                            SET     IMWE.UploadVal = @Name
                            WHERE   IMWE.ImportTemplate = @ImportTemplate
                                    AND IMWE.ImportId = @ImportId
                                    AND IMWE.RecordSeq = @currrecseq
                                    AND IMWE.Identifier = @NameID
                                    AND IMWE.RecordType = @rectype;
                           SET @IsEmptyName=CASE WHEN @Name IS NULL THEN 'Y' ELSE 'N' END;
                        END;
                        
/**********Validate Name  ******* Required ******/  
                    IF @NameID <> 0 AND @Name IS null
                        BEGIN;
                            UPDATE  IMWE
                            SET     IMWE.UploadVal = '** Invalid Name must have a value'
                            WHERE   IMWE.ImportTemplate = @ImportTemplate
                                    AND IMWE.ImportId = @ImportId
                                    AND IMWE.RecordSeq = @currrecseq
                                    AND IMWE.Identifier = @NameID
                                    AND IMWE.RecordType = @rectype;
                        END; 

                    IF @NameID <> 0 AND @Name IS NOT null
                        BEGIN;
							IF EXISTS(SELECT [Name] FROM dbo.SMWorkOrderScopeTask
								 WHERE [SMCo]=@SMCo
									AND [Name]=@Name
									AND [WorkOrder]=@WorkOrder
									AND [Scope]=@Scope
									AND [ServiceItem]=@ServiceItem)
								UPDATE  IMWE
								SET     IMWE.UploadVal = '** Invalid Name must be unique'
								WHERE   IMWE.ImportTemplate = @ImportTemplate
										AND IMWE.ImportId = @ImportId
										AND IMWE.RecordSeq = @currrecseq
										AND IMWE.Identifier = @NameID
										AND IMWE.RecordType = @rectype;
                        END;                         
                        
/********** Description  *************/  
					--- double check and get from IMWENotes since Description>60 chars
SET @IsEmptyDescription= CASE WHEN @Description IS  NULL THEN 'Y' ELSE 'N' END;					
                    IF @DescriptionID <> 0 AND @IsEmptyDescription='Y'
						BEGIN;
							SELECT @Description=IMWENotes.UploadVal
							FROM dbo.IMWENotes
							 WHERE   IMWENotes.ImportTemplate = @ImportTemplate
                                    AND IMWENotes.ImportId = @ImportId
                                    AND IMWENotes.RecordSeq = @currrecseq
                                    AND IMWENotes.Identifier = @DescriptionID
                                    AND IMWENotes.RecordType = @rectype;
							SET @IsEmptyDescription= CASE WHEN @Description IS  NULL THEN 'Y' ELSE 'N' END;
						END;
				   IF @DescriptionID <> 0 
                        AND ( ISNULL(@OverwriteDescription, 'Y') = 'Y'
                              OR ISNULL(@IsEmptyDescription, 'Y') = 'Y' ) 
                        BEGIN;
                            SELECT  @Description = @stdtaskdescription
                            UPDATE  IMWE
                            SET     IMWE.UploadVal = LEFT(@Description,60)
                            WHERE   IMWE.ImportTemplate = @ImportTemplate
                                    AND IMWE.ImportId = @ImportId
                                    AND IMWE.RecordSeq = @currrecseq
                                    AND IMWE.Identifier = @DescriptionID
                                    AND IMWE.RecordType = @rectype;
                            UPDATE  IMWENotes
                            SET     IMWENotes.UploadVal = @Description
                            WHERE   IMWENotes.ImportTemplate = @ImportTemplate
                                    AND IMWENotes.ImportId = @ImportId
                                    AND IMWENotes.RecordSeq = @currrecseq
                                    AND IMWENotes.Identifier = @DescriptionID
                                    AND IMWENotes.RecordType = @rectype;
							SET @IsEmptyDescription= CASE WHEN @Description IS  NULL THEN 'Y' ELSE 'N' END;  
                                                                     
                        END;

/********** Validate ServiceItem - no default ***********/  
                    IF @ServiceItemID <> 0 AND @IsEmptyServiceItem ='N'
                        BEGIN;
                            SELECT  @msg = ServiceItem
                            FROM    dbo.vSMWorkOrder WITH ( NOLOCK )
                            JOIN    dbo.vSMServiceItems WITH ( NOLOCK )
                                    ON vSMServiceItems.SMCo = dbo.vSMWorkOrder.SMCo 
                                       AND vSMServiceItems.ServiceSite = dbo.vSMWorkOrder.ServiceSite
                            WHERE   vSMWorkOrder.SMCo = @SMCo
                                    AND vSMWorkOrder.WorkOrder = @WorkOrder
                                    AND vSMServiceItems.ServiceItem = @ServiceItem;
                            IF @@rowcount = 0 
                                UPDATE  IMWE
                                SET     IMWE.UploadVal = '**Invalid Service item'
                                WHERE   IMWE.ImportTemplate = @ImportTemplate
                                        AND IMWE.ImportId = @ImportId
                                        AND IMWE.RecordSeq = @currrecseq
                                        AND IMWE.Identifier = @ServiceItemID
                                        AND IMWE.RecordType = @rectype;
                        END;

 -- Get Next RecSeq

                    SELECT  @currrecseq = @Recseq;
                    SELECT  @counter = @counter + 1;
    
                END;		--End SET DEFAULT VALUE process
        END;		-- End @complete Loop, Last IMWE record has been processed

    CLOSE WorkEditCursor;
    DEALLOCATE WorkEditCursor;
    SELECT  @rcode = 0

									
/** EXIT **/
    vspexit:
    SELECT  @msg = ISNULL(@desc, 'Work Order Scope Tasks ') + CHAR(13)
            + CHAR(13) + '[vspIMVPDefaultsSMWOScopeTask]';

    RETURN @rcode;
GO
GRANT EXECUTE ON  [dbo].[vspIMVPDefaultsSMWOScopeTask] TO [public]
GO
