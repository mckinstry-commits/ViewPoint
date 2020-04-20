SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[cvspVU8085_JulianDatePO]
/**************************************************************************
      Created By:       VCS Tech Services - Jake Fisher
      Modified By:            
      Usage:                  Used to get the next purchase order number formatted to today's Julian Date + Sequence Number.
            Pass:
                  Project           PM Project
                  

                  Success returns:
                        0 - Success
                        1 - ERROR
                  
                  Output:
                        @PO - Next purchase order

                  Error:
                        1 and error message
**************************************************************************/
	(
		@PMCo		VARCHAR(10)	= NULL, 
		@Project	VARCHAR(30)	= NULL, 
		@POCo		VARCHAR(10)	= NULL,
		@PO			VARCHAR(30)	= NULL OUTPUT)



AS

SET NOCOUNT ON

DECLARE 
      @rcode			INT, 
      @retcode          INT, 
      @pono             VARCHAR(1), 
      @posigpartjob     bYN, 
      @validpartjob     VARCHAR(30),
      @pocharsproject   TINYINT, 
      @pocharsvendor    TINYINT, 
      @projectpart      bProject,
      @formattedpo      VARCHAR(30), 
      @tmppo            VARCHAR(30), 
      @poseqlen         INT, 
      @mseq             INT,
      @paddedstring     VARCHAR(60),
      @tmpseq           VARCHAR(30), 
      @sigcharspo       SMALLINT,
      @tmpproject       VARCHAR(30), 
      @actchars         SMALLINT, 
      @polength         VARCHAR(10), 
      @pomask           VARCHAR(30),
      @dummy_po         VARCHAR(30), 
      @tmppo1           VARCHAR(30), 
      @i                INT, 
      @value            VARCHAR(1), 
      @tmpseq1          VARCHAR(10),
      @postartseq       SMALLINT, 
      @counter          INT,
      @TranType         CHAR(1)
      
      

SELECT 
      @rcode            = 0, 
      @PO               = '', 
      @counter			= 0

/**Get input mask for bPO**/
      SELECT 
            @pomask           = InputMask, 
            @polength   = CONVERT(VARCHAR(10), InputLength)
      FROM DDDTShared WITH (NOLOCK)
      WHERE Datatype = 'bPO'
      
            IF ISNULL(@pomask,'') = '' 
                  SELECT @pomask = 'L'
            
            IF ISNULL(@polength,'') = '' 
                  SELECT @polength = '10'
                  
            IF @pomask in ('R','L')
                  BEGIN
                        SELECT @pomask = @polength + @pomask + 'N'
                  END


      SELECT 
            @tmppo      = NULL, 
            @tmppo1     = NULL, 
            @mseq = 1
            
/**Max from PMMF**/
      SELECT @tmppo = LTRIM(RTRIM(MAX(PO))) 
      FROM bPMMF 
      WHERE SUBSTRING(PO,1,5) = CONVERT(VARCHAR(30),dbo.JulianDate(GETDATE()))

/**Max from POHD, POHB, POPendingPurchaseOrder**/
      SELECT @tmppo1 = LTRIM(RTRIM(MAX(PO))) 
      FROM dbo.POUnique 
      WHERE SUBSTRING(PO,1,5) = CONVERT(VARCHAR(30),dbo.JulianDate(GETDATE()))
      

/**Use highest to get next sequence**/
      IF ISNULL(@tmppo,'') <> '' AND ISNULL(@tmppo1,'') = ''
            SELECT @tmppo1 = @tmppo
      
      IF ISNULL(@tmppo1,'') <> '' AND ISNULL(@tmppo,'') = ''
            SELECT @tmppo = @tmppo1

      IF @tmppo1 > @tmppo 
            SELECT @tmppo = @tmppo1

/**Build PO**/
      build_po:

      /**format po using appropiate value**/
      SELECT 
            @dummy_po         = NULL, 
            @formattedpo      =  ISNULL(@tmppo,CONVERT(VARCHAR(30),dbo.JulianDate(GETDATE()))
								 + RIGHT('000'+ CONVERT(VARCHAR,(ROW_NUMBER() OVER (PARTITION BY @PO ORDER BY @PO))),3))
            
      SET @dummy_po = CONVERT(VARCHAR(30),dbo.JulianDate(GETDATE()))
                              + RIGHT('000'+ CONVERT(VARCHAR,(ROW_NUMBER() OVER (PARTITION BY @PO ORDER BY @PO))),3)
      
/**Check if purchase order already exists**/

      IF EXISTS
            (SELECT * FROM POHD WITH (NOLOCK) WHERE PO=@formattedpo)
      OR EXISTS
            (SELECT * FROM dbo.PMMF WHERE PO=@formattedpo)
      OR EXISTS
			(SELECT * FROM dbo.POUnique WHERE PO=@formattedpo)
      
            BEGIN 
                  SELECT @formattedpo = CAST(MAX(PO) AS INT)+1 
					from POUnique 
					where SUBSTRING(PO,1,5) = CONVERT(VARCHAR(30),dbo.JulianDate(GETDATE()))
            end
            
      ELSE
            SELECT @formattedpo = LTRIM(RTRIM(@formattedpo))

      SELECT @PO = @formattedpo
      

bspexit:
      return @rcode
GO
GRANT EXECUTE ON  [dbo].[cvspVU8085_JulianDatePO] TO [public]
GO
