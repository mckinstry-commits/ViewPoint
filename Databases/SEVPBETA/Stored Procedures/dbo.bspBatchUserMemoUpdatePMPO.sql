SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/**********************************************************/
CREATE  PROCEDURE [dbo].[bspBatchUserMemoUpdatePMPO]
   /***********************************************************
   * CREATED BY:	MV 03/13/03
   * MODIFIED By: GF 09/01/2003 - issue #22327 - changed to view, expanded update string, expanded pmmfseq value
   *				GF 07/12/2004 - issue #25080 - convert for p.POItem was only 3 chararcters. Needs to be bigger.
   *				GF 01/14/2005 - #25726 changed exec update to sp_executesql statement. changed varchar to nvarchar
   *			    DANF 04/02/2008 - #125049 Corrected update statement to include variable in the dynamic sql statement.
   *				AMR - 6/27/11 - TK-06411, Fixing performance issue by using an inline table function.
   *				TRL  07/27/2011  TK-07143  Expand bPO parameters/varialbles to varchar(30)
   *				GP 7/29/2011 - TK-07143 changed @PO from varchar(10) to varchar(30)
   *
   *
   * USAGE:     Updates POIB with
   *            user memo data from PMMF for PM Interface
   *
   * INPUT:
   *
   * OUTPUT:
   *   @errmsg     if something went wrong
   * RETURN VALUE
   *   0   success
   *   1   fail
   *****************************************************/
    (
      @poco bCompany,
      @mth bMonth,
      @batchid bBatchID,
      @batchseq INT,
      @po varchar(30),
      @poitem bItem,
      @pmco INT,
      @project bJob,
      @pmmfseq INT,
      @errmsg VARCHAR(255) OUTPUT
    )
AS 
    SET nocount ON
     
    DECLARE @rcode INT,
        @updatestring NVARCHAR(4000),
        @columnname VARCHAR(30),
        @paramsin NVARCHAR(500)
      
    SELECT  @rcode = 0
   
   -- -- -- define parameters for exec sql statement #25726
    SELECT  @paramsin = N'@poco tinyint, @mth bMonth, @batchid int, @batchseq int, @po varchar(30), '
            + '@poitem smallint, @pmco tinyint, @project varchar(10), @pmmfseq int'
   
   
    SELECT  @columnname = MIN(ColumnName)
			-- using inline table function for perf
    FROM    dbo.vfDDFIShared('PMPOItems')
    WHERE   FieldType = 4
            AND ColumnName LIKE 'ud%'
            
    WHILE @columnname IS NOT NULL 
        BEGIN
            IF EXISTS ( SELECT  *
							-- using inline table function for perf
                        FROM    dbo.vfDDFIShared('POEntryItems')
                        WHERE   ColumnName = @columnname ) 
                BEGIN
                    SELECT  @updatestring = NULL
                    SELECT  @updatestring = 'update POIB set ' + @columnname
                            + '= p.' + @columnname
                            + ' from PMMF p join POIB b on p.POCo=b.Co and p.POItem=b.POItem 
    				  where b.Co = @poco and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @batchseq
    					and b.POItem= @poitem and p.PMCo= @pmco and p.Project= @project and p.Seq= @pmmfseq 
    					and p.POCo= @poco and p.PO= @po and p.POItem=@poitem'
   
   		-- -- -- changed to use sp_executesql - #25726
                    EXECUTE sp_executesql @updatestring, @paramsin, @poco,
                        @mth, @batchid, @batchseq, @po, @poitem, @pmco,
                        @project, @pmmfseq
   -- -- -- 		exec (@updatestring)
                    IF @@rowcount = 0 
                        BEGIN
                            SELECT  @rcode = 1
                            RETURN @rcode
                        END
                END
  
            SELECT  @columnname = MIN(ColumnName)
					-- using inline table function for perf
            FROM    dbo.vfDDFIShared('PMPOItems')
            WHERE   FieldType = 4
                    AND ColumnName LIKE 'ud%'
                    AND ColumnName > @columnname
        END
   
    RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[bspBatchUserMemoUpdatePMPO] TO [public]
GO
