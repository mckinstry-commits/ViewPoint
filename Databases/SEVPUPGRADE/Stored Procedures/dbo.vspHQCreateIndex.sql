SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE[dbo].[vspHQCreateIndex]  
	/**********************************************************  
	* Created:  JonathanP	06/11/07 - Adapted from bspHQCreateIndex  
	* History:  JonathanP	06/11/07 - Changed all DD table references to vDD.   
	*			JonathanP	06/13/08 - See issue #128454. We now check to make sure a column name UniqueAttchID exists  
	*									linked tables before running "exec @rowCount = bspGetRowCount @selectstring"  
	*			JonathanP	08/26/08 - #129534. Search for 129534 in this procedure to find my change.  
	*			JonathanP	10/14/08 - #129277. @mod will now be capitalized when it gets a value to include UD forms correctly.  
	*			RickM		05/13/09 - #133498 - Exclude AttachmentID from allowed index columns.  
	*			Dave C		07/23/09 - #134840 - Added a "SkipIndex" flag to prevent some fields from being added to HQAD  
	*			JVH			11/30/09 - #136513 - Commented print line so that it doesn't appear in error messages
	*			CC			04/27/10 - #139151 - Use temp table & variables to avoid hitting system tables repeatedly,
	*											 reformatted, removed cursor
	*			JVH			10/19/10 - #141299 - Changed @hqattable,@detailtable,@realtable,@indextable,@subdetailtable to varchar(128)
	*           FDT			10/21/11 - B-06396 - Added "Customer" and "CustGroup" to CASE which filters
	*                                            out duplicate "truncated" names.
	*     
	* Usage:  
	* Creates HQAI Attachment Indexes  
	*  
	* Inputs:  
	* @attachID  Attachment ID  
	* @clearexisting Y = delete and refesh index, N = leave existing index, add new only  
	*  
	* Outputs:  
	* @msg   Message  
	*  
	* Return Code:  
	* @rcode   0 = success, 1 = error  
	*  
	************************************************************/  
       
      (@attachID int, @clearexisting bYN = 'Y', @msg varchar(255) = '' OUTPUT)  
        
     AS
     BEGIN
     SET NOCOUNT ON;
        
	DECLARE @rcode int,
			@returnID UNIQUEIDENTIFIER,
			@hqattable varchar(128),
			@uniqueID uniqueidentifier,
			@selectstring nvarchar(max),
			@detailtable varchar(128),
			@joinclause varchar(255),
			@columnname varchar(100),
			@tmptocols varchar(1500),
			@tmpfromcols varchar(1500),
			@tableid int,
			@mod char(2),
			@hqaicolumn varchar(30),
			@realtable varchar(128),
			@indextable varchar(128),
			@subdetailtable varchar(128),
			@attachform varchar(30),
			@currentState varchar(1),
			@tocoltype varchar(50),
			@fromcoltype varchar(50) ;
       
     SELECT  @rcode = 0,
			 @returnID = NULL;
      

	      
	-- get guid and attachment table from HQ Attachments  
	SELECT  @uniqueID = UniqueAttchID,
			@hqattable = TableName,
			@attachform = CASE CHARINDEX('.', FormName)
							WHEN 0 THEN FormName
							ELSE LEFT(FormName, CHARINDEX('.', FormName) - 1)
						  END,
			@currentState = CurrentState
	FROM    bHQAT WITH ( NOLOCK )
	WHERE   AttachmentID = @attachID;

	IF @@rowcount = 0
		GOTO bspexit

	-- See issue #129534. Only refresh attached attachments and make sure we have a table for the next section.  
	IF @currentState <> 'A'
		OR @currentState IS NULL
		OR @hqattable IS NULL
		BEGIN
			GOTO bspexit;
		END

     SELECT @selectstring='SELECT @returnID = UniqueAttchID FROM [' + isnull(@hqattable,'') + '] WITH ( NOLOCK ) WHERE UniqueAttchID=@uniqueID'  
     EXEC sp_executesql @selectstring, N'@uniqueID uniqueidentifier, @returnID uniqueidentifier OUTPUT', @uniqueID = @uniqueID, @returnID = @returnID OUTPUT;
       
     WHILE @returnID IS NULL
     BEGIN
      SELECT @realtable = MIN(LinkedTable)  
      FROM vDDLT with (nolock)  
      WHERE PrimaryTable = @hqattable AND
			((LinkedTable>@realtable) OR @realtable IS NULL);
         
      IF @realtable IS NULL
      BEGIN
       SELECT	@msg='Could not find record for this attachment, Create indexes failed.',
				@rcode=1 ;
       GOTO bspexit  
      END 
         
       -- check for existence in linked table  
      SELECT @selectstring='SELECT @returnID = UniqueAttchID FROM [' + isnull(@realtable,'') + '] WITH ( NOLOCK ) WHERE UniqueAttchID=@uniqueID'
         
       -- See issue #128454  
		IF EXISTS (	SELECT TOP 1 1 
					FROM sys.syscolumns 
					WHERE id = OBJECT_ID(@realtable) AND name = 'UniqueAttchID')  
		BEGIN		    
			EXEC sp_executesql @selectstring, N'@uniqueID uniqueidentifier, @returnID uniqueidentifier OUTPUT', @uniqueID = @uniqueID, @returnID = @returnID OUTPUT;
		END                     
     END  
       
     SELECT @hqattable=ISNULL(@realtable,@hqattable);
        
      -- See 129277. Module is first 2 chars of table name. We use upper() to cover ud forms  
      -- and since the module should always be capitalized. (@mod is only 2 characters)  
     SELECT @mod = UPPER(@hqattable),
			@selectstring=NULL;
       
       
		-- get related detail table and join info from DD Header Detail  
		SELECT  @detailtable = DetailTable,
				@joinclause = JoinClause
		FROM    vDDHD WITH ( NOLOCK )
		WHERE   HeaderTable = @hqattable;
		
		IF @@rowcount <> 0 
			SELECT  @selectstring = ' left outer join ' + ISNULL(@detailtable, '')
					+ ' on ' + ISNULL(@joinclause, '');
		        
       
     
		-- get related  3rd detail table and join info from DD Header Detail  
		SELECT  @subdetailtable = DetailTable,
				@joinclause = JoinClause
		FROM    vDDHD WITH ( NOLOCK )
		WHERE   HeaderTable = @detailtable;
		
		IF @@rowcount <> 0 
			SELECT  @selectstring = ISNULL(@selectstring, '') + ' left outer join '
					+ ISNULL(@subdetailtable, '') + ' on ' + ISNULL(@joinclause, '');
     
		--filter on UniqueAttchID  
		SELECT  @selectstring = ISNULL(@selectstring, '') + ' where '
				+ ISNULL(@hqattable, '') + '.UniqueAttchID = @uniqueID',          
				@tmptocols = '',
				@tmpfromcols = '';

		   --This Select matches per form and/or per module
		   --Declare cursor to hold all columns in this particular table (@tablex)
		   --SkipIndex column of HQAD is used to prevent a field from being mapped.  
		DECLARE @SubDetailID int,
			@DetailID int,
			@hqatID int,
			@hqaiID int ;
					
		SELECT  @SubDetailID = OBJECT_ID(ISNULL(@subdetailtable,
												ISNULL(@detailtable, @hqattable))),
				@DetailID = OBJECT_ID(ISNULL(@detailtable, @hqattable)),
				@hqatID = OBJECT_ID(@hqattable),
				@hqaiID = OBJECT_ID('bHQAI') ;


		CREATE TABLE #SystemColumns
		(
		  name varchar(255),
		  id int,
		  CoColumnName varchar(255),
		  TruncatedColumnName varchar(255)
		);
		CREATE INDEX IDX_sysc ON tempdb..#SystemColumns(name);
		CREATE INDEX IDX_sysc_id ON tempdb..#SystemColumns(id);

		INSERT  #SystemColumns
				( name,
				  id,
				  CoColumnName,
				  TruncatedColumnName
				)
				( SELECT    name,
							id,
							CASE name
							  WHEN 'Co' THEN @mod + name
							  WHEN 'Customer' THEN @mod + name
							  WHEN 'CustGroup' THEN @mod + name
							  ELSE name
							END,
							RIGHT(name, LEN(name) - 2)
				  FROM      syscolumns WITH ( NOLOCK )
				  WHERE     id IN ( @SubDetailID, @DetailID, @hqatID, @hqaiID )
							AND name NOT IN ( 'Notes', 'UniqueAttchID', 'AttachmentID' )
				) ;

		DECLARE @SystemTypes TABLE
		(
		  TypeName varchar(255),
		  ColumnName varchar(255),
		  TableId int
		) ;
		INSERT  INTO @SystemTypes
				( TypeName,
				  ColumnName,
				  TableId
				)
				( SELECT    TYPE_NAME(systypes.xtype),
							syscolumns.name,
							syscolumns.id
				  FROM      systypes WITH ( NOLOCK )
							INNER JOIN syscolumns WITH ( NOLOCK ) ON systypes.xusertype = syscolumns.xusertype
				  WHERE     syscolumns.id IN ( @SubDetailID, @DetailID, @hqatID,
											   @hqaiID )
				) ;

		DECLARE @IndexColumns TABLE
		(
		  ColumnName varchar(128),
		  TableID int,
		  HQAITableID int,
		  HQAIColumn varchar(128),
		  SkipIndex char(1),
		  SortCol INT,
		  Form VARCHAR (30),
		  Module CHAR(2)
		) ;
		INSERT  INTO @IndexColumns
				( ColumnName,
				  TableID,
				  HQAITableID,
				  HQAIColumn,
				  SkipIndex,
				  SortCol,
				  Form,
				  Module
				)
				( SELECT    s.name,
							s.id,
							h.id,
							h.name,
							CASE WHEN ( d.Form IS NULL
										AND d.Module IS NULL
									  ) THEN 'N'
								 ELSE d.SkipIndex
							END,
							/*Sort Column*/ 
							CASE OBJECT_NAME ( s.id )
								WHEN @hqattable THEN 3 
								WHEN @detailtable THEN 2 
								WHEN @subdetailtable THEN 1 
							END as SortCol,
							d.Form,
							d.Module
				  FROM      #SystemColumns AS h WITH ( NOLOCK ) --HQAI Columns  
							JOIN HQAD AS d WITH ( NOLOCK ) ON d.ParentColumn = h.name
							JOIN #SystemColumns AS s WITH ( NOLOCK ) --Source Table Columns  
							ON ( d.ColumnName = s.name
								 OR d.ColumnName = s.CoColumnName
							   )
				  WHERE     s.id IN ( @SubDetailID, @DetailID, @hqatID )
							AND h.id = @hqaiID
							AND ( d.Module = @mod
								  OR d.Module IS NULL
								)
							AND ( d.Form = @attachform
								  OR d.Form IS NULL
								)
				  UNION  
				  		   
		   --This Select pattern matches   
		   --SkipIndex column set to 'N', since default behaviour is not to skip creating an index  
				  SELECT    s.name,
							s.id,
							h.id,
							h.name,
							'N',
							/*Sort Column*/ 
							CASE OBJECT_NAME ( s.id )
								WHEN @hqattable THEN 3 
								WHEN @detailtable THEN 2 
								WHEN @subdetailtable THEN 1 
							END as SortCol,
							NULL,
							NULL
				  FROM      #SystemColumns AS h WITH ( NOLOCK )--HQAI Columns  
							JOIN #SystemColumns AS s WITH ( NOLOCK )  --Source Table Columns  
							ON ( h.name = s.name
								 OR h.name = s.CoColumnName
								 OR h.TruncatedColumnName = s.CoColumnName
							   )
				  WHERE     s.id IN ( @SubDetailID, @DetailID, @hqatID )
							AND h.id = @hqaiID
				) ;
	
		WITH DistinctSet (HQAIColumn, TableID, ColumnName, RowNumber)
		AS
		(
		SELECT  [@IndexColumns].HQAIColumn ,
				[@IndexColumns].TableID,
				[@IndexColumns].ColumnName,
				ROW_NUMBER() OVER	(
									PARTITION BY [@IndexColumns].HQAIColumn 
									ORDER BY [@IndexColumns].SortCol, [@IndexColumns].Form DESC, [@IndexColumns].Module DESC 
									) AS RowNumber
		FROM    @IndexColumns 
				LEFT OUTER JOIN @IndexColumns AS ExcludeColumns ON ( [@IndexColumns].ColumnName = ExcludeColumns.ColumnName
																	 AND ExcludeColumns.SkipIndex = 'Y'
																   )
				LEFT OUTER JOIN @SystemTypes AS FromColumn ON [@IndexColumns].ColumnName = FromColumn.ColumnName
														  AND [@IndexColumns].TableID = FromColumn.TableId
				LEFT OUTER JOIN @SystemTypes AS ToColumn ON [@IndexColumns].HQAIColumn = ToColumn.ColumnName
														AND [@IndexColumns].HQAITableID = ToColumn.TableId
		WHERE   NOT ( ToColumn.TypeName IN ( 'tinyint', 'smallint', 'int', 'bigint',
											 'decimal', 'numeric', 'money' )
											 
					  AND FromColumn.TypeName NOT IN ( 'tinyint', 'smallint', 'int',
													   'bigint', 'decimal', 'numeric',
													   'money' )
					)
				AND ExcludeColumns.SkipIndex IS NULL
		)
		SELECT
			@tmptocols = ISNULL(@tmptocols, '') + CASE ISNULL(@tmptocols, '')
													WHEN '' THEN ''
													ELSE ','
												  END + HQAIColumn ,
			@tmpfromcols = ISNULL(@tmpfromcols, '')
			+ CASE ISNULL(@tmpfromcols, '')
				WHEN '' THEN ''
				ELSE ','
			  END + OBJECT_NAME(TableID) + '.'
			+ ColumnName
		FROM DistinctSet
		WHERE RowNumber = 1
		;				

		SELECT  @selectstring = 'INSERT HQAI(AttachmentID,' + ISNULL(@tmptocols, '')
				+ ') Select ' + ISNULL(CONVERT(varchar(10), @attachID), '') + ','
				+ ISNULL(@tmpfromcols, '') + ' from ' + ISNULL(@hqattable, '')
				+ ' with (nolock) ' + ISNULL(@selectstring, '');

     --print @selectstring

     -- update attachment index  
     IF ISNULL (@tmptocols,'') <> ''  
      BEGIN   
       -- delete existing index entry  
         IF @clearexisting = 'Y'  
			--issue #22727, do not delete user-added (custom) indexes.  
			--  delete bHQAI where AttachmentID = @attachID  
			DELETE bHQAI WHERE AttachmentID = @attachID AND CustomYN = 'N';
         
		-- insert new index entry (possible duplicates if @clearexisting <> 'Y' ??????)  
		 EXEC sp_executesql @selectstring, N'@uniqueID uniqueidentifier', @uniqueID = @uniqueID ;    
       END 
        
     bspexit:  
      RETURN @rcode;
END      
GO
GRANT EXECUTE ON  [dbo].[vspHQCreateIndex] TO [public]
GO
